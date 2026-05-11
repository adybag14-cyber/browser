# Headed Mode Linux Zig 0.17 Build Notes

This note captures the current Linux-side build recovery state for
`fork/headed-mode-foundation` when work is happening in the scheduled or saved
workspace environment.

It is not the primary product path for headed mode. Windows remains the main
headed runtime target. This document exists so future runs can restore the
offline Linux workspace quickly, reproduce the current Zig 0.17 migration
surface, and avoid re-deriving the same blocker stack.

Read this with:
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/HEADED_MODE_ROADMAP.md`
- `scripts/linux/prepare_offline_build_inputs.sh`

## What This Is Good For

Use the Linux path to:
- check parser and type-level breakage while porting the fork toward newer Zig
  toolchains
- preserve small compatibility edits in branch-visible commits
- capture the next real compiler blocker after a focused migration slice

Do not use it as proof that headed mode itself is production-ready. The real
headed browser validation path is still the Windows native runtime plus the
bounded smoke suites.

## Offline Restore Baseline

When the saved dependency archives are available, restore the Linux workspace in
this order:

1. Extract the browser repo so it sits beside its sibling dependency trees.
2. Run:

```bash
scripts/linux/prepare_offline_build_inputs.sh \
  --browser-deps-archive /path/to/04-zig-browser-depo.tar.zip \
  --boringssl-archive /path/to/03-boringssl-zig-main.zip \
  --html5ever-archive /path/to/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip
```

3. Put the saved Rust toolchain on `PATH` before invoking Zig.
4. Use the prebuilt V8 archive that the script restores under `../offline-deps/`
   so validation does not reintroduce depot-tools bootstrap work.

Example validation command:

```bash
export PATH="/path/to/rust-1.79.0-x86_64-unknown-linux-gnu/cargo/bin:/path/to/rust-1.79.0-x86_64-unknown-linux-gnu/rustc/bin:$PATH"
zig build --summary all -Dprebuilt_v8_path='../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a'
```

## Current Toolchain Assumption

The recovered Linux workspace has recently been exercised against:
- Zig `0.17.0-dev.299+a76ce7710`
- Rust `1.79.0`

Treat new failures under that setup as source/toolchain compatibility work
unless the error explicitly says a file or binary is missing.

## Current Migration Status

As of 2026-05-11, the branch already has the offline restore helper checked in,
but the source tree is not yet broadly compatible with Zig 0.17.

Recent workspace-only progress has included:
- replacing Linux-facing `@cImport` uses with translated Zig bindings in the
  curl and V8 integration paths
- replacing several Windows-only `@cImport` sites that still get parsed during
  hosted Linux builds with local stub imports
- moving parts of argument parsing and panic handling toward newer Zig std APIs

That means the main Linux value right now is to land small compatibility slices
and then re-run until the next parser or type blocker is exposed.

## First Known Blocker Cluster

A fresh Zig 0.17 parse pass still stops very early on syntax and builtin churn
that is scattered across the tree. The first cluster currently includes:
- repetition expressions that now require consistent whitespace around `**`
- old `@Type(...)` call sites that must be migrated to the current builtin form
- remaining top-level `@cImport` usage in files that are still parsed during
  hosted Linux builds

Representative files from the current blocker surface include:
- `src/Net.zig`
- `src/browser/Mime.zig`
- `src/browser/js/Caller.zig`
- `src/browser/js/bridge.zig`
- `src/browser/webapi/Event.zig`
- `src/browser/webapi/canvas/CanvasSurface.zig`
- `src/browser/webapi/canvas/WebGLRenderingContext.zig`
- `src/browser/webapi/element/html/Image.zig`
- `src/browser/webapi/storage/Cookie.zig`
- `src/display/baremetal_backend.zig`
- `src/display/win32_backend.zig`
- `src/render/DocumentPainter.zig`
- `src/string.zig`
- `src/testing.zig`

Do not assume later blockers are gone just because one of these is fixed. Clear
this front parser layer first, then rerun immediately to reveal the next real
compatibility tier.

## Next Slice Guidance

Prefer the next Linux migration unit in this order:
1. land one or more very small parser-level fixes in smaller files first
2. rerun the build or targeted Zig parse pass immediately
3. record the new first failure before widening into larger files such as
   `src/display/win32_backend.zig`

When a blocker reaches a very large file, checkpoint the smaller-file wins first
so publication friction does not erase the progress.

## Validation Rule

For Linux migration work, success for a single run is not a full build. Success
is one focused compatibility slice plus a truthful rerun that shows the next
blocker.
