// Copyright (C) 2023-2025  Lightpanda (Selecy SAS)
//
// Francis Bouvier <francis@lightpanda.io>
// Pierre Tachoire <pierre@lightpanda.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");

pub const log = @import("log.zig");
pub const datetime = @import("datetime.zig");
pub const App = @import("App.zig");
pub const Arena = @import("Arena.zig");
pub const ArenaPool = @import("ArenaPool.zig");
pub const Network = @import("network/Network.zig");
pub const Server = @import("Server.zig");
pub const Config = @import("Config.zig");
pub const String = @import("string.zig").String;
pub const Notification = @import("Notification.zig");

pub const URL = @import("browser/URL.zig");
pub const Page = @import("browser/Page.zig");
pub const Frame = @import("browser/Frame.zig");
pub const Browser = @import("browser/Browser.zig");
pub const Session = @import("browser/Session.zig");

pub const js = @import("browser/js/js.zig");
pub const dump = @import("browser/dump.zig");
pub const markdown = @import("browser/markdown.zig");
pub const SemanticTree = @import("SemanticTree.zig");
pub const CDPNode = @import("cdp/Node.zig");
pub const interactive = @import("browser/interactive.zig");
pub const links = @import("browser/links.zig");
pub const forms = @import("browser/forms.zig");
pub const actions = @import("browser/actions.zig");
pub const structured_data = @import("browser/structured_data.zig");
pub const tools = @import("browser/tools.zig");
pub const HttpClient = @import("network/HttpClient.zig");

pub const mcp = @import("mcp.zig");
pub const Agent = @import("agent/Agent.zig");
pub const Command = @import("script/command.zig").Command;
pub const Recorder = @import("script/Recorder.zig");
pub const Runtime = @import("script/Runtime.zig");
pub const Schema = @import("script/Schema.zig");
pub const skill = @import("script/skill.zig");
pub const cookies = @import("cookies.zig");
pub const build_config = @import("build_config");
pub const crash_handler = @import("crash_handler.zig");
pub const core_dump = @import("core_dump.zig");

pub const Updater = @import("Updater.zig");

pub var metrics = @import("Metrics.zig"){};

pub const IS_TEST = @import("builtin").is_test;
pub const IS_DEBUG = @import("builtin").mode == .Debug;

/// Process-wide Io instance for blocking syscalls (fs, net, time, futex).
/// Single-threaded-init only disables Io.async/Io.concurrent task spawning;
/// blocking operations work from any thread.
var io_threaded: std.Io.Threaded = .init_single_threaded;
pub const io: std.Io = io_threaded.io();

/// The single-threaded Io instance carries an empty environ; consumers that
/// need the real process environment (env-var lookups, spawned children) use
/// this instead.
pub fn environ() std.process.Environ {
    return .{ .block = .{ .slice = std.mem.span(std.c.environ) } };
}

/// Environ.Map view of `environ` for spawned children that should inherit the
/// process environment (argv[0] PATH resolution always uses the parent
/// environment regardless).
pub fn environMap(allocator: std.mem.Allocator) !std.process.Environ.Map {
    return environ().createMap(allocator);
}

/// Io.Condition has no timed wait (@ZIG16: delete when std grows one).
/// Mirrors std's Condition.waitInner with a deadline-bounded futex wait.
/// Not a cancelation point. Returns error.Timeout when no signal arrives.
pub fn timedWait(cond: *std.Io.Condition, mutex: *std.Io.Mutex, timeout_ns: u64) error{Timeout}!void {
    const deadline: std.Io.Clock.Timestamp = .fromNow(io, .{
        .raw = .fromNanoseconds(@intCast(timeout_ns)),
        .clock = .awake,
    });

    var epoch = cond.epoch.load(.acquire);
    _ = cond.state.fetchAdd(.{ .waiters = 1, .signals = 0 }, .monotonic);

    mutex.unlock(io);
    defer mutex.lockUncancelable(io);

    while (true) {
        io.futexWaitTimeout(u32, &cond.epoch.raw, epoch, .{ .deadline = deadline }) catch {};
        epoch = cond.epoch.load(.acquire);

        // Consume a pending signal even after a timeout-shaped wake, so a
        // signal never gets stuck in the state with no waiter (same race
        // std's waitInner defends against).
        var prev_state = cond.state.load(.monotonic);
        while (prev_state.signals > 0) {
            prev_state = cond.state.cmpxchgWeak(prev_state, .{
                .waiters = prev_state.waiters - 1,
                .signals = prev_state.signals - 1,
            }, .acquire, .monotonic) orelse return;
        }

        if (deadline.compare(.lte, .now(io, .awake))) {
            _ = cond.state.fetchSub(.{ .waiters = 1, .signals = 0 }, .monotonic);
            return error.Timeout;
        }
    }
}

/// Drop-in for the removed std.Thread.WaitGroup (start/finish/wait subset).
pub const WaitGroup = struct {
    state: std.atomic.Value(u32) = .init(0),

    pub fn start(self: *WaitGroup) void {
        _ = self.state.fetchAdd(1, .monotonic);
    }

    pub fn startMany(self: *WaitGroup, n: u32) void {
        _ = self.state.fetchAdd(n, .monotonic);
    }

    pub fn finish(self: *WaitGroup) void {
        if (self.state.fetchSub(1, .acq_rel) == 1) {
            io.futexWake(u32, &self.state.raw, std.math.maxInt(u32));
        }
    }

    pub fn wait(self: *WaitGroup) void {
        while (true) {
            const n = self.state.load(.acquire);
            if (n == 0) {
                return;
            }
            io.futexWaitUncancelable(u32, &self.state.raw, n);
        }
    }
};

/// Drop-in for the removed std.once: `f` runs exactly once; concurrent
/// callers block until the first call completes.
pub fn once(comptime f: fn () void) Once(f) {
    return .{};
}

pub fn Once(comptime f: fn () void) type {
    return struct {
        done: bool = false,
        mutex: std.Io.Mutex = .init,

        pub fn call(self: *@This()) void {
            if (@atomicLoad(bool, &self.done, .acquire)) {
                return;
            }
            self.mutex.lockUncancelable(io);
            defer self.mutex.unlock(io);
            if (!self.done) {
                f();
                @atomicStore(bool, &self.done, true, .release);
            }
        }
    };
}

pub const FetchOpts = struct {
    wait_ms: u32 = 5000,
    wait_until: ?Config.WaitUntil = null,
    wait_script: ?[:0]const u8 = null,
    inject_script: std.ArrayList([]const u8) = .empty,
    wait_selector: ?[:0]const u8 = null,
    dump: dump.Opts,
    dump_mode: ?Config.DumpFormat = null,
    writer: ?*std.Io.Writer = null,
    json: bool = false,
};

/// `.load`, not `.done`: pages with constant background activity never go
/// quiescent, so `.done` just rides the `wait_ms` cap. A lone
/// `wait_selector`/`wait_script` is itself the wait, so no level applies
/// unless given explicitly.
fn resolveWaitUntil(opts: FetchOpts) ?Config.WaitUntil {
    if (opts.wait_until) |wu| return wu;
    if (opts.wait_selector == null and opts.wait_script == null) return .load;
    return null;
}
/// Loads each url in `urls` in a fresh session and waits per `opts`.
///
/// Errors:
///   - `error.Timeout` if the deadline expires while a `wait_selector` or
///     `wait_script` is still unmet. The `wait_until` phase never raises it:
///     when the budget runs out the page is dumped as-is.
///   - `error.Cancelled` if the embedder installed a `Session.cancel_hook`
///     that returned true during the wait. The hook is opt-in via
///     `session.cancel_hook = .{...}`; without it, this error never fires.
///   - Other errors from navigation / parsing / I/O surface as their
///     underlying tag.
pub fn fetch(app: *App, browser: *Browser, urls: []const [:0]const u8, opts: FetchOpts) !void {
    const notification = try Notification.init(app.allocator);
    defer notification.deinit();

    var session = try browser.newSession(notification);
    // Session.deinit unregisters from notification; close before notification.deinit runs.
    defer browser.closeSession();

    if (app.config.cookieFile()) |cookie_path| {
        cookies.loadFromFile(session, cookie_path);
    }

    defer {
        if (app.config.cookieJarFile()) |cookie_jar_path| {
            cookies.saveToFile(&session.cookie_jar, cookie_jar_path);
        }
    }

    // Stash scripts user want to inject.
    session.inject_scripts = opts.inject_script.items;

    // One page per url. `PageHandle.frame()` always re-resolves the live frame,
    // so the handles stay valid across navigate / wait. The Runner's wait paths
    // already operate over every live page in the session.
    var pages: std.ArrayList(Session.PageHandle) = try .initCapacity(session.arena.allocator(), urls.len);
    for (urls) |url| {
        const page = try session.createPage();
        const frame = page.frame().?;
        // not guaranteed to be valid after navigate
        const encoded_url = try URL.resolveNavigation(frame.call_arena, url, .{});
        _ = try frame.navigate(encoded_url, .{
            .reason = .address_bar,
            .kind = .{ .push = null },
        });
        pages.appendAssumeCapacity(page);
    }

    // // Both profilers are debug-only (`@compileError` in the start functions)
    // // and cover pages.items[0], so pass a single url.

    // // Uncomment to get a profile of the JS code. You can open this in
    // // Chrome's profiler. I've seen it generate invalid JSON, but I'm not
    // // sure why. It happens rarely, and I manually fix the file.
    // pages.items[0].frame().?.js.startCpuProfiler();
    // defer {
    //     if (pages.items[0].frame().?.js.stopCpuProfiler()) |profile| {
    //         std.Io.Dir.cwd().writeFile(io, .{
    //             .sub_path = ".lp-cache/cpu_profile.json",
    //             .data = profile,
    //         }) catch |err| {
    //             log.err(.app, "profile write error", .{ .err = err });
    //         };
    //     } else |err| {
    //         log.err(.app, "profile error", .{ .err = err });
    //     }
    // }

    // // Uncomment to get a V8 heap profile. The snapshot opens in Chrome's
    // // Memory tab, which is where the retainer breakdown lives.
    // pages.items[0].frame().?.js.startHeapProfiler();
    // defer {
    //     if (pages.items[0].frame().?.js.stopHeapProfiler()) |profile| {
    //         std.Io.Dir.cwd().writeFile(io, .{
    //             .sub_path = ".lp-cache/allocating.heapprofile",
    //             .data = profile.@"0",
    //         }) catch |err| {
    //             log.err(.app, "allocating write error", .{ .err = err });
    //         };
    //         std.Io.Dir.cwd().writeFile(io, .{
    //             .sub_path = ".lp-cache/snapshot.heapsnapshot",
    //             .data = profile.@"1",
    //         }) catch |err| {
    //             log.err(.app, "heapsnapshot write error", .{ .err = err });
    //         };
    //     } else |err| {
    //         log.err(.app, "profile error", .{ .err = err });
    //     }
    // }

    var runner = session.runner(.{});

    var timer: std.Io.Timestamp = .now(io, .boot);

    if (resolveWaitUntil(opts)) |wu| {
        try runner.waitForAll(opts.wait_ms, .{ .until = wu });
    }

    if (opts.wait_selector) |selector| {
        const elapsed: u32 = @intCast(timer.untilNow(io, .boot).toMilliseconds());
        const remaining = opts.wait_ms -| elapsed;
        if (remaining == 0) {
            return error.Timeout;
        }
        for (session.pages.items) |p| {
            if (p.replacement == null) {
                _ = try runner.waitForSelector(p.frame._frame_id, selector, remaining);
            }
        }
    }

    if (opts.wait_script) |wait_script| {
        const elapsed: u32 = @intCast(timer.untilNow(io, .boot).toMilliseconds());
        const remaining = opts.wait_ms -| elapsed;
        if (remaining == 0) {
            return error.Timeout;
        }
        for (session.pages.items) |p| {
            if (p.replacement == null) {
                try runner.waitForScript(p.frame._frame_id, wait_script, remaining);
            }
        }
    }

    const writer = opts.writer orelse return;

    if (opts.json) {
        // A single url keeps the original bare-object output. Multiple urls are
        // wrapped in an extensible `{"results": [...]}` envelope: a bare
        // top-level array is hard to evolve (consumers index it directly),
        // whereas an object lets us add sibling fields later without breaking
        // anyone reading `results`.
        const wrap = pages.items.len > 1;
        if (wrap) {
            try writer.writeAll("{\"results\":[");
        }
        for (pages.items, 0..) |page, i| {
            if (i != 0) {
                try writer.writeByte(',');
            }

            var aw: std.Io.Writer.Allocating = .init(app.allocator);
            defer aw.deinit();

            if (opts.dump_mode) |mode| blk: {
                const frame = page.frame() orelse break :blk;
                try dumpContent(app, mode, opts.dump, frame, &aw.writer);
            }

            try writeJsonEnvelope(writer, page.frame(), opts.dump_mode, aw.written());
        }
        if (wrap) {
            try writer.writeAll("]}");
        }
        try writer.writeByte('\n');
    } else {
        // main validates that non-JSON dump is only reached with a single url.
        const page = pages.items[0];
        if (opts.dump_mode) |mode| blk: {
            const frame = page.frame() orelse {
                try writer.writeAll("Frame closed. Please open a bug report including the URL\n");
                break :blk;
            };
            try dumpContent(app, mode, opts.dump, frame, writer);
        }
    }
    try writer.flush();
}

fn dumpContent(app: *App, mode: Config.DumpFormat, dump_opts: dump.Opts, frame: *Frame, writer: *std.Io.Writer) !void {
    switch (mode) {
        .html => try dump.root(frame.window._document, dump_opts, writer, frame),
        .markdown => try markdown.dump(frame.window._document.asNode(), .{}, writer, frame),
        .semantic_tree, .semantic_tree_text => {
            var registry = CDPNode.Registry.init(app.allocator);
            defer registry.deinit();

            const st: SemanticTree = .{
                .dom_node = frame.window._document.asNode(),
                .registry = &registry,
                .frame = frame,
                .arena = frame.call_arena,
                .prune = (mode == .semantic_tree_text),
            };

            if (mode == .semantic_tree) {
                try std.json.Stringify.value(st, .{}, writer);
            } else {
                try st.textStringify(writer);
            }
        },
        .wpt => try dumpWPT(frame, writer),
    }
}

pub fn checkVersion(allocator: std.mem.Allocator, config: *const Config) !void {
    var client = try Updater.init(allocator, config);
    defer client.deinit();

    const stdout = std.Io.File.stdout();
    var buf: [4096]u8 = undefined;
    var writer = stdout.writer(io, &buf);
    const w = &writer.interface;
    try client.inform(w);
}

// Writes a single page's result object. Framing (the enclosing array and any
// separators / trailing newline) is the caller's responsibility.
fn writeJsonEnvelope(writer: *std.Io.Writer, frame: ?*Frame, dump_mode: ?Config.DumpFormat, content: []const u8) !void {
    const meta: ?Frame.HttpMetadata = if (frame) |f| f.httpMetadata() else null;
    try std.json.Stringify.value(.{
        .url = if (meta) |m| m.url else "",
        .http_status = if (meta) |m| m.status orelse 0 else 0,
        .headers = if (meta) |m| m.headers else &.{},
        .dump = if (dump_mode) |mode| @tagName(mode) else "",
        .content = content,
    }, .{}, writer);
}

fn dumpWPT(frame: *Frame, writer: *std.Io.Writer) !void {
    var ls: js.Local.Scope = undefined;
    frame.js.localScope(&ls);
    defer ls.deinit();

    var try_catch: js.TryCatch = undefined;
    try_catch.init(&ls.local);
    defer try_catch.deinit();

    // return the detailed result.
    const dump_script =
        \\ JSON.stringify((() => {
        \\   const statuses = ['Pass', 'Fail', 'Timeout', 'Not Run', 'Optional Feature Unsupported'];
        \\   const parse = (raw) => {
        \\     for (const status of statuses) {
        \\       const idx = raw.indexOf('|' + status);
        \\       if (idx !== -1) {
        \\         const name = raw.slice(0, idx);
        \\         const rest = raw.slice(idx + status.length + 1);
        \\         const message = rest.length > 0 && rest[0] === '|' ? rest.slice(1) : null;
        \\         return { name, status, message };
        \\       }
        \\     }
        \\     return { name: raw, status: 'Unknown', message: null };
        \\   };
        \\   const cases = Object.values(report.cases).map(parse);
        \\   return {
        \\     url: window.location.href,
        \\     status: report.status,
        \\     message: report.message,
        \\     summary: {
        \\       total: cases.length,
        \\       passed: cases.filter(c => c.status === 'Pass').length,
        \\       failed: cases.filter(c => c.status === 'Fail').length,
        \\       timeout: cases.filter(c => c.status === 'Timeout').length,
        \\       notrun: cases.filter(c => c.status === 'Not Run').length,
        \\       unsupported: cases.filter(c => c.status === 'Optional Feature Unsupported').length
        \\     },
        \\     not_passed: cases.filter(c => c.status !== 'Pass')
        \\   };
        \\ })(), null, 2)
    ;
    const value = ls.local.exec(dump_script, "dump_script") catch |err| {
        const caught = try_catch.caughtOrError(frame.call_arena, err);
        return writer.print("Caught error trying to access WPT's report: {f}\n", .{caught});
    };
    try writer.writeAll("== WPT Results==\n");
    try writer.writeAll(try value.toStringSliceWithAlloc(frame.call_arena));
}

pub inline fn assert(ok: bool, comptime ctx: []const u8, args: anytype) void {
    if (!ok) {
        assertionFailure(ctx, args);
    }
}

noinline fn assertionFailure(comptime ctx: []const u8, args: anytype) noreturn {
    @branchHint(.cold);
    if (@inComptime()) {
        @compileError(std.fmt.comptimePrint("assertion failure: " ++ ctx, args));
    }
    @import("crash_handler.zig").crash(ctx, args, @returnAddress());
}

// Written into every RC at construction (rc_canary) and overwritten with
// rc_poison on the final release. We only get crash reports (not logs) from
// prod, so reading _canary in the "release overflow" assert tells us which kind
// of bug it is:
//   - rc_canary ("RCNT"): the struct still looks live -> a real refcount
//     accounting bug, OR the memory was reused by a freshly-built RC (which
//     re-stamps the canary, so this case can't be fully ruled out).
//   - rc_poison ("DEADC0DE"): a stale finalizer fired again on an object we
//     already released, before its memory was reused -> UAF.
//   - anything else: the memory was freed and reused by non-RC data -> UAF.
const rc_canary: u32 = 0x52434E54;
const rc_poison: u32 = 0xDEADC0DE;

// Reference counting helper. The count is a u32: a u8 silently wrapped at 256
// concurrent refs (e.g. hundreds of live iterators on one URLSearchParams),
// causing a premature deinit and a poisoned "release overflow" crash.
pub const RC = struct {
    _refs: std.atomic.Value(u32) = .init(0),
    _canary: u32 = rc_canary,

    pub fn init(refs: u32) RC {
        return .{ ._refs = .init(refs) };
    }

    pub fn acquire(self: *RC) void {
        _ = self._refs.fetchAdd(1, .monotonic);
    }

    pub fn release(self: *RC, value: anytype, page: *Page) void {
        const prev = self._refs.fetchSub(1, .acq_rel);
        assert(prev > 0, "release overflow", .{
            .type = @typeName(@TypeOf(value)),
            .canary = self._canary, // rc_canary=live/accounting, rc_poison=double-release, else=reuse
            .refs = prev,
            .ptr = @intFromPtr(value),
        });
        if (prev == 1) {
            // Mark dead before deinit frees this memory, so a stale
            // weak-callback re-fire reads rc_poison instead of a
            // misleadingly-intact canary.
            self._canary = rc_poison;
            value.deinit(page);
        }
    }

    pub fn format(self: RC, writer: *std.Io.Writer) !void {
        return writer.print("{d}", .{self._refs.load(.monotonic)});
    }
};

const testing = @import("testing.zig");
test "writeJsonEnvelope: null frame" {
    var aw: std.Io.Writer.Allocating = .init(testing.allocator);
    defer aw.deinit();

    try writeJsonEnvelope(&aw.writer, null, null, "");
    try testing.expectJson(.{
        .url = "",
        .http_status = 0,
        .dump = "",
        .content = "",
    }, aw.written());
}

test "writeJsonEnvelope: null frame with dump mode and content" {
    var aw: std.Io.Writer.Allocating = .init(testing.allocator);
    defer aw.deinit();

    try writeJsonEnvelope(&aw.writer, null, .html, "<html><body>hello</body></html>");
    try testing.expectJson(.{
        .dump = "html",
        .content = "<html><body>hello</body></html>",
    }, aw.written());
}

test "fetch: resolveWaitUntil" {
    try testing.expectEqual(.load, resolveWaitUntil(.{ .dump = .{} }));
    try testing.expectEqual(.done, resolveWaitUntil(.{ .dump = .{}, .wait_until = .done }));
    try testing.expectEqual(null, resolveWaitUntil(.{ .dump = .{}, .wait_selector = "#main" }));
    try testing.expectEqual(null, resolveWaitUntil(.{ .dump = .{}, .wait_script = "true" }));
    try testing.expectEqual(
        .networkidle,
        resolveWaitUntil(.{ .dump = .{}, .wait_until = .networkidle, .wait_selector = "#main" }),
    );
}

test {
    std.testing.refAllDecls(@This());
}

test "normalizeBrowseUrl keeps explicit schemes" {
    const allocator = std.testing.allocator;

    const explicit = try normalizeBrowseUrl(allocator, "http://example.com");
    defer allocator.free(explicit.?);
    try std.testing.expectEqualStrings("http://example.com", explicit.?);

    const about = try normalizeBrowseUrl(allocator, "about:blank");
    defer allocator.free(about.?);
    try std.testing.expectEqualStrings("about:blank", about.?);
}

test "normalizeBrowseUrl defaults bare hosts to https" {
    const allocator = std.testing.allocator;

    const normalized = try normalizeBrowseUrl(allocator, "example.com/path?q=1");
    defer allocator.free(normalized.?);
    try std.testing.expectEqualStrings("https://example.com/path?q=1", normalized.?);
}

test "normalizeBrowseUrl keeps loopback targets on http" {
    const allocator = std.testing.allocator;

    const localhost = try normalizeBrowseUrl(allocator, "localhost:8123/status");
    defer allocator.free(localhost.?);
    try std.testing.expectEqualStrings("http://localhost:8123/status", localhost.?);

    const ipv4 = try normalizeBrowseUrl(allocator, "127.0.0.1:9222/json/version");
    defer allocator.free(ipv4.?);
    try std.testing.expectEqualStrings("http://127.0.0.1:9222/json/version", ipv4.?);

    const ipv6 = try normalizeBrowseUrl(allocator, "[::1]:8080/");
    defer allocator.free(ipv6.?);
    try std.testing.expectEqualStrings("http://[::1]:8080/", ipv6.?);
}

test "applyZoomCommand clamps and resets zoom" {
    try std.testing.expectEqual(@as(i32, 110), applyZoomCommand(100, 100, .zoom_in));
    try std.testing.expectEqual(@as(i32, 90), applyZoomCommand(100, 100, .zoom_out));
    try std.testing.expectEqual(@as(i32, 120), applyZoomCommand(180, 120, .zoom_reset));
    try std.testing.expectEqual(@as(i32, 300), applyZoomCommand(300, 100, .zoom_in));
    try std.testing.expectEqual(@as(i32, 30), applyZoomCommand(30, 100, .zoom_out));
}

test "parseBrowseSettings restores session, popup policy, zoom, and homepage" {
    var settings = try parseBrowseSettings(
        std.testing.allocator,
        "lightpanda-browse-settings-v1\nrestore_previous_session\t0\nallow_script_popups\t0\ndefault_zoom_percent\t130\nhomepage_url\thttp://home.test/\n",
    );
    defer settings.deinit(std.testing.allocator);

    try std.testing.expect(!settings.restore_previous_session);
    try std.testing.expect(!settings.allow_script_popups);
    try std.testing.expectEqual(@as(i32, 130), settings.default_zoom_percent);
    try std.testing.expectEqualStrings("http://home.test/", settings.homepage_url);
}

test "applyDefaultZoomCommand clamps and resets default zoom" {
    try std.testing.expectEqual(@as(i32, 110), applyDefaultZoomCommand(100, .settings_default_zoom_in));
    try std.testing.expectEqual(@as(i32, 90), applyDefaultZoomCommand(100, .settings_default_zoom_out));
    try std.testing.expectEqual(@as(i32, 100), applyDefaultZoomCommand(180, .settings_default_zoom_reset));
    try std.testing.expectEqual(@as(i32, 300), applyDefaultZoomCommand(300, .settings_default_zoom_in));
    try std.testing.expectEqual(@as(i32, 30), applyDefaultZoomCommand(30, .settings_default_zoom_out));
}

test "parseSavedBrowseSession restores active index and zoom" {
    var session = try parseSavedBrowseSession(
        std.testing.allocator,
        "lightpanda-browse-session-v1\nactive\t1\ntab\t125\thttp://one.test/\ntab\t90\thttp://two.test/\n",
    );
    defer session.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), session.active_index);
    try std.testing.expectEqual(@as(usize, 2), session.tabs.items.len);
    try std.testing.expectEqualStrings("http://one.test/", session.tabs.items[0].url);
    try std.testing.expectEqual(@as(i32, 125), session.tabs.items[0].zoom_percent);
    try std.testing.expectEqualStrings("http://two.test/", session.tabs.items[1].url);
    try std.testing.expectEqual(@as(i32, 90), session.tabs.items[1].zoom_percent);
}

test "shouldAppendStartupUrl skips restored duplicates" {
    var saved = SavedBrowseSession{};
    defer saved.deinit(std.testing.allocator);

    try saved.tabs.append(std.testing.allocator, .{
        .url = try std.testing.allocator.dupe(u8, "http://one.test/"),
        .zoom_percent = 100,
    });
    try saved.tabs.append(std.testing.allocator, .{
        .url = try std.testing.allocator.dupe(u8, "http://two.test/"),
        .zoom_percent = 110,
    });

    try std.testing.expect(!shouldAppendStartupUrl(saved.tabs.items, "http://two.test/"));
    try std.testing.expect(shouldAppendStartupUrl(saved.tabs.items, "http://three.test/"));
}

test "targetAlwaysOpensFreshTab only matches _blank" {
    try std.testing.expect(targetAlwaysOpensFreshTab("_blank"));
    try std.testing.expect(targetAlwaysOpensFreshTab(" _BLANK "));
    try std.testing.expect(!targetAlwaysOpensFreshTab(""));
    try std.testing.expect(!targetAlwaysOpensFreshTab("report"));
}

test "findBrowseTabIndexByTargetName ignores blank and matches named targets" {
    var one = BrowseTab{
        .http_client = undefined,
        .notification = undefined,
        .browser = undefined,
        .session = undefined,
        .target_name = @constCast("report"),
    };
    var two = BrowseTab{
        .http_client = undefined,
        .notification = undefined,
        .browser = undefined,
        .session = undefined,
        .target_name = @constCast("audit"),
    };
    const tabs = [_]*BrowseTab{ &one, &two };
    try std.testing.expectEqual(@as(?usize, 0), findBrowseTabIndexByTargetName(&tabs, "report"));
    try std.testing.expectEqual(@as(?usize, 1), findBrowseTabIndexByTargetName(&tabs, " AUDIT "));
    try std.testing.expectEqual(@as(?usize, null), findBrowseTabIndexByTargetName(&tabs, "_blank"));
}

test "openOrReuseTargetedBrowseTab reuses existing named tab" {
    var tabs: std.ArrayListUnmanaged(*BrowseTab) = .{};
    defer deinitBrowseTabs(testing.test_app.allocator, &tabs);

    var active_tab_index: usize = 0;
    const source = try createBrowseTab(testing.test_app, null, 100, true);
    try appendBrowseTab(testing.test_app.allocator, &tabs, source, &active_tab_index, true);

    const first_url = "http://127.0.0.1:9582/src/browser/tests/page/popup-target-result.html";
    const second_url = "http://127.0.0.1:9582/src/browser/tests/page/popup-target-post.html";
    const opts: Page.NavigateOpts = .{
        .reason = .address_bar,
        .kind = .{ .push = null },
    };

    try openOrReuseTargetedBrowseTab(
        testing.test_app,
        &tabs,
        &active_tab_index,
        true,
        100,
        first_url,
        opts,
        "report",
        true,
        .script,
    );
    try std.testing.expectEqual(@as(usize, 2), tabs.items.len);
    try std.testing.expectEqual(@as(usize, 1), active_tab_index);
    try std.testing.expectEqualStrings("report", tabs.items[1].target_name);
    try std.testing.expectEqual(PopupSource.script, tabs.items[1].popup_source);
    _ = tabs.items[1].session.wait(2000);

    active_tab_index = 0;
    try openOrReuseTargetedBrowseTab(
        testing.test_app,
        &tabs,
        &active_tab_index,
        true,
        100,
        second_url,
        opts,
        "report",
        true,
        .form,
    );
    try std.testing.expectEqual(@as(usize, 2), tabs.items.len);
    try std.testing.expectEqual(@as(usize, 1), active_tab_index);
    try std.testing.expectEqualStrings("report", tabs.items[1].target_name);
    try std.testing.expectEqual(PopupSource.form, tabs.items[1].popup_source);
    _ = tabs.items[1].session.wait(2000);

    const target_page = tabs.items[1].session.currentPage() orelse return error.TestPageMissing;
    try std.testing.expectEqualStrings(second_url, target_page.url);
}

test "openOrReuseTargetedBrowseTab resets live named script popup tab before reuse" {
    var tabs: std.ArrayListUnmanaged(*BrowseTab) = .{};
    defer deinitBrowseTabs(testing.test_app.allocator, &tabs);

    var active_tab_index: usize = 0;
    const source = try createBrowseTab(testing.test_app, null, 100, true);
    try appendBrowseTab(testing.test_app.allocator, &tabs, source, &active_tab_index, true);

    const first_url = "http://127.0.0.1:9582/src/browser/tests/page/popup-target-result.html?from=script-one";
    const second_url = "http://127.0.0.1:9582/src/browser/tests/page/popup-target-post.html?from=script-two";
    const opts: Page.NavigateOpts = .{
        .reason = .address_bar,
        .kind = .{ .push = null },
    };

    try openOrReuseTargetedBrowseTab(
        testing.test_app,
        &tabs,
        &active_tab_index,
        true,
        100,
        first_url,
        opts,
        "report",
        true,
        .script,
    );
    _ = tabs.items[1].session.wait(2000);

    const first_page = tabs.items[1].session.currentPage() orelse return error.TestPageMissing;
    try std.testing.expectEqualStrings(first_url, first_page.url);

    active_tab_index = 0;
    try openOrReuseTargetedBrowseTab(
        testing.test_app,
        &tabs,
        &active_tab_index,
        true,
        100,
        second_url,
        opts,
        "report",
        true,
        .script,
    );
    _ = tabs.items[1].session.wait(2000);

    const second_page = tabs.items[1].session.currentPage() orelse return error.TestPageMissing;
    try std.testing.expect(first_page != second_page);
    try std.testing.expectEqualStrings(second_url, second_page.url);
}

test "sanitizeDownloadFileName replaces invalid windows characters" {
    const sanitized = try sanitizeDownloadFileName(std.testing.allocator, "report<>:\\/|?*.txt");
    defer std.testing.allocator.free(sanitized);

    try std.testing.expectEqualStrings("report________.txt", sanitized);
}

test "parseSavedDownloadEntry restores interrupted active downloads" {
    var entry = try parseSavedDownloadEntry(
        std.testing.allocator,
        "1\t12\t20\t1\texample.txt\tC:\\tmp\\example.txt\thttp://example.test/file.txt\tDownloading",
    );
    defer entry.deinit(std.testing.allocator);

    try std.testing.expectEqual(BrowseDownloadStatus.interrupted, entry.status);
    try std.testing.expectEqual(@as(usize, 12), entry.bytes_received);
    try std.testing.expectEqual(@as(usize, 20), entry.total_bytes);
    try std.testing.expect(entry.has_total_bytes);
    try std.testing.expectEqualStrings("example.txt", entry.filename);
}

test "normalizeBrowseUrl rejects blank input" {
    try std.testing.expect((try normalizeBrowseUrl(std.testing.allocator, "   ")) == null);
}

test "normalizeBrowseUrl rejects search-like input without a scheme" {
    try std.testing.expectError(error.InvalidUrl, normalizeBrowseUrl(std.testing.allocator, "two words"));
}

test "parseInternalBrowsePage recognizes browser aliases" {
    try std.testing.expectEqual(@as(?InternalBrowsePage, .start), parseInternalBrowsePage("browser://start"));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .error_page), parseInternalBrowsePage("browser://error"));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .tabs), parseInternalBrowsePage("browser://tabs"));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .history), parseInternalBrowsePage("browser://history"));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .bookmarks), parseInternalBrowsePage("browser://bookmarks/"));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .downloads), parseInternalBrowsePage("browser://downloads?recent=1"));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .settings), parseInternalBrowsePage("browser://settings#shell"));
    try std.testing.expectEqual(@as(?InternalBrowsePage, null), parseInternalBrowsePage("https://example.com"));
}

test "parseInternalBrowseRoute recognizes interactive browser page actions" {
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .page = .start },
        parseInternalBrowseRoute("browser://start").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .page = .error_page },
        parseInternalBrowseRoute("browser://error").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .error_retry },
        parseInternalBrowseRoute("browser://error/retry").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .home },
        parseInternalBrowseRoute("browser://error/home").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .page_start },
        parseInternalBrowseRoute("browser://error/start").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .page = .tabs },
        parseInternalBrowseRoute("browser://tabs").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .tab_new },
        parseInternalBrowseRoute("browser://tabs/new").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .tab_reopen_closed },
        parseInternalBrowseRoute("browser://tabs/reopen-closed").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .tab_reopen_closed_index = 1 } },
        parseInternalBrowseRoute("browser://tabs/reopen-closed/1").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .tab_activate = 2 } },
        parseInternalBrowseRoute("browser://tabs/activate/2").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .tab_duplicate_index = 1 } },
        parseInternalBrowseRoute("browser://tabs/duplicate/1").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .tab_reload_index = 0 } },
        parseInternalBrowseRoute("browser://tabs/reload/0").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .tab_close = 3 } },
        parseInternalBrowseRoute("browser://tabs/close/3").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .history_traverse = 2 } },
        parseInternalBrowseRoute("browser://history/traverse/2").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .history_open_new_tab = 2 } },
        parseInternalBrowseRoute("browser://history/open-new-tab/2").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .history_sort_set = .newest_first } },
        parseInternalBrowseRoute("browser://history/sort/newest-first").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .history_clear_session },
        parseInternalBrowseRoute("browser://history/clear-session").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .history_filter_clear },
        parseInternalBrowseRoute("browser://history/filter-clear").?,
    );
    const history_filter_route = parseInternalBrowseRoute("browser://history/filter/127.0.0.1").?;
    switch (history_filter_route) {
        .command => |command| switch (command) {
            .history_filter_set => |value| try std.testing.expectEqualStrings("127.0.0.1", value),
            else => return error.TestUnexpectedResult,
        },
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .bookmark_add_current },
        parseInternalBrowseRoute("browser://bookmarks/add-current").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .bookmark_sort_set = .alphabetical } },
        parseInternalBrowseRoute("browser://bookmarks/sort/alphabetical").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .bookmark_filter_clear },
        parseInternalBrowseRoute("browser://bookmarks/filter-clear").?,
    );
    const bookmark_filter_route = parseInternalBrowseRoute("browser://bookmarks/filter/browser%3A%2F%2F").?;
    switch (bookmark_filter_route) {
        .command => |command| switch (command) {
            .bookmark_filter_set => |value| try std.testing.expectEqualStrings("browser%3A%2F%2F", value),
            else => return error.TestUnexpectedResult,
        },
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .bookmark_open = 3 } },
        parseInternalBrowseRoute("browser://bookmarks/open/3").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .bookmark_open_new_tab = 2 } },
        parseInternalBrowseRoute("browser://bookmarks/open-new-tab/2").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .bookmark_move_up = 2 } },
        parseInternalBrowseRoute("browser://bookmarks/move-up/2").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .bookmark_move_down = 1 } },
        parseInternalBrowseRoute("browser://bookmarks/move-down/1").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .bookmark_remove = 1 } },
        parseInternalBrowseRoute("browser://bookmarks/remove/1").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .download_source = 4 } },
        parseInternalBrowseRoute("browser://downloads/source/4").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .download_sort_set = .newest_first } },
        parseInternalBrowseRoute("browser://downloads/sort/newest-first").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .download_source_new_tab = 1 } },
        parseInternalBrowseRoute("browser://downloads/source-new-tab/1").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .download_retry = 1 } },
        parseInternalBrowseRoute("browser://downloads/retry/1").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .{ .download_remove = 0 } },
        parseInternalBrowseRoute("browser://downloads/remove/0").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .download_clear },
        parseInternalBrowseRoute("browser://downloads/clear").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .download_filter_clear },
        parseInternalBrowseRoute("browser://downloads/filter-clear").?,
    );
    const download_filter_route = parseInternalBrowseRoute("browser://downloads/filter/failed").?;
    switch (download_filter_route) {
        .command => |command| switch (command) {
            .download_filter_set => |value| try std.testing.expectEqualStrings("failed", value),
            else => return error.TestUnexpectedResult,
        },
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .settings_toggle_script_popups },
        parseInternalBrowseRoute("browser://settings/toggle-script-popups").?,
    );
    try std.testing.expectEqualDeep(
        InternalBrowseRoute{ .command = .settings_set_homepage_to_current },
        parseInternalBrowseRoute("browser://settings/homepage/set-current").?,
    );
}

test "writeInternalShellNav marks current section and links other shell pages" {
    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();

    try writeInternalShellNav(&buf.writer, .downloads);

    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "<strong>Downloads</strong>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://start") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://history") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://settings") != null);
}

test "hashInternalTabsPageState changes when active tab changes" {
    var session_one: Session = undefined;
    session_one.page = null;
    var session_two: Session = undefined;
    session_two.page = null;
    var tab_one: BrowseTab = undefined;
    var tab_two: BrowseTab = undefined;
    tab_one.session = &session_one;
    tab_one.committed_surface = .{};
    tab_one.error_state = .{};
    tab_one.internal_filters = .{};
    tab_one.target_name = &.{};
    tab_one.popup_source = .none;
    tab_one.zoom_percent = 100;
    tab_two.session = &session_two;
    tab_two.committed_surface = .{};
    tab_two.error_state = .{};
    tab_two.internal_filters = .{};
    tab_two.target_name = &.{};
    tab_two.popup_source = .none;
    tab_two.zoom_percent = 125;

    var tab_items = [_]*BrowseTab{ &tab_one, &tab_two };
    var tabs = std.ArrayListUnmanaged(*BrowseTab){
        .items = tab_items[0..],
        .capacity = tab_items.len,
    };
    var closed_item = [_]ClosedBrowseTab{.{
        .url = @constCast("about:blank"),
        .zoom_percent = 100,
    }};
    var closed_tabs = std.ArrayListUnmanaged(ClosedBrowseTab){
        .items = closed_item[0..],
        .capacity = closed_item.len,
    };
    var active_index: usize = 1;
    var shell: BrowseShell = .{
        .tabs = &tabs,
        .closed_tabs = &closed_tabs,
        .active_tab_index = &active_index,
    };

    const first_hash = hashInternalTabsPageState(&shell);
    active_index = 1;
    const second_hash = hashInternalTabsPageState(&shell);
    try std.testing.expect(first_hash != second_hash);
}

test "hashInternalTabsPageState changes when closed tab content changes" {
    var session: Session = undefined;
    session.page = null;
    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.committed_surface = .{};
    tab.error_state = .{};
    tab.internal_filters = .{};
    tab.target_name = &.{};
    tab.popup_source = .none;
    tab.zoom_percent = 100;

    var tab_items = [_]*BrowseTab{&tab};
    var tabs = std.ArrayListUnmanaged(*BrowseTab){
        .items = tab_items[0..],
        .capacity = tab_items.len,
    };
    var closed_items = [_]ClosedBrowseTab{
        .{ .url = @constCast("http://closed-one.test/"), .zoom_percent = 100 },
        .{ .url = @constCast("http://closed-two.test/"), .zoom_percent = 110 },
    };
    var closed_tabs = std.ArrayListUnmanaged(ClosedBrowseTab){
        .items = closed_items[0..],
        .capacity = closed_items.len,
    };
    var active_index: usize = 1;
    const shell: BrowseShell = .{
        .tabs = &tabs,
        .closed_tabs = &closed_tabs,
        .active_tab_index = &active_index,
    };

    const first_hash = hashInternalTabsPageState(&shell);
    closed_tabs.items[1].url = @constCast("http://closed-three.test/");
    const second_hash = hashInternalTabsPageState(&shell);
    try std.testing.expect(first_hash != second_hash);
}

test "writeInternalTabsPage includes indexed actions and popup metadata" {
    var session_one: Session = undefined;
    session_one.page = null;
    var session_two: Session = undefined;
    session_two.page = null;
    var tab_one: BrowseTab = undefined;
    var tab_two: BrowseTab = undefined;
    tab_one.session = &session_one;
    tab_one.committed_surface = .{};
    tab_one.error_state = .{};
    tab_one.internal_filters = .{};
    tab_one.zoom_percent = 100;
    tab_one.target_name = @constCast("report");
    tab_one.popup_source = .script;
    tab_two.session = &session_two;
    tab_two.committed_surface = .{};
    tab_two.error_state = .{};
    tab_two.internal_filters = .{};
    try tab_two.error_state.replace(std.testing.allocator, .navigation_failed, "http://failed.test/", "http://failed.test/", "CouldntConnect");
    defer tab_two.error_state.deinit(std.testing.allocator);
    tab_two.zoom_percent = 125;
    tab_two.target_name = &.{};
    tab_two.popup_source = .none;

    var tab_items = [_]*BrowseTab{ &tab_one, &tab_two };
    var tabs = std.ArrayListUnmanaged(*BrowseTab){
        .items = tab_items[0..],
        .capacity = tab_items.len,
    };
    var closed_item = [_]ClosedBrowseTab{
        .{
            .url = @constCast("http://closed-a.test/"),
            .zoom_percent = 100,
        },
        .{
            .url = @constCast("http://closed-b.test/"),
            .zoom_percent = 125,
        },
    };
    var closed_tabs = std.ArrayListUnmanaged(ClosedBrowseTab){
        .items = closed_item[0..],
        .capacity = closed_item.len,
    };
    var active_index: usize = 1;
    const shell: BrowseShell = .{
        .tabs = &tabs,
        .closed_tabs = &closed_tabs,
        .active_tab_index = &active_index,
    };

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    var downloads = BrowseDownloads{ .allocator = std.testing.allocator };
    defer downloads.deinit(null);
    try writeInternalTabsPage(std.testing.allocator, &buf.writer, null, &shell, &downloads);

    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "Browser Tabs (2)") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/new") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/duplicate/1") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/reopen-closed") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/reopen-closed/0") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/reopen-closed/1") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "target=report") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "popup=script") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "(Error)") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Reason: CouldntConnect") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://error") != null);
}

test "makeClosedBrowseTabDisplayEntries returns newest first ui ordering" {
    const closed_tabs = [_]ClosedBrowseTab{
        .{ .url = @constCast("http://first.test/"), .zoom_percent = 100 },
        .{ .url = @constCast("http://second.test/"), .zoom_percent = 110 },
        .{ .url = @constCast("http://third.test/"), .zoom_percent = 120 },
    };

    var entries = try makeClosedBrowseTabDisplayEntries(std.testing.allocator, closed_tabs[0..], 3);
    defer entries.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 3), entries.items.len);
    try std.testing.expectEqual(@as(usize, 0), entries.items[0].ui_index);
    try std.testing.expectEqualStrings("http://third.test/", entries.items[0].url);
    try std.testing.expectEqual(@as(i32, 120), entries.items[0].zoom_percent);
    try std.testing.expectEqual(@as(usize, 1), entries.items[1].ui_index);
    try std.testing.expectEqualStrings("http://second.test/", entries.items[1].url);
    try std.testing.expectEqual(@as(usize, 2), entries.items[2].ui_index);
    try std.testing.expectEqualStrings("http://first.test/", entries.items[2].url);
}

test "writeInternalStartPage includes preview sections and quick actions" {
    const NavigationHistoryEntry = @import("browser/webapi/navigation/NavigationHistoryEntry.zig");
    const rel_dir = ".zig-cache/tmp/internal-start-page-preview-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);
    savePersistedBookmarks(std.testing.allocator, abs_dir, &.{ "http://bookmark-one.test/", "http://bookmark-two.test/" });

    var session: Session = undefined;
    session.page = null;
    session.navigation = .{ ._proto = undefined };
    const history_one = try std.testing.allocator.create(NavigationHistoryEntry);
    errdefer std.testing.allocator.destroy(history_one);
    history_one.* = .{
        ._id = "history-one",
        ._key = "history-one",
        ._url = "http://history-one.test/",
        ._state = .{ .source = .history, .value = null },
    };
    const history_two = try std.testing.allocator.create(NavigationHistoryEntry);
    errdefer std.testing.allocator.destroy(history_two);
    history_two.* = .{
        ._id = "history-two",
        ._key = "history-two",
        ._url = "http://history-two.test/",
        ._state = .{ .source = .history, .value = null },
    };
    try session.navigation._entries.append(std.testing.allocator, history_one);
    try session.navigation._entries.append(std.testing.allocator, history_two);
    defer {
        session.navigation._entries.deinit(std.testing.allocator);
        std.testing.allocator.destroy(history_one);
        std.testing.allocator.destroy(history_two);
    }
    session.navigation._index = 1;

    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.committed_surface = .{ .url = @constCast("http://current.test/") };
    tab.error_state = .{};
    tab.internal_filters = .{};
    try tab.error_state.replace(std.testing.allocator, .navigation_failed, "http://failed.test/", "http://failed.test/", "CouldntConnect");
    defer tab.error_state.deinit(std.testing.allocator);
    tab.zoom_percent = 100;
    tab.target_name = &.{};
    tab.popup_source = .none;

    var tab_items = [_]*BrowseTab{&tab};
    var tabs = std.ArrayListUnmanaged(*BrowseTab){
        .items = tab_items[0..],
        .capacity = tab_items.len,
    };
    var closed_items = [_]ClosedBrowseTab{
        .{ .url = @constCast("http://closed-one.test/"), .zoom_percent = 100 },
        .{ .url = @constCast("http://closed-two.test/"), .zoom_percent = 125 },
    };
    var closed_tabs = std.ArrayListUnmanaged(ClosedBrowseTab){
        .items = closed_items[0..],
        .capacity = closed_items.len,
    };
    var active_index: usize = 0;
    const shell: BrowseShell = .{
        .tabs = &tabs,
        .closed_tabs = &closed_tabs,
        .active_tab_index = &active_index,
    };
    var settings = BrowseSettings{
        .restore_previous_session = true,
        .allow_script_popups = false,
        .default_zoom_percent = 120,
        .homepage_url = try std.testing.allocator.dupe(u8, "http://home.test/"),
    };
    defer settings.deinit(std.testing.allocator);
    var downloads = BrowseDownloads{ .allocator = std.testing.allocator };
    defer downloads.deinit(null);
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "seed.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/seed.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://download.test/seed.txt"),
        .detail = try std.testing.allocator.dupe(u8, ""),
        .status = .completed,
    });

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    try writeInternalStartPage(std.testing.allocator, &buf.writer, abs_dir, &shell, 0, &settings, &downloads);
    const html = buf.written();

    try std.testing.expect(std.mem.indexOf(u8, html, "Quick Actions") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/new") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://error") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/reopen-closed") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/add-current") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/clear") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Open Tabs") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/activate/0") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Recently Closed") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://tabs/reopen-closed/0") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Recent History") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://history/traverse/1") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Recent Bookmarks") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/open/1") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Recent Downloads") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/source/0") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Settings Snapshot") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://settings/toggle-script-popups") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://settings/default-zoom/reset") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://settings/homepage/clear") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Current Tab Status") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "CouldntConnect") != null);
}

test "writeInternalHistoryPage applies filter state and renders quick links" {
    const NavigationHistoryEntry = @import("browser/webapi/navigation/NavigationHistoryEntry.zig");
    var session: Session = undefined;
    session.page = null;
    session.navigation = .{ ._proto = undefined };
    const first = try std.testing.allocator.create(NavigationHistoryEntry);
    errdefer std.testing.allocator.destroy(first);
    first.* = .{
        ._id = "history-a",
        ._key = "history-a",
        ._url = "http://127.0.0.1:8190/page-two.html",
        ._state = .{ .source = .history, .value = null },
    };
    const second = try std.testing.allocator.create(NavigationHistoryEntry);
    errdefer std.testing.allocator.destroy(second);
    second.* = .{
        ._id = "history-b",
        ._key = "history-b",
        ._url = "http://other.test/hidden.html",
        ._state = .{ .source = .history, .value = null },
    };
    try session.navigation._entries.append(std.testing.allocator, first);
    try session.navigation._entries.append(std.testing.allocator, second);
    defer {
        session.navigation._entries.deinit(std.testing.allocator);
        std.testing.allocator.destroy(first);
        std.testing.allocator.destroy(second);
    }
    session.navigation._index = 0;

    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.committed_surface = .{};
    tab.error_state = .{};
    tab.internal_filters = .{};
    tab.target_name = &.{};
    tab.popup_source = .none;
    tab.zoom_percent = 100;
    try replaceInternalBrowseFilter(std.testing.allocator, &tab.internal_filters.history, "127.0.0.1");
    defer tab.internal_filters.deinit(std.testing.allocator);

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    try writeInternalHistoryPage(std.testing.allocator, &buf.writer, &tab);
    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "Browser History (1/2)") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://history/filter-clear") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://history/sort/newest-first") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://history/filter/127.0.0.1%3A8190") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://history/open-new-tab/0") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "http://127.0.0.1:8190/page-two.html") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "http://other.test/hidden.html") == null);
}

test "writeInternalBookmarksPage applies filter state and renders quick links" {
    const rel_dir = ".zig-cache/tmp/internal-bookmark-filter-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);
    savePersistedBookmarks(std.testing.allocator, abs_dir, &.{ "http://other.test/hidden.html", "http://127.0.0.1:8190/page-two.html" });

    var session: Session = undefined;
    session.page = null;
    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.committed_surface = .{};
    tab.error_state = .{};
    tab.internal_filters = .{};
    tab.target_name = &.{};
    tab.popup_source = .none;
    tab.zoom_percent = 100;
    try replaceInternalBrowseFilter(std.testing.allocator, &tab.internal_filters.bookmarks, "127.0.0.1");
    defer tab.internal_filters.deinit(std.testing.allocator);

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    try writeInternalBookmarksPage(std.testing.allocator, &buf.writer, abs_dir, &tab);
    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "Browser Bookmarks (1/2)") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/filter-clear") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/sort/alphabetical") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/filter/127.0.0.1%3A8190") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/open-new-tab/1") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/move-up/1") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "http://127.0.0.1:8190/page-two.html") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "http://other.test/hidden.html") == null);
}

test "writeInternalDownloadsPage applies filter state and renders quick links" {
    var session: Session = undefined;
    session.page = null;
    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.committed_surface = .{};
    tab.error_state = .{};
    tab.internal_filters = .{};
    tab.target_name = &.{};
    tab.popup_source = .none;
    tab.zoom_percent = 100;
    try replaceInternalBrowseFilter(std.testing.allocator, &tab.internal_filters.downloads, "failed");
    defer tab.internal_filters.deinit(std.testing.allocator);

    var downloads = BrowseDownloads{ .allocator = std.testing.allocator };
    defer downloads.deinit(null);
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "report.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/report.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://127.0.0.1:8190/report.txt"),
        .detail = try std.testing.allocator.dupe(u8, "Failed: CouldntConnect"),
        .status = .failed,
    });
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "seed.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/seed.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://127.0.0.1:8190/seed.txt"),
        .detail = try std.testing.allocator.dupe(u8, ""),
        .status = .completed,
    });

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    try writeInternalDownloadsPage(std.testing.allocator, &buf.writer, &downloads, &tab);
    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "Browser Downloads (1/2)") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/filter-clear") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/sort/newest-first") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/filter/failed") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/source-new-tab/0") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/retry/0") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "report.txt") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "seed.txt") == null);
}

test "writeInternalHistoryPage applies newest-first sort ordering" {
    const NavigationHistoryEntry = @import("browser/webapi/navigation/NavigationHistoryEntry.zig");
    var session: Session = undefined;
    session.page = null;
    session.navigation = .{ ._proto = undefined };
    const first = try std.testing.allocator.create(NavigationHistoryEntry);
    errdefer std.testing.allocator.destroy(first);
    first.* = .{
        ._id = "history-order-a",
        ._key = "history-order-a",
        ._url = "http://one.test/older.html",
        ._state = .{ .source = .history, .value = null },
    };
    const second = try std.testing.allocator.create(NavigationHistoryEntry);
    errdefer std.testing.allocator.destroy(second);
    second.* = .{
        ._id = "history-order-b",
        ._key = "history-order-b",
        ._url = "http://two.test/newer.html",
        ._state = .{ .source = .history, .value = null },
    };
    try session.navigation._entries.append(std.testing.allocator, first);
    try session.navigation._entries.append(std.testing.allocator, second);
    defer {
        session.navigation._entries.deinit(std.testing.allocator);
        std.testing.allocator.destroy(first);
        std.testing.allocator.destroy(second);
    }
    session.navigation._index = 1;

    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.committed_surface = .{};
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.internal_filters.deinit(std.testing.allocator);
    tab.target_name = &.{};
    tab.popup_source = .none;
    tab.zoom_percent = 100;
    tab.internal_filters.history_sort = .newest_first;

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    try writeInternalHistoryPage(std.testing.allocator, &buf.writer, &tab);
    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "Browser History (2, newest first)") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://history/sort/oldest-first") != null);
    const newer_index = std.mem.indexOf(u8, html, "http://two.test/newer.html") orelse return error.TestUnexpectedResult;
    const older_index = std.mem.indexOf(u8, html, "http://one.test/older.html") orelse return error.TestUnexpectedResult;
    try std.testing.expect(newer_index < older_index);
}

test "writeInternalBookmarksPage applies alphabetical sort ordering" {
    const rel_dir = ".zig-cache/tmp/internal-bookmark-sort-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);
    savePersistedBookmarks(std.testing.allocator, abs_dir, &.{ "http://zeta.test/two", "http://alpha.test/one" });

    var session: Session = undefined;
    session.page = null;
    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.committed_surface = .{};
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.internal_filters.deinit(std.testing.allocator);
    tab.target_name = &.{};
    tab.popup_source = .none;
    tab.zoom_percent = 100;
    tab.internal_filters.bookmarks_sort = .alphabetical;

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    try writeInternalBookmarksPage(std.testing.allocator, &buf.writer, abs_dir, &tab);
    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "Browser Bookmarks (2, alphabetical)") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/sort/saved-order") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/move-up/") == null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://bookmarks/move-down/") == null);
    const alpha_index = std.mem.indexOf(u8, html, "http://alpha.test/one") orelse return error.TestUnexpectedResult;
    const zeta_index = std.mem.indexOf(u8, html, "http://zeta.test/two") orelse return error.TestUnexpectedResult;
    try std.testing.expect(alpha_index < zeta_index);
}

test "writeInternalDownloadsPage applies newest-first sort ordering" {
    var session: Session = undefined;
    session.page = null;
    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.committed_surface = .{};
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.internal_filters.deinit(std.testing.allocator);
    tab.target_name = &.{};
    tab.popup_source = .none;
    tab.zoom_percent = 100;
    tab.internal_filters.downloads_sort = .newest_first;

    var downloads = BrowseDownloads{ .allocator = std.testing.allocator };
    defer downloads.deinit(null);
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "older.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/older.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://one.test/older.txt"),
        .detail = try std.testing.allocator.dupe(u8, ""),
        .status = .completed,
    });
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "newer.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/newer.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://one.test/newer.txt"),
        .detail = try std.testing.allocator.dupe(u8, ""),
        .status = .completed,
    });

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    try writeInternalDownloadsPage(std.testing.allocator, &buf.writer, &downloads, &tab);
    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "Browser Downloads (2, newest first)") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/sort/saved-order") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://downloads/retry/") == null);
    const newer_index = std.mem.indexOf(u8, html, "newer.txt") orelse return error.TestUnexpectedResult;
    const older_index = std.mem.indexOf(u8, html, "older.txt") orelse return error.TestUnexpectedResult;
    try std.testing.expect(newer_index < older_index);
}

test "addPersistedBookmark appends unique bookmark once" {
    const rel_dir = ".zig-cache/tmp/internal-bookmark-add-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);

    try std.testing.expect(addPersistedBookmark(std.testing.allocator, abs_dir, "http://one.test/"));
    try std.testing.expect(!addPersistedBookmark(std.testing.allocator, abs_dir, "http://one.test/"));

    var bookmarks = loadPersistedBookmarks(std.testing.allocator, abs_dir);
    defer deinitOwnedStrings(std.testing.allocator, &bookmarks);
    try std.testing.expectEqual(@as(usize, 1), bookmarks.items.len);
    try std.testing.expectEqualStrings("http://one.test/", bookmarks.items[0]);
}

test "clearInactiveEntries removes completed download files and metadata" {
    const rel_dir = ".zig-cache/tmp/internal-download-clear-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);
    const file_path = try std.fs.path.join(std.testing.allocator, &.{ abs_dir, "gone.txt" });
    defer std.testing.allocator.free(file_path);
    var dir = try std.fs.openDirAbsolute(abs_dir, .{});
    defer dir.close();
    try dir.writeFile(.{ .sub_path = "gone.txt", .data = "gone" });

    var downloads = BrowseDownloads{ .allocator = std.testing.allocator };
    defer downloads.deinit(null);
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "gone.txt"),
        .path = try std.testing.allocator.dupe(u8, file_path),
        .url = try std.testing.allocator.dupe(u8, "http://one.test/gone.txt"),
        .detail = try std.testing.allocator.dupe(u8, ""),
        .bytes_received = 4,
        .status = .completed,
    });

    try std.testing.expect(downloads.clearInactiveEntries(abs_dir));
    try std.testing.expectEqual(@as(usize, 0), downloads.entries.items.len);
    try std.testing.expectError(error.FileNotFound, std.fs.accessAbsolute(file_path, .{}));
}

test "makeInternalBrowsePageDisplayTitle reflects live counts" {
    const rel_dir = ".zig-cache/tmp/internal-title-count-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);
    savePersistedBookmarks(std.testing.allocator, abs_dir, &.{ "http://one.test/", "http://two.test/" });

    var session: Session = undefined;
    session.page = null;
    session.navigation = .{ ._proto = undefined };
    const history_one = try std.testing.allocator.create(@import("browser/webapi/navigation/NavigationHistoryEntry.zig"));
    errdefer std.testing.allocator.destroy(history_one);
    history_one.* = .{
        ._id = "title-history-a",
        ._key = "title-history-a",
        ._url = "http://one.test/alpha.html",
        ._state = .{ .source = .history, .value = null },
    };
    const history_two = try std.testing.allocator.create(@import("browser/webapi/navigation/NavigationHistoryEntry.zig"));
    errdefer std.testing.allocator.destroy(history_two);
    history_two.* = .{
        ._id = "title-history-b",
        ._key = "title-history-b",
        ._url = "http://two.test/zeta.html",
        ._state = .{ .source = .history, .value = null },
    };
    try session.navigation._entries.append(std.testing.allocator, history_one);
    try session.navigation._entries.append(std.testing.allocator, history_two);
    defer {
        session.navigation._entries.deinit(std.testing.allocator);
        std.testing.allocator.destroy(history_one);
        std.testing.allocator.destroy(history_two);
    }
    session.navigation._index = 1;
    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.internal_filters.deinit(std.testing.allocator);
    try tab.error_state.replace(std.testing.allocator, .navigation_failed, "http://failed.test/", "http://failed.test/", "CouldntConnect");
    defer tab.error_state.deinit(std.testing.allocator);
    tab.zoom_percent = 100;
    tab.target_name = &.{};
    tab.popup_source = .none;

    const tabs = [_]*BrowseTab{&tab};

    var downloads = BrowseDownloads{ .allocator = std.testing.allocator };
    defer downloads.deinit(null);
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "file.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/file.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://one.test/file.txt"),
        .detail = try std.testing.allocator.dupe(u8, ""),
        .status = .completed,
    });

    const tabs_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .tabs);
    defer std.testing.allocator.free(tabs_title);
    try std.testing.expectEqualStrings("Browser Tabs (1)", tabs_title);

    const history_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .history);
    defer std.testing.allocator.free(history_title);
    try std.testing.expectEqualStrings("Browser History (2)", history_title);

    tab.internal_filters.history_sort = .newest_first;
    const sorted_history_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .history);
    defer std.testing.allocator.free(sorted_history_title);
    try std.testing.expectEqualStrings("Browser History (2, newest first)", sorted_history_title);

    const bookmarks_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .bookmarks);
    defer std.testing.allocator.free(bookmarks_title);
    try std.testing.expectEqualStrings("Browser Bookmarks (2)", bookmarks_title);

    try replaceInternalBrowseFilter(std.testing.allocator, &tab.internal_filters.bookmarks, "two.test");
    const filtered_bookmarks_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .bookmarks);
    defer std.testing.allocator.free(filtered_bookmarks_title);
    try std.testing.expectEqualStrings("Browser Bookmarks (1/2)", filtered_bookmarks_title);

    tab.internal_filters.bookmarks_sort = .alphabetical;
    try replaceInternalBrowseFilter(std.testing.allocator, &tab.internal_filters.bookmarks, "");
    const sorted_bookmarks_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .bookmarks);
    defer std.testing.allocator.free(sorted_bookmarks_title);
    try std.testing.expectEqualStrings("Browser Bookmarks (2, alphabetical)", sorted_bookmarks_title);

    const downloads_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .downloads);
    defer std.testing.allocator.free(downloads_title);
    try std.testing.expectEqualStrings("Browser Downloads (1)", downloads_title);

    try replaceInternalBrowseFilter(std.testing.allocator, &tab.internal_filters.downloads, "failed");
    const filtered_downloads_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .downloads);
    defer std.testing.allocator.free(filtered_downloads_title);
    try std.testing.expectEqualStrings("Browser Downloads (0/1)", filtered_downloads_title);

    tab.internal_filters.downloads_sort = .newest_first;
    try replaceInternalBrowseFilter(std.testing.allocator, &tab.internal_filters.downloads, "");
    const sorted_downloads_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .downloads);
    defer std.testing.allocator.free(sorted_downloads_title);
    try std.testing.expectEqualStrings("Browser Downloads (1, newest first)", sorted_downloads_title);

    const error_title = try makeInternalBrowsePageDisplayTitle(std.testing.allocator, abs_dir, tabs[0..], 0, &downloads, .error_page);
    defer std.testing.allocator.free(error_title);
    try std.testing.expectEqualStrings("Navigation Error", error_title);
}

test "hashInternalBrowsePageState changes after bookmark and download mutations" {
    const rel_dir = ".zig-cache/tmp/internal-page-hash-mutation-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);

    savePersistedBookmarks(std.testing.allocator, abs_dir, &.{"http://one.test/"});

    var session: Session = undefined;
    session.page = null;
    session.navigation = .{ ._proto = undefined };
    const history_one = try std.testing.allocator.create(@import("browser/webapi/navigation/NavigationHistoryEntry.zig"));
    errdefer std.testing.allocator.destroy(history_one);
    history_one.* = .{
        ._id = "hash-history-a",
        ._key = "hash-history-a",
        ._url = "http://one.test/alpha.html",
        ._state = .{ .source = .history, .value = null },
    };
    const history_two = try std.testing.allocator.create(@import("browser/webapi/navigation/NavigationHistoryEntry.zig"));
    errdefer std.testing.allocator.destroy(history_two);
    history_two.* = .{
        ._id = "hash-history-b",
        ._key = "hash-history-b",
        ._url = "http://two.test/zeta.html",
        ._state = .{ .source = .history, .value = null },
    };
    try session.navigation._entries.append(std.testing.allocator, history_one);
    try session.navigation._entries.append(std.testing.allocator, history_two);
    defer {
        session.navigation._entries.deinit(std.testing.allocator);
        std.testing.allocator.destroy(history_one);
        std.testing.allocator.destroy(history_two);
    }
    session.navigation._index = 1;
    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.internal_filters.deinit(std.testing.allocator);
    tab.zoom_percent = 100;
    tab.target_name = &.{};
    tab.popup_source = .none;

    var tab_items = [_]*BrowseTab{&tab};
    var tabs = std.ArrayListUnmanaged(*BrowseTab){
        .items = tab_items[0..],
        .capacity = tab_items.len,
    };
    var closed_tabs = std.ArrayListUnmanaged(ClosedBrowseTab){};
    defer closed_tabs.deinit(std.testing.allocator);
    var active_index: usize = 0;
    const shell: BrowseShell = .{
        .tabs = &tabs,
        .closed_tabs = &closed_tabs,
        .active_tab_index = &active_index,
    };
    var settings = BrowseSettings{};
    defer settings.deinit(std.testing.allocator);

    var downloads = BrowseDownloads{ .allocator = std.testing.allocator };
    defer downloads.deinit(null);
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "file.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/file.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://one.test/file.txt"),
        .detail = try std.testing.allocator.dupe(u8, ""),
        .status = .completed,
    });

    const first_bookmarks_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .bookmarks);
    try std.testing.expect(addPersistedBookmark(std.testing.allocator, abs_dir, "http://two.test/"));
    const second_bookmarks_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .bookmarks);
    try std.testing.expect(first_bookmarks_hash != second_bookmarks_hash);

    const third_bookmarks_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .bookmarks);
    try replaceInternalBrowseFilter(std.testing.allocator, &tab.internal_filters.bookmarks, "two.test");
    const fourth_bookmarks_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .bookmarks);
    try std.testing.expect(third_bookmarks_hash != fourth_bookmarks_hash);

    const fifth_bookmarks_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .bookmarks);
    tab.internal_filters.bookmarks_sort = .alphabetical;
    const sixth_bookmarks_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .bookmarks);
    try std.testing.expect(fifth_bookmarks_hash != sixth_bookmarks_hash);

    const first_downloads_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .downloads);
    try std.testing.expect(downloads.clearInactiveEntries(abs_dir));
    const second_downloads_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .downloads);
    try std.testing.expect(first_downloads_hash != second_downloads_hash);

    const history_first_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .history);
    tab.internal_filters.history_sort = .newest_first;
    const history_second_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .history);
    try std.testing.expect(history_first_hash != history_second_hash);

    const third_downloads_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .downloads);
    tab.internal_filters.downloads_sort = .newest_first;
    const fourth_downloads_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .downloads);
    try std.testing.expect(third_downloads_hash != fourth_downloads_hash);

    const first_error_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .error_page);
    try tab.error_state.replace(std.testing.allocator, .navigation_failed, "http://failed.test/", "http://failed.test/", "CouldntConnect");
    defer tab.error_state.deinit(std.testing.allocator);
    const second_error_hash = hashInternalBrowsePageState(std.testing.allocator, abs_dir, &shell, 0, &settings, &downloads, .error_page);
    try std.testing.expect(first_error_hash != second_error_hash);
}

test "writeInternalErrorPage includes retry home and start actions" {
    var tab: BrowseTab = undefined;
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.error_state.deinit(std.testing.allocator);
    try tab.error_state.replace(std.testing.allocator, .invalid_address, "two words", "two words", "Enter a full URL, for example https://example.com");
    var settings = BrowseSettings{};
    defer settings.deinit(std.testing.allocator);

    var buf = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer buf.deinit();
    try writeInternalErrorPage(&buf.writer, &tab, &settings);
    const html = buf.written();
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://error/retry") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://error/home") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "browser://error/start") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "two words") != null);
}

test "browseTabPersistentUrl prefers retry target for error page" {
    var session: Session = undefined;
    session.page = null;
    var page: Page = undefined;
    page.url = @constCast("browser://error");
    session.page = &page;
    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.error_state.deinit(std.testing.allocator);
    try tab.error_state.replace(std.testing.allocator, .navigation_failed, "http://retry.test/", "http://retry.test/", "CouldntConnect");
    try std.testing.expectEqualStrings("http://retry.test/", browseTabPersistentUrl(&tab));
}

test "captureBrowseTabRuntimeError preserves error state on internal pages" {
    var session: Session = undefined;
    var page: Page = undefined;
    page.url = @constCast("browser://start");
    page._queued_navigation = null;
    page._parse_state = .{ .complete = {} };
    session.page = &page;

    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.error_state.deinit(std.testing.allocator);
    try tab.error_state.replace(std.testing.allocator, .navigation_failed, "http://retry.test/", "http://retry.test/", "CouldntConnect");

    try std.testing.expect(!(try captureBrowseTabRuntimeError(std.testing.allocator, &tab)));
    try std.testing.expect(tab.error_state.hasValue());
}

test "captureBrowseTabRuntimeError clears error state on successful external pages" {
    var session: Session = undefined;
    var page: Page = undefined;
    page.url = @constCast("http://ok.test/");
    page._queued_navigation = null;
    page._parse_state = .{ .complete = {} };
    session.page = &page;

    var tab: BrowseTab = undefined;
    tab.session = &session;
    tab.error_state = .{};
    tab.internal_filters = .{};
    defer tab.error_state.deinit(std.testing.allocator);
    try tab.error_state.replace(std.testing.allocator, .navigation_failed, "http://retry.test/", "http://retry.test/", "CouldntConnect");

    try std.testing.expect(!(try captureBrowseTabRuntimeError(std.testing.allocator, &tab)));
    try std.testing.expect(!tab.error_state.hasValue());
}

test "internalBrowseCommandHostPage maps stateful internal actions" {
    try std.testing.expectEqual(@as(?InternalBrowsePage, .history), internalBrowseCommandHostPage(.history_clear_session));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .history), internalBrowseCommandHostPage(.{ .history_open_new_tab = 0 }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .history), internalBrowseCommandHostPage(.{ .history_sort_set = .newest_first }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .history), internalBrowseCommandHostPage(.{ .history_filter_set = "one" }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .history), internalBrowseCommandHostPage(.history_filter_clear));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .bookmarks), internalBrowseCommandHostPage(.bookmark_add_current));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .bookmarks), internalBrowseCommandHostPage(.{ .bookmark_open_new_tab = 0 }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .bookmarks), internalBrowseCommandHostPage(.{ .bookmark_move_up = 0 }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .bookmarks), internalBrowseCommandHostPage(.{ .bookmark_move_down = 0 }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .bookmarks), internalBrowseCommandHostPage(.{ .bookmark_sort_set = .alphabetical }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .bookmarks), internalBrowseCommandHostPage(.{ .bookmark_filter_set = "one" }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .bookmarks), internalBrowseCommandHostPage(.bookmark_filter_clear));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .downloads), internalBrowseCommandHostPage(.download_clear));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .downloads), internalBrowseCommandHostPage(.{ .download_source_new_tab = 0 }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .downloads), internalBrowseCommandHostPage(.{ .download_retry = 0 }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .downloads), internalBrowseCommandHostPage(.{ .download_sort_set = .newest_first }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .downloads), internalBrowseCommandHostPage(.{ .download_filter_set = "one" }));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .downloads), internalBrowseCommandHostPage(.download_filter_clear));
    try std.testing.expectEqual(@as(?InternalBrowsePage, .settings), internalBrowseCommandHostPage(.settings_set_homepage_to_current));
    try std.testing.expectEqual(@as(?InternalBrowsePage, null), internalBrowseCommandHostPage(.reload));
}

test "internalBrowseCommandUsesBrowseLoopHandler includes indexed closed tab reopen" {
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.tab_new));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.tab_reopen_closed));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .tab_reopen_closed_index = 1 }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .history_open_new_tab = 0 }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .history_sort_set = .newest_first }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .history_filter_set = "one" }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.history_filter_clear));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .bookmark_open_new_tab = 0 }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .bookmark_move_up = 0 }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .bookmark_move_down = 0 }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .bookmark_sort_set = .alphabetical }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .bookmark_filter_set = "one" }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.bookmark_filter_clear));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .download_source_new_tab = 0 }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .download_retry = 0 }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .download_sort_set = .newest_first }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.{ .download_filter_set = "one" }));
    try std.testing.expect(internalBrowseCommandUsesBrowseLoopHandler(.download_filter_clear));
    try std.testing.expect(!internalBrowseCommandUsesBrowseLoopHandler(.download_clear));
}

test "internalBrowseCommandKeepsCurrentPage includes internal open in new tab actions" {
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .history_open_new_tab = 0 }));
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .history_sort_set = .newest_first }));
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .bookmark_open_new_tab = 0 }));
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .bookmark_move_up = 0 }));
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .bookmark_move_down = 0 }));
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .bookmark_sort_set = .alphabetical }));
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .download_source_new_tab = 0 }));
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .download_retry = 0 }));
    try std.testing.expect(internalBrowseCommandKeepsCurrentPage(.{ .download_sort_set = .newest_first }));
    try std.testing.expect(!internalBrowseCommandKeepsCurrentPage(.{ .download_source = 0 }));
}

test "removePersistedBookmarkAtIndex rewrites bookmark file" {
    const rel_dir = ".zig-cache/tmp/internal-bookmark-remove-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);

    var dir = try std.fs.openDirAbsolute(abs_dir, .{});
    defer dir.close();
    dir.writeFile(.{ .sub_path = BROWSE_BOOKMARKS_FILE, .data = 
        \\http://one.test/
        \\http://two.test/
    }) catch |err| switch (err) {
        else => return err,
    };

    try std.testing.expect(removePersistedBookmarkAtIndex(std.testing.allocator, abs_dir, 0));

    var bookmarks = loadPersistedBookmarks(std.testing.allocator, abs_dir);
    defer deinitOwnedStrings(std.testing.allocator, &bookmarks);
    try std.testing.expectEqual(@as(usize, 1), bookmarks.items.len);
    try std.testing.expectEqualStrings("http://two.test/", bookmarks.items[0]);
}

test "movePersistedBookmarkUpAtIndex rewrites bookmark file" {
    const rel_dir = ".zig-cache/tmp/internal-bookmark-move-up-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);

    savePersistedBookmarks(std.testing.allocator, abs_dir, &.{
        "http://one.test/",
        "http://two.test/",
        "http://three.test/",
    });
    try std.testing.expect(movePersistedBookmarkUpAtIndex(std.testing.allocator, abs_dir, 2));

    var bookmarks = loadPersistedBookmarks(std.testing.allocator, abs_dir);
    defer deinitOwnedStrings(std.testing.allocator, &bookmarks);
    try std.testing.expectEqualStrings("http://one.test/", bookmarks.items[0]);
    try std.testing.expectEqualStrings("http://three.test/", bookmarks.items[1]);
    try std.testing.expectEqualStrings("http://two.test/", bookmarks.items[2]);
}

test "movePersistedBookmarkDownAtIndex rewrites bookmark file" {
    const rel_dir = ".zig-cache/tmp/internal-bookmark-move-down-test";
    std.fs.cwd().makePath(rel_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const abs_dir = try std.fs.cwd().realpathAlloc(std.testing.allocator, rel_dir);
    defer std.testing.allocator.free(abs_dir);

    savePersistedBookmarks(std.testing.allocator, abs_dir, &.{
        "http://one.test/",
        "http://two.test/",
        "http://three.test/",
    });
    try std.testing.expect(movePersistedBookmarkDownAtIndex(std.testing.allocator, abs_dir, 0));

    var bookmarks = loadPersistedBookmarks(std.testing.allocator, abs_dir);
    defer deinitOwnedStrings(std.testing.allocator, &bookmarks);
    try std.testing.expectEqualStrings("http://two.test/", bookmarks.items[0]);
    try std.testing.expectEqualStrings("http://one.test/", bookmarks.items[1]);
    try std.testing.expectEqualStrings("http://three.test/", bookmarks.items[2]);
}

test "downloadEntryCanRetry only allows inactive failed and interrupted entries" {
    var downloads = BrowseDownloads{ .allocator = std.testing.allocator };
    defer downloads.deinit(null);
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "failed.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/failed.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://failed.test/"),
        .status = .failed,
    });
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "interrupted.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/interrupted.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://interrupted.test/"),
        .status = .interrupted,
    });
    try downloads.entries.append(std.testing.allocator, .{
        .filename = try std.testing.allocator.dupe(u8, "done.txt"),
        .path = try std.testing.allocator.dupe(u8, "C:/tmp/done.txt"),
        .url = try std.testing.allocator.dupe(u8, "http://done.test/"),
        .status = .completed,
    });

    try std.testing.expect(downloadEntryCanRetry(&downloads, 0));
    try std.testing.expect(downloadEntryCanRetry(&downloads, 1));
    try std.testing.expect(!downloadEntryCanRetry(&downloads, 2));
}

test "buildJsStringLiteral escapes control characters" {
    const literal = try buildJsStringLiteral(std.testing.allocator, "<title>'Browser'\\Settings\n</title>");
    defer std.testing.allocator.free(literal);

    try std.testing.expect(std.mem.startsWith(u8, literal, "'"));
    try std.testing.expect(std.mem.endsWith(u8, literal, "'"));
    try std.testing.expect(std.mem.indexOf(u8, literal, "\\'Browser\\'") != null);
    try std.testing.expect(std.mem.indexOf(u8, literal, "\\\\Settings") != null);
    try std.testing.expect(std.mem.indexOf(u8, literal, "\\n") != null);
}
