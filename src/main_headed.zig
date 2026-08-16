// Native headed Lightpanda entry point for Windows validation/distribution.
const std = @import("std");
const lp = @import("lightpanda");

pub const panic = lp.crash_handler.panic;

pub fn main(init: std.process.Init) !void {
    var gpa_instance: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;
    const allocator = if (lp.IS_DEBUG) gpa_instance.allocator() else std.heap.c_allocator;
    defer if (lp.IS_DEBUG) {
        if (gpa_instance.detectLeaks() != 0) std.process.exit(1);
    };

    var arena_instance = std.heap.ArenaAllocator.init(allocator);
    const arena = arena_instance.allocator();
    defer arena_instance.deinit();

    const config = try lp.Config.parseArgs(arena, init.minimal.args);
    defer config.deinit(arena);

    const opts = switch (config.mode) {
        .browse => |opts| opts,
        .help => |tag| {
            try config.printUsageAndExit(arena, tag, true);
            return;
        },
        .version => {
            var stdout = std.Io.File.stdout().writerStreaming(lp.io, &.{});
            try stdout.interface.print("{s}\n", .{lp.build_config.version});
            return;
        },
        else => {
            lp.log.err(.app, "headed executable supports browse mode", .{ .hint = "use: lightpanda-headed browse [URL]" });
            return error.UnsupportedMode;
        },
    };

    var app = try lp.App.init(allocator, &config);
    defer app.deinit();
    app.telemetry.record(.{ .run = {} });
    try lp.headed.browse(app, opts);
}
