# Linux Offline Build Recovery

Use this when Linux validation needs to run from saved dependency archives
instead of live network fetches.

## Goal

Restore the dependency layout that `build.zig.zon` expects so `zig build`
advances into real compile diagnostics instead of failing on remote fetches.

The browser repo expects these sibling paths:

- `../zig-v8-fork`
- `../boringssl-zig`

The browser build also needs local copies of:

- `../offline-deps/brotli`
- `../offline-deps/zlib`
- `../offline-deps/nghttp2`
- `../offline-deps/curl`
- a prebuilt `libc_v8_*.a` archive for `-Dprebuilt_v8_path`

If html5ever was saved as a vendor bundle, the repo root should also contain:

- `.cargo/config.toml`
- `vendor/`

## Restore Helper

Run the in-repo helper from the browser checkout:

```bash
scripts/linux/prepare_offline_build_inputs.sh \
  --browser-deps-archive /path/to/zig-browser-depo.tar.zip \
  --boringssl-archive /path/to/boringssl-zig-main.zip \
  --html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip
```

What it does:

1. extracts `zig-v8-fork` beside the browser repo
2. extracts `boringssl-zig` beside the browser repo
3. extracts brotli, zlib, nghttp2, curl, and any prebuilt `libc_v8_*.a`
   archive under `../offline-deps/`
4. restores `.cargo/config.toml` and `vendor/` when the html5ever archive is
   provided
5. saves a one-time backup at `build.zig.zon.before-offline`
6. rewrites `build.zig.zon` from remote URL dependencies to local `.path`
   dependencies

## Preflight Check

Before running `zig build`, confirm that the checkout is actually ready:

```bash
scripts/linux/check_offline_build_prereqs.sh
```

What it checks:

1. `zig version` exactly matches the `build.zig.zon` minimum (`0.15.2` on the
   current branch)
2. `build.zig.zon.before-offline` exists
3. `build.zig.zon` points brotli, zlib, nghttp2, and curl at `../offline-deps`
4. the sibling `zig-v8-fork` and `boringssl-zig` directories exist
5. the extracted offline dependency directories, `.cargo/config.toml`,
   `vendor/`, and a prebuilt `libc_v8_*.a` archive are present

If the preflight fails, rerun `scripts/linux/prepare_offline_build_inputs.sh`
or switch to the repo-compatible Zig toolchain before retrying the build.

## Validation

After the restore helper completes, run the preflight checker first. When it
passes, use the printed `-Dprebuilt_v8_path=...` value and run:

```bash
zig build --summary all -Dprebuilt_v8_path=/absolute/path/to/libc_v8_...a
```

Expected result:

- the build should stop failing on GitHub `403` package fetches
- the next failures, if any, should be real compile or build-API diagnostics

## Notes

- The helper is intentionally destructive for the extracted sibling dependency
  directories and for `vendor/`; it rebuilds those from the supplied archives.
- The original manifest is preserved at `build.zig.zon.before-offline` so the
  checkout can be restored after the offline validation pass.
