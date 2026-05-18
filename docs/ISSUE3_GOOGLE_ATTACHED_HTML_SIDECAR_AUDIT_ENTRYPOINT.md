# Issue #3 Google Attached HTML Sidecar Audit Entrypoint

Use this note when issue `#3` replay is already narrowing toward the Google-shaped attached localhost branch and you want the lightest export-integrity check first before you reopen the broader Google attached-page surface checks, deeper asset audit, or the narrower issue-specific replay bridge.

This note is the compact written companion for the sidecar-aware attached-pages helpers that now exist on `fork/headed-mode-foundation`.

Keep these companion notes nearby:
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`

## Goal

Rule out the simplest saved-export failure first: the attached HTML page is present, but its sibling `_files` sidecar bundle is missing or incomplete.

Do that before spending time on the broader Google attached-page validation surface, deeper local asset-closure checks, or headed-runtime diagnosis.

## Default read-first route

Use this route when no saved summary, non-default repo root, or explicit bundle path needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:
- the replay is already centered on the Google-shaped attached localhost lane
- you want the sidecar-bundle verdict before the broader Google attached-page surface checker or the narrower issue-specific checker takes over
- you still want the broader Google attached-page helper and the shorter issue-specific bridge visible once the sidecar audit passes

## Direct sidecar-only route

Use this route when you only need the smallest possible export-integrity answer:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_sidecar_audit.py --root '<attached-html-root>'
```

Use that route when:
- the current question is simply whether the saved export is missing its whole sibling `_files` bundle
- you do not need the catalog launcher, broader Google surface checker, or narrower issue-specific bridge yet
- you want a direct count of missing sidecar directories before reopening any broader replay helper chain

## Preserve replay context

If the replay already carries a non-default repo root or explicit inputs, keep that same context attached to the sidecar-first route:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --repo-root '<repo-root>' --input '<attached-html-or-folder>' --google-style --audit-sidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<attached-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<attached-html-or-folder>'
```

Use that form when:
- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- explicit `InputPath` values are already pinned to the current attached-page set
- a saved `SummaryPath` already points at the current replay outputs and should stay attached to the narrower issue-specific bridge

## Practical rule

Once the replay is clearly on the Google-shaped attached localhost lane, run the sidecar audit first. If that fails, treat the result as an export-bundle problem before you spend time on broader Google surface checks or headed-runtime diagnosis. If it passes, reopen the broader Google attached-page flow and the narrower issue-specific entrypoint in that order.
