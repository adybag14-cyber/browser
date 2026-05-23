# Headed Fork Build Toolchain Re-entry

This note is the fastest honest re-entry path when Linux or WSL validation is
blocked before headed-mode source changes can be exercised.

Treat these branch facts as product truth on `fork/headed-mode-foundation`:

- `build.zig.zon` currently declares `minimum_zig_version = "0.15.2"`
- the saved Rust toolchain is `1.79.0`
- the saved Linux prebuilt V8 archive should be preferred over a depot-tools
  fetch path during recovery work
- the attached Zig `0.17.0-dev.299` toolchain is still useful for narrow scratch
  tests, but it is not a trustworthy full-build validator for this branch yet

## What to use first

1. Prefer a Zig `0.15.2` toolchain for any real `zig build` or
   `zig build test` attempt on this branch.
2. Put the saved Rust `1.79.0` toolchain on `PATH` before retrying `html5ever`
   or any full build.
3. Keep the repo beside sibling dependency directories:
   - `../zig-v8-fork`
   - `../boringssl-zig`
4. Stay on the prebuilt-V8 path during Linux recovery unless you are explicitly
   debugging V8 packaging.

## Known Zig 0.17 boundary

When only the attached Zig `0.17.0-dev.299` toolchain is available, treat these
failures as expected toolchain-compatibility checkpoints before blaming a new
headed-mode regression:

- `build.zig` uses Build APIs such as `addCSourceFiles` and `addConfigHeader`
  in forms that do not match Zig `0.17`
- `boringssl-zig` still hits `addStaticLibrary` API mismatches under Zig `0.17`
- later retries can also stop in the legacy test target because `src/Server.zig`
  is seen in both the root and `lightpanda` modules on that toolchain

If the failure lands on one of those surfaces, the run is blocked on toolchain
compatibility, not on the headed runtime change you were trying to validate.

## Fast Linux or WSL re-entry commands

Use the saved Rust toolchain first:

```bash
export PATH=/workspace/.toolchains/rust-1.79-install/bin:$PATH
cargo --version
rustc --version
```

Sanity-check the chosen Zig first:

```bash
zig version
zig build --help
```

Then retry the branch on the prebuilt-V8 path with explicit recovery caches:

```bash
zig build test \
  -Dprebuilt_v8_path='../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a' \
  --summary all \
  --cache-dir .zig-cache-recover \
  --global-cache-dir .zig-global-cache-recover
```

If the branch is using a different extracted workspace layout, adjust only the
`-Dprebuilt_v8_path` value. Keep the rest of the command shape the same so the
logs remain comparable across runs.

## How to classify the result

- If Zig `0.15.2` is available and the build still fails, treat the resulting
  parser, type, or linker diagnostics as source-level work.
- If only Zig `0.17` is available and the build stops on the known API mismatch
  surfaces above, switch to a compatible toolchain or explicitly port the build
  scripts before reopening headed runtime validation.
- If the build fails on remote dependency fetches, re-check the offline staging
  instructions in `docs/WINDOWS_FULL_USE.md` before editing source.

## Next practical moves

1. Save a compatible Zig `0.15.2` toolchain beside the other Memory archives so
   future runs can validate the branch without rediscovering the version gap.
2. If a Zig `0.15.2` toolchain is not available, treat build-script porting as
   its own slice across `build.zig`, the sibling `zig-v8-fork` build scripts,
   and `boringssl-zig` rather than mixing that work into headed runtime fixes.
3. Reopen headed runtime validation only after the build path is back on a
   branch-compatible toolchain.
