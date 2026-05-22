# Linux / WSL Offline Build Prereqs

Use this note when a Linux or WSL run needs to reopen the headed fork's offline
build path without confusing toolchain staging failures for browser-source
regressions.

## Why This Exists

`build.zig.zon` currently pins:

- `minimum_zig_version = "0.15.2"`
- sibling path dependencies at `../zig-v8-fork` and `../boringssl-zig`
- browser-managed offline dependency paths under `../offline-deps`
- Rust/Cargo-backed html5ever build steps that still need a compatible Rust toolchain

That means an offline Linux or WSL build can fail long before the headed source
is at fault if the checkout is using the wrong Zig version, the sibling layout
was never restored, or the offline dependency manifest no longer matches the
workspace.

## Quick Preflight

Run this from the browser checkout before the first offline retry:

```bash
bash scripts/linux/check_offline_build_prereqs.sh
```

The branch-native helper already knows how to:

- read `build.zig.zon` and enforce the required Zig version
- verify `../zig-v8-fork` and `../boringssl-zig`
- check that `brotli`, `zlib`, `nghttp2`, and `curl` resolve under `../offline-deps`
- verify that `cargo`, `rustc`, `.cargo/config.toml`, `vendor/`, and a `libc_v8_*.a` archive are available for a real retry
- scan nearby workspace roots, the saved Memory dependency area, and `/workspace/agent_files` for matching Zig or Rust archives when the active toolchains are missing or mismatched
- print rerun hints with explicit `--zig-binary`, `--cargo-binary`, and `--rustc-binary` paths when it finds compatible candidates off PATH

## Useful Flags

Use these when the compatible tools are present but not on PATH:

```bash
bash scripts/linux/check_offline_build_prereqs.sh \
  --zig-binary /path/to/zig \
  --cargo-binary /path/to/cargo \
  --rustc-binary /path/to/rustc \
  --prebuilt-v8-path /path/to/libc_v8.a
```

During active Zig-port experiments, `--allow-zig-mismatch` keeps the layout and
archive checks running without treating the known Zig-version drift as the first
hard failure.

## What A Healthy Staging Layout Looks Like

Keep these pieces under one shared parent before retrying `zig build`:

- the browser checkout
- `zig-v8-fork`
- `boringssl-zig`
- `offline-deps/` with extracted `brotli`, `zlib`, `nghttp2`, and `curl`
- a prebuilt `libc_v8_*.a` archive that matches the intended validation path

If the run is using the saved dependency bundle from Memory, keep these archive
names together so the helper can rediscover them when the active toolchains are
missing:

- `01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz`
- `02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip`
- `03-boringssl-zig-main.zip`
- `04-zig-browser-depo.tar.zip`
- a Zig archive that matches `0.15.2`

## Interpreting Failure

Treat the following as environment or staging problems first:

- Zig is present but not `0.15.2`
- the sibling dependency directories are missing
- `build.zig.zon` is not pointed at local `../offline-deps/...` paths
- `cargo` or `rustc` are missing for the html5ever step
- `libc_v8_*.a` is missing from the workspace
- `zig build` fails on offline dependency fetches before source-level diagnostics appear

Only start source-level headed-mode debugging after the preflight is green or a
failure clearly survives the staged retry that the helper prints.
