# Headed Mode Build Toolchain Preflight

Use this note before retrying headed-mode build or validation work on
`fork/headed-mode-foundation`.

## Why this exists

The branch declares `0.15.2` in `build.zig.zon`, but the saved fallback toolchain
used by some recovery runs is `0.17.0-dev`. Recent autonomous runs hit untouched
branch failures under that newer toolchain before the focused headed-mode tests
could even start. When that happens, the first problem is usually the toolchain
or dependency staging, not the headed-mode slice being validated.

## Run the preflight first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_zig_toolchain_preflight.ps1
```

The script prints:

- the repo root it resolved
- the minimum Zig version declared by the branch
- the `zig` version currently on `PATH`
- whether sibling dependencies exist at `../zig-v8-fork` and `../boringssl-zig`
- the next recovery commands to run before deeper headed-mode diagnosis

## Expected baseline

Treat this as the healthy starting point:

- Zig `0.15.2`
- repo checked out beside `../zig-v8-fork`
- repo checked out beside `../boringssl-zig`
- saved dependency bundles already extracted when running offline or from WSL

## If the script warns about Zig version drift

Do not treat that warning as a headed-mode regression by itself.

1. Switch to a `0.15.2` toolchain first.
2. Re-run the preflight.
3. Retry the build or test command only after the toolchain and sibling paths look right.

## If Windows build startup still looks unhealthy

Capture fresh logs first:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all 1> tmp-current-build.stdout.txt 2> tmp-current-build.stderr.txt
```

If the first retry still looks cache-related, use fresh cache directories:

```powershell
zig build test --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover
```

After a successful fresh-cache retry, clean only the transient build caches:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1 -CleanBuildCaches -CleanSliceOutputs
```

## Relationship to the main Windows guide

Keep `docs/WINDOWS_FULL_USE.md` as the broader runbook for Windows and WSL
headed-mode work. Use this preflight note when the branch might be failing
before the real headed validation surface is even in play.