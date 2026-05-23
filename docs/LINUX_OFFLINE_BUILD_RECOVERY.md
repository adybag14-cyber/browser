# Linux Offline Build Recovery

Use this when Linux validation needs to run from saved dependency archives
instead of live network fetches, or when you want to confirm the saved-archive
recovery path before mutating the checkout.

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

## Shared Readiness Helper

Before rewriting anything, run the shared Python readiness helper from the
browser checkout:

```bash
python3 scripts/check_linux_build_readiness.py \
  --expect-saved-archives \
  --expect-offline-deps \
  --require-prebuilt-v8
```

What this helper is good at:

1. reading `build.zig.zon` and printing the branch's minimum Zig line
2. checking the active `zig`, `cargo`, and `rustc` binaries unless skipped
3. confirming whether the sibling path dependencies already exist
4. confirming whether `../offline-deps` and the prebuilt `libc_v8_*.a` archive
   are already staged
5. confirming whether the saved archive bundle is present and printing the
   matching `prepare_offline_build_inputs.sh --check-only` command shape

Use it as the first pass when you want an honest answer about what is still
missing before running a destructive restore step. If the layout is still only
partially staged, a failing result here is expected and more useful than a
blind `zig build` attempt.

The helper also treats Zig major/minor drift as a setup problem instead of a
headed-mode regression. If it reports that the active Zig is `0.17.x` while the
branch still expects `0.15.2`, switch toolchains before trusting any build
result.

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

Add `--check-only` first when you want to verify the supplied archive paths and
print the derived restore layout without changing the repo.

## Checkout Preflight Check

After the restore path completes, confirm that the active checkout is ready for
an actual build attempt:

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

If the configured Zig binary is missing or the version is wrong, the preflight
also scans nearby workspace roots for an exact-match Zig and prints
ready-to-rerun `--zig-binary` and `ZIG=...` hints for any candidates it finds.

If the preflight fails, rerun `scripts/linux/restore_offline_build_inputs.sh`
or use `scripts/linux/prepare_offline_build_inputs.sh` when the archives are
stored outside the standard Memory layout.

## Validation

After the restore helper completes, run the checkout preflight checker first.
When it passes, use the printed `-Dprebuilt_v8_path=...` value and run the same
Zig binary that passed preflight:

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
- The attached Zig `0.17.x` fallback is still useful for narrow diagnostics,
  but it should not be treated as a green light for Linux build validation
  while the branch keeps `0.15.2` in `build.zig.zon`.
- A good recovery order is: shared readiness helper, restore helper, checkout
  preflight checker, then the real `zig build` or focused `zig test` command.
