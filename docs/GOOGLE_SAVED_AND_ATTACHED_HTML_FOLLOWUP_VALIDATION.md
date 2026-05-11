# Google Saved And Attached HTML Follow-Up Validation

Use this note when issue `#3` has already cleared its bounded localhost, title,
reduced-homepage, submit-timing, and shared Enter-order gates and the next step
is comparing the browser against saved Google-like pages or the current
attached-page bundle.

This is a follow-up checkpoint, not a replacement for the earlier localhost
ladder.

## Goal

Fail fast before a later rerun burns time on the wrong follow-up surface.

The main command is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_saved_and_attached_html_validation_surface.ps1
```

That checker confirms all three follow-up routes still exist and still point to
real files:

- the Google-style attached HTML helper chain
- the known three-page attached HTML target-bundle route
- the reusable fixed-list saved-page fixture replay path

## Recommended order

1. Keep the issue `#3` run localhost-first.
2. Use the new follow-up checker only after the earlier bounded gates are green.
3. If the current HTML pages are the known three-page compatibility bundle, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

4. If the current HTML pages are attached Google-like pages from the current
run, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

5. If the next step is a saved export or a fixed local fixture replay, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 -FixturePaths '<saved-html-or-folder>'
```

## Working rule

Use the smallest follow-up route that matches the pages in hand.
Do not jump from the early localhost Google ladder straight to a broad manual
replay when one of the pinned attached or saved-page routes can narrow the next
failure first.
