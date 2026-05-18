# Windows Build Self-Recovery Route

Use this note when a headed Windows build fails before you can tell whether the
problem is cache state, shell policy, or a real source diagnostic.

This route does not replace the main validation router. It gets the build back
to a trustworthy state first, then hands control back to the smallest headed
probe family.

Read this together with:

- `docs/WINDOWS_BUILD_SELF_RECOVERY.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_VALIDATION_MATRIX.md`

## Fast route

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_build_self_recovery_route.ps1
```

Use `-NextChangeArea` when you already know which headed subsystem should be the
next stop after the build is healthy again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_build_self_recovery_route.ps1 -NextChangeArea input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_build_self_recovery_route.ps1 -NextChangeArea rendering
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_build_self_recovery_route.ps1 -NextChangeArea attached-html
```

## Route order

1. Run `check_lightpanda_windows_prereqs.ps1` first.
2. Run `invoke_headed_build_self_recovery.ps1` to capture logs, classify the
   first failure, and retry once with fresh caches when that still makes sense.
3. Read `tmp-current-build.stderr.txt` before changing code when the helper says
   the failure contains direct diagnostics.
4. Run `manage_build_artifacts.ps1 -CleanBuildCaches` only after the fresh-cache
   retry succeeded and you want to restore the default cache path.
5. Reopen `show_headed_validation_suites.ps1` and continue with the smallest
   bounded headed probe family for the subsystem you were actually changing.

## Practical rule

Treat this route as the build-discipline bridge between a noisy Windows build
failure and real headed validation.

- If the helper reports `build.exe: FileNotFound`, think cache state first.
- If it reports `GetLastError(5): Access is denied`, think shell or environment
  restriction first.
- If it reports direct diagnostics, fix the source problem before broader cache
  cleanup.
- If the fresh-cache retry succeeds, clean the default caches and rerun the
  normal build before returning to headed probes.

## Saved summary form

When you want a durable machine-readable record of the recovery pass, use the
JSON mode:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_build_self_recovery_route.ps1 -Json
powershell -ExecutionPolicy Bypass -File .\scripts\windows\invoke_headed_build_self_recovery.ps1 -Json |
  Set-Content -Path .\tmp-headed-build-self-recovery.json
```

Use the saved JSON summary to keep the recovery result attached to the same run
before you reopen the headed validation router.
