// Copyright (C) 2023-2026 Lightpanda contributors
// Persistence helpers for the native headed browser profile.

const std = @import("std");
const lp = @import("lightpanda");
const HostPaths = @import("HostPaths.zig");
const storage = @import("browser/webapi/storage/storage.zig");

const SESSION_FILE = "browse-session-v1.txt";
const SETTINGS_FILE = "browse-settings-v1.txt";
const COOKIES_FILE = "cookies-v1.txt";
const LOCAL_STORAGE_FILE = "local-storage-v1.txt";
const MAX_SESSION_BYTES: usize = 64 * 1024;
const MAX_SETTINGS_BYTES: usize = 16 * 1024;
const MAX_COOKIES_BYTES: usize = 128 * 1024;
const MAX_LOCAL_STORAGE_BYTES: usize = 1024 * 1024;
const DEFAULT_ZOOM: i32 = 100;
const MIN_ZOOM: i32 = 30;
const MAX_ZOOM: i32 = 300;

pub const Settings = struct {
    restore_previous_session: bool = true,
    allow_script_popups: bool = true,
    default_zoom_percent: i32 = DEFAULT_ZOOM,
    homepage_url: ?[]u8 = null,

    pub fn deinit(self: *Settings, allocator: std.mem.Allocator) void {
        if (self.homepage_url) |url| allocator.free(url);
        self.* = .{};
    }
};

pub const TabState = struct {
    url: []const u8,
    zoom_percent: i32,
};

pub const SavedTab = struct {
    url: []u8,
    zoom_percent: i32,

    fn deinit(self: *SavedTab, allocator: std.mem.Allocator) void {
        allocator.free(self.url);
        self.* = undefined;
    }
};

pub const SavedSession = struct {
    tabs: std.ArrayListUnmanaged(SavedTab) = .empty,
    active_index: usize = 0,

    pub fn deinit(self: *SavedSession, allocator: std.mem.Allocator) void {
        for (self.tabs.items) |*tab| tab.deinit(allocator);
        self.tabs.deinit(allocator);
        self.* = .{};
    }
};

pub const Store = struct {
    allocator: std.mem.Allocator,
    session_path: ?[]u8,
    settings_path: ?[]u8,
    cookies_path: ?[]u8,
    local_storage_path: ?[]u8,
    last_session_hash: ?u64 = null,
    last_settings_hash: ?u64 = null,
    last_cookies_hash: ?u64 = null,
    last_local_storage_hash: ?u64 = null,

    pub fn init(allocator: std.mem.Allocator, profile_dir: ?[]const u8) Store {
        return .{
            .allocator = allocator,
            .session_path = HostPaths.resolveProfileFile(allocator, profile_dir, SESSION_FILE),
            .settings_path = HostPaths.resolveProfileFile(allocator, profile_dir, SETTINGS_FILE),
            .cookies_path = HostPaths.resolveProfileFile(allocator, profile_dir, COOKIES_FILE),
            .local_storage_path = HostPaths.resolveProfileFile(allocator, profile_dir, LOCAL_STORAGE_FILE),
        };
    }

    pub fn deinit(self: *Store) void {
        if (self.session_path) |path| self.allocator.free(path);
        if (self.settings_path) |path| self.allocator.free(path);
        if (self.cookies_path) |path| self.allocator.free(path);
        if (self.local_storage_path) |path| self.allocator.free(path);
        self.* = undefined;
    }

    pub fn loadCookies(self: *Store, jar: *storage.Cookie.Jar) void {
        const path = self.cookies_path orelse return;
        const data = std.Io.Dir.cwd().readFileAlloc(lp.io, path, self.allocator, .limited(MAX_COOKIES_BYTES)) catch |err| switch (err) {
            error.FileNotFound => {
                self.last_cookies_hash = hashCookies(jar);
                return;
            },
            else => {
                lp.log.warn(.app, "headed cookies read failed", .{ .err = err, .path = path });
                return;
            },
        };
        defer self.allocator.free(data);

        const previous_notification = jar.notification;
        jar.notification = null;
        defer jar.notification = previous_notification;

        var it = std.mem.splitScalar(u8, data, '\n');
        while (it.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, "\r\n ");
            if (line.len == 0 or std.mem.eql(u8, line, "lightpanda-browse-cookies-v1")) continue;
            if (!std.mem.startsWith(u8, line, "cookie\t")) continue;

            var fields = std.mem.splitScalar(u8, line["cookie\t".len..], '\t');
            const name = fields.next() orelse continue;
            const value = fields.next() orelse continue;
            const domain = fields.next() orelse continue;
            const cookie_path = fields.next() orelse continue;
            const expires_raw = fields.next() orelse continue;
            const secure_raw = fields.next() orelse continue;
            const http_only_raw = fields.next() orelse continue;
            const same_site_raw = fields.next() orelse continue;
            if (domain.len == 0 or cookie_path.len == 0) continue;

            const same_site = std.meta.stringToEnum(storage.Cookie.SameSite, same_site_raw) orelse continue;
            const expires: ?f64 = if (expires_raw.len == 0)
                null
            else
                @floatFromInt(std.fmt.parseInt(i64, expires_raw, 10) catch continue);
            const cookie = initOwnedCookie(
                self.allocator,
                name,
                value,
                domain,
                cookie_path,
                expires,
                parseBool(secure_raw),
                parseBool(http_only_raw),
                same_site,
            ) catch continue;
            jar.add(cookie, lp.datetime.timestamp(.real), true) catch |err| {
                lp.log.warn(.app, "headed cookie load failed", .{ .err = err });
            };
        }
        jar.removeExpired(null);
        self.last_cookies_hash = hashCookies(jar);
    }

    pub fn persistCookies(self: *Store, jar: *storage.Cookie.Jar) void {
        const path = self.cookies_path orelse return;
        const hash = hashCookies(jar);
        if (self.last_cookies_hash != null and self.last_cookies_hash.? == hash) return;

        var buf = std.Io.Writer.Allocating.init(self.allocator);
        defer buf.deinit();
        buf.writer.writeAll("lightpanda-browse-cookies-v1\n") catch return;
        jar.removeExpired(null);
        for (jar.cookies.items) |cookie| {
            if (cookie.expires) |expires| {
                buf.writer.print(
                    "cookie\t{s}\t{s}\t{s}\t{s}\t{d}\t{d}\t{d}\t{s}\n",
                    .{
                        cookie.name,
                        cookie.value,
                        cookie.domain,
                        cookie.path,
                        @as(i64, @intFromFloat(expires)),
                        if (cookie.secure) @as(u8, 1) else @as(u8, 0),
                        if (cookie.http_only) @as(u8, 1) else @as(u8, 0),
                        @tagName(cookie.same_site),
                    },
                ) catch return;
            } else {
                buf.writer.print(
                    "cookie\t{s}\t{s}\t{s}\t{s}\t\t{d}\t{d}\t{s}\n",
                    .{
                        cookie.name,
                        cookie.value,
                        cookie.domain,
                        cookie.path,
                        if (cookie.secure) @as(u8, 1) else @as(u8, 0),
                        if (cookie.http_only) @as(u8, 1) else @as(u8, 0),
                        @tagName(cookie.same_site),
                    },
                ) catch return;
            }
        }
        std.Io.Dir.cwd().writeFile(lp.io, .{ .sub_path = path, .data = buf.written() }) catch |err| {
            lp.log.warn(.app, "headed cookies write failed", .{ .err = err, .path = path });
            return;
        };
        self.last_cookies_hash = hash;
    }

    pub fn loadLocalStorage(self: *Store, shed: *storage.Shed) void {
        const path = self.local_storage_path orelse return;
        const data = std.Io.Dir.cwd().readFileAlloc(lp.io, path, self.allocator, .limited(MAX_LOCAL_STORAGE_BYTES)) catch |err| switch (err) {
            error.FileNotFound => {
                self.last_local_storage_hash = hashLocalStorage(self.allocator, shed);
                return;
            },
            else => {
                lp.log.warn(.app, "headed localStorage read failed", .{ .err = err, .path = path });
                return;
            },
        };
        defer self.allocator.free(data);

        var it = std.mem.splitScalar(u8, data, '\n');
        while (it.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, "\r\n ");
            if (line.len == 0 or std.mem.eql(u8, line, "lightpanda-browse-local-storage-v1")) continue;
            if (!std.mem.startsWith(u8, line, "entry\t")) continue;
            var fields = std.mem.splitScalar(u8, line["entry\t".len..], '\t');
            const origin_raw = fields.next() orelse continue;
            const key_raw = fields.next() orelse continue;
            const value_raw = fields.next() orelse continue;

            const origin = decodeStorageField(self.allocator, origin_raw) catch continue;
            defer self.allocator.free(origin);
            const key = decodeStorageField(self.allocator, key_raw) catch continue;
            defer self.allocator.free(key);
            const value = decodeStorageField(self.allocator, value_raw) catch continue;
            defer self.allocator.free(value);
            const bucket = shed.getOrPut(self.allocator, origin) catch continue;
            bucket.local.setItem(key, value) catch |err| {
                lp.log.warn(.app, "headed localStorage load failed", .{ .err = err });
            };
        }
        self.last_local_storage_hash = hashLocalStorage(self.allocator, shed);
    }

    pub fn persistLocalStorage(self: *Store, shed: *storage.Shed) void {
        const path = self.local_storage_path orelse return;
        const hash = hashLocalStorage(self.allocator, shed);
        if (self.last_local_storage_hash != null and self.last_local_storage_hash.? == hash) return;

        var entries = collectLocalStorageEntries(self.allocator, shed) catch return;
        defer entries.deinit(self.allocator);
        var buf = std.Io.Writer.Allocating.init(self.allocator);
        defer buf.deinit();
        buf.writer.writeAll("lightpanda-browse-local-storage-v1\n") catch return;
        for (entries.items) |entry| {
            const origin = encodeStorageField(self.allocator, entry.origin) catch return;
            defer self.allocator.free(origin);
            const key = encodeStorageField(self.allocator, entry.key) catch return;
            defer self.allocator.free(key);
            const value = encodeStorageField(self.allocator, entry.value) catch return;
            defer self.allocator.free(value);
            buf.writer.print("entry\t{s}\t{s}\t{s}\n", .{ origin, key, value }) catch return;
        }
        std.Io.Dir.cwd().writeFile(lp.io, .{ .sub_path = path, .data = buf.written() }) catch |err| {
            lp.log.warn(.app, "headed localStorage write failed", .{ .err = err, .path = path });
            return;
        };
        self.last_local_storage_hash = hash;
    }

    pub fn loadSettings(self: *Store) Settings {
        const path = self.settings_path orelse return .{};
        const data = std.Io.Dir.cwd().readFileAlloc(lp.io, path, self.allocator, .limited(MAX_SETTINGS_BYTES)) catch |err| switch (err) {
            error.FileNotFound => return .{},
            else => {
                lp.log.warn(.app, "headed settings read failed", .{ .err = err, .path = path });
                return .{};
            },
        };
        defer self.allocator.free(data);

        const settings = parseSettings(self.allocator, data) catch |err| {
            lp.log.warn(.app, "headed settings parse failed", .{ .err = err, .path = path });
            return .{};
        };
        self.last_settings_hash = hashSettings(settings);
        return settings;
    }

    pub fn persistSettings(self: *Store, settings: Settings) void {
        const path = self.settings_path orelse return;
        const hash = hashSettings(settings);
        if (self.last_settings_hash != null and self.last_settings_hash.? == hash) return;

        var buf = std.Io.Writer.Allocating.init(self.allocator);
        defer buf.deinit();
        buf.writer.writeAll("lightpanda-browse-settings-v1\n") catch return;
        buf.writer.print(
            "restore_previous_session\t{d}\nallow_script_popups\t{d}\ndefault_zoom_percent\t{d}\nhomepage_url\t{s}\n",
            .{
                if (settings.restore_previous_session) @as(u8, 1) else @as(u8, 0),
                if (settings.allow_script_popups) @as(u8, 1) else @as(u8, 0),
                std.math.clamp(settings.default_zoom_percent, MIN_ZOOM, MAX_ZOOM),
                sanitizeField(settings.homepage_url orelse ""),
            },
        ) catch |err| {
            lp.log.warn(.app, "headed settings serialize failed", .{ .err = err });
            return;
        };
        std.Io.Dir.cwd().writeFile(lp.io, .{ .sub_path = path, .data = buf.written() }) catch |err| {
            lp.log.warn(.app, "headed settings write failed", .{ .err = err, .path = path });
            return;
        };
        self.last_settings_hash = hash;
    }

    pub fn loadSession(self: *Store) SavedSession {
        const path = self.session_path orelse return .{};
        const data = std.Io.Dir.cwd().readFileAlloc(lp.io, path, self.allocator, .limited(MAX_SESSION_BYTES)) catch |err| switch (err) {
            error.FileNotFound => return .{},
            else => {
                lp.log.warn(.app, "headed session read failed", .{ .err = err, .path = path });
                return .{};
            },
        };
        defer self.allocator.free(data);

        const session = parseSession(self.allocator, data) catch |err| {
            lp.log.warn(.app, "headed session parse failed", .{ .err = err, .path = path });
            return .{};
        };
        self.last_session_hash = hashSavedSession(session);
        return session;
    }

    pub fn persistSession(self: *Store, tabs: []const TabState, active_index: usize, restore_previous_session: bool) void {
        const path = self.session_path orelse return;
        if (!restore_previous_session or tabs.len == 0) {
            std.Io.Dir.cwd().deleteFile(lp.io, path) catch |err| switch (err) {
                error.FileNotFound => {},
                else => lp.log.warn(.app, "headed session delete failed", .{ .err = err, .path = path }),
            };
            self.last_session_hash = null;
            return;
        }

        const normalized_active = @min(active_index, tabs.len - 1);
        const hash = hashTabStates(tabs, normalized_active);
        if (self.last_session_hash != null and self.last_session_hash.? == hash) return;

        var buf = std.Io.Writer.Allocating.init(self.allocator);
        defer buf.deinit();
        buf.writer.writeAll("lightpanda-browse-session-v1\n") catch return;
        buf.writer.print("active\t{d}\n", .{normalized_active}) catch return;
        for (tabs) |tab| {
            buf.writer.print(
                "tab\t{d}\t{s}\n",
                .{ std.math.clamp(tab.zoom_percent, MIN_ZOOM, MAX_ZOOM), sanitizeField(tab.url) },
            ) catch |err| {
                lp.log.warn(.app, "headed session serialize failed", .{ .err = err });
                return;
            };
        }
        std.Io.Dir.cwd().writeFile(lp.io, .{ .sub_path = path, .data = buf.written() }) catch |err| {
            lp.log.warn(.app, "headed session write failed", .{ .err = err, .path = path });
            return;
        };
        self.last_session_hash = hash;
    }
};

const LocalStorageEntryRef = struct {
    origin: []const u8,
    key: []const u8,
    value: []const u8,
};

fn localStorageEntryLessThan(_: void, a: LocalStorageEntryRef, b: LocalStorageEntryRef) bool {
    const origin_order = std.mem.order(u8, a.origin, b.origin);
    if (origin_order != .eq) return origin_order == .lt;
    return std.mem.order(u8, a.key, b.key) == .lt;
}

fn collectLocalStorageEntries(allocator: std.mem.Allocator, shed: *storage.Shed) !std.ArrayListUnmanaged(LocalStorageEntryRef) {
    var entries: std.ArrayListUnmanaged(LocalStorageEntryRef) = .empty;
    errdefer entries.deinit(allocator);
    var origin_it = shed._origins.iterator();
    while (origin_it.next()) |origin_kv| {
        const bucket = origin_kv.value_ptr.*;
        var item_it = bucket.local._data.iterator();
        while (item_it.next()) |item_kv| {
            try entries.append(allocator, .{
                .origin = origin_kv.key_ptr.*,
                .key = item_kv.key_ptr.*,
                .value = item_kv.value_ptr.*,
            });
        }
    }
    std.mem.sort(LocalStorageEntryRef, entries.items, {}, localStorageEntryLessThan);
    return entries;
}

fn hashLocalStorage(allocator: std.mem.Allocator, shed: *storage.Shed) u64 {
    var entries = collectLocalStorageEntries(allocator, shed) catch return 0;
    defer entries.deinit(allocator);
    var hasher = std.hash.Wyhash.init(0);
    const count = entries.items.len;
    hasher.update(std.mem.asBytes(&count));
    for (entries.items) |entry| {
        hasher.update(entry.origin);
        hasher.update(&.{0});
        hasher.update(entry.key);
        hasher.update(&.{0});
        hasher.update(entry.value);
        hasher.update(&.{0});
    }
    return hasher.final();
}

fn encodeStorageField(allocator: std.mem.Allocator, value: []const u8) ![]u8 {
    const size = std.base64.standard.Encoder.calcSize(value.len);
    const encoded = try allocator.alloc(u8, size);
    _ = std.base64.standard.Encoder.encode(encoded, value);
    return encoded;
}

fn decodeStorageField(allocator: std.mem.Allocator, value: []const u8) ![]u8 {
    const size = std.base64.standard.Decoder.calcSizeForSlice(value) catch return error.InvalidCharacter;
    const decoded = try allocator.alloc(u8, size);
    errdefer allocator.free(decoded);
    try std.base64.standard.Decoder.decode(decoded, value);
    return decoded;
}

fn initOwnedCookie(
    allocator: std.mem.Allocator,
    name: []const u8,
    value: []const u8,
    domain: []const u8,
    cookie_path: []const u8,
    expires: ?f64,
    secure: bool,
    http_only: bool,
    same_site: storage.Cookie.SameSite,
) !storage.Cookie {
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();
    const aa = arena.allocator();

    // Allocate first, then copy the final ArenaAllocator state into Cookie.
    // Copying `arena` into the struct literal before these dupes would capture
    // an empty/stale state and make Cookie.deinit unable to release the blocks.
    const owned_name = try aa.dupe(u8, name);
    const owned_value = try aa.dupe(u8, value);
    const owned_domain = try aa.dupe(u8, domain);
    const owned_path = try aa.dupe(u8, cookie_path);

    return .{
        .arena = arena,
        .name = owned_name,
        .value = owned_value,
        .domain = owned_domain,
        .path = owned_path,
        .expires = expires,
        .secure = secure,
        .http_only = http_only,
        .same_site = same_site,
    };
}

fn hashCookies(jar: *storage.Cookie.Jar) u64 {
    jar.removeExpired(null);
    var hasher = std.hash.Wyhash.init(0);
    const count = jar.cookies.items.len;
    hasher.update(std.mem.asBytes(&count));
    for (jar.cookies.items) |cookie| {
        hasher.update(cookie.name);
        hasher.update(&.{0});
        hasher.update(cookie.value);
        hasher.update(&.{0});
        hasher.update(cookie.domain);
        hasher.update(&.{0});
        hasher.update(cookie.path);
        hasher.update(&.{0});
        hasher.update(std.mem.asBytes(&cookie.secure));
        hasher.update(std.mem.asBytes(&cookie.http_only));
        hasher.update(&.{@intFromEnum(cookie.same_site)});
        if (cookie.expires) |expires| {
            const has_expiry: u8 = 1;
            const expires_i64: i64 = @intFromFloat(expires);
            hasher.update(&.{has_expiry});
            hasher.update(std.mem.asBytes(&expires_i64));
        } else {
            const has_expiry: u8 = 0;
            hasher.update(&.{has_expiry});
        }
    }
    return hasher.final();
}

fn parseSettings(allocator: std.mem.Allocator, data: []const u8) !Settings {
    var settings: Settings = .{};
    errdefer settings.deinit(allocator);

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r\n ");
        if (line.len == 0 or std.mem.eql(u8, line, "lightpanda-browse-settings-v1")) continue;
        if (std.mem.startsWith(u8, line, "restore_previous_session\t")) {
            settings.restore_previous_session = parseBool(line["restore_previous_session\t".len..]);
            continue;
        }
        if (std.mem.startsWith(u8, line, "allow_script_popups\t")) {
            settings.allow_script_popups = parseBool(line["allow_script_popups\t".len..]);
            continue;
        }
        if (std.mem.startsWith(u8, line, "default_zoom_percent\t")) {
            settings.default_zoom_percent = std.math.clamp(
                std.fmt.parseInt(i32, line["default_zoom_percent\t".len..], 10) catch settings.default_zoom_percent,
                MIN_ZOOM,
                MAX_ZOOM,
            );
            continue;
        }
        if (std.mem.startsWith(u8, line, "homepage_url\t")) {
            const raw = std.mem.trim(u8, line["homepage_url\t".len..], "\r\n\t ");
            if (settings.homepage_url) |old| allocator.free(old);
            settings.homepage_url = if (raw.len == 0) null else try allocator.dupe(u8, raw);
        }
    }
    return settings;
}

fn parseSession(allocator: std.mem.Allocator, data: []const u8) !SavedSession {
    var session: SavedSession = .{};
    errdefer session.deinit(allocator);

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r\n ");
        if (line.len == 0 or std.mem.eql(u8, line, "lightpanda-browse-session-v1")) continue;
        if (std.mem.startsWith(u8, line, "active\t")) {
            session.active_index = std.fmt.parseInt(usize, line["active\t".len..], 10) catch session.active_index;
            continue;
        }
        if (!std.mem.startsWith(u8, line, "tab\t")) continue;
        const rest = line["tab\t".len..];
        const sep = std.mem.indexOfScalar(u8, rest, '\t') orelse continue;
        const raw_url = std.mem.trim(u8, rest[sep + 1 ..], "\r\n\t ");
        if (raw_url.len == 0) continue;
        try session.tabs.append(allocator, .{
            .url = try allocator.dupe(u8, raw_url),
            .zoom_percent = std.math.clamp(
                std.fmt.parseInt(i32, rest[0..sep], 10) catch DEFAULT_ZOOM,
                MIN_ZOOM,
                MAX_ZOOM,
            ),
        });
    }
    if (session.tabs.items.len > 0) session.active_index = @min(session.active_index, session.tabs.items.len - 1);
    return session;
}

fn parseBool(raw: []const u8) bool {
    const value = std.mem.trim(u8, raw, "\r\n\t ");
    return std.mem.eql(u8, value, "1") or std.ascii.eqlIgnoreCase(value, "true");
}

fn sanitizeField(value: []const u8) []const u8 {
    return std.mem.trim(u8, value, "\r\n\t");
}

fn hashSettings(settings: Settings) u64 {
    var hasher = std.hash.Wyhash.init(0);
    hasher.update(std.mem.asBytes(&settings.restore_previous_session));
    hasher.update(std.mem.asBytes(&settings.allow_script_popups));
    hasher.update(std.mem.asBytes(&settings.default_zoom_percent));
    hasher.update(settings.homepage_url orelse "");
    return hasher.final();
}

fn hashTabStates(tabs: []const TabState, active_index: usize) u64 {
    var hasher = std.hash.Wyhash.init(0);
    hasher.update(std.mem.asBytes(&active_index));
    for (tabs) |tab| {
        hasher.update(tab.url);
        hasher.update(std.mem.asBytes(&tab.zoom_percent));
    }
    return hasher.final();
}

fn hashSavedSession(session: SavedSession) u64 {
    var hasher = std.hash.Wyhash.init(0);
    const active = if (session.tabs.items.len == 0) @as(usize, 0) else @min(session.active_index, session.tabs.items.len - 1);
    hasher.update(std.mem.asBytes(&active));
    for (session.tabs.items) |tab| {
        hasher.update(tab.url);
        hasher.update(std.mem.asBytes(&tab.zoom_percent));
    }
    return hasher.final();
}

test "headed profile owned cookie releases its arena" {
    const cookie = try initOwnedCookie(
        std.testing.allocator,
        "__Secure-example",
        "persistent-value-with-enough-bytes-to-force-arena-storage",
        ".example.com",
        "/",
        null,
        true,
        true,
        .lax,
    );
    defer cookie.deinit();

    try std.testing.expectEqualStrings("__Secure-example", cookie.name);
    try std.testing.expectEqualStrings("persistent-value-with-enough-bytes-to-force-arena-storage", cookie.value);
    try std.testing.expectEqualStrings(".example.com", cookie.domain);
    try std.testing.expectEqualStrings("/", cookie.path);
}
