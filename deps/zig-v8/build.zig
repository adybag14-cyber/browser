const std = @import("std");

const V8_VERSION: []const u8 = "14.0.365.4";

const LazyPath = std.Build.LazyPath;

fn getDepotToolExePath(b: *std.Build, depot_tools_dir: []const u8, executable: []const u8) []const u8 {
    return b.fmt("{s}/{s}", .{ depot_tools_dir, executable });
}

fn addDepotToolsToPath(step: *std.Build.Step.Run, depot_tools_dir: []const u8) void {
    step.addPathDir(depot_tools_dir);
}

const GnArgs = struct {
    is_asan: bool,
    is_tsan: bool,
    is_debug: bool,
    symbol_level: u8,
    v8_enable_sandbox: bool,

    fn asString(self: GnArgs, b: *std.Build, target: std.Build.ResolvedTarget) ![]const u8 {
        const tag = target.result.os.tag;
        const arch = target.result.cpu.arch;

        var args: std.ArrayList(u8) = .empty;
        const gpa = b.allocator;

        // Use modern siso instead of outdated ninja to speed up the build.
        try args.appendSlice(gpa, "use_siso=true\n");

        // official builds depend on pgo
        try args.appendSlice(gpa, "is_official_build=false\n");
        try args.appendSlice(gpa, b.fmt("is_debug={}\n", .{self.is_debug}));
        try args.appendSlice(gpa, b.fmt("symbol_level={d}\n", .{self.symbol_level}));
        try args.appendSlice(gpa, b.fmt("is_asan={}\n", .{self.is_asan}));
        try args.appendSlice(gpa, b.fmt("is_tsan={}\n", .{self.is_tsan}));
        try args.appendSlice(gpa, b.fmt("v8_enable_sandbox={}\n", .{self.v8_enable_sandbox}));

        switch (tag) {
            .ios => {
                try args.appendSlice(gpa, "v8_enable_pointer_compression=false\n");
                try args.appendSlice(gpa, "v8_enable_webassembly=false\n");
            },
            .linux => {
                if (arch == .aarch64) {
                    try args.appendSlice(gpa, "clang_base_path=\"/usr/lib/llvm-21\"\n");
                    try args.appendSlice(gpa, "clang_use_chrome_plugins=false\n");
                    try args.appendSlice(gpa, "treat_warnings_as_errors=false\n");
                }
            },
            else => {},
        }

        return gpa.dupe(u8, args.items);
    }
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const gn_args = GnArgs{
        .is_debug = optimize == .Debug,
        .symbol_level = b.option(u8, "symbol_level", "Symbol level") orelse if (optimize == .Debug) 1 else 0,
        .is_asan = b.option(bool, "is_asan", "Address sanitizer") orelse false,
        .is_tsan = b.option(bool, "is_tsan", "Thread sanitizer") orelse false,
        .v8_enable_sandbox = b.option(bool, "v8_enable_sandbox", "V8 lightable sandbox") orelse false,
    };

    var build_opts = b.addOptions();
    build_opts.addOption(
        bool,
        "inspector_subtype",
        b.option(bool, "inspector_subtype", "Export default valueSubtype and descriptionForValueSubtype") orelse true,
    );

    const cache_root = b.option([]const u8, "cache_root", "Root directory for the V8 and depot_tools cache") orelse b.pathFromRoot(".lp-cache");
    std.fs.cwd().access(cache_root, .{}) catch {
        try std.fs.cwd().makeDir(cache_root);
    };

    const prebuilt_v8_path = b.option([]const u8, "prebuilt_v8_path", "Path to prebuilt libc_v8.a");

    const v8_dir = b.fmt("{s}/v8-{s}", .{ cache_root, V8_VERSION });
    const depot_tools_dir = b.fmt("{s}/depot_tools-{s}", .{ cache_root, V8_VERSION });

    const built_v8 = if (prebuilt_v8_path) |path| blk: {
        // Use prebuilt_v8 if available.
        const wf = b.addWriteFiles();
        _ = wf.addCopyFile(.{ .cwd_relative = path }, "libc_v8.a");
        break :blk wf;
    } else blk: {
        const bootstrapped_depot_tools = try bootstrapDepotTools(b, depot_tools_dir);
        const bootstrapped_v8 = try bootstrapV8(b, bootstrapped_depot_tools, v8_dir, depot_tools_dir);

        const prepare_step = b.step("prepare-v8", "Prepare V8 source code");
        prepare_step.dependOn(&bootstrapped_v8.step);

        // Otherwise, go through build process.
        break :blk try buildV8(b, v8_dir, depot_tools_dir, bootstrapped_v8, target, gn_args);
    };

    const build_step = b.step("build-v8", "Build v8");
    build_step.dependOn(&built_v8.step);

    b.getInstallStep().dependOn(build_step);

    // the module we export as a library
    const v8_module = b.addModule("v8", .{
        .root_source_file = b.path("src/v8.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    v8_module.addIncludePath(b.path("src"));
    v8_module.addImport("default_exports", build_opts.createModule());
    v8_module.addObjectFile(built_v8.getDirectory().path(b, "libc_v8.a"));

    switch (target.result.os.tag) {
        .macos => {
            v8_module.addSystemFrameworkPath(.{ .cwd_relative = "/System/Library/Frameworks" });
            v8_module.linkFramework("CoreFoundation", .{});
        },
        else => {},
    }

    {
        const test_module = b.createModule(.{
            .root_source_file = b.path("src/v8.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        });

        // test
        const tests = b.addTest(.{
            .root_module = test_module,
        });
        tests.root_module.addImport("default_exports", build_opts.createModule());

        const release_dir = if (optimize == .Debug) "debug" else "release";
        const os = switch (target.result.os.tag) {
            .linux => "linux",
            .macos => "macos",
            .ios => "ios",
            else => return error.UnsupportedPlatform,
        };

        tests.addObjectFile(b.path(b.fmt("v8/out/{s}/{s}/obj/zig/libc_v8.a", .{ os, release_dir })));
        tests.addIncludePath(b.path("src"));

        switch (target.result.os.tag) {
            .macos => {
                // v8 has a dependency, abseil-cpp, which, on Mac, uses CoreFoundation
                tests.addSystemFrameworkPath(.{ .cwd_relative = "/System/Library/Frameworks" });
                tests.linkFramework("CoreFoundation");
            },
            else => {},
        }

        const run_tests = b.addRunArtifact(tests);
        const tests_step = b.step("test", "Run unit tests");
        tests_step.dependOn(&run_tests.step);
    }
}

fn bootstrapDepotTools(b: *std.Build, depot_tools_dir: []const u8) !*std.Build.Step.Run {
    const depot_tools = b.dependency("depot_tools", .{});
    const marker_file = b.fmt("{s}/.bootstrap-complete", .{depot_tools_dir});

    const needs_full_bootstrap = blk: {
        std.fs.cwd().access(marker_file, .{}) catch break :blk true;
        break :blk false;
    };

    if (!needs_full_bootstrap) {
        std.debug.print("Using cached depot_tools bootstrap from {s}\n", .{depot_tools_dir});
        const noop = b.addSystemCommand(&.{"true"});
        return noop;
    }

    std.debug.print("Bootstrapping depot_tools {s} in {s} (this will take a while)...\n", .{ V8_VERSION, depot_tools_dir });

    const copy_depot_tools = b.addSystemCommand(&.{ "cp", "-r" });
    copy_depot_tools.addDirectoryArg(depot_tools.path(""));
    copy_depot_tools.addArg(depot_tools_dir);

    const build_telemetry_config_content =
        \\ {
        \\   "user": "lightpanda",
        \\   "status": "opt-out",
        \\   "countdown": 20,
        \\   "version": 1
        \\ }
    ;

    const write_telemetry_config = b.addSystemCommand(&.{ "sh", "-c" });
    write_telemetry_config.addArg(b.fmt("echo '{s}' > {s}/build_telemetry.cfg", .{
        build_telemetry_config_content,
        depot_tools_dir,
    }));
    write_telemetry_config.step.dependOn(&copy_depot_tools.step);

    const ensure_bootstrap = b.addSystemCommand(&.{
        getDepotToolExePath(b, depot_tools_dir, "ensure_bootstrap"),
    });
    ensure_bootstrap.setCwd(.{ .cwd_relative = depot_tools_dir });
    addDepotToolsToPath(ensure_bootstrap, depot_tools_dir);
    ensure_bootstrap.step.dependOn(&write_telemetry_config.step);

    const create_marker = b.addSystemCommand(&.{ "touch", marker_file });
    create_marker.step.dependOn(&ensure_bootstrap.step);

    return create_marker;
}

fn bootstrapV8(
    b: *std.Build,
    bootstrapped_depot_tools: *std.Build.Step.Run,
    v8_dir: []const u8,
    depot_tools_dir: []const u8,
) !*std.Build.Step.Run {
    const marker_file = b.fmt("{s}/.bootstrap-complete", .{v8_dir});

    // Check if already bootstrapped
    const needs_full_bootstrap = blk: {
        std.fs.cwd().access(marker_file, .{}) catch break :blk true;
        break :blk false;
    };

    if (!needs_full_bootstrap) {
        const needs_source_update = blk: {
            if (needs_full_bootstrap) break :blk false;

            // Check if marker exists
            const marker_stat = std.fs.cwd().statFile(marker_file) catch break :blk true;
            const marker_mtime = marker_stat.mtime;

            const source_dirs = [_][]const u8{
                b.pathFromRoot("src"),
                b.pathFromRoot("build-tools"),
            };

            for (source_dirs) |dir_path| {
                var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
                defer dir.close();

                var walker = try dir.walk(b.allocator);
                while (try walker.next()) |entry| {
                    switch (entry.kind) {
                        .file => {
                            const file = try entry.dir.openFile(entry.path, .{});
                            defer file.close();
                            const stat = try file.stat();
                            const mtime = stat.mtime;

                            if (mtime > marker_mtime) {
                                std.debug.print("Source file {s} changed, updating bootstrap\n", .{entry.path});
                                break :blk true;
                            }
                        },
                        // Doesn't currently search into subfolders.
                        else => {},
                    }
                }
            }

            break :blk false;
        };

        if (needs_source_update) {
            // Just needs the bindings to be updated, will reuse cached dir.
            std.debug.print("Updating source files in V8 bootstrap\n", .{});

            // Just copy the updated files
            const copy_binding = b.addSystemCommand(&.{"cp"});
            copy_binding.addFileArg(b.path("src/binding.cpp"));
            copy_binding.addArg(b.fmt("{s}/binding.cpp", .{v8_dir}));

            const copy_inspector = b.addSystemCommand(&.{"cp"});
            copy_inspector.addFileArg(b.path("src/inspector.h"));
            copy_inspector.addArg(b.fmt("{s}/inspector.h", .{v8_dir}));
            copy_inspector.step.dependOn(&copy_binding.step);

            const copy_build_gn = b.addSystemCommand(&.{"cp"});
            copy_build_gn.addFileArg(b.path("build-tools/BUILD.gn"));
            copy_build_gn.addArg(b.fmt("{s}/zig/BUILD.gn", .{v8_dir}));
            copy_build_gn.step.dependOn(&copy_inspector.step);

            const copy_gn = b.addSystemCommand(&.{"cp"});
            copy_gn.addFileArg(b.path("build-tools/.gn"));
            copy_gn.addArg(b.fmt("{s}/zig/.gn", .{v8_dir}));
            copy_gn.step.dependOn(&copy_build_gn.step);

            // Touch marker to update timestamp
            const update_marker = b.addSystemCommand(&.{ "touch", marker_file });
            update_marker.step.dependOn(&copy_gn.step);

            return update_marker;
        } else {
            // Cached V8 is still valid.
            std.debug.print("Using cached V8 bootstrap from {s}\n", .{v8_dir});
            const noop = b.addSystemCommand(&.{"true"});
            return noop;
        }
    }

    std.debug.print("Bootstrapping V8 {s} in {s} (this will take a while)...\n", .{ V8_VERSION, v8_dir });

    // Create cache directory
    const mkdir = b.addSystemCommand(&.{ "mkdir", "-p", v8_dir });
    mkdir.step.dependOn(&bootstrapped_depot_tools.step);

    // Write .gclient file
    const gclient_content = b.fmt(
        \\solutions = [
        \\  {{
        \\    "name": ".",
        \\    "url": "https://chromium.googlesource.com/v8/v8.git@{s}",
        \\    "deps_file": "DEPS",
        \\    "managed": False,
        \\    "custom_deps": {{}},
        \\  }},
        \\]
        \\
    , .{V8_VERSION});

    const write_gclient = b.addSystemCommand(&.{ "sh", "-c" });
    write_gclient.addArg(b.fmt("echo '{s}' > {s}/.gclient", .{ gclient_content, v8_dir }));
    write_gclient.step.dependOn(&mkdir.step);

    // Copy binding files
    const copy_binding = b.addSystemCommand(&.{"cp"});
    copy_binding.addFileArg(b.path("src/binding.cpp"));
    copy_binding.addArg(b.fmt("{s}/binding.cpp", .{v8_dir}));
    copy_binding.step.dependOn(&write_gclient.step);

    const copy_inspector = b.addSystemCommand(&.{"cp"});
    copy_inspector.addFileArg(b.path("src/inspector.h"));
    copy_inspector.addArg(b.fmt("{s}/inspector.h", .{v8_dir}));
    copy_inspector.step.dependOn(&copy_binding.step);

    // Create zig directory and copy build files
    const mkdir_zig = b.addSystemCommand(&.{ "mkdir", "-p", b.fmt("{s}/zig", .{v8_dir}) });
    mkdir_zig.step.dependOn(&copy_inspector.step);

    const copy_build_gn = b.addSystemCommand(&.{"cp"});
    copy_build_gn.addFileArg(b.path("build-tools/BUILD.gn"));
    copy_build_gn.addArg(b.fmt("{s}/zig/BUILD.gn", .{v8_dir}));
    copy_build_gn.step.dependOn(&mkdir_zig.step);

    const copy_gn = b.addSystemCommand(&.{"cp"});
    copy_gn.addFileArg(b.path("build-tools/.gn"));
    copy_gn.addArg(b.fmt("{s}/zig/.gn", .{v8_dir}));
    copy_gn.step.dependOn(&copy_build_gn.step);

    // Create gclient_args.gni
    const mkdir_build_config = b.addSystemCommand(&.{ "mkdir", "-p", b.fmt("{s}/build/config", .{v8_dir}) });
    mkdir_build_config.step.dependOn(&copy_gn.step);

    const write_gclient_args = b.addSystemCommand(&.{ "sh", "-c" });
    write_gclient_args.addArg(b.fmt("echo '# Generated by Zig build system' > {s}/build/config/gclient_args.gni", .{v8_dir}));
    write_gclient_args.step.dependOn(&mkdir_build_config.step);

    // Run gclient sync
    const gclient_sync = b.addSystemCommand(&.{
        getDepotToolExePath(b, depot_tools_dir, "gclient"),
        "sync",
    });
    gclient_sync.setCwd(.{ .cwd_relative = v8_dir });
    addDepotToolsToPath(gclient_sync, depot_tools_dir);
    gclient_sync.step.dependOn(&write_gclient_args.step);

    // Run clang update
    const clang_update = b.addSystemCommand(&.{
        getDepotToolExePath(b, depot_tools_dir, "python-bin/python3"),
        "tools/clang/scripts/update.py",
    });
    clang_update.setCwd(.{ .cwd_relative = v8_dir });
    addDepotToolsToPath(clang_update, depot_tools_dir);
    clang_update.step.dependOn(&gclient_sync.step);

    // Create marker file
    const create_marker = b.addSystemCommand(&.{ "touch", marker_file });
    create_marker.step.dependOn(&clang_update.step);

    return create_marker;
}

fn buildV8(
    b: *std.Build,
    v8_dir: []const u8,
    depot_tools_dir: []const u8,
    bootstrapped_v8: *std.Build.Step.Run,
    target: std.Build.ResolvedTarget,
    gn_args: GnArgs,
) !*std.Build.Step.WriteFile {
    const v8_dir_lazy_path: LazyPath = .{ .cwd_relative = v8_dir };

    const args_string = try gn_args.asString(b, target);
    const out_dir = b.fmt("out/{s}/{s}", .{ @tagName(target.result.os.tag), if (gn_args.is_debug) "debug" else "release" });

    const gn_run = b.addSystemCommand(&.{
        getDepotToolExePath(b, depot_tools_dir, "gn"),
        "--root=.",
        "--root-target=//zig",
        "--dotfile=zig/.gn",
        "gen",
        out_dir,
        b.fmt("--args={s}", .{args_string}),
    });
    gn_run.setCwd(v8_dir_lazy_path);
    addDepotToolsToPath(gn_run, depot_tools_dir);
    gn_run.step.dependOn(&bootstrapped_v8.step);

    const ninja_run = b.addSystemCommand(&.{
        getDepotToolExePath(b, depot_tools_dir, "autoninja"),
        "-C",
        out_dir,
        "c_v8",
    });
    ninja_run.setCwd(v8_dir_lazy_path);
    addDepotToolsToPath(ninja_run, depot_tools_dir);
    ninja_run.step.dependOn(&gn_run.step);

    const wf = b.addWriteFiles();
    wf.step.dependOn(&ninja_run.step);
    const libc_v8_path = b.fmt("{s}/obj/zig/libc_v8.a", .{out_dir});
    _ = wf.addCopyFile(v8_dir_lazy_path.path(b, libc_v8_path), "libc_v8.a");

    return wf;
}
