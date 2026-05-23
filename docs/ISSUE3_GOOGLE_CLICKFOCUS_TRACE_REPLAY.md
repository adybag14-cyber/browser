# Issue #3 Click-Focus Trace Replay

Use this note when issue `#3` is already narrowed to the real click-first Google homepage path and you need the shortest honest route from the shared Enter-order rung to fresh live headed traces.

## Keep This Order

1. Re-run the shared form-controls checkpoint that matches the real click-first path:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
```

2. Re-run the pinned attached-page compatibility bundle route before widening back to live Google:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
```

3. Only if both of those rungs are green, reproduce the current drift again on a fresh headed `https://www.google.com/` replay.

4. Inspect only the trace files from that fresh live replay before widening back into the broader issue `#3` helper chain:

- `tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log`
- `tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log`

Treat older copies of those trace files as stale until the current headed replay rewrites them.

## Why This Exists

The remaining issue `#3` gap is no longer broad headed startup or generic typing. The narrow question is whether the click-focus Google homepage path still drifts after the shared click-first checkpoint and the pinned attached-page bundle both pass. This note keeps that narrower decision point visible so the next replay does not widen too early.