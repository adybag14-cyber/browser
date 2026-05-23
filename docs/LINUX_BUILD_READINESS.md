# Linux and WSL Build Readiness

Use this guide before retrying Linux or WSL headed-mode validation on this fork.
It turns the branch's existing preflight helpers into a short recovery loop so
Zig validation fails fast on missing toolchains or missing sibling
dependencies instead of burning time inside `zig build`.

Read this together with:
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/prepare_offline_build_inputs.sh`

## What this fork expects

Current branch assumptions:
- `build.zig.zon` declares `minimum_zig_version = "0.15.2"`
- the repo lives beside sibling checkouts at `../zig-v8-fork` and `../boringssl-zig`
- offline validation works best when URL-backed dependencies are staged under
  `../offline-deps/{brotli,zlib,nghttp2,curl}`
- a prebuilt `libc_v8_*.a` archive under `../offline-deps/` avoids the unused
  `depot_tools` fetch that otherwise blocks offline validation

Do not treat the attached Zig `0.17.0-dev.299` fallback as the first Linux
validation toolchain for this branch. Recent runtime replays showed that it can
fail in untouched branch files before the focused headed-mode checks even run.
Prefer a Zig `0.15.2` toolchain or the same branch-compatible path already used
by the normal build environment.

## Fast triage order

Use this order every time a Linux or WSL build path needs to be reopened:

1. Check the current repo layout without mutating anything.
2. Restore offline inputs and sibling dependencies if they are missing.
3. Re-run the readiness helper with the stricter offline checks enabled.
4. Only then retry `zig build`, `zig build test`, or a focused headed-mode
   probe.

## 1) Run the lightweight readiness helper first

From the browser checkout root:

```bash
python3 scripts/check_linux_build_readiness.py --repo-root .
```

This helper reports:
- the branch minimum Zig version
- the installed Zig version, unless skipped
- the installed `cargo` and `rustc`, unless skipped
- whether `../zig-v8-fork` and `../boringssl-zig` exist with the markers this
  fork expects
- whether URL-backed dependencies still need a network path or an offline cache

Useful focused variants:

```bash
python3 scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
python3 scripts/check_linux_build_readiness.py --repo-root . --skip-rust-check
python3 scripts/check_linux_build_readiness.py --self-test
```

Use `--skip-zig-check` when a matching Zig toolchain is not installed yet and
you only want to validate the workspace layout. Use `--self-test` when you want
a quick confidence check that the helper itself still behaves as expected.

## 2) Restore the offline dependency layout

When the helper reports missing sibling dependencies or missing offline inputs,
use the restore helper in `scripts/linux/prepare_offline_build_inputs.sh`.

Dry-run the restore plan first:

```bash
bash scripts/linux/prepare_offline_build_inputs.sh \
  --browser-root "$(pwd)" \
  --browser-deps-archive /path/to/zig-browser-depo.tar.zip \
  --boringssl-archive /path/to/boringssl-zig-main.zip \
  --html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip \
  --check-only
```

That prints the expected restore layout for:
- `../zig-v8-fork`
- `../boringssl-zig`
- `../offline-deps/`
- the optional vendored html5ever cargo inputs inside the repo checkout

If the dry run looks correct, run the same command again without `--check-only`:

```bash
bash scripts/linux/prepare_offline_build_inputs.sh \
  --browser-root "$(pwd)" \
  --browser-deps-archive /path/to/zig-browser-depo.tar.zip \
  --boringssl-archive /path/to/boringssl-zig-main.zip \
  --html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip
```

The helper will:
- restore `../zig-v8-fork`
- restore `../boringssl-zig`
- stage `../offline-deps/{brotli,zlib,nghttp2,curl}`
- restore a prebuilt `libc_v8_*.a` archive when present
- rewrite this fork's `build.zig.zon` from remote URL dependency stanzas to the
  local offline paths
- optionally restore `.cargo/config.toml` plus `vendor/` from the saved
  html5ever bundle
- rewrite `../zig-v8-fork/build.zig.zon` to skip the unused `depot_tools`
  dependency when a prebuilt V8 archive is available

## 3) Re-run the stricter readiness check

After the offline inputs are staged, rerun the helper with the stricter offline
flags enabled:

```bash
python3 scripts/check_linux_build_readiness.py \
  --repo-root . \
  --expect-offline-deps \
  --require-prebuilt-v8
```

A healthy result should show:
- Zig on the `0.15.x` line expected by the branch
- `cargo` and `rustc` visible on `PATH`
- sibling checkouts for `zig-v8-fork` and `boringssl-zig`
- non-empty offline dependency directories
- at least one `libc_v8_*.a` archive under `../offline-deps/`

## 4) Retry the actual build with clean expectations

Once the readiness helper passes, prefer the smaller confirmation steps before a
full headed replay:

```bash
zig build --help
zig build test --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover
```

If the offline restore helper printed a `-Dprebuilt_v8_path=...` suggestion,
reuse that exact value on the next `zig build` or `zig build test` attempt.

If the build still fails at this point:
- treat direct parser, type, linker, or API errors as real source-level work
- treat missing sibling directories, missing offline dependency roots, and wrong
  Zig line as environment problems first
- reopen the nearest bounded probe only after the build path itself is clean

## Common failure meanings

- `zig ... does not match the branch's expected 0.15.x line`
  Use a Zig `0.15.2` toolchain before blaming headed-mode source changes.
- `missing sibling dependency`
  Restore `../zig-v8-fork` or `../boringssl-zig` first.
- `offline dependency root is missing`
  Run `scripts/linux/prepare_offline_build_inputs.sh` before retrying the
  build.
- `missing prebuilt V8 archive`
  Restage the browser dependency bundle so `../offline-deps/libc_v8_*.a` is
  available.
- `URL-backed dependencies still need network access or an offline cache`
  Treat this as an offline staging miss unless the current workflow is expected
  to use a live network path.

## Suggested recovery loop for future runs

When a scheduled or manual run needs Linux or WSL validation again, reuse this
exact sequence:

```bash
python3 scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
bash scripts/linux/prepare_offline_build_inputs.sh --browser-root "$(pwd)" --browser-deps-archive /path/to/zig-browser-depo.tar.zip --boringssl-archive /path/to/boringssl-zig-main.zip --html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip --check-only
bash scripts/linux/prepare_offline_build_inputs.sh --browser-root "$(pwd)" --browser-deps-archive /path/to/zig-browser-depo.tar.zip --boringssl-archive /path/to/boringssl-zig-main.zip --html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip
python3 scripts/check_linux_build_readiness.py --repo-root . --expect-offline-deps --require-prebuilt-v8
zig build --help
```

That sequence is intentionally small. It is meant to tell you whether the next
run is blocked by environment staging or whether it is finally worth spending
time in the headed-mode source itself.