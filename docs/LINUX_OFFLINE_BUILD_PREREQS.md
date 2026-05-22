# Linux / WSL Offline Build Prereqs

Use this note when a Linux or WSL run needs to stage the headed fork's saved
dependencies before debugging a local `zig build` failure.

## Why This Exists

`build.zig.zon` currently pins:

- `minimum_zig_version = "0.15.2"`
- sibling path dependencies at `../zig-v8-fork` and `../boringssl-zig`
- additional network-fetched archives for `brotli`, `zlib`, `nghttp2`, and
  `curl`

That means a Linux or WSL build can fail long before the browser source is at
fault if the checkout is using the wrong Zig version or the sibling dependency
layout was never staged.

## Quick Preflight

Run this from the browser checkout before a first offline retry:

```bash
bash scripts/linux/check_offline_build_prereqs.sh
```

If you also have the saved dependency bundle directory nearby, pass it in so the
checker verifies the expected archive names too:

```bash
bash scripts/linux/check_offline_build_prereqs.sh --deps-dir /path/to/dependencies
```

## What The Checker Verifies

- a working Zig executable is available
- the Zig version matches `build.zig.zon` exactly
- `../zig-v8-fork` exists next to the browser checkout
- `../boringssl-zig` exists next to the browser checkout
- the saved archive bundle is present when `--deps-dir` is supplied

## Expected Saved Archive Names

When a run is using the saved dependency bundle, keep these filenames together:

- `01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz`
- `02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip`
- `03-boringssl-zig-main.zip`
- `04-zig-browser-depo.tar.zip`

## Staging Rule

Before the build retry:

1. Place the browser checkout, `zig-v8-fork`, and `boringssl-zig` under one
shared parent directory.
2. Extract the saved BoringSSL bundle so the checkout can resolve
   `../boringssl-zig`.
3. Extract the saved V8 bundle so the checkout can resolve `../zig-v8-fork`.
4. Keep the remaining saved archives close by for offline cache setup or a
   throwaway path-rewrite step if the run needs to satisfy the GitHub-hosted
   `brotli`, `zlib`, `nghttp2`, or `curl` downloads without network access.

## Interpreting Failure

Treat the following as environment or staging problems first:

- Zig is present but not `0.15.2`
- the sibling directories are missing
- the saved dependency archive bundle is incomplete
- `zig build` fails on `403` fetches for `brotli`, `zlib`, `nghttp2`, or `curl`

Only start source-level headed-mode debugging after those checks are green.
