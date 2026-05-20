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
const builtin = @import("builtin");
const build_config = @import("build_config");

const Allocator = std.mem.Allocator;

const Config = @import("Config.zig");
const HostPaths = @import("HostPaths.zig");
const Host = @import("sys/host.zig").Host;
const Snapshot = @import("browser/js/Snapshot.zig");
const Platform = @import("browser/js/Platform.zig");
const Display = @import("display/Display.zig");
const log = @import("log.zig");
const Telemetry = @import("telemetry/telemetry.zig").Telemetry;
const RobotStore = @import("browser/Robots.zig").RobotStore;

pub const Http = @import("http/Http.zig");
pub const ArenaPool = @import("ArenaPool.zig");

const App = @This();

http: Http,
config: *const Config,
platform: Platform,
display: Display,
snapshot: Snapshot,
telemetry: Telemetry,
allocator: Allocator,
arena_pool: ArenaPool,
robots: RobotStore,
app_dir_path: ?[]const u8,
host: ?*Host = null,
shutdown: bool = false,

fn requestedProfileDirLabel(config: *const Config) []const u8 {
    return config.profileDir() orelse "(platform default)";
}

fn resolvedProfileDirLabel(path: ?[]const u8) []const u8 {
    return path orelse "(unavailable)";
}

fn resolvedProfileDirSourceLabel(config: *const Config, path: ?[]const u8) []const u8 {
    if (config.profileDir() != null) {
        return if (path != null) "explicit_override" else "explicit_override_unavailable";
    }
    return if (path != null) "platform_default" else "unavailable";
}

fn displayBackendLabel(display: *const Display) []const u8 {
    return @tagName(std.meta.activeTag(display.backend));
}

fn logDisplayRuntimeSelection(app: *const App) void {
    if (app.display.requested_mode != .headed) {
        return;
    }

    const runtime_active = app.display.runtime_mode == .headed;
    const payload = .{
        .requested = @tagName(app.display.requested_mode),
        .runtime = @tagName(app.display.runtime_mode),
        .display_backend = displayBackendLabel(&app.display),
        .native_surface_active = runtime_active,
        .target_class = @tagName(build_config.target_class),
        .os = @tagName(builtin.os.tag),
        .requested_profile_dir = requestedProfileDirLabel(app.config),
        .profile_dir = resolvedProfileDirLabel(app.app_dir_path),
        .resolved_profile_dir_source = resolvedProfileDirSourceLabel(app.config, app.app_dir_path),
        .window_width = app.display.default_viewport.width,
        .window_height = app.display.default_viewport.height,
        .snapshot = app.snapshot.fromEmbedded(),
    };

    if (runtime_active) {
        log.info(.app, "display runtime selected", payload);
        return;
    }

    log.warn(.app, "display runtime fallback", payload);
}

pub fn init(allocator: Allocator, config: *const Config, host: ?*Host) !*App {
    const app = try allocator.create(App);
    errdefer allocator.destroy(app);

    app.* = .{
        .config = config,
        .allocator = allocator,
        .display = Display.init(allocator, config, host),
        .robots = RobotStore.init(allocator),
        .http = undefined,
        .platform = undefined,
        .snapshot = undefined,
        .app_dir_path = undefined,
        .telemetry = undefined,
        .arena_pool = undefined,
        .host = host,
    };

    app.http = try Http.init(allocator, &app.robots, config);
    errdefer app.http.deinit();
    app.display.setHttpRuntime(&app.http);

    app.platform = try Platform.init();
    errdefer app.platform.deinit();

    app.snapshot = try Snapshot.load();
    errdefer app.snapshot.deinit();

    app.app_dir_path = if (host) |host_ref|
        host_ref.resolveProfileDir(config.profileDir())
    else
        HostPaths.resolveProfileDir(allocator, config.profileDir());
    app.display.setAppDataPath(app.app_dir_path);
    logDisplayRuntimeSelection(app);

    app.telemetry = try Telemetry.init(app, config.mode);
    errdefer app.telemetry.deinit();

    app.arena_pool = ArenaPool.init(allocator, 512, 1024 * 16);
    errdefer app.arena_pool.deinit();

    return app;
}

pub fn deinit(self: *App) void {
    if (@atomicRmw(bool, &self.shutdown, .Xchg, true, .monotonic)) {
        return;
    }

    const allocator = self.allocator;
    if (self.app_dir_path) |app_dir_path| {
        allocator.free(app_dir_path);
        self.app_dir_path = null;
    }
    self.telemetry.deinit();
    self.robots.deinit();
    self.http.deinit();
    self.snapshot.deinit();
    self.display.deinit();
    self.platform.deinit();
    self.arena_pool.deinit();

    allocator.destroy(self);
}