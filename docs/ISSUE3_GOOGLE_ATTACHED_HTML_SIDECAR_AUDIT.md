# Issue #3 Google Attached HTML Sidecar Audit

Use this note when the next issue `#3` replay needs the quickest way to verify
that the current attached HTML exports still have their sibling `_files`
bundles before you reopen the broader Google-shaped attached-page helper chain.

The matching helper script is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_sidecar_audit.ps1
```

## Default command surface

For auto-discovered attached HTML inputs or an explicit saved-page list, prefer
the wrapper-backed launcher audit so the sidecar check stays aligned with the
same attached-pages discovery and staging surface used elsewhere on
`fork/headed-mode-foundation`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars
```

If the replay should stay pinned to a non-default checkout, preserve that
branch root directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -GoogleStyle -AuditSidecars
```

If the replay is already pinned to a specific attached-page file or folder,
preserve those inputs on the same wrapper-backed command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -GoogleStyle -AuditSidecars -InputPath '<attached-html-or-folder>'
```

## Page-root fallback

When the replay is already organized around one page root instead of the
attached-pages launcher inputs, keep using the direct Python sidecar audit for
now:

```powershell
python '<repo-root>\tmp-browser-smoke\attached-pages\attached_pages_sidecar_audit.py' --root '<page-root>'
```

Use that fallback only until `start_attached_pages_catalog.ps1` grows a
page-root mode. For ordinary attached-page replay, the wrapper-backed command
above is the preferred route.

## Degraded mode

If missing sidecars are already understood and the replay still needs a
best-effort run, allow that explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_sidecar_audit.ps1 -AllowMissingSidecars
```

## Companion helpers

Keep these nearby when the sidecar audit is only the first step:

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `scripts/windows/show_google_attached_html_validation_flow.ps1`
- `scripts/windows/check_google_attached_html_validation_surface.ps1`
- `scripts/windows/check_attached_html_local_asset_closure.ps1`
