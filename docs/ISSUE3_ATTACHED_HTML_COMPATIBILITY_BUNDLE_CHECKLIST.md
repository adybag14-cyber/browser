# Issue #3 Attached HTML Compatibility Bundle Checklist

Use this note when the next headed replay should stay pinned to the known
three-page localhost compatibility bundle instead of widening immediately into
the longer attached-page helper chain.

The matching helper script is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_bundle_checklist.ps1
```

## Goal

Keep one compact, honest route for:

- bundle preflight
- validation-router re-entry
- page-by-page compatibility proof
- deciding when to escalate back to a narrower runtime bug

## Pinned Bundle

Keep this exact file set together:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Prefer the Google Safety Centre export as the initial page when the replay
should keep one Google-like page first while still staying on the same pinned
bundle.

## Compact Route

Run these in order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<bundle-html-or-folder>" -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<bundle-html-or-folder>" -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<bundle-html-or-folder>" -RequireCompleteSidecars -RequireCompleteAssets -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath "<bundle-html-or-folder>" -PreferredInitialPage "<preferred-page>"
```

Use this route on purpose:

1. The surface check proves the replay quickstart entrypoint still matches the
   current branch.
2. `-AuditSidecars` catches missing sibling `_files` bundles before browser
   debugging starts.
3. `-AuditAssets` catches local export drift before browser debugging starts.
4. The strict manifest step proves the exact same inputs are closed enough to
   blame the browser if the replay still fails.
5. The two router commands keep the bundle-specific and Google-shaped routes
   visible before the replay narrows again.

If the sidecar or asset checks fail, treat that as an attached-export problem
first, not a headed-browser regression.

## Page-by-Page Proof Loop

Run the actual headed replay in this order and stop on the first failing page:

1. Google Safety Centre

Confirm the page title resolves, the cookie bar renders, `Agree` and
`No thanks` both activate, and one top navigation target such as `Safer by
design` or `Product protections` can be focused or opened without freezing the
page.

2. Anthropic application

Confirm the application form loads, one select-style field such as `Gender`
opens and closes, and `Submit application` stays reachable after scrolling.

3. UAP page

Confirm the title renders, the search input accepts focus and typed text, one
`record-row` opens the detail modal, `Close` returns to the list, and
pagination advances without crashing the headed session.

This order matters. If the Google-shaped page fails first, keep the next fix
narrow. If the first page passes, the second and third pages separate broader
combobox, modal, and pagination gaps from the original text-entry boundary.

## Escalation Rules

Use the `rendering` route first when the current change touched layout, paint,
screenshot timing, or other visible headed-surface behavior.

Use the `network` route first when the current change touched authenticated
stylesheets, fetch credentials, or shared subresource loading.

Reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` when:

- the sidecar and asset checks pass
- the strict manifest stays green
- the Google-shaped page still narrows the failure back to focused text entry
  or Enter submit timing

That runtime note is the correct re-entry point for the `Page.zig` plus
`win32_backend.zig` slice. Do not widen back into a generic attached-page
rewrite before checking that narrower runtime note.

## Companion Notes

Keep these nearby:

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
