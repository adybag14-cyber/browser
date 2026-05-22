# Issue #3 Google Input Validation Flow

Use this note when the headed validation router has already narrowed the next run to the `google-input` change area and you want one read-first guide for the current shared-to-real-surface ladder.

Start with the router-backed surface first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
```

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_VALIDATION_MATRIX.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`

## Goal

Start from the smallest shared headed input probes, prove the Google-shaped Enter-submit checkpoint on the real headed surface, check live Google only after the shared ladder is green, and keep the attached-page follow-up route visible before the run widens back into broader replay.

## Default Ladder

Use this order when the current failure still looks like issue `#3` input, focus, typing, or Enter-submit drift:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
& ".\zig-out\bin\lightpanda.exe" browse --headed "https://www.google.com/"
```

Use the two bounded localhost probes first. They are the quickest way to prove the shared focus, typing, label activation, and Enter-submit path before you ask the real Google surface a harder question. Then run the dedicated Google form-controls Enter-order surface check and its flow so the shared keypress-before-submit contract is revalidated before the manual headed Google step.

Only widen into manual Google after the bounded probes and the dedicated Enter-order gate are green. At that point the remaining failure is much more likely to be specific to the real Google runtime path rather than the shared input ladder.

## Attached HTML Follow-Up

If live Google is still flaky, keep the saved-page route visible instead of jumping straight to broad replay:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this follow-up when the next step should stay on the issue `#3` attached-localhost ladder instead of reopening the whole replay family by hand.

When the replay is already pinned to the current three-page compatibility bundle, keep these exact files together from the start:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Prefer the Google Safety Centre export as the first page when you want one Google-like page to stay first while the same saved bundle remains locked through follow-up replay.

## What To Record

After running this ladder, keep a short note with:

- the first rung that failed
- whether the failure reproduced on shared localhost probes, the dedicated Enter-order gate, live Google, or only the attached-page follow-up
- whether the browser accepted typing but missed submit, missed typing entirely, or drifted focus after click
- whether the same behavior changed when the replay stayed on the pinned three-page bundle

That makes the next run much more likely to reopen the right lane without repeating the full issue history.
