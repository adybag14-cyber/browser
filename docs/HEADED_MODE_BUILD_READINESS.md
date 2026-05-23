# Headed Mode Build Readiness

This note keeps the smallest branch-local build checklist in one place for
headed-mode work on `fork/headed-mode-foundation`.

Use it when a build or validation run fails before the browser code itself has
proven anything useful.

Read this together with:

- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` when issue `#3` is the
  active runtime target

## Why this exists

The current headed branch already has a strong Windows runbook and a broader
prerequisite checker. The missing piece has been a quick branch-specific entry
point for the exact build traps that keep showing up during headed validation:

- using the attached Zig `0.17.0-dev.299` fallback even though the current
  branch still has known untouched-source failures under that toolchain
- opening the browser checkout without the sibling `../zig-v8-fork` and
  `../boringssl-zig` trees that `build.zig.zon` expects
- treating offline fetch failures for `brotli`, `zlib`, `nghttp2`, or `curl`
  as browser regressions before the dependency staging is fixed

## Fast path

From a Windows checkout, run these first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_lightpanda_windows_prereqs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_build_readiness.ps1
```

If the second script reports a branch-compatibility failure, fix the toolchain
or dependency layout before retrying headed probes.

## What good looks like

The headed branch is build-ready when all of these are true:

- `zig version` resolves from `PATH`
- the Zig version satisfies `build.zig.zon`
- the Zig version is not the known-bad attached `0.17.0-dev.299` fallback for
  the current issue `#3` validation path
- `../zig-v8-fork` exists beside the browser checkout
- `../boringssl-zig` exists beside the browser checkout
- Linux or WSL runs have an offline plan for `brotli`, `zlib`, `nghttp2`, and
  `curl` before `zig build` is blamed on browser code

## Recommended sequence

### Windows-first route

1. Run `check_lightpanda_windows_prereqs.ps1`.
2. Run `show_headed_build_readiness.ps1`.
3. If both pass, continue into the normal headed build:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
```

4. If the build succeeds, reopen the narrowest headed validation route for the
   subsystem you changed.

### Linux or WSL route

1. Keep the checkout under one shared parent directory with:
   - `../zig-v8-fork`
   - `../boringssl-zig`
2. Stage offline dependency inputs for:
   - `brotli`
   - `zlib`
   - `nghttp2`
   - `curl`
3. Retry with explicit cache directories before editing browser code:

```bash
zig build --help
zig build test --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover
```

4. Treat `403` fetch failures as dependency staging misses first.

## Known issue #3 validation caveat

The current issue `#3` Enter-submit runtime note is still the source of truth
for the smallest live runtime slice. Recent scheduled reruns showed:

- the saved runtime patch still narrows cleanly to `src/browser/Page.zig` and
  `src/display/win32_backend.zig`
- the attached Zig `0.17.0-dev.299` fallback still fails in untouched branch
  files before the focused issue `#3` assertions run

Practical rule:

- prefer a branch-compatible Zig toolchain and a writable checkout before
  retrying the direct runtime patch
- use the build-readiness helper first so toolchain drift is visible before the
  browser code is blamed again

## Script output

`show_headed_build_readiness.ps1` reports:

- repo root discovery
- `build.zig.zon` minimum Zig version
- current Zig version
- branch-specific Zig compatibility status
- sibling dependency status for `zig-v8-fork` and `boringssl-zig`
- whether the branch still relies on remote package URLs for the remaining
  offline Linux or WSL dependencies
- the next recommended build command

Use that output as the fast fail-or-go signal before a longer headed build or
an issue `#3` validation replay.
