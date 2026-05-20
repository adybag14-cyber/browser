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

fn headedRuntimeActive(requested_mode: Config.BrowserMode, runtime_mode: Config.BrowserMode) bool {
    return requested_mode == .headed and runtime_mode == .headed;
}

fn nativeHeadedSurfaceExpected(requested_mode: Config.BrowserMode) bool {
    return requested_mode == .headed and (lp.build_config.target_class == .bare_metal or builtin.os.tag == .windows);
}

fn displayBackendLabel(app: *const App) []const u8 {
    return switch (app.display.backend) {
        .headless => "headless",
        .headed_stub => "headed_stub",
        .bare_metal => "bare_metal",
        .headed_windows => "headed_windows",
    };
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
            std.debug.print("{s}\n", .{lp.build_config.git_commit});
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
                log.fatal(.app, "server run error", .{ .err = err });
                return err;
            };
        },
        .browse => |opts| {
            const url = opts.url;
            log.debug(.app, "startup", .{
                .mode = "browse",
                .requested_browser_mode = @tagName(requested_browser_mode),
                .browser_mode = @tagName(browser_mode),
                .display_backend = display_backend,
                .native_surface_expected = native_headed_surface_expected,
                .native_surface_active = headed_runtime_active,
                .url = url,
                .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                .window_width = args.windowWidth(),
                .window_height = args.windowHeight(),
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
                    .window = "enabled",
                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                    .window_width = args.windowWidth(),
                    .window_height = args.windowHeight(),
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
                    .window = "disabled",
                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
                    .window_width = args.windowWidth(),
                    .window_height = args.windowHeight(),
                    .reason = info.reason,
                });
            }

            lp.browse(app, url, .{}) catch |err| {
                log.fatal(.app, "browse error", .{ .err = err, .url = url });
                return err;
            };
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