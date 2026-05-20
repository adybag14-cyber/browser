// Copyright (C) 2023-2026  Lightpanda (Selecy SAS)
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
const lp = @import("lightpanda");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;

const log = lp.log;
const App = lp.App;
const Config = lp.Config;
const Host = lp.sys.Host;
const SigHandler = @import("Sighandler.zig");
pub const panic = lp.crash_handler.panic;

pub fn main(process: std.process.Init) !void {
    // allocator
    // - in Debug mode we use the General Purpose Allocator to detect memory leaks
    // - in Release mode we use the c allocator
    var gpa_instance: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;
    const gpa = if (builtin.mode == .Debug) gpa_instance.allocator() else std.heap.c_allocator;

    defer if (builtin.mode == .Debug) {
        if (gpa_instance.detectLeaks()) std.posix.exit(1);
    };

    // arena for main-specific allocations
    var main_arena_instance = std.heap.ArenaAllocator.init(gpa);
    const main_arena = main_arena_instance.allocator();
    defer main_arena_instance.deinit();

    run(gpa, main_arena, process.io, process.minimal.args) catch |err| {
        log.fatal(.app, "exit", .{ .err = err });
        std.posix.exit(1);
    };
}

const BrowserModeFallbackInfo = struct {
    reason: []const u8,
    support_expected: bool,
};

fn browserModeFallbackInfo(requested_mode: Config.BrowserMode, runtime_mode: Config.BrowserMode) ?BrowserModeFallbackInfo {
    if (requested_mode != .headed or runtime_mode != .headless) {
        return null;
    }
    if (lp.build_config.target_class == .bare_metal or builtin.os.tag == .windows) {
        return .{
            .reason = "headed mode was requested on a runtime that should support a native headed surface, but startup still resolved to headless; inspect earlier startup diagnostics for the display bring-up failure",
            .support_expected = true,
        };
    }
    return .{
        .reason = "native headed mode is currently available on Windows and bare metal only; continuing with the safe headless runtime",
        .support_expected = false,
    };
}

fn resolvedProfileDirLabel(path: ?[]const u8) []const u8 {
    return path orelse "(unavailable)";
}

fn resolvedOptionalPathLabel(path: ?[]const u8) []const u8 {
    return path orelse "(disabled)";
}

fn browseArtifactStatus(
    path: ?[]const u8,
    requested_mode: Config.BrowserMode,
    runtime_mode: Config.BrowserMode,
    attempted: bool,
    navigation_state_seen: bool,
    is_loading: bool,
) []const u8 {
    if (path == null) {
        return "disabled";
    }
    if (attempted) {
        return "attempted";
    }
    if (requested_mode == .headed and runtime_mode != .headed) {
        return "unavailable_without_native_surface";
    }
    if (!navigation_state_seen) {
        return "pre_navigation";
    }
    return if (is_loading) "waiting_for_load" else "settled_without_export";
}

fn headedRuntimeActive(requested_mode: Config.BrowserMode, runtime_mode: Config.BrowserMode) bool {
    return requested_mode == .headed and runtime_mode == .headed;
}

fn nativeHeadedSurfaceExpected(requested_mode: Config.BrowserMode) bool {
    return requested_mode == .headed and (lp.build_config.target_class == .bare_metal or builtin.os.tag == .windows);
}

fn displayBackendLabel(app: *const App) []const u8 {
    return switch (app.display.backend) {
        .headless => "headless",
        .bare_metal => "bare_metal",
        .headed_windows => "headed_windows",
    };
}

fn commandExitReason(app: *const App) []const u8 {
    if (app.display.userClosed()) {
        return "window_closed";
    }
    if (app.shutdown) {
        return "shutdown_requested";
    }
    return "natural_return";
}

fn browseLifecycleLabel(app: *const App) []const u8 {
    if (!app.display.browse_navigation_state_seen) {
        return "pre_navigation";
    }
    return if (app.display.browse_is_loading) "loading" else "settled";
}

fn httpTimeoutSourceLabel(common: Config.Common, interactive_default: bool) []const u8 {
    if (common.http_timeout != null) {
        return "explicit_override";
    }
    return if (interactive_default) "interactive_default" else "standard_default";
}

const BrowseTargetInfo = struct {
    scheme: []const u8,
    scope: []const u8,
    host: []const u8,
    port: []const u8,
};

fn browseTargetScheme(url: []const u8) []const u8 {
    const scheme_end = std.mem.indexOf(u8, url, "://") orelse return "unknown";
    if (scheme_end == 0) {
        return "unknown";
    }
    return url[0..scheme_end];
}

fn browseTargetAuthority(url: []const u8) ?[]const u8 {
    const scheme_end = std.mem.indexOf(u8, url, "://") orelse return null;
    const authority_start = scheme_end + 3;
    if (authority_start >= url.len) {
        return null;
    }
    const authority_tail = url[authority_start..];
    const authority_end = std.mem.indexOfAny(u8, authority_tail, "/?#") orelse authority_tail.len;
    if (authority_end == 0) {
        return null;
    }
    return authority_tail[0..authority_end];
}

fn browseTargetHostPortAuthority(authority: []const u8) []const u8 {
    const at_index = std.mem.lastIndexOfScalar(u8, authority, '@') orelse return authority;
    if (at_index + 1 >= authority.len) {
        return authority;
    }
    return authority[at_index + 1 ..];
}

fn browseTargetHost(authority: []const u8) []const u8 {
    const host_port_authority = browseTargetHostPortAuthority(authority);
    if (host_port_authority.len == 0) {
        return host_port_authority;
    }
    if (host_port_authority[0] == '[') {
        const closing = std.mem.indexOfScalar(u8, host_port_authority, ']') orelse return host_port_authority;
        return host_port_authority[0 .. closing + 1];
    }
    const port_separator = std.mem.lastIndexOfScalar(u8, host_port_authority, ':') orelse return host_port_authority;
    return host_port_authority[0..port_separator];
}

fn browseTargetPort(authority: []const u8) []const u8 {
    const host_port_authority = browseTargetHostPortAuthority(authority);
    if (host_port_authority.len == 0) {
        return "(none)";
    }
    if (host_port_authority[0] == '[') {
        const closing = std.mem.indexOfScalar(u8, host_port_authority, ']') orelse return "(default)";
        if (closing + 1 >= host_port_authority.len or host_port_authority[closing + 1] != ':') {
            return "(default)";
        }
        const port = host_port_authority[closing + 2 ..];
        return if (port.len == 0) "(default)" else port;
    }
    const port_separator = std.mem.lastIndexOfScalar(u8, host_port_authority, ':') orelse return "(default)";
    const port = host_port_authority[port_separator + 1 ..];
    return if (port.len == 0) "(default)" else port;
}

fn isLoopbackBrowseHost(host: []const u8) bool {
    if (host.len == 0) {
        return false;
    }
    return std.ascii.eqlIgnoreCase(host, "localhost") or
        std.ascii.endsWithIgnoreCase(host, ".localhost") or
        std.mem.eql(u8, host, "127.0.0.1") or
        std.mem.eql(u8, host, "0.0.0.0") or
        std.ascii.eqlIgnoreCase(host, "[::1]") or
        std.ascii.eqlIgnoreCase(host, "[0:0:0:0:0:0:0:1]");
}

fn browseTargetInfo(url: []const u8) BrowseTargetInfo {
    const scheme = browseTargetScheme(url);
    if (std.ascii.eqlIgnoreCase(scheme, "file")) {
        return .{
            .scheme = "file",
            .scope = "file",
            .host = "(none)",
            .port = "(none)",
        };
    }

    const authority = browseTargetAuthority(url) orelse {
        return .{
            .scheme = scheme,
            .scope = "unknown",
            .host = "(none)",
            .port = "(none)",
        };
    };
    const host = browseTargetHost(authority);
    const port = browseTargetPort(authority);
    if (isLoopbackBrowseHost(host)) {
        return .{
            .scheme = scheme,
            .scope = "loopback",
            .host = host,
            .port = port,
        };
    }
    return .{
        .scheme = scheme,
        .scope = "remote",
        .host = if (host.len == 0) "(none)" else host,
        .port = port,
    };
}

test "browse artifact status reports unavailable without native surface" {
    try std.testing.expectEqualStrings(
        "unavailable_without_native_surface",
        browseArtifactStatus("capture.png", .headed, .headless, false, false, true),
    );
}

test "browse artifact status keeps disabled when export path is off" {
    try std.testing.expectEqualStrings(
        "disabled",
        browseArtifactStatus(null, .headed, .headless, false, false, true),
    );
}

test "browse artifact status preserves attempted exports" {
    try std.testing.expectEqualStrings(
        "attempted",
        browseArtifactStatus("capture.png", .headed, .headless, true, false, true),
    );
}

test "browse artifact status still reports settled headed exports" {
    try std.testing.expectEqualStrings(
        "settled_without_export",
        browseArtifactStatus("capture.png", .headed, .headed, false, true, false),
    );
}

test "browse target info strips userinfo before loopback host classification" {
    const info = browseTargetInfo("http://user:pass@localhost:9222/");

    try std.testing.expectEqualStrings("http", info.scheme);
    try std.testing.expectEqualStrings("loopback", info.scope);
    try std.testing.expectEqualStrings("localhost", info.host);
    try std.testing.expectEqualStrings("9222", info.port);
}

test "browse target info strips userinfo before ipv6 loopback classification" {
    const info = browseTargetInfo("http://user:pass@[::1]:8080/");

    try std.testing.expectEqualStrings("http", info.scheme);
    try std.testing.expectEqualStrings("loopback", info.scope);
    try std.testing.expectEqualStrings("[::1]", info.host);
    try std.testing.expectEqualStrings("8080", info.port);
}

test "headed runtime helper stays active only for native headed execution" {
    try std.testing.expect(!headedRuntimeActive(.headless, .headless));
    try std.testing.expect(!headedRuntimeActive(.headed, .headless));
    try std.testing.expect(headedRuntimeActive(.headed, .headed));
}

test "browser mode fallback info only appears for headed-to-headless fallback" {
    try std.testing.expect(browserModeFallbackInfo(.headless, .headless) == null);
    try std.testing.expect(browserModeFallbackInfo(.headed, .headed) == null);

    const info = browserModeFallbackInfo(.headed, .headless) orelse return error.TestUnexpectedResult;
    const support_expected = lp.build_config.target_class == .bare_metal or builtin.os.tag == .windows;
    try std.testing.expectEqual(support_expected, info.support_expected);
    if (support_expected) {
        try std.testing.expectEqualStrings(
            "headed mode was requested on a runtime that should support a native headed surface, but startup still resolved to headless; inspect earlier startup diagnostics for the display bring-up failure",
            info.reason,
        );
    } else {
        try std.testing.expectEqualStrings(
            "native headed mode is currently available on Windows and bare metal only; continuing with the safe headless runtime",
            info.reason,
        );
    }
}

test "resolved startup labels keep explicit values and placeholders" {
    try std.testing.expectEqualStrings("/tmp/profile", resolvedProfileDirLabel("/tmp/profile"));
    try std.testing.expectEqualStrings("(unavailable)", resolvedProfileDirLabel(null));
    try std.testing.expectEqualStrings("/tmp/capture.png", resolvedOptionalPathLabel("/tmp/capture.png"));
    try std.testing.expectEqualStrings("(disabled)", resolvedOptionalPathLabel(null));
}

test "http timeout source label distinguishes overrides from defaults" {
    try std.testing.expectEqualStrings(
        "interactive_default",
        httpTimeoutSourceLabel(.{}, true),
    );
    try std.testing.expectEqualStrings(
        "standard_default",
        httpTimeoutSourceLabel(.{}, false),
    );
    try std.testing.expectEqualStrings(
        "explicit_override",
        httpTimeoutSourceLabel(.{ .http_timeout = 1234 }, true),
    );
}

fn run(allocator: Allocator, main_arena: Allocator, io: std.Io, argv: std.process.Args) !void {
    const args = try Config.parseArgs(main_arena, argv);
    defer args.deinit(main_arena);

    switch (args.mode) {
        .help => {
            args.printUsageAndExit(args.mode.help);
            return std.process.cleanExit();
        },
        .version => {
            std.debug.print("{s}{c}", .{ lp.build_config.git_commit, @as(u8, 10) });
            return std.process.cleanExit();
        },
        else => {},
    }

    if (args.logLevel()) |ll| {
        log.opts.level = ll;
    }
    if (args.logFormat()) |lf| {
        log.opts.format = lf;
    }
    if (args.logFilterScopes()) |lfs| {
        log.opts.filter_scopes = lfs;
    }

    const requested_browser_mode = args.browserMode();
    const native_headed_surface_expected = nativeHeadedSurfaceExpected(requested_browser_mode);

    // _app is global to handle graceful shutdown.
    var host = Host.initForBuildClass(allocator, lp.build_config.target_class == .bare_metal);
    defer host.deinit();

    var app = try App.init(allocator, &args, &host);

    defer app.deinit();
    const browser_mode = app.display.runtime_mode;
    const display_backend = displayBackendLabel(app);
    const fallback_info = browserModeFallbackInfo(requested_browser_mode, browser_mode);
    const headed_runtime_active = headedRuntimeActive(requested_browser_mode, browser_mode);
    if (fallback_info) |info| {
        log.warn(.app, "browser mode fallback", .{
            .requested = @tagName(requested_browser_mode),
            .runtime = @tagName(browser_mode),
            .display_backend = display_backend,
            .status = if (info.support_expected) "unexpected_supported_runtime_fallback" else "experimental_unsupported_platform",
            .support_expected = info.support_expected,
            .native_surface_expected = native_headed_surface_expected,
            .native_surface_active = headed_runtime_active,
            .target_class = @tagName(lp.build_config.target_class),
            .os = @tagName(builtin.os.tag),
            .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
            .window_width = args.windowWidth(),
            .window_height = args.windowHeight(),
            .reason = info.reason,
        });
    }
    app.telemetry.record(.{ .run = {} });

    switch (args.mode) {
        .serve => |opts| {
            const sighandler = try main_arena.create(SigHandler);
            sighandler.* = .{ .arena = main_arena };
            try sighandler.install();
            const effective_http_timeout_ms = args.httpTimeout();
            const http_timeout_source = httpTimeoutSourceLabel(opts.common, opts.common.browser_mode == .headed);

            log.debug(.app, "startup", .{
                .mode = "serve",
                .requested_browser_mode = @tagName(requested_browser_mode),
                .browser_mode = @tagName(browser_mode),
                .display_backend = display_backend,
                .native_surface_expected = native_headed_surface_expected,
                .native_surface_active = headed_runtime_active,
                .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                .window_width = args.windowWidth(),
                .window_height = args.windowHeight(),
                .http_timeout_ms = effective_http_timeout_ms,
                .http_timeout_source = http_timeout_source,
                .snapshot = app.snapshot.fromEmbedded(),
            });
            if (headed_runtime_active) {
                log.info(.app, "serve headed runtime", .{
                    .host = opts.host,
                    .port = opts.port,
                    .requested = @tagName(requested_browser_mode),
                    .runtime = @tagName(browser_mode),
                    .display_backend = display_backend,
                    .native_surface_expected = native_headed_surface_expected,
                    .native_surface_active = headed_runtime_active,
                    .target_class = @tagName(lp.build_config.target_class),
                    .os = @tagName(builtin.os.tag),
                    .window = "enabled",
                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                    .window_width = args.windowWidth(),
                    .window_height = args.windowHeight(),
                    .http_timeout_ms = effective_http_timeout_ms,
                    .http_timeout_source = http_timeout_source,
                    .snapshot = app.snapshot.fromEmbedded(),
                });
            }
            if (fallback_info) |info| {
                log.info(.app, "serve headed fallback", .{
                    .host = opts.host,
                    .port = opts.port,
                    .requested = @tagName(requested_browser_mode),
                    .runtime = @tagName(browser_mode),
                    .display_backend = display_backend,
                    .support_expected = info.support_expected,
                    .native_surface_expected = native_headed_surface_expected,
                    .native_surface_active = headed_runtime_active,
                    .target_class = @tagName(lp.build_config.target_class),
                    .os = @tagName(builtin.os.tag),
                    .window = "disabled",
                    .cdp_browser_runtime = "headless",
                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                    .window_width = args.windowWidth(),
                    .window_height = args.windowHeight(),
                    .http_timeout_ms = effective_http_timeout_ms,
                    .http_timeout_source = http_timeout_source,
                    .reason = info.reason,
                });
            }
            const address = std.net.Address.parseIp(opts.host, opts.port) catch |err| {
                log.fatal(.app, "invalid server address", .{ .err = err, .host = opts.host, .port = opts.port });
                return args.printUsageAndExit(false);
            };

            // _server is global to handle graceful shutdown.
            var server = try lp.Server.init(app, address);
            defer server.deinit();

            try sighandler.on(lp.Server.stop, .{&server});

            // max timeout of 1 week.
            const timeout = if (opts.timeout > 604_800) 604_800_000 else @as(u32, opts.timeout) * 1000;
            server.run(address, timeout) catch |err| {
                log.fatal(.app, "server run error", .{
                    .err = err,
                    .host = opts.host,
                    .port = opts.port,
                    .requested = @tagName(requested_browser_mode),
                    .runtime = @tagName(browser_mode),
                    .display_backend = display_backend,
                    .native_surface_expected = native_headed_surface_expected,
                    .native_surface_active = headed_runtime_active,
                    .target_class = @tagName(lp.build_config.target_class),
                    .os = @tagName(builtin.os.tag),
                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                    .window_width = args.windowWidth(),
                    .window_height = args.windowHeight(),
                    .http_timeout_ms = effective_http_timeout_ms,
                    .http_timeout_source = http_timeout_source,
                    .snapshot = app.snapshot.fromEmbedded(),
                });
                return err;
            };
            log.info(.app, "serve finished", .{
                .host = opts.host,
                .port = opts.port,
                .requested = @tagName(requested_browser_mode),
                .runtime = @tagName(browser_mode),
                .display_backend = display_backend,
                .native_surface_expected = native_headed_surface_expected,
                .native_surface_active = headed_runtime_active,
                .target_class = @tagName(lp.build_config.target_class),
                .os = @tagName(builtin.os.tag),
                .window_closed = app.display.userClosed(),
                .shutdown_requested = app.shutdown,
                .exit_reason = commandExitReason(&app),
                .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                .window_width = args.windowWidth(),
                .window_height = args.windowHeight(),
                .http_timeout_ms = effective_http_timeout_ms,
                .http_timeout_source = http_timeout_source,
                .snapshot = app.snapshot.fromEmbedded(),
            });
        },
        .browse => |opts| {
            const url = opts.url;
            const browse_target = browseTargetInfo(url);
            const effective_http_timeout_ms = args.httpTimeout();
            const http_timeout_source = httpTimeoutSourceLabel(opts.common, true);
            log.debug(.app, "startup", .{
                .mode = "browse",
                .requested_browser_mode = @tagName(requested_browser_mode),
                .browser_mode = @tagName(browser_mode),
                .display_backend = display_backend,
                .native_surface_expected = native_headed_surface_expected,
                .native_surface_active = headed_runtime_active,
                .url = url,
                .target_scheme = browse_target.scheme,
                .target_scope = browse_target.scope,
                .target_host = browse_target.host,
                .target_port = browse_target.port,
                .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                .window_width = args.windowWidth(),
                .window_height = args.windowHeight(),
                .http_timeout_ms = effective_http_timeout_ms,
                .http_timeout_source = http_timeout_source,
                .screenshot_bmp_path = resolvedOptionalPathLabel(opts.screenshot_bmp_path),
                .screenshot_bmp_status = browseArtifactStatus(opts.screenshot_bmp_path, requested_browser_mode, browser_mode, false, false, true),
                .screenshot_png_path = resolvedOptionalPathLabel(opts.screenshot_png_path),
                .screenshot_png_status = browseArtifactStatus(opts.screenshot_png_path, requested_browser_mode, browser_mode, false, false, true),
                .snapshot = app.snapshot.fromEmbedded(),
            });
            if (headed_runtime_active) {
                log.info(.app, "browse headed runtime", .{
                    .url = url,
                    .requested = @tagName(requested_browser_mode),
                    .runtime = @tagName(browser_mode),
                    .display_backend = display_backend,
                    .native_surface_expected = native_headed_surface_expected,
                    .native_surface_active = headed_runtime_active,
                    .target_class = @tagName(lp.build_config.target_class),
                    .os = @tagName(builtin.os.tag),
                    .target_scheme = browse_target.scheme,
                    .target_scope = browse_target.scope,
                    .target_host = browse_target.host,
                    .target_port = browse_target.port,
                    .window = "enabled",
                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                    .window_width = args.windowWidth(),
                    .window_height = args.windowHeight(),
                    .http_timeout_ms = effective_http_timeout_ms,
                    .http_timeout_source = http_timeout_source,
                    .screenshot_bmp_path = resolvedOptionalPathLabel(opts.screenshot_bmp_path),
                    .screenshot_bmp_status = browseArtifactStatus(opts.screenshot_bmp_path, requested_browser_mode, browser_mode, false, false, true),
                    .screenshot_png_path = resolvedOptionalPathLabel(opts.screenshot_png_path),
                    .screenshot_png_status = browseArtifactStatus(opts.screenshot_png_path, requested_browser_mode, browser_mode, false, false, true),
                    .snapshot = app.snapshot.fromEmbedded(),
                });
            }
            if (fallback_info) |info| {
                log.info(.app, "browse headed fallback", .{
                    .url = url,
                    .requested = @tagName(requested_browser_mode),
                    .runtime = @tagName(browser_mode),
                    .display_backend = display_backend,
                    .support_expected = info.support_expected,
                    .native_surface_expected = native_headed_surface_expected,
                    .native_surface_active = headed_runtime_active,
                    .target_class = @tagName(lp.build_config.target_class),
                    .os = @tagName(builtin.os.tag),
                    .target_scheme = browse_target.scheme,
                    .target_scope = browse_target.scope,
                    .target_host = browse_target.host,
                    .target_port = browse_target.port,
                    .window = "disabled",
                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                    .window_width = args.windowWidth(),
                    .window_height = args.windowHeight(),
                    .http_timeout_ms = effective_http_timeout_ms,
                    .http_timeout_source = http_timeout_source,
                    .screenshot_bmp_path = resolvedOptionalPathLabel(opts.screenshot_bmp_path),
                    .screenshot_bmp_status = browseArtifactStatus(opts.screenshot_bmp_path, requested_browser_mode, browser_mode, false, false, true),
                    .screenshot_png_path = resolvedOptionalPathLabel(opts.screenshot_png_path),
                    .screenshot_png_status = browseArtifactStatus(opts.screenshot_png_path, requested_browser_mode, browser_mode, false, false, true),
                    .reason = info.reason,
                });
            }

            lp.browse(app, url, .{}) catch |err| {
                log.fatal(.app, "browse error", .{
                    .err = err,
                    .url = url,
                    .requested = @tagName(requested_browser_mode),
                    .runtime = @tagName(browser_mode),
                    .display_backend = display_backend,
                    .native_surface_expected = native_headed_surface_expected,
                    .native_surface_active = headed_runtime_active,
                    .target_class = @tagName(lp.build_config.target_class),
                    .os = @tagName(builtin.os.tag),
                    .target_scheme = browse_target.scheme,
                    .target_scope = browse_target.scope,
                    .target_host = browse_target.host,
                    .target_port = browse_target.port,
                    .window_closed = app.display.userClosed(),
                    .shutdown_requested = app.shutdown,
                    .exit_reason = commandExitReason(&app),
                    .navigation_state = browseLifecycleLabel(&app),
                    .navigation_state_seen = app.display.browse_navigation_state_seen,
                    .is_loading = app.display.browse_is_loading,
                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                    .window_width = args.windowWidth(),
                    .window_height = args.windowHeight(),
                    .http_timeout_ms = effective_http_timeout_ms,
                    .http_timeout_source = http_timeout_source,
                    .screenshot_bmp_path = resolvedOptionalPathLabel(opts.screenshot_bmp_path),
                    .screenshot_bmp_status = browseArtifactStatus(
                        opts.screenshot_bmp_path,
                        requested_browser_mode,
                        browser_mode,
                        app.display.browse_screenshot_bmp_attempted,
                        app.display.browse_navigation_state_seen,
                        app.display.browse_is_loading,
                    ),
                    .screenshot_png_path = resolvedOptionalPathLabel(opts.screenshot_png_path),
                    .screenshot_png_status = browseArtifactStatus(
                        opts.screenshot_png_path,
                        requested_browser_mode,
                        browser_mode,
                        app.display.browse_screenshot_png_attempted,
                        app.display.browse_navigation_state_seen,
                        app.display.browse_is_loading,
                    ),
                    .snapshot = app.snapshot.fromEmbedded(),
                });
                return err;
            };
            log.info(.app, "browse finished", .{
                .url = url,
                .requested = @tagName(requested_browser_mode),
                .runtime = @tagName(browser_mode),
                .display_backend = display_backend,
                .native_surface_expected = native_headed_surface_expected,
                .native_surface_active = headed_runtime_active,
                .target_class = @tagName(lp.build_config.target_class),
                .os = @tagName(builtin.os.tag),
                .target_scheme = browse_target.scheme,
                .target_scope = browse_target.scope,
                .target_host = browse_target.host,
                .target_port = browse_target.port,
                .window_closed = app.display.userClosed(),
                .shutdown_requested = app.shutdown,
                .exit_reason = commandExitReason(&app),
                .navigation_state = browseLifecycleLabel(&app),
                .navigation_state_seen = app.display.browse_navigation_state_seen,
                .is_loading = app.display.browse_is_loading,
                .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                .window_width = args.windowWidth(),
                .window_height = args.windowHeight(),
                .http_timeout_ms = effective_http_timeout_ms,
                .http_timeout_source = http_timeout_source,
                .screenshot_bmp_path = resolvedOptionalPathLabel(opts.screenshot_bmp_path),
                .screenshot_bmp_status = browseArtifactStatus(
                    opts.screenshot_bmp_path,
                    requested_browser_mode,
                    browser_mode,
                    app.display.browse_screenshot_bmp_attempted,
                    app.display.browse_navigation_state_seen,
                    app.display.browse_is_loading,
                ),
                .screenshot_png_path = resolvedOptionalPathLabel(opts.screenshot_png_path),
                .screenshot_png_status = browseArtifactStatus(
                    opts.screenshot_png_path,
                    requested_browser_mode,
                    browser_mode,
                    app.display.browse_screenshot_png_attempted,
                    app.display.browse_navigation_state_seen,
                    app.display.browse_is_loading,
                ),
                .snapshot = app.snapshot.fromEmbedded(),
            });
        },
        .fetch => |opts| {
            const url = opts.url;
            log.debug(.app, "startup", .{
                .mode = "fetch",
                .requested_browser_mode = @tagName(requested_browser_mode),
                .browser_mode = @tagName(browser_mode),
                .display_backend = display_backend,
                .native_surface_expected = native_headed_surface_expected,
                .native_surface_active = headed_runtime_active,
                .dump_mode = opts.dump_mode,
                .url = url,
                .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                .snapshot = app.snapshot.fromEmbedded(),
            });

            var fetch_opts = lp.FetchOpts{
                .wait_ms = 5000,
                .dump_mode = opts.dump_mode,
                .dump = .{
                    .strip = opts.strip,
                    .with_base = opts.with_base,
                    .with_frames = opts.with_frames,
                },
            };

            var stdout = std.Io.File.stdout();
            var writer = stdout.writer(io, &.{});
            if (opts.dump_mode != null) {
                fetch_opts.writer = &writer.interface;
            }

            lp.fetch(app, url, fetch_opts) catch |err| {
                log.fatal(.app, "fetch error", .{ .err = err, .url = url });
                return err;
            };
        },
        .mcp => {
            log.info(.mcp, "starting server", .{});

            log.opts.format = .logfmt;

            var stdout = std.Io.File.stdout().writer(io, &.{});

            var mcp_server: *lp.mcp.Server = try .init(allocator, app, &stdout.interface);
            defer mcp_server.deinit();

            var stdin_buf: [64 * 1024]u8 = undefined;
            var stdin = std.Io.File.stdin().reader(io, &stdin_buf);

            try lp.mcp.router.processRequests(mcp_server, &stdin.interface);
        },
        else => unreachable,
    }
}
