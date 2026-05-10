# Headed Mode Linux: Zig 0.17 Offline Build Blockers

This note captures the current Linux offline restore path for `fork/headed-mode-foundation` when the available toolchain is `zig 0.17.0-dev.299+a76ce7710`.

## What already works

- `scripts/linux/prepare_offline_build_inputs.sh` restores the saved offline dependency layout expected by `build.zig.zon`.
- The saved `litefetch-html5ever` archive can be restored into `.cargo/config.toml` plus `vendor/` for offline Rust-side builds.
- With the saved prebuilt V8 archive passed through `-Dprebuilt_v8_path`, the main browser build no longer stops on remote dependency fetches.
- The browser-owned `build.zig` is already on the newer module-based APIs needed by Zig 0.17.

## Reproduction

1. Restore the saved dependency layout with:
   `scripts/linux/prepare_offline_build_inputs.sh --browser-deps-archive /path/to/04-zig-browser-depo.tar.zip --boringssl-archive /path/to/03-boringssl-zig-main.zip --html5ever-archive /path/to/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip`
2. Run:
   `zig build --summary all -Dprebuilt_v8_path='../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a'`

## Current remaining blockers

The first remaining failures are now in extracted dependency build scripts, not in the browser repo itself.

### `../zig-v8-fork/build.zig`

Current Zig 0.17 failure shape:
- `std.fs.cwd()` no longer exists on this toolchain.
- The cached bootstrap checks and source-walk logic still use the older filesystem API.

Observed failure examples:
- `std.fs.cwd().access(cache_root, .{})`
- `std.fs.cwd().openDir(dir_path, .{ .iterate = true })`
- `std.fs.cwd().statFile(marker_file)`

### `../boringssl-zig/build.zig`

Current Zig 0.17 failure shape:
- `b.addStaticLibrary` is no longer available on `std.Build`.
- The build script still uses compile-step methods such as `addIncludePath`, `addCSourceFile`, and direct library linking in the older style.

Observed failure example:
- `error: no field or member function named 'addStaticLibrary' in 'Build'`

## Practical next step

When continuing Linux build readiness work on Zig 0.17, patch the extracted dependency build scripts in this order:

1. Port `../zig-v8-fork/build.zig` off `std.fs.cwd()` onto the current `std.Io.Dir` filesystem APIs.
2. Port `../boringssl-zig/build.zig` from `b.addStaticLibrary` and compile-step source/include helpers onto `b.addLibrary` plus root-module source/include wiring.
3. Re-run the same `zig build --summary all -Dprebuilt_v8_path=...` command after each dependency port so the next blocker is captured from the compiler directly.

## Why this file exists

The offline restore path is now good enough that repeated Linux failures should be treated as dependency build-script compatibility work, not as missing archives or network setup problems.
