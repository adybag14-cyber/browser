# Issue #3 Handoff Refresh Route

Use this note when the current issue `#3` Windows replay has already reached the handoff-safe checkpoint, but the saved refresh state may still need bounded follow-up before the raw handoff helper should reopen.

## Command

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe_refresh_route.ps1
```

## When to use it

Use this wrapper when:

- the saved summary and manifest already exist
- you want to resume from the current handoff-safe state instead of running a broader replay first
- the next safe move may still pass through the refresh-status safe path route before raw handoff is ready

Prefer this wrapper over running `show_google_issue3_validation_handoff_safe.ps1` and `show_google_issue3_validation_refresh_status_safe_path_route.ps1` separately when you want that branch reopened in one step.

## What it does

The wrapper keeps the replay on the safer chain first:

1. It runs `show_google_issue3_validation_handoff_safe.ps1`.
2. If the handoff-safe helper says refresh follow-up is still needed, it immediately reopens `show_google_issue3_validation_refresh_status_safe_path_route.ps1`.
3. It saves one combined artifact so the next Windows replay can continue from the narrowed refresh or handoff guidance without rediscovering which helper should run next.

## Artifact

The combined report is written to:

- `tmp-browser-smoke\headed-probe\google-issue3-validation-handoff-safe-refresh-route.json`

Open that artifact first before widening back out to raw helpers.

## Key statuses

- `ready-for-handoff`
  Use the raw handoff helper next because the safe chain already says the narrower handoff step is ready.

- `refresh-status-safe-follow-up-ready`
  Stay on the emitted refresh follow-up guidance. The wrapper has already reopened the bounded refresh-status path-route helper for you.

- `handoff-safe-follow-up-needed`
  Follow the current handoff-safe recommendation. The replay does not need the refresh-status path-route bridge yet.

- `handoff-safe-failed`
  Reopen the handoff-safe helper itself before trusting narrower follow-up steps.

- `refresh-status-safe-failed`
  The handoff-safe helper correctly routed into the refresh-safe branch, but that bounded refresh follow-up did not finish cleanly. Reopen the refresh-safe path-route helper directly.

## Follow-up rules

- If the wrapper reports `ready-for-handoff`, continue with `show_google_issue3_validation_handoff.ps1`.
- If it reports `refresh-status-safe-follow-up-ready`, use the wrapper's emitted `recommended_command` instead of jumping straight to raw handoff.
- If it reports `handoff-safe-follow-up-needed`, keep following the current handoff-safe guidance until the safe chain says the narrower refresh or raw handoff step is ready.
- If it reports a failure status, return to the safer checkpoint named in the report before reopening raw helpers.

## Practical rule

Use `show_google_issue3_validation_handoff_safe_refresh_route.ps1` when you already trust the current saved outputs and want the handoff-safe checkpoint to decide whether refresh recovery is still needed. Use the broader validation wrappers when the saved outputs may be stale or missing.
