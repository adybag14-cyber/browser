# Issue #3 Current Attached Compatibility Bundle

Use this note when the next Windows headed replay should stay pinned to the
current three attached compatibility pages without retyping those paths by
hand.

The matching helper script is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_current_attached_bundle.ps1
```

That helper auto-resolves this pinned bundle from the current workspace when
all three files are present together:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

It prints:

- the detected bundle root
- the preferred Google-like starting page
- the compact `attached-html-target-bundle` router command
- the bundle-suite surface helper
- the bundle-first helper
- the pinned bundle flow and runner commands
- the broader Google attached-page flow command for side-by-side comparison

## Default route

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_current_attached_bundle.ps1
```

Use this when the current replay is already supposed to stay on the known
three-page compatibility bundle and you want the exact `-InputPath` reused
across the existing issue `#3` helpers.

## Preserve repo or binary overrides

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_current_attached_bundle.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -SummaryPath '<saved-summary-path>'
```

Use this when the replay already carries a non-default checkout, a non-default
headed binary, or a saved summary path that should stay attached to the printed
commands.

## If the bundle is not under the usual workspace roots

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_current_attached_bundle.ps1 -SearchRoot '<folder-containing-the-three-html-files>'
```

Use `-SearchRoot` when the current attached-page bundle lives outside the usual
workspace roots such as the repo root, its parent, or a sibling `agent_files`
folder.

## Follow-up helpers

After this helper prints the pinned bundle paths, the most direct next commands
are:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -InputPath '<bundle-root>' -Wait
```

Keep `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` nearby when the
replay still needs the broader Google-shaped attached-page route visible before
the pinned bundle runner takes over.
