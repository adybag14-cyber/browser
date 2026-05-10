# Linux Offline Build Recovery

Use this when headed-fork Linux validation is running from saved dependency
archives instead of live GitHub fetches.

## Goal

Restore the sibling dependency layout that the branch already expects for:
- `../zig-v8-fork`
- `../boringssl-zig`
- `../offline-deps/{brotli,zlib,nghttp2,curl}`

Optionally refresh:
- `.cargo/config.toml`
- `vendor/`

## Restore Command

```console
./scripts/linux/restore_offline_build_deps.sh \
  --deps-archive /path/to/04-zig-browser-depo.tar.zip \
  --boringssl-archive /path/to/03-boringssl-zig-main.zip \
  --html5ever-archive /path/to/02-litefetch-html5ever-linux-x86_64-deps.zip
```

The script saves `build.zig.zon.before-offline` and rewrites the working copy's
`build.zig.zon` so brotli, zlib, nghttp2, and curl resolve from local
`../offline-deps/*` paths instead of remote URLs.

## Validation Rule

Use the branch's supported Zig `0.15.2` toolchain for a real Linux build or
test pass.

If only Zig `0.17.x` dev is available, use it only to confirm that offline
package fetches are no longer blocking progress. Later build-API mismatches are
still expected until the repo and its dependencies are ported or a compatible
Zig `0.15.x` toolchain is restored.

## Suggested Build Check

```console
zig build --summary all \
  -Dprebuilt_v8_path='../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a'
```