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
const Downloads = @import("headed_downloads.zig").Manager;
const Profile = @import("headed_profile.zig");
const markdown = @import("browser/markdown.zig");
const js = lp.js;
const storage = @import("browser/webapi/storage/storage.zig");
const IdbManager = @import("browser/webapi/storage/idb/idb.zig").Manager;

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

const NavigationScopeGuard = struct {
    frame: *Frame,
    previous_local: ?*const js.Local,
    scope: js.Local.Scope,

    fn init(self: *NavigationScopeGuard, frame: *Frame) void {
        self.frame = frame;
        self.previous_local = frame.js.local;
        frame.js.localScope(&self.scope);
        frame.js.local = &self.scope.local;
    }

    fn deinit(self: *NavigationScopeGuard) void {
        self.scope.deinit();
        self.frame.js.local = self.previous_local;
    }
};

const TabIsolateScope = struct {
    isolate: js.Isolate,

    fn init(tab: *Tab) TabIsolateScope {
        const isolate = tab.browser.env.isolate;
        tab.session.cookieJar().notification = tab.notification;
        isolate.enter();
        return .{ .isolate = isolate };
    }

    fn deinit(self: *TabIsolateScope) void {
        self.isolate.exit();
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
    last_presented_render_version: usize = 0,
    last_presented_loading: bool = false,
    last_error: ?anyerror = null,

    fn init(
        app: *App,
        initial_url: ?[]const u8,
        zoom_percent: i32,
        width: u32,
        height: u32,
        shared_cookie_jar: *storage.Cookie.Jar,
        shared_local_storage_shed: *storage.Shed,
        shared_idb: *IdbManager,
    ) !*Tab {
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
        tab.session.shared_cookie_jar = shared_cookie_jar;
        tab.session.shared_local_storage_shed = shared_local_storage_shed;
        tab.session.shared_idb = shared_idb;
        tab.handle = try tab.session.createPage();

        if (initial_url) |raw| {
            if (!isBlankAddress(raw)) {
                try tab.navigateEntered(raw);
            }
        }

        // Env.init keeps its isolate entered for the Browser lifetime. Headed
        // mode owns multiple Browsers on one OS thread, so leaving every isolate
        // entered makes the most recently-created tab's LocalHeap current while
        // older tabs are ticked. Detach between browser operations and enter the
        // owning isolate explicitly at each headed call boundary.
        tab.browser.env.isolate.exit();
        return tab;
    }

    fn deinit(self: *Tab, allocator: Allocator) void {
        // Restore Env's lifetime-enter invariant so Browser.deinit/Env.deinit can
        // tear down V8 and perform their matching isolate.exit().
        self.browser.env.isolate.enter();
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
        var isolate_scope = TabIsolateScope.init(self);
        defer isolate_scope.deinit();
        const active_frame = self.frame() orelse return allocator.dupe(u8, "New Tab");
        if (try active_frame.getTitle()) |page_title| {
            const trimmed = std.mem.trim(u8, page_title, &std.ascii.whitespace);
            if (trimmed.len > 0) return allocator.dupe(u8, trimmed);
        }
        if (!isBlankAddress(active_frame.url)) return allocator.dupe(u8, active_frame.url);
        return allocator.dupe(u8, "New Tab");
    }

    fn navigate(self: *Tab, raw: []const u8) !void {
        var isolate_scope = TabIsolateScope.init(self);
        defer isolate_scope.deinit();
        return self.navigateEntered(raw);
    }

    fn navigateEntered(self: *Tab, raw: []const u8) !void {
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
        var isolate_scope = TabIsolateScope.init(self);
        defer isolate_scope.deinit();
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

const PRESENTATION_INTERVAL_MS: u64 = 16;

const Shell = struct {
    app: *App,
    /// Reusable backing storage for per-loop chrome/render temporaries. This is
    /// especially important for the Windows DebugAllocator, which deliberately
    /// avoids reusing freed addresses and otherwise turns harmless 4 ms UI
    /// polling allocations into resident high-water growth. Nothing allocated
    /// here may escape a synchronous Display/Profile call.
    scratch_arena: std.heap.ArenaAllocator,
    display: Display,
    profile_dir: ?[]const u8,
    profile: Profile.Store,
    downloads: Downloads,
    shared_cookie_jar: storage.Cookie.Jar,
    shared_local_storage_shed: storage.Shed = .{},
    shared_idb: IdbManager,
    profile_storage_ticks: u8 = 0,
    tabs: std.ArrayList(*Tab) = .empty,
    closed_tabs: std.ArrayList(ClosedTab) = .empty,
    active_index: usize = 0,
    default_zoom_percent: i32 = DEFAULT_ZOOM,
    homepage_url: ?[]u8 = null,
    restore_previous_session: bool = true,
    allow_script_popups: bool = true,
    last_presentation_attempt: ?std.Io.Timestamp = null,
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
        var profile = Profile.Store.init(app.allocator, profile_dir);
        errdefer profile.deinit();
        var settings = profile.loadSettings();
        errdefer settings.deinit(app.allocator);
        var downloads = try Downloads.init(app, profile_dir);
        errdefer downloads.deinit();
        var shared_cookie_jar = storage.Cookie.Jar.init(app.allocator, null);
        errdefer shared_cookie_jar.deinit();
        profile.loadCookies(&shared_cookie_jar);
        var shared_local_storage_shed: storage.Shed = .{};
        errdefer shared_local_storage_shed.deinit(app.allocator);
        profile.loadLocalStorage(&shared_local_storage_shed);
        const idb_dir = HostPaths.resolveProfileSubdir(app.allocator, profile_dir, "indexeddb");
        defer if (idb_dir) |dir| app.allocator.free(dir);
        var shared_idb = if (idb_dir) |dir|
            try IdbManager.initPersistent(app.allocator, dir)
        else
            IdbManager.init(app.allocator);
        errdefer shared_idb.deinit();
        const homepage_url = settings.homepage_url;
        settings.homepage_url = null;
        return .{
            .app = app,
            .scratch_arena = std.heap.ArenaAllocator.init(app.allocator),
            .display = display,
            .profile_dir = profile_dir,
            .profile = profile,
            .downloads = downloads,
            .shared_cookie_jar = shared_cookie_jar,
            .shared_local_storage_shed = shared_local_storage_shed,
            .shared_idb = shared_idb,
            .default_zoom_percent = settings.default_zoom_percent,
            .homepage_url = homepage_url,
            .restore_previous_session = settings.restore_previous_session,
            .allow_script_popups = settings.allow_script_popups,
            .width = width,
            .height = height,
        };
    }

    fn deinit(self: *Shell) void {
        self.persistProfileState(true);
        self.downloads.deinit();
        while (self.tabs.items.len > 0) {
            const tab = self.tabs.pop().?;
            self.display.onPageRemoved();
            tab.deinit(self.app.allocator);
        }
        self.tabs.deinit(self.app.allocator);
        for (self.closed_tabs.items) |*closed| closed.deinit(self.app.allocator);
        self.closed_tabs.deinit(self.app.allocator);
        self.display.deinit();
        self.shared_idb.deinit();
        self.shared_local_storage_shed.deinit(self.app.allocator);
        self.shared_cookie_jar.deinit();
        if (self.homepage_url) |url| self.app.allocator.free(url);
        self.profile.deinit();
        if (self.profile_dir) |path| self.app.allocator.free(path);
        self.scratch_arena.deinit();
    }

    fn restoreOrStart(self: *Shell, startup_url: ?[]const u8) !void {
        if (!self.restore_previous_session) {
            self.profile.persistSession(&.{}, 0, false);
            try self.newTab(startup_url, true);
            return;
        }

        var saved = self.profile.loadSession();
        defer saved.deinit(self.app.allocator);
        if (saved.tabs.items.len == 0) {
            try self.newTab(startup_url, true);
            return;
        }

        for (saved.tabs.items) |saved_tab| {
            const restored_url: ?[]const u8 = if (isBlankAddress(saved_tab.url)) null else saved_tab.url;
            try self.newTab(restored_url, false);
            self.tabs.items[self.tabs.items.len - 1].zoom_percent = saved_tab.zoom_percent;
        }
        self.active_index = @min(saved.active_index, self.tabs.items.len - 1);

        if (startup_url) |url| {
            const trimmed = std.mem.trim(u8, url, &std.ascii.whitespace);
            if (trimmed.len > 0 and !isBlankAddress(trimmed) and !self.hasTabUrl(trimmed)) {
                try self.newTab(trimmed, true);
                return;
            }
        }
        self.tabs.items[self.active_index].last_presented_hash = 0;
        try self.syncDisplayState();
    }

    fn hasTabUrl(self: *const Shell, url: []const u8) bool {
        for (self.tabs.items) |tab| {
            if (std.mem.eql(u8, tab.url(), url)) return true;
        }
        return false;
    }

    fn persistProfileState(self: *Shell, force_storage: bool) void {
        _ = self.scratch_arena.reset(.retain_capacity);
        const scratch = self.scratch_arena.allocator();
        const states = scratch.alloc(Profile.TabState, self.tabs.items.len) catch |err| {
            lp.log.warn(.app, "headed session state allocation failed", .{ .err = err });
            return;
        };
        for (self.tabs.items, 0..) |tab, index| {
            states[index] = .{ .url = tab.url(), .zoom_percent = tab.zoom_percent };
        }
        self.profile.persistSession(states, self.active_index, self.restore_previous_session);
        self.profile.persistSettings(.{
            .restore_previous_session = self.restore_previous_session,
            .allow_script_popups = self.allow_script_popups,
            .default_zoom_percent = self.default_zoom_percent,
            .homepage_url = self.homepage_url,
        });
        if (force_storage or self.profile_storage_ticks >= 63) {
            self.profile.persistCookies(&self.shared_cookie_jar);
            self.profile.persistLocalStorage(&self.shared_local_storage_shed);
            self.profile_storage_ticks = 0;
        } else {
            self.profile_storage_ticks += 1;
        }
    }

    fn activeTab(self: *Shell) ?*Tab {
        if (self.tabs.items.len == 0) return null;
        self.active_index = @min(self.active_index, self.tabs.items.len - 1);
        return self.tabs.items[self.active_index];
    }

    fn newTab(self: *Shell, url: ?[]const u8, activate: bool) !void {
        const tab = try Tab.init(
            self.app,
            url,
            self.default_zoom_percent,
            self.width,
            self.height,
            &self.shared_cookie_jar,
            &self.shared_local_storage_shed,
            &self.shared_idb,
        );
        errdefer tab.deinit(self.app.allocator);
        try self.tabs.append(self.app.allocator, tab);
        self.display.onPageCreated();
        if (activate) self.active_index = self.tabs.items.len - 1;
        try self.syncDisplayState();
    }

    fn closeTab(self: *Shell, index: usize, remember: bool) !void {
        if (index >= self.tabs.items.len) return;
        const previous_active = self.active_index;
        const tab = self.tabs.orderedRemove(index);
        self.downloads.cancelForSource(tab);
        if (remember) try self.pushClosed(tab);
        self.display.onPageRemoved();
        tab.deinit(self.app.allocator);
        if (self.tabs.items.len == 0) return;

        if (index < previous_active) {
            // Preserve the active tab's identity after entries before it shift left.
            self.active_index = previous_active - 1;
        } else if (index == previous_active) {
            // Prefer the tab that slid into the closed tab's slot; when the last
            // tab was closed, fall back to the new last tab.
            self.active_index = @min(index, self.tabs.items.len - 1);
        } else {
            self.active_index = @min(previous_active, self.tabs.items.len - 1);
        }
        // Even a previously rendered survivor must repaint after becoming the
        // active surface, otherwise its cached hash leaves the Win32 title/body
        // from the closed tab visible.
        self.tabs.items[self.active_index].last_presented_hash = 0;
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

    fn tick(self: *Shell) !void {
        for (self.tabs.items) |tab| {
            tab.tick();
            if (tab.frame()) |frame| {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                try self.downloads.processPendingRequests(self.app, frame, tab.session, tab.notification, tab);
            }
        }
        self.downloads.tick(0);
    }

    fn syncDisplayState(self: *Shell) !void {
        _ = self.scratch_arena.reset(.retain_capacity);
        const scratch = self.scratch_arena.allocator();
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
        const history = try scratch.alloc([]const u8, nav_entries.len);
        defer scratch.free(history);
        for (nav_entries, 0..) |entry, i| history[i] = entry.url() orelse "about:blank";
        self.display.setHistoryEntries(history, navigation.getCurrentIndex());

        const entries = try scratch.alloc(Display.TabEntry, self.tabs.items.len);
        defer scratch.free(entries);
        var titles: std.ArrayList([]u8) = .empty;
        defer {
            for (titles.items) |title| scratch.free(title);
            titles.deinit(scratch);
        }
        try titles.ensureTotalCapacity(scratch, self.tabs.items.len);
        for (self.tabs.items, 0..) |candidate, i| {
            const owned_title = try candidate.title(scratch);
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
        const download_entries = try self.downloads.toDisplayEntries(scratch);
        defer self.downloads.freeDisplayEntries(scratch, download_entries);
        self.display.setDownloadEntries(download_entries);
        self.display.setSettingsState(.{
            .restore_previous_session = self.restore_previous_session,
            .allow_script_popups = self.allow_script_popups,
            .default_zoom_percent = self.default_zoom_percent,
            .homepage_url = self.homepage_url orelse "",
        });
        self.display.setImageRequestCookieJar(tab.session.cookieJar());
        _ = frame;
    }

    fn present(self: *Shell) !void {
        const tab = self.activeTab() orelse return;
        const frame = tab.frame() orelse return;
        const render_changed = frame._page.render_version != tab.last_presented_render_version;
        const loading_changed = tab.loading != tab.last_presented_loading;
        const force_present = tab.last_presented_hash == 0;
        // Rebuild presentation only when page/UI state can actually have changed.
        // Parser/DOM/CSS/control/canvas changes advance Page.render_version;
        // native input/navigation also explicitly invalidate presentation.
        // Coalesce bursts to ~60 Hz.
        if (!force_present and !render_changed and !loading_changed) return;
        if (self.last_presentation_attempt) |last| {
            const elapsed_ms: u64 = @intCast(last.untilNow(lp.io, .boot).toMilliseconds());
            if (elapsed_ms < PRESENTATION_INTERVAL_MS) return;
        }
        self.last_presentation_attempt = .now(lp.io, .boot);

        var isolate_scope = TabIsolateScope.init(tab);
        defer isolate_scope.deinit();

        if (tab.last_error) |err| {
            var buf: [256]u8 = undefined;
            const message = std.fmt.bufPrint(&buf, "Page failed: {s}", .{@errorName(err)}) catch "Page failed";
            try self.display.presentDocument("Lightpanda Browser", tab.url(), message);
            return;
        }
        // Real browsers paint incrementally while subresources/subframes are
        // still loading. Blocking presentation on Session.Runner `.done` makes
        // long-lived widgets (for example reCAPTCHA, workers, streaming pages)
        // leave the native window stuck on a synthetic "Loading page..." even
        // after their DOM is ready. Keep the navigation spinner state, but paint
        // the current document on every stable hash while loading continues.
        if (isBlankAddress(frame.url)) {
            try self.display.presentDocument("New Tab", "about:blank", "Open a page with Ctrl+L or the address bar.");
            return;
        }

        // Reuse presentation scratch capacity between frames. The Display
        // backend clones the list synchronously in presentPageView(), so no
        // pointers allocated from this arena escape this function.
        _ = self.scratch_arena.reset(.retain_capacity);
        const presentation_allocator = self.scratch_arena.allocator();

        var body: std.Io.Writer.Allocating = .init(presentation_allocator);
        defer body.deinit();
        try markdown.dump(frame.window._document.asNode(), .{ .scratch_allocator = presentation_allocator }, &body.writer, frame);

        var list = try DocumentPainter.paintDocument(presentation_allocator, frame, .{
            .viewport_width = @intCast(self.display.viewport.width),
            .viewport_height = @intCast(self.display.viewport.height),
            .layout_scale = tab.zoom_percent,
        });
        defer list.deinit(presentation_allocator);

        const title = (try frame.getTitle()) orelse "";
        const text = body.written();
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(title);
        hasher.update(frame.url);
        hasher.update(text);
        list.hashInto(&hasher);
        const hash = hasher.final();
        tab.last_presented_render_version = frame._page.render_version;
        tab.last_presented_loading = tab.loading;
        if (hash == tab.last_presented_hash) return;
        tab.last_presented_hash = hash;
        self.display.setImageRequestCookieJar(tab.session.cookieJar());
        try self.display.presentPageView(title, frame.url, text, &list);
    }

    fn applyNativeViewportResize(self: *Shell, viewport: Display.Viewport) !void {
        self.width = viewport.width;
        self.height = viewport.height;

        // All tabs in this native window share its client viewport. Update the
        // browser-level source of truth first so resize handlers/media queries
        // observe the new dimensions synchronously.
        for (self.tabs.items) |tab| {
            tab.browser.viewport_override = .{ .width = viewport.width, .height = viewport.height };
            var isolate_scope = TabIsolateScope.init(tab);
            defer isolate_scope.deinit();
            for (tab.session.pages.items) |page| {
                try page.viewportChanged();
            }
            tab.last_presented_hash = 0;
        }
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
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                const target_frame = if (activation.frame_id == 0) frame else frame.findFrameById(activation.frame_id) orelse frame;
                const pending_before = tab.session.pending_downloads.items.len;
                try target_frame.triggerMouseDown(activation.x, activation.y, .main, .{ .buttons = 1 });
                try target_frame.triggerMouseUp(activation.x, activation.y, .main, .{});
                var click = try target_frame.triggerMouseClickOnNodePathWithResult(activation.dom_path, activation.x, activation.y, .main, .{});
                if (!click.dispatched) {
                    click = try target_frame.triggerMouseClickWithModifiers(activation.x, activation.y, .main, .{});
                }
                tab.last_presented_hash = 0;
                const queued_download = tab.session.pending_downloads.items.len > pending_before;
                if (!click.default_prevented and !queued_download and (activation.open_in_new_tab or activation.target_name.len > 0)) {
                    try self.newTab(activation.url, true);
                }
            },
            .activate_control_region => |activation| {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                const target_frame = if (activation.frame_id == 0) frame else frame.findFrameById(activation.frame_id) orelse frame;
                try target_frame.triggerMouseDown(activation.x, activation.y, .main, .{ .buttons = 1 });
                if (activation.caret_character_index) |character_index| {
                    try target_frame.setInputCaretOnNodePath(activation.dom_path, character_index);
                }
                try target_frame.triggerMouseUp(activation.x, activation.y, .main, .{});
                var click = try target_frame.triggerMouseClickOnNodePathWithResult(activation.dom_path, activation.x, activation.y, .main, .{});
                if (!click.dispatched) {
                    click = try target_frame.triggerMouseClickWithModifiers(activation.x, activation.y, .main, .{});
                }
                tab.last_presented_hash = 0;
            },
            .back => {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                if (tab.session.navigation.getCanGoBack()) {
                    var nav_scope: NavigationScopeGuard = undefined;
                    nav_scope.init(frame);
                    defer nav_scope.deinit();
                    _ = try tab.session.navigation.back(frame);
                    tab.loading = true;
                    tab.last_presented_hash = 0;
                }
            },
            .forward => {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                if (tab.session.navigation.getCanGoForward()) {
                    var nav_scope: NavigationScopeGuard = undefined;
                    nav_scope.init(frame);
                    defer nav_scope.deinit();
                    _ = try tab.session.navigation.forward(frame);
                    tab.loading = true;
                    tab.last_presented_hash = 0;
                }
            },
            .reload => {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                if (!isBlankAddress(frame.url)) {
                    var nav_scope: NavigationScopeGuard = undefined;
                    nav_scope.init(frame);
                    defer nav_scope.deinit();
                    _ = try tab.session.navigation.reload(null, frame);
                    tab.loading = true;
                    tab.last_presented_hash = 0;
                }
            },
            .stop => {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                frame.abortTransfers();
                tab.loading = false;
                tab.last_presented_hash = 0;
            },
            .history_traverse => |index| {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                const entries = tab.session.navigation.entries();
                if (index < entries.len) {
                    var nav_scope: NavigationScopeGuard = undefined;
                    nav_scope.init(frame);
                    defer nav_scope.deinit();
                    _ = try tab.session.navigation.traverseTo(entries[index].key(), null, frame);
                    tab.loading = true;
                    tab.last_presented_hash = 0;
                }
            },
            .history_open_new_tab => |index| {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
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
                    var isolate_scope = TabIsolateScope.init(candidate);
                    defer isolate_scope.deinit();
                    var nav_scope: NavigationScopeGuard = undefined;
                    nav_scope.init(candidate_frame);
                    defer nav_scope.deinit();
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
            .download => |request| {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                try self.downloads.startDownloadFromValues(self.app, frame, tab.session, tab.notification, tab, request.url, request.suggested_filename);
            },
            .download_source => |index| if (self.downloads.entryUrl(index)) |url| try tab.navigate(url),
            .download_source_new_tab => |index| if (self.downloads.entryUrl(index)) |url| try self.newTab(url, true),
            .download_retry => |index| if (self.downloads.entryUrl(index)) |url| {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                const filename = self.downloads.entrySuggestedFilename(index) orelse "";
                try self.downloads.startDownloadFromValues(self.app, frame, tab.session, tab.notification, tab, url, filename);
            },
            .download_remove => |index| _ = self.downloads.removeEntry(index),
            .download_clear => self.downloads.clearCompleted(),
            .download_open_file, .download_reveal_file, .download_open_folder, .download_sort_set, .download_filter_set, .download_filter_clear => {},
            .settings_clear_cookies => {
                tab.session.cookieJar().clearRetainingCapacity();
                self.profile.persistCookies(&self.shared_cookie_jar);
            },
            .settings_clear_local_storage => {
                // Keep existing Bucket/Lookup addresses stable: V8 Storage wrappers
                // may still reference them after the clear action.
                self.shared_local_storage_shed.clearLocal();
                self.profile.persistLocalStorage(&self.shared_local_storage_shed);
            },
            .settings_clear_indexed_db => {},
            .error_retry => if (tab.last_error != null) try tab.navigate(tab.url()),
        }
        try self.syncDisplayState();
    }
};

pub fn browse(app: *App, opts: anytype) !void {
    var shell = try Shell.init(app, opts);
    defer shell.deinit();

    try shell.restoreOrStart(opts.url);
    while (shell.tabs.items.len > 0 and !shell.display.userClosed()) {
        if (shell.display.takeNativeViewportResize()) |viewport| {
            try shell.applyNativeViewportResize(viewport);
        }
        if (shell.activeTab()) |tab| {
            if (tab.frame()) |frame| {
                var isolate_scope = TabIsolateScope.init(tab);
                defer isolate_scope.deinit();
                const input_changed = shell.display.dispatchNativeInput(frame) catch |err| blk: {
                    lp.log.warn(.app, "headed input", .{ .err = err });
                    break :blk false;
                };
                if (input_changed) {
                    // Native input can change selector state (:hover/:active/:focus)
                    // without a DOM mutation, so invalidate render/style caches too.
                    frame.renderChanged();
                    tab.last_presented_hash = 0;
                }
            }
        }
        try shell.drainCommands();
        if (shell.tabs.items.len == 0) break;
        try shell.tick();
        try shell.syncDisplayState();
        try shell.present();
        shell.persistProfileState(false);
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
