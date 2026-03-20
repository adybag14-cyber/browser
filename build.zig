const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const git_commit = b.option([]const u8, "git_commit", "Current git commit") orelse "dev";
    const git_version = b.option([]const u8, "git_version", "Current git version (from tag)");
    const snapshot_path = b.option([]const u8, "snapshot_path", "Path to v8 snapshot");
    const prebuilt_v8_path = b.option([]const u8, "prebuilt_v8_path", "Path to prebuilt libc_v8.a") orelse "../v8_artifacts/v8/libc_v8.a";

    var build_config = b.addOptions();
    build_config.addOption([]const u8, "version", "0.0.0");
    build_config.addOption([]const u8, "git_commit", git_commit);
    build_config.addOption(?[]const u8, "git_version", git_version orelse null);
    build_config.addOption(?[]const u8, "snapshot_path", snapshot_path);
    const build_config_mod = build_config.createModule();

    var default_exports = b.addOptions();
    default_exports.addOption(bool, "inspector_subtype", false);
    const default_exports_mod = default_exports.createModule();

    const v8_module = b.addModule("v8", .{
        .root_source_file = .{ .cwd_relative = "deps/zig-v8/src/v8.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    v8_module.addImport("default_exports", default_exports_mod);
    v8_module.addIncludePath(.{ .cwd_relative = "deps/zig-v8/src" });
    v8_module.addObjectFile(.{ .cwd_relative = prebuilt_v8_path });
    linkExternalCppRuntime(v8_module);
    linkCommonSystemLibraries(v8_module);

    const html5ever_lib = b.addLibrary(.{
        .name = "html5ever_fallback",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/html5ever_fallback.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const lightpanda_module = b.addModule("lightpanda", .{
        .root_source_file = b.path("src/lightpanda.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lightpanda_module.addImport("lightpanda", lightpanda_module);
    lightpanda_module.addImport("build_config", build_config_mod);
    lightpanda_module.addImport("v8", v8_module);
    lightpanda_module.linkLibrary(html5ever_lib);
    linkCurl(lightpanda_module);
    linkOpenSSL(lightpanda_module);

    const fmt_step = b.step("fmt", "Check code formatting");
    const fmt = b.addFmt(.{
        .paths = &.{ "src", "build.zig", "build.zig.zon" },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);

    {
        const exe = b.addExecutable(.{
            .name = "lightpanda",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .imports = &.{
                    .{ .name = "lightpanda", .module = lightpanda_module },
                },
            }),
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| run_cmd.addArgs(args);
        const run_step = b.step("run", "Run lightpanda");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "lightpanda-snapshot-creator",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main_snapshot_creator.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .imports = &.{
                    .{ .name = "lightpanda", .module = lightpanda_module },
                },
            }),
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| run_cmd.addArgs(args);
        const run_step = b.step("snapshot_creator", "Generate a v8 snapshot");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "legacy_test",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main_legacy_test.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .imports = &.{
                    .{ .name = "lightpanda", .module = lightpanda_module },
                },
            }),
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| run_cmd.addArgs(args);
        const run_step = b.step("legacy_test", "Run the legacy test harness");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const tests = b.addTest(.{
            .root_module = lightpanda_module,
            .test_runner = .{ .path = b.path("src/test_runner.zig"), .mode = .simple },
        });
        const run_tests = b.addRunArtifact(tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_tests.step);
    }
}

fn linkCommonSystemLibraries(mod: *Build.Module) void {
    mod.linkSystemLibrary("m", .{});
    mod.linkSystemLibrary("dl", .{});
    mod.linkSystemLibrary("pthread", .{});
    mod.linkSystemLibrary("rt", .{});
    mod.linkSystemLibrary("gcc_s", .{});
    mod.linkSystemLibrary("atomic", .{});
}

fn linkExternalCppRuntime(mod: *Build.Module) void {
    mod.addObjectFile(.{ .cwd_relative = "vendor/cpp/lib/libc++.a" });
    mod.addObjectFile(.{ .cwd_relative = "vendor/cpp/lib/libc++abi.a" });
    mod.addObjectFile(.{ .cwd_relative = "vendor/cpp/lib/libunwind.a" });
}

fn linkCurl(mod: *Build.Module) void {
    mod.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    mod.addIncludePath(.{ .cwd_relative = "/usr/include" });
    mod.addIncludePath(.{ .cwd_relative = "/usr/include/x86_64-linux-gnu" });
    mod.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    mod.linkSystemLibrary("curl", .{ .preferred_link_mode = .dynamic });
}

fn linkOpenSSL(mod: *Build.Module) void {
    mod.linkSystemLibrary("ssl", .{});
    mod.linkSystemLibrary("crypto", .{});
}
