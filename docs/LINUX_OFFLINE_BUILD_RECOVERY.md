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

- `../offline-deps/...` for brotli, zlib, nghttp2, and curl
- a prebuilt `libc_v8_*.a` archive for `-Dprebuilt_v8_path`

If html5ever was saved as a vendor bundle, the repo root should also contain:

- `.cargo/config.toml`
- `vendor/`

## Restore Helper

When the saved dependency archives already live under the standard Memory path,
run the in-repo helper from the browser checkout with no extra arguments:

```bash
scripts/linux/restore_offline_build_inputs.sh
```

What it does:

1. extracts `zig-v8-fork` beside the browser repo
2. extracts `boringssl-zig` beside the browser repo
3. extracts brotli, zlib, nghttp2, curl, and any prebuilt `libc_v8_*.a`
   archive under `../offline-deps/`
4. restores `.cargo/config.toml` and `vendor/` from the saved html5ever bundle
5. saves a one-time backup at `build.zig.zon.remote-sources.bak`
6. rewrites `build.zig.zon` from remote URL dependencies to local `.path`
   dependencies
7. removes `zig-v8-fork`'s remote `depot_tools` dependency when the saved
   prebuilt V8 archive is being used for offline validation

If the archives live somewhere else, use the explicit-archive helper instead:

```bash
scripts/linux/prepare_offline_build_inputs.sh \
  --browser-deps-archive /path/to/zig-browser-depo.tar.zip \
  --boringssl-archive /path/to/boringssl-zig-main.zip \
  --html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip
```

## Preflight Check

Before running `zig build`, confirm that the checkout is actually ready:

```bash
scripts/linux/check_offline_build_prereqs.sh
```

If the compatible Zig toolchain is installed outside PATH, point the preflight
at it directly:

```bash
scripts/linux/check_offline_build_prereqs.sh \
  --zig-binary /absolute/path/to/zig
```

or:

```bash
ZIG=/absolute/path/to/zig scripts/linux/check_offline_build_prereqs.sh
```

What it checks:

1. `zig version` exactly matches the `build.zig.zon` minimum (`0.15.2` on the
   current branch)
2. an offline manifest backup exists at either
   `build.zig.zon.remote-sources.bak` or the older
   `build.zig.zon.before-offline`
3. `build.zig.zon` points brotli, zlib, nghttp2, and curl at local
   `../offline-deps/...` paths
4. the sibling `zig-v8-fork` and `boringssl-zig` directories exist
5. the extracted offline dependency directories, `.cargo/config.toml`,
   `vendor/`, and a prebuilt `libc_v8_*.a` archive are present

If the preflight fails, rerun `scripts/linux/restore_offline_build_inputs.sh`
or use `scripts/linux/prepare_offline_build_inputs.sh` when the archives are
stored outside the standard Memory layout.

## Validation

After the restore helper completes, run the preflight checker first. When it
passes, use the printed `-Dprebuilt_v8_path=...` value and run the same Zig
binary that passed preflight:

```bash
/absolute/path/to/zig build --summary all -Dprebuilt_v8_path=/absolute/path/to/libc_v8_...a
```

If the compatible toolchain is already on PATH, `zig build` is still fine.

Expected result:

- the build should stop failing on GitHub `403` package fetches
- the next failures, if any, should be real compile or build-API diagnostics

## Notes

- The helpers are intentionally destructive for the extracted sibling
  dependency directories and for `vendor/`; they rebuild those from the saved
  archives.
- The original manifest is preserved at `build.zig.zon.remote-sources.bak` on
  the current path, with `build.zig.zon.before-offline` still accepted as a
  legacy backup name.
