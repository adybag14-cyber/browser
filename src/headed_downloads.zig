// Copyright (C) 2023-2026 Lightpanda contributors
// Headed-browser download manager. Keeps explicit <a download> requests out of
// page navigation while reusing Lightpanda's HTTP stack, cookie jar and headers.

const std = @import("std");
const lp = @import("lightpanda");
const HostPaths = @import("HostPaths.zig");

const App = lp.App;
const Display = lp.Display;
const Frame = lp.Frame;
const HttpClient = lp.HttpClient;
const Notification = lp.Notification;
const Session = lp.Session;

const MAX_DOWNLOADS_HISTORY: usize = 64;
const DOWNLOADS_DIR = "downloads";
const DOWNLOADS_FILE = "downloads-v1.txt";
const MAX_DOWNLOADS_STATE_BYTES: usize = 128 * 1024;

const Status = enum(u8) {
    queued,
    downloading,
    completed,
    failed,
    interrupted,
};

const Entry = struct {
    filename: []u8,
    path: []u8,
    url: []u8,
    detail: []u8 = &.{},
    bytes_received: usize = 0,
    total_bytes: usize = 0,
    has_total_bytes: bool = false,
    status: Status = .queued,

    fn deinit(self: *Entry, allocator: std.mem.Allocator) void {
        allocator.free(self.filename);
        allocator.free(self.path);
        allocator.free(self.url);
        allocator.free(self.detail);
        self.* = undefined;
    }
};

pub const Manager = struct {
    allocator: std.mem.Allocator,
    downloads_dir: []u8,
    state_file_path: ?[]u8,
    entries: std.ArrayListUnmanaged(Entry) = .empty,
    active: std.ArrayListUnmanaged(*ActiveDownload) = .empty,
    last_saved_hash: u64 = 0,

    pub fn init(app: *App, profile_dir: ?[]const u8) !Manager {
        const downloads_dir = if (HostPaths.resolveProfileSubdir(app.allocator, profile_dir, DOWNLOADS_DIR)) |path|
            path
        else blk: {
            try std.Io.Dir.cwd().createDirPath(lp.io, DOWNLOADS_DIR);
            break :blk try app.allocator.dupe(u8, DOWNLOADS_DIR);
        };
        errdefer app.allocator.free(downloads_dir);

        const state_file_path = HostPaths.resolveProfileFile(app.allocator, profile_dir, DOWNLOADS_FILE);
        errdefer if (state_file_path) |path| app.allocator.free(path);

        var manager: Manager = .{
            .allocator = app.allocator,
            .downloads_dir = downloads_dir,
            .state_file_path = state_file_path,
        };
        manager.loadFromDisk();
        return manager;
    }

    pub fn deinit(self: *Manager) void {
        for (self.active.items) |download| download.cancel(.interrupted, "Browser shutting down");
        while (self.active.pop()) |download| {
            download.deinit();
        }
        self.active.deinit(self.allocator);
        self.persistIfChanged();

        while (self.entries.pop()) |value| {
            var entry = value;
            entry.deinit(self.allocator);
        }
        self.entries.deinit(self.allocator);
        if (self.state_file_path) |path| self.allocator.free(path);
        self.allocator.free(self.downloads_dir);
        self.* = undefined;
    }

    pub fn processPendingRequests(
        self: *Manager,
        app: *App,
        frame: *Frame,
        session: *Session,
        notification: *Notification,
        source_token: *anyopaque,
    ) !void {
        var pending = session.takePendingDownloads();
        defer {
            for (pending.items) |*request| request.deinit(app.allocator);
            pending.deinit(app.allocator);
        }

        for (pending.items) |request| {
            try self.startDownload(app, frame, session, notification, source_token, request.url, request.suggested_filename);
        }
    }

    pub fn startDownloadFromValues(
        self: *Manager,
        app: *App,
        frame: *Frame,
        session: *Session,
        notification: *Notification,
        source_token: *anyopaque,
        url: []const u8,
        suggested_filename: []const u8,
    ) !void {
        try self.startDownload(app, frame, session, notification, source_token, url, suggested_filename);
    }

    pub fn tick(self: *Manager, timeout_ms: u32) void {
        for (self.active.items) |download| {
            if (download.finished) continue;
            _ = download.http_client.tick(timeout_ms) catch |err| download.fail("Download tick failed", err);
        }

        var i: usize = 0;
        while (i < self.active.items.len) {
            const download = self.active.items[i];
            if (!download.finished) {
                i += 1;
                continue;
            }
            _ = self.active.orderedRemove(i);
            download.deinit();
        }
    }

    pub fn cancelForSource(self: *Manager, source_token: *anyopaque) void {
        for (self.active.items) |download| {
            if (download.source_token == source_token) download.cancel(.interrupted, "Tab closed");
        }
        self.persistIfChanged();
    }

    pub fn removeEntry(self: *Manager, index: usize) bool {
        if (index >= self.entries.items.len or self.entryActive(index)) return false;
        var removed = self.entries.orderedRemove(index);
        deletePath(removed.path);
        removed.deinit(self.allocator);
        for (self.active.items) |download| {
            if (download.entry_index > index) download.entry_index -= 1;
        }
        self.persistIfChanged();
        return true;
    }

    pub fn clearCompleted(self: *Manager) void {
        var i = self.entries.items.len;
        while (i > 0) {
            i -= 1;
            if (self.entries.items[i].status == .completed and !self.entryActive(i)) {
                _ = self.removeEntry(i);
            }
        }
    }

    pub fn entryUrl(self: *const Manager, index: usize) ?[]const u8 {
        if (index >= self.entries.items.len) return null;
        return self.entries.items[index].url;
    }

    pub fn entryPath(self: *const Manager, index: usize) ?[]const u8 {
        if (index >= self.entries.items.len) return null;
        return self.entries.items[index].path;
    }

    pub fn entrySuggestedFilename(self: *const Manager, index: usize) ?[]const u8 {
        if (index >= self.entries.items.len) return null;
        return self.entries.items[index].filename;
    }

    pub fn toDisplayEntries(self: *Manager, allocator: std.mem.Allocator) ![]Display.DownloadEntry {
        const display_entries = try allocator.alloc(Display.DownloadEntry, self.entries.items.len);
        var initialized: usize = 0;
        errdefer {
            for (display_entries[0..initialized]) |entry| allocator.free(entry.status);
            allocator.free(display_entries);
        }
        for (self.entries.items, 0..) |entry, index| {
            display_entries[index] = .{
                .filename = entry.filename,
                .path = entry.path,
                .status = try formatStatus(allocator, entry),
                .removable = !self.entryActive(index),
            };
            initialized += 1;
        }
        return display_entries;
    }

    pub fn freeDisplayEntries(_: *Manager, allocator: std.mem.Allocator, entries: []Display.DownloadEntry) void {
        for (entries) |entry| allocator.free(entry.status);
        allocator.free(entries);
    }

    fn startDownload(
        self: *Manager,
        app: *App,
        frame: *Frame,
        session: *Session,
        notification: *Notification,
        source_token: *anyopaque,
        url: []const u8,
        suggested_filename: []const u8,
    ) !void {
        const derived_name = try deriveFileName(app.allocator, url, suggested_filename);
        defer app.allocator.free(derived_name);

        const final_name = try makeUniqueFileName(app.allocator, self.downloads_dir, derived_name);
        defer app.allocator.free(final_name);
        const file_path = try std.fs.path.join(app.allocator, &.{ self.downloads_dir, final_name });
        defer app.allocator.free(file_path);

        var file: ?std.Io.File = try std.Io.Dir.cwd().createFile(lp.io, file_path, .{ .truncate = true });
        errdefer deletePath(file_path);
        errdefer if (file) |owned_file| owned_file.close(lp.io);

        var entry = blk: {
            const owned_filename = try app.allocator.dupe(u8, final_name);
            errdefer app.allocator.free(owned_filename);
            const owned_path = try app.allocator.dupe(u8, file_path);
            errdefer app.allocator.free(owned_path);
            const owned_url = try app.allocator.dupe(u8, url);
            errdefer app.allocator.free(owned_url);
            break :blk Entry{
                .filename = owned_filename,
                .path = owned_path,
                .url = owned_url,
            };
        };
        var entry_owned = true;
        errdefer if (entry_owned) entry.deinit(app.allocator);

        const entry_index = self.entries.items.len;
        try self.entries.append(app.allocator, entry);
        entry_owned = false;
        errdefer self.persistIfChanged();
        errdefer {
            var removed = self.entries.pop().?;
            removed.deinit(app.allocator);
        }

        const download = try app.allocator.create(ActiveDownload);
        var download_state: enum { raw, initialized, transferred } = .raw;
        errdefer switch (download_state) {
            .raw => app.allocator.destroy(download),
            .initialized => {
                download.http_client.abort();
                download.deinit();
            },
            .transferred => {},
        };

        download.* = try ActiveDownload.init(app, self, source_token, entry_index, file.?);
        download_state = .initialized;
        file = null;

        try download.start(frame, session, notification, url);
        try self.active.append(app.allocator, download);
        download_state = .transferred;
        self.trimHistory();
        self.persistIfChanged();
    }
    fn trimHistory(self: *Manager) void {
        while (self.entries.items.len > MAX_DOWNLOADS_HISTORY) {
            if (self.entryActive(0)) return;
            var removed = self.entries.orderedRemove(0);
            removed.deinit(self.allocator);
            for (self.active.items) |download| {
                if (download.entry_index > 0) download.entry_index -= 1;
            }
        }
    }

    fn entryActive(self: *const Manager, index: usize) bool {
        for (self.active.items) |download| {
            if (download.entry_index == index and !download.finished) return true;
        }
        return false;
    }

    fn setDetail(entry: *Entry, allocator: std.mem.Allocator, detail: []const u8) void {
        allocator.free(entry.detail);
        entry.detail = allocator.dupe(u8, detail) catch &.{};
    }

    fn loadFromDisk(self: *Manager) void {
        const path = self.state_file_path orelse return;
        const data = std.Io.Dir.cwd().readFileAlloc(lp.io, path, self.allocator, .limited(MAX_DOWNLOADS_STATE_BYTES)) catch |err| switch (err) {
            error.FileNotFound => return,
            else => {
                lp.log.warn(.app, "headed downloads read failed", .{ .err = err, .path = path });
                return;
            },
        };
        defer self.allocator.free(data);

        var it = std.mem.splitScalar(u8, data, '\n');
        while (it.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, "\r\n");
            if (line.len == 0) continue;
            var entry = parseSavedEntry(self.allocator, line) catch continue;
            self.entries.append(self.allocator, entry) catch {
                entry.deinit(self.allocator);
                break;
            };
            self.trimLoadedHistory();
        }
        self.last_saved_hash = hashEntries(self.entries.items);
    }

    fn persistIfChanged(self: *Manager) void {
        const path = self.state_file_path orelse return;
        const hash = hashEntries(self.entries.items);
        if (hash == self.last_saved_hash) return;

        var buf = std.Io.Writer.Allocating.init(self.allocator);
        defer buf.deinit();
        for (self.entries.items) |entry| {
            buf.writer.print(
                "{d}\t{d}\t{d}\t{d}\t{s}\t{s}\t{s}\t{s}\n",
                .{
                    @intFromEnum(entry.status),
                    entry.bytes_received,
                    entry.total_bytes,
                    if (entry.has_total_bytes) @as(u8, 1) else @as(u8, 0),
                    sanitizePersistedField(entry.filename),
                    sanitizePersistedField(entry.path),
                    sanitizePersistedField(entry.url),
                    sanitizePersistedField(entry.detail),
                },
            ) catch |err| {
                lp.log.warn(.app, "headed downloads serialize failed", .{ .err = err });
                return;
            };
        }

        std.Io.Dir.cwd().writeFile(lp.io, .{ .sub_path = path, .data = buf.written() }) catch |err| {
            lp.log.warn(.app, "headed downloads write failed", .{ .err = err, .path = path });
            return;
        };
        self.last_saved_hash = hash;
    }

    fn trimLoadedHistory(self: *Manager) void {
        while (self.entries.items.len > MAX_DOWNLOADS_HISTORY) {
            var removed = self.entries.orderedRemove(0);
            removed.deinit(self.allocator);
        }
    }
};

const ActiveDownload = struct {
    allocator: std.mem.Allocator,
    manager: *Manager,
    source_token: *anyopaque,
    http_client: *HttpClient.Client,
    file: ?std.Io.File,
    arena: std.heap.ArenaAllocator,
    entry_index: usize,
    finished: bool = false,

    fn init(app: *App, manager: *Manager, source_token: *anyopaque, entry_index: usize, file: std.Io.File) !ActiveDownload {
        const client = try app.allocator.create(HttpClient.Client);
        errdefer app.allocator.destroy(client);
        try client.init(app.allocator, &app.network, null);
        return .{
            .allocator = app.allocator,
            .manager = manager,
            .source_token = source_token,
            .http_client = client,
            .file = file,
            .arena = std.heap.ArenaAllocator.init(app.allocator),
            .entry_index = entry_index,
        };
    }

    fn deinit(self: *ActiveDownload) void {
        if (self.file) |file| {
            file.close(lp.io);
            self.file = null;
        }
        self.http_client.deinit();
        self.allocator.destroy(self.http_client);
        self.arena.deinit();
        self.allocator.destroy(self);
    }

    fn start(self: *ActiveDownload, frame: *Frame, session: *Session, notification: *Notification, request_url: []const u8) !void {
        const arena = self.arena.allocator();
        const url_z = try arena.dupeZ(u8, request_url);
        const transfer = try self.http_client.newRequest(.{
            .ctx = self,
            .frame_id = frame._frame_id,
            .loader_id = frame._loader_id,
            .url = url_z,
            .method = .GET,
            .cookie_jar = &session.cookie_jar,
            .cookie_origin = frame.url,
            .resource_type = .fetch,
            .notification = notification,
            .header_callback = headerCallback,
            .data_callback = dataCallback,
            .done_callback = doneCallback,
            .error_callback = errorCallback,
            .shutdown_callback = shutdownCallback,
        }, null);
        errdefer transfer.deinit();
        try frame.headersForRequest(transfer);
        self.manager.entries.items[self.entry_index].status = .downloading;
        self.manager.persistIfChanged();
        try transfer.submit();
    }

    fn fail(self: *ActiveDownload, detail: []const u8, err: anyerror) void {
        if (self.finished) return;
        const entry = &self.manager.entries.items[self.entry_index];
        entry.status = .failed;
        const message = std.fmt.allocPrint(self.allocator, "{s}: {s}", .{ detail, @errorName(err) }) catch null;
        if (message) |owned| {
            defer self.allocator.free(owned);
            Manager.setDetail(entry, self.allocator, owned);
        } else {
            Manager.setDetail(entry, self.allocator, detail);
        }
        self.cleanupPartialFile();
        self.finished = true;
        self.manager.persistIfChanged();
    }

    fn cancel(self: *ActiveDownload, status: Status, detail: []const u8) void {
        if (self.finished) return;
        const entry = &self.manager.entries.items[self.entry_index];
        entry.status = status;
        Manager.setDetail(entry, self.allocator, detail);
        self.finished = true;
        self.cleanupPartialFile();
        self.manager.persistIfChanged();
        self.http_client.abort();
    }

    fn cleanupPartialFile(self: *ActiveDownload) void {
        if (self.file) |file| {
            file.close(lp.io);
            self.file = null;
        }
        deletePath(self.manager.entries.items[self.entry_index].path);
    }
};

fn headerCallback(transfer: *HttpClient.Transfer) !HttpClient.Transfer.HeaderResult {
    const download: *ActiveDownload = @ptrCast(@alignCast(transfer.req.ctx));
    const entry = &download.manager.entries.items[download.entry_index];
    entry.status = .downloading;
    if (transfer.getContentLength()) |content_length| {
        entry.total_bytes = content_length;
        entry.has_total_bytes = true;
    }
    if (transfer.responseStatus()) |status| {
        if (status >= 400) return error.BadStatusCode;
    }
    download.manager.persistIfChanged();
    return .proceed;
}

fn dataCallback(transfer: *HttpClient.Transfer, data: []const u8) !void {
    const download: *ActiveDownload = @ptrCast(@alignCast(transfer.req.ctx));
    const file = download.file orelse return error.Closed;
    try file.writeStreamingAll(lp.io, data);
    download.manager.entries.items[download.entry_index].bytes_received += data.len;
}

fn doneCallback(ctx: *anyopaque) !void {
    const download: *ActiveDownload = @ptrCast(@alignCast(ctx));
    if (download.finished) return;
    if (download.file) |file| {
        file.close(lp.io);
        download.file = null;
    }
    const entry = &download.manager.entries.items[download.entry_index];
    entry.status = .completed;
    Manager.setDetail(entry, download.allocator, "");
    download.finished = true;
    download.manager.persistIfChanged();
}

fn errorCallback(ctx: *anyopaque, err: anyerror) void {
    const download: *ActiveDownload = @ptrCast(@alignCast(ctx));
    if (download.finished) return;
    download.fail("Failed", err);
}

fn shutdownCallback(ctx: *anyopaque) void {
    const download: *ActiveDownload = @ptrCast(@alignCast(ctx));
    if (download.finished) return;
    download.cancel(.interrupted, "Interrupted");
}

fn hashEntries(entries: []const Entry) u64 {
    var hasher = std.hash.Wyhash.init(0);
    for (entries) |entry| {
        hasher.update(entry.filename);
        hasher.update(entry.path);
        hasher.update(entry.url);
        hasher.update(entry.detail);
        hasher.update(std.mem.asBytes(&entry.bytes_received));
        hasher.update(std.mem.asBytes(&entry.total_bytes));
        hasher.update(std.mem.asBytes(&entry.has_total_bytes));
        const status: u8 = @intFromEnum(entry.status);
        hasher.update(std.mem.asBytes(&status));
    }
    return hasher.final();
}

fn sanitizePersistedField(value: []const u8) []const u8 {
    return std.mem.trim(u8, value, "\r\n\t");
}

fn parseSavedEntry(allocator: std.mem.Allocator, line: []const u8) !Entry {
    var fields_it = std.mem.splitScalar(u8, line, '\t');
    const status_raw = fields_it.next() orelse return error.InvalidFormat;
    const received_raw = fields_it.next() orelse return error.InvalidFormat;
    const total_raw = fields_it.next() orelse return error.InvalidFormat;
    const has_total_raw = fields_it.next() orelse return error.InvalidFormat;
    const filename = fields_it.next() orelse return error.InvalidFormat;
    const path = fields_it.next() orelse return error.InvalidFormat;
    const url = fields_it.next() orelse return error.InvalidFormat;
    const detail = fields_it.next() orelse "";

    const status_value = try std.fmt.parseInt(u8, status_raw, 10);
    if (status_value > @intFromEnum(Status.interrupted)) return error.InvalidFormat;
    const saved_status: Status = @enumFromInt(status_value);
    const bytes_received = try std.fmt.parseInt(usize, received_raw, 10);
    const total_bytes = try std.fmt.parseInt(usize, total_raw, 10);
    const has_total_bytes = (try std.fmt.parseInt(u8, has_total_raw, 10)) != 0;

    const owned_filename = try allocator.dupe(u8, filename);
    errdefer allocator.free(owned_filename);
    const owned_path = try allocator.dupe(u8, path);
    errdefer allocator.free(owned_path);
    const owned_url = try allocator.dupe(u8, url);
    errdefer allocator.free(owned_url);
    const owned_detail = try allocator.dupe(u8, detail);
    errdefer allocator.free(owned_detail);

    return .{
        .filename = owned_filename,
        .path = owned_path,
        .url = owned_url,
        .detail = owned_detail,
        .bytes_received = bytes_received,
        .total_bytes = total_bytes,
        .has_total_bytes = has_total_bytes,
        .status = switch (saved_status) {
            .queued, .downloading => .interrupted,
            else => saved_status,
        },
    };
}
fn formatStatus(allocator: std.mem.Allocator, entry: Entry) ![]u8 {
    return switch (entry.status) {
        .queued => allocator.dupe(u8, "Queued"),
        .downloading => if (entry.has_total_bytes)
            std.fmt.allocPrint(allocator, "Downloading {d}/{d} B", .{ entry.bytes_received, entry.total_bytes })
        else
            std.fmt.allocPrint(allocator, "Downloading {d} B", .{entry.bytes_received}),
        .completed => std.fmt.allocPrint(allocator, "Complete {d} B", .{entry.bytes_received}),
        .failed, .interrupted => if (entry.detail.len > 0)
            allocator.dupe(u8, entry.detail)
        else if (entry.status == .failed)
            allocator.dupe(u8, "Failed")
        else
            allocator.dupe(u8, "Interrupted"),
    };
}

fn deriveFileName(allocator: std.mem.Allocator, url: []const u8, suggested_filename: []const u8) ![]u8 {
    const preferred = std.mem.trim(u8, suggested_filename, &std.ascii.whitespace);
    if (preferred.len > 0) return sanitizeFileName(allocator, preferred);

    const trimmed_url = std.mem.trim(u8, url, &std.ascii.whitespace);
    const slash_index = std.mem.lastIndexOfScalar(u8, trimmed_url, '/') orelse 0;
    const basename = if (slash_index + 1 < trimmed_url.len) trimmed_url[slash_index + 1 ..] else trimmed_url;
    const without_query = basename[0..(std.mem.indexOfAny(u8, basename, "?#") orelse basename.len)];
    if (without_query.len == 0) return allocator.dupe(u8, "download.bin");
    return sanitizeFileName(allocator, without_query);
}

fn sanitizeFileName(allocator: std.mem.Allocator, raw_name: []const u8) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(allocator);
    const trimmed = std.mem.trim(u8, raw_name, &std.ascii.whitespace);
    for (trimmed) |char| {
        switch (char) {
            '<', '>', ':', '"', '/', '\\', '|', '?', '*', '\r', '\n', '\t' => try buf.append(allocator, '_'),
            else => try buf.append(allocator, char),
        }
    }
    const candidate = std.mem.trim(u8, buf.items, ". ");
    if (candidate.len == 0) return allocator.dupe(u8, "download.bin");
    return allocator.dupe(u8, candidate);
}

fn makeUniqueFileName(allocator: std.mem.Allocator, downloads_dir: []const u8, base_name: []const u8) ![]u8 {
    if (!(try pathExists(allocator, downloads_dir, base_name))) return allocator.dupe(u8, base_name);
    const ext_index = std.mem.lastIndexOfScalar(u8, base_name, '.');
    const stem = if (ext_index) |index| base_name[0..index] else base_name;
    const ext = if (ext_index) |index| base_name[index..] else "";
    var suffix: usize = 2;
    while (true) : (suffix += 1) {
        const candidate = try std.fmt.allocPrint(allocator, "{s} ({d}){s}", .{ stem, suffix, ext });
        errdefer allocator.free(candidate);
        if (!(try pathExists(allocator, downloads_dir, candidate))) return candidate;
        allocator.free(candidate);
    }
}

fn pathExists(allocator: std.mem.Allocator, downloads_dir: []const u8, filename: []const u8) !bool {
    const path = try std.fs.path.join(allocator, &.{ downloads_dir, filename });
    defer allocator.free(path);
    std.Io.Dir.cwd().access(lp.io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return true,
    };
    return true;
}

fn deletePath(path: []const u8) void {
    if (path.len == 0) return;
    if (std.fs.path.isAbsolute(path)) {
        std.Io.Dir.deleteFileAbsolute(lp.io, path) catch {};
    } else {
        std.Io.Dir.cwd().deleteFile(lp.io, path) catch {};
    }
}
