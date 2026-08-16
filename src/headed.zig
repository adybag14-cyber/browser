// Copyright (C) 2023-2026 Lightpanda contributors
// Native headed browser shell rebased onto the current Page + Frame architecture.

const std = @import("std");
const lp = @import("lightpanda");

const App = lp.App;
const Browser = lp.Browser;
const Frame = lp.Frame;
const Notification = lp.Notification;
const Session = lp.Session;
const URL = lp.URL;
const Display = lp.Display;
const DocumentPainter = lp.DocumentPainter;
const BrowserCommand = Display.BrowserCommand;
const HostPaths = @import("HostPaths.zig");
const markdown = @import("browser/markdown.zig");
const js = lp.js;

const Allocator = std.mem.Allocator;
const DEFAULT_ZOOM: i32 = 100;
const MIN_ZOOM: i32 = 30;
const MAX_ZOOM: i32 = 300;
const ZOOM_STEP: i32 = 10;
const MAX_CLOSED_TABS: usize = 32;

const ClosedTab = struct {
    url: []u8,
    zoom_percent: i32,

    fn deinit(self: *ClosedTab, allocator: Allocator) void {
        allocator.free(self.url);
        self.* = undefined;
    }
};

const Tab = struct {
    browser: Browser = undefined,
    notification: *Notification = undefined,
    session: *Session = undefined,
    handle: Session.PageHandle = undefined,
    zoom_percent: i32 = DEFAULT_ZOOM,
    loading: bool = false,
    last_presented_hash: u64 = 0,
    last_error: ?anyerror = null,

    fn init(app: *App, initial_url: ?[]const u8, zoom_percent: i32, width: u32, height: u32) !*Tab {
        const allocator = app.allocator;
        const tab = try allocator.create(Tab);
        errdefer allocator.destroy(tab);
        tab.* = .{ .zoom_percent = std.math.clamp(zoom_percent, MIN_ZOOM, MAX_ZOOM) };

        tab.notification = try Notification.init(allocator);
        errdefer tab.notification.deinit();

        try tab.browser.init(app, .{}, null);
        errdefer tab.browser.deinit();
        tab.browser.viewport_override = .{ .width = width, .height = height };

        tab.session = try tab.browser.newSession(tab.notification);
        tab.handle = try tab.session.createPage();

        if (initial_url) |raw| {
            if (!isBlankAddress(raw)) {
                try tab.navigate(raw);
            }
        }
        return tab;
    }

    fn deinit(self: *Tab, allocator: Allocator) void {
        self.browser.deinit();
        self.notification.deinit();
        allocator.destroy(self);
    }

    fn frame(self: *Tab) ?*Frame {
        return self.handle.frame();
    }

    fn url(self: *Tab) []const u8 {
        const active_frame = self.frame() orelse return "about:blank";
        return if (active_frame.url.len == 0) "about:blank" else active_frame.url;
    }

    fn title(self: *Tab, allocator: Allocator) ![]u8 {
        const active_frame = self.frame() orelse return allocator.dupe(u8, "New Tab");
        if (try active_frame.getTitle()) |page_title| {
            const trimmed = std.mem.trim(u8, page_title, &std.ascii.whitespace);
            if (trimmed.len > 0) return allocator.dupe(u8, trimmed);
        }
        if (!isBlankAddress(active_frame.url)) return allocator.dupe(u8, active_frame.url);
        return allocator.dupe(u8, "New Tab");
    }

    fn navigate(self: *Tab, raw: []const u8) !void {
        const active_frame = self.frame() orelse return error.FrameNotLoaded;
        const normalized = try normalizeAddress(active_frame.call_arena, raw);
        self.loading = true;
        self.last_error = null;
        self.last_presented_hash = 0;
        const opts: Frame.NavigateOpts = .{
            .reason = .address_bar,
            .kind = .{ .push = null },
        };
        if (active_frame._load_state == .waiting) {
            try self.handle.navigate(normalized, opts);
        } else {
            try active_frame.scheduleNavigation(normalized, opts, .{ .script = null });
        }
    }

    fn tick(self: *Tab) void {
        var runner = self.session.runner(.{});
        const result = runner.tickForFrame(self.handle.frame_id, 4, .{ .until = .done }) catch |err| {
            self.loading = false;
            self.last_error = err;
            return;
        };
        switch (result) {
            .done => self.loading = false,
            .ok => self.loading = true,
        }
    }
};

const Shell = struct {
    app: *App,
    display: Display,
    profile_dir: ?[]const u8,
    tabs: std.ArrayList(*Tab) = .empty,
    closed_tabs: std.ArrayList(ClosedTab) = .empty,
    active_index: usize = 0,
    default_zoom_percent: i32 = DEFAULT_ZOOM,
    homepage_url: ?[]u8 = null,
    restore_previous_session: bool = true,
    allow_script_popups: bool = true,
    width: u32,
    height: u32,

    fn init(app: *App, opts: anytype) !Shell {
        const width = if (opts.width == 0) 1280 else opts.width;
        const height = if (opts.height == 0) 720 else opts.height;
        const profile_dir = HostPaths.resolveProfileDir(app.allocator, opts.profile_dir);
        var display = Display.init(app.allocator, .{
            .mode = .headed,
            .width = width,
            .height = height,
            .screenshot_bmp_path = opts.screenshot_bmp,
            .screenshot_png_path = opts.screenshot_png,
        }, null);
        display.setAppDataPath(profile_dir);
        return .{
            .app = app,
            .display = display,
            .profile_dir = profile_dir,
            .width = width,
            .height = height,
        };
    }

    fn deinit(self: *Shell) void {
        while (self.tabs.items.len > 0) {
            const tab = self.tabs.pop().?;
            self.display.onPageRemoved();
            tab.deinit(self.app.allocator);
        }
        self.tabs.deinit(self.app.allocator);
        for (self.closed_tabs.items) |*closed| closed.deinit(self.app.allocator);
        self.closed_tabs.deinit(self.app.allocator);
        self.display.deinit();
        if (self.homepage_url) |url| self.app.allocator.free(url);
        if (self.profile_dir) |path| self.app.allocator.free(path);
    }

    fn activeTab(self: *Shell) ?*Tab {
        if (self.tabs.items.len == 0) return null;
        self.active_index = @min(self.active_index, self.tabs.items.len - 1);
        return self.tabs.items[self.active_index];
    }

    fn newTab(self: *Shell, url: ?[]const u8, activate: bool) !void {
        const tab = try Tab.init(self.app, url, self.default_zoom_percent, self.width, self.height);
        errdefer tab.deinit(self.app.allocator);
        try self.tabs.append(self.app.allocator, tab);
        self.display.onPageCreated();
        if (activate) self.active_index = self.tabs.items.len - 1;
        try self.syncDisplayState();
    }

    fn closeTab(self: *Shell, index: usize, remember: bool) !void {
        if (index >= self.tabs.items.len) return;
        const tab = self.tabs.orderedRemove(index);
        if (remember) try self.pushClosed(tab);
        self.display.onPageRemoved();
        tab.deinit(self.app.allocator);
        if (self.tabs.items.len == 0) return;
        if (self.active_index >= self.tabs.items.len) self.active_index = self.tabs.items.len - 1;
        try self.syncDisplayState();
    }

    fn pushClosed(self: *Shell, tab: *Tab) !void {
        if (self.closed_tabs.items.len == MAX_CLOSED_TABS) {
            var old = self.closed_tabs.orderedRemove(0);
            old.deinit(self.app.allocator);
        }
        try self.closed_tabs.append(self.app.allocator, .{
            .url = try self.app.allocator.dupe(u8, tab.url()),
            .zoom_percent = tab.zoom_percent,
        });
    }

    fn reopenClosed(self: *Shell, ui_index: usize) !void {
        if (ui_index >= self.closed_tabs.items.len) return;
        const storage_index = self.closed_tabs.items.len - 1 - ui_index;
        var closed = self.closed_tabs.orderedRemove(storage_index);
        defer closed.deinit(self.app.allocator);
        try self.newTab(closed.url, true);
        if (self.activeTab()) |tab| tab.zoom_percent = closed.zoom_percent;
    }

    fn tick(self: *Shell) void {
        for (self.tabs.items) |tab| tab.tick();
    }

    fn syncDisplayState(self: *Shell) !void {
        const tab = self.activeTab() orelse return;
        const frame = tab.frame() orelse return;
        const navigation = tab.session.navigation;
        self.display.setNavigationState(
            navigation.getCanGoBack(),
            navigation.getCanGoForward(),
            tab.loading,
            tab.zoom_percent,
        );

        const nav_entries = navigation.entries();
        const history = try self.app.allocator.alloc([]const u8, nav_entries.len);
        defer self.app.allocator.free(history);
        for (nav_entries, 0..) |entry, i| history[i] = entry.url() orelse "about:blank";
        self.display.setHistoryEntries(history, navigation.getCurrentIndex());

        const entries = try self.app.allocator.alloc(Display.TabEntry, self.tabs.items.len);
        defer self.app.allocator.free(entries);
        var titles: std.ArrayList([]u8) = .empty;
        defer {
            for (titles.items) |title| self.app.allocator.free(title);
            titles.deinit(self.app.allocator);
        }
        try titles.ensureTotalCapacity(self.app.allocator, self.tabs.items.len);
        for (self.tabs.items, 0..) |candidate, i| {
            const owned_title = try candidate.title(self.app.allocator);
            titles.appendAssumeCapacity(owned_title);
            entries[i] = .{
                .title = titles.items[i],
                .url = candidate.url(),
                .is_loading = candidate.loading,
                .has_error = candidate.last_error != null,
                .target_name = "",
                .popup_source = .none,
            };
        }
        self.display.setTabEntries(entries, self.active_index);
        self.display.setDownloadEntries(&.{});
        self.display.setSettingsState(.{
            .restore_previous_session = self.restore_previous_session,
            .allow_script_popups = self.allow_script_popups,
            .default_zoom_percent = self.default_zoom_percent,
            .homepage_url = self.homepage_url orelse "",
        });
        self.display.setImageRequestCookieJar(&tab.session.cookie_jar);
        _ = frame;
    }

    fn present(self: *Shell) !void {
        const tab = self.activeTab() orelse return;
        const frame = tab.frame() orelse return;

        if (tab.last_error) |err| {
            var buf: [256]u8 = undefined;
            const message = std.fmt.bufPrint(&buf, "Page failed: {s}", .{@errorName(err)}) catch "Page failed";
            try self.display.presentDocument("Lightpanda Browser", tab.url(), message);
            return;
        }
        if (tab.loading) {
            try self.display.presentDocument("Lightpanda Browser", tab.url(), "Loading page...");
            return;
        }
        if (isBlankAddress(frame.url)) {
            try self.display.presentDocument("New Tab", "about:blank", "Open a page with Ctrl+L or the address bar.");
            return;
        }

        var body: std.Io.Writer.Allocating = .init(self.app.allocator);
        defer body.deinit();
        try markdown.dump(frame.window._document.asNode(), .{}, &body.writer, frame);

        var list = try DocumentPainter.paintDocument(self.app.allocator, frame, .{
            .viewport_width = @intCast(self.display.viewport.width),
            .viewport_height = @intCast(self.display.viewport.height),
            .layout_scale = tab.zoom_percent,
        });
        defer list.deinit(self.app.allocator);

        const title = (try frame.getTitle()) orelse "";
        const text = body.written();
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(title);
        hasher.update(frame.url);
        hasher.update(text);
        list.hashInto(&hasher);
        const hash = hasher.final();
        if (hash == tab.last_presented_hash) return;
        tab.last_presented_hash = hash;
        self.display.setImageRequestCookieJar(&tab.session.cookie_jar);
        try self.display.presentPageView(title, frame.url, text, &list);
    }

    fn drainCommands(self: *Shell) !void {
        while (self.display.nextBrowserCommand()) |command| {
            defer command.deinit(self.app.allocator);
            try self.handleCommand(command);
            if (self.tabs.items.len == 0) return;
        }
    }

    fn handleCommand(self: *Shell, command: BrowserCommand) !void {
        const tab = self.activeTab() orelse return;
        const frame = tab.frame() orelse return;
        switch (command) {
            .navigate => |url| try tab.navigate(url),
            .navigate_new_tab => |url| try self.newTab(url, true),
            .navigate_target_tab => |target| try self.newTab(target.url, true),
            .activate_link_region => |activation| {
                if (activation.open_in_new_tab or activation.target_name.len > 0) {
                    try self.newTab(activation.url, true);
                } else {
                    try tab.navigate(activation.url);
                }
            },
            .activate_control_region => |activation| {
                try frame.triggerMouseDown(activation.x, activation.y, .main, .{ .buttons = 1 });
                try frame.triggerMouseUp(activation.x, activation.y, .main, .{});
                try frame.triggerMouseClickWithModifiers(activation.x, activation.y, .main, .{});
                tab.last_presented_hash = 0;
            },
            .back => {
                if (tab.session.navigation.getCanGoBack()) {
                    const previous_local = frame.js.local;
                    defer frame.js.local = previous_local;
                    var nav_scope: js.Local.Scope = undefined;
                    frame.js.localScope(&nav_scope);
                    defer nav_scope.deinit();
                    frame.js.local = &nav_scope.local;
                    _ = try tab.session.navigation.back(frame);
                    tab.loading = true;
                    tab.last_presented_hash = 0;
                }
            },
            .forward => {
                if (tab.session.navigation.getCanGoForward()) {
                    const previous_local = frame.js.local;
                    defer frame.js.local = previous_local;
                    var nav_scope: js.Local.Scope = undefined;
                    frame.js.localScope(&nav_scope);
                    defer nav_scope.deinit();
                    frame.js.local = &nav_scope.local;
                    _ = try tab.session.navigation.forward(frame);
                    tab.loading = true;
                    tab.last_presented_hash = 0;
                }
            },
            .reload => {
                if (!isBlankAddress(frame.url)) {
                    const previous_local = frame.js.local;
                    defer frame.js.local = previous_local;
                    var nav_scope: js.Local.Scope = undefined;
                    frame.js.localScope(&nav_scope);
                    defer nav_scope.deinit();
                    frame.js.local = &nav_scope.local;
                    _ = try tab.session.navigation.reload(null, frame);
                    tab.loading = true;
                    tab.last_presented_hash = 0;
                }
            },
            .stop => {
                frame.abortTransfers();
                tab.loading = false;
                tab.last_presented_hash = 0;
            },
            .history_traverse => |index| {
                const entries = tab.session.navigation.entries();
                if (index < entries.len) {
                    const previous_local = frame.js.local;
                    defer frame.js.local = previous_local;
                    var nav_scope: js.Local.Scope = undefined;
                    frame.js.localScope(&nav_scope);
                    defer nav_scope.deinit();
                    frame.js.local = &nav_scope.local;
                    _ = try tab.session.navigation.traverseTo(entries[index].key(), null, frame);
                    tab.loading = true;
                    tab.last_presented_hash = 0;
                }
            },
            .history_open_new_tab => |index| {
                const entries = tab.session.navigation.entries();
                if (index < entries.len) if (entries[index].url()) |url| try self.newTab(url, true);
            },
            .tab_new => try self.newTab(null, true),
            .tab_duplicate => try self.newTab(tab.url(), true),
            .tab_duplicate_index => |index| if (index < self.tabs.items.len) try self.newTab(self.tabs.items[index].url(), true),
            .tab_close => |index| try self.closeTab(index, true),
            .tab_activate => |index| {
                if (index < self.tabs.items.len) {
                    self.active_index = index;
                    if (self.activeTab()) |active| active.last_presented_hash = 0;
                }
            },
            .tab_next => if (self.tabs.items.len > 1) {
                self.active_index = (self.active_index + 1) % self.tabs.items.len;
                self.tabs.items[self.active_index].last_presented_hash = 0;
            },
            .tab_previous => if (self.tabs.items.len > 1) {
                self.active_index = if (self.active_index == 0) self.tabs.items.len - 1 else self.active_index - 1;
                self.tabs.items[self.active_index].last_presented_hash = 0;
            },
            .tab_reopen_closed => try self.reopenClosed(0),
            .tab_reopen_closed_index => |index| try self.reopenClosed(index),
            .tab_reload_index => |index| if (index < self.tabs.items.len) {
                const candidate = self.tabs.items[index];
                if (candidate.frame()) |candidate_frame| {
                    _ = try candidate.session.navigation.reload(null, candidate_frame);
                    candidate.loading = true;
                    candidate.last_presented_hash = 0;
                }
            },
            .zoom_in => {
                tab.zoom_percent = @min(MAX_ZOOM, tab.zoom_percent + ZOOM_STEP);
                tab.last_presented_hash = 0;
            },
            .zoom_out => {
                tab.zoom_percent = @max(MIN_ZOOM, tab.zoom_percent - ZOOM_STEP);
                tab.last_presented_hash = 0;
            },
            .zoom_reset => {
                tab.zoom_percent = DEFAULT_ZOOM;
                tab.last_presented_hash = 0;
            },
            .settings_default_zoom_in => self.default_zoom_percent = @min(MAX_ZOOM, self.default_zoom_percent + ZOOM_STEP),
            .settings_default_zoom_out => self.default_zoom_percent = @max(MIN_ZOOM, self.default_zoom_percent - ZOOM_STEP),
            .settings_default_zoom_reset => self.default_zoom_percent = DEFAULT_ZOOM,
            .settings_toggle_restore_session => self.restore_previous_session = !self.restore_previous_session,
            .settings_toggle_script_popups => self.allow_script_popups = !self.allow_script_popups,
            .settings_set_homepage_to_current => {
                if (self.homepage_url) |old| self.app.allocator.free(old);
                self.homepage_url = try self.app.allocator.dupe(u8, tab.url());
            },
            .settings_clear_homepage => {
                if (self.homepage_url) |old| self.app.allocator.free(old);
                self.homepage_url = null;
            },
            .home => if (self.homepage_url) |home_url| try tab.navigate(home_url) else try tab.navigate("about:blank"),
            .page_start, .page_tabs, .page_history, .page_bookmarks, .page_downloads, .page_settings => {
                // The native Win32 chrome owns these overlays; keeping the current
                // document avoids disturbing page history when they are toggled.
            },
            .bookmark_add_current, .bookmark_open_visible_new_tabs, .bookmark_sort_set, .bookmark_filter_set, .bookmark_filter_clear, .bookmark_open, .bookmark_open_new_tab, .bookmark_move_up, .bookmark_move_down, .bookmark_remove => {},
            .history_clear_session, .history_remove, .history_remove_before, .history_remove_after, .history_sort_set, .history_filter_set, .history_filter_clear => {},
            .download, .download_source, .download_source_new_tab, .download_open_file, .download_reveal_file, .download_open_folder, .download_retry, .download_remove, .download_clear, .download_sort_set, .download_filter_set, .download_filter_clear => {},
            .settings_clear_cookies => tab.session.cookie_jar.clearRetainingCapacity(),
            .settings_clear_local_storage, .settings_clear_indexed_db => {},
            .error_retry => if (tab.last_error != null) try tab.navigate(tab.url()),
        }
        try self.syncDisplayState();
    }
};

pub fn browse(app: *App, opts: anytype) !void {
    var shell = try Shell.init(app, opts);
    defer shell.deinit();

    try shell.newTab(opts.url, true);
    while (shell.tabs.items.len > 0 and !shell.display.userClosed()) {
        if (shell.activeTab()) |tab| {
            if (tab.frame()) |frame| {
                shell.display.dispatchNativeInput(frame) catch |err| {
                    lp.log.warn(.app, "headed input", .{ .err = err });
                };
            }
        }
        try shell.drainCommands();
        if (shell.tabs.items.len == 0) break;
        shell.tick();
        try shell.syncDisplayState();
        try shell.present();
        lp.io.sleep(.fromMilliseconds(4), .awake) catch {};
    }
}

fn isBlankAddress(url: []const u8) bool {
    return url.len == 0 or std.mem.eql(u8, url, "about:blank");
}

fn normalizeAddress(allocator: Allocator, raw: []const u8) ![:0]u8 {
    const trimmed = std.mem.trim(u8, raw, &std.ascii.whitespace);
    if (trimmed.len == 0) return allocator.dupeZ(u8, "about:blank");
    if (std.mem.startsWith(u8, trimmed, "http://") or
        std.mem.startsWith(u8, trimmed, "https://") or
        std.mem.startsWith(u8, trimmed, "about:") or
        std.mem.startsWith(u8, trimmed, "file:") or
        std.mem.startsWith(u8, trimmed, "data:") or
        std.mem.startsWith(u8, trimmed, "blob:"))
    {
        return allocator.dupeZ(u8, trimmed);
    }
    return std.fmt.allocPrintSentinel(allocator, "https://{s}", .{trimmed}, 0);
}
