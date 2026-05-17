# Windows Build Self-Recovery Helper

Use `scripts/windows/invoke_headed_build_self_recovery.ps1` when a headed
Windows build stalls early, times out before direct compiler diagnostics, or
fails before you can tell whether the problem is cache state, environment
policy, or a real source break.

## Default command

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\invoke_headed_build_self_recovery.ps1
```

This helper does the routine in one place:

- prints a snapshot of candidate orphaned build-related processes (`zig`,
  `cargo`, `ninja`, `build`, `cl`, `link`, `lld-link`)
- checks that `zig build --help` works in the current shell before treating the
  later failure as a source issue
- captures the default build logs to:
  - `tmp-current-build.stdout.txt`
  - `tmp-current-build.stderr.txt`
- classifies the most common early failure signatures:
  - `build.exe: FileNotFound`
  - `GetLastError(5): Access is denied`
  - direct compiler or linker diagnostics
- retries the same build once with:
  - `.zig-cache-recover`
  - `.zig-global-cache-recover`
  when the first failure is not already a direct source diagnostic

## JSON mode

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\invoke_headed_build_self_recovery.ps1 -Json |
  Set-Content -Path .\tmp-headed-build-self-recovery.json
```

The JSON summary includes:

- the resolved repo root
- the exact build arguments used
- the process snapshot
- the `zig` preflight result
- the default-build classification and log paths
- the fresh-cache retry result when it ran
- the recommended next steps

## Typical follow-up

If the helper says the fresh-cache retry succeeded after a cache-corruption
signature, recover the normal cache path with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1 -CleanBuildCaches
```

Then rerun the default build and only move back into code edits once the normal
cache path is healthy again.

If the helper reports direct diagnostics, read
`tmp-current-build.stderr.txt` first and fix the source error before trying
broader cache cleanup.

If the helper reports `GetLastError(5): Access is denied`, treat the failure as
an environment restriction first and keep the captured logs for a fresh-shell or
lower-restriction retry.