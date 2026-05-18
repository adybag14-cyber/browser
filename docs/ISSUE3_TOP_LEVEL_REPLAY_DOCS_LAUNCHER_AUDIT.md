# Issue #3 Top-Level Replay-Docs Launcher Audit

Use this note when the top-level attached-page replay notes may still be carrying older raw Python launcher routes and you want the shortest checker-first path before reopening the broader attached localhost helper chain.

## Goal

Run the replay-doc launcher audit first, then the launcher-companion checker, then the compact launcher companion helper, and only then return to the broader top-level attached HTML quickstart.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_replay_docs_launcher_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

If the replay is already running from a non-default checkout or from explicit attached bundle paths, preserve that same context when you reopen the compact launcher ladder and the broader top-level attached HTML helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_replay_docs_launcher_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
```

## Practical rule

Use this checker-first route when:
- the top-level attached-page notes may still mention older raw Python launcher commands
- you want the wrapper-backed sidecar audit route re-surfaced before trusting a broader replay note
- the compact launcher companion already provides the smaller wrapper/Python ladder you need, and the wider top-level quickstart should only reopen after those guard rails pass

Keep these nearby:
- `scripts/windows/check_google_issue3_replay_docs_launcher_validation_surface.ps1`
- `scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1`
- `scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
