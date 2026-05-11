# Headed Mode Validation Gates

This is the quick-route map for choosing the first bounded headed validation
step after a change on `fork/headed-mode-foundation`.

Use it together with:

- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `scripts/windows/show_headed_validation_suites.ps1`
- the suite-specific flow helpers under `scripts/windows/`

The goal is simple: pick the smallest real validation family first, prove that
surface, then widen only when the change crosses into a shared behavior area.

## Core rule

Start with one bounded suite that matches the code you changed.
Only widen to the neighboring suite family after the first gate is green or the
symptom clearly spans both surfaces.

Use the shared router first when you are not sure where a change belongs:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -List
```

## Quick routing table

| Change area | First gate | Add next when needed |
| --- | --- | --- |
| Shell, browser pages, tabs, startup restore | `tabs` or `browser-pages` | `settings`, `stop-loading` |
| Layout, visual placement, screenshots, clipping | `layout-smoke` | `flow-layout`, `rendered-link-dom` |
| Wrapped inline controls, focus travel, mixed submit behavior | `inline-flow` | `form-controls`, `layout-smoke` |
| Text entry, label click, Enter submit, caret, keyboard behavior | `form-controls` | `inline-flow`, `find` |
| Fonts, text metrics, authored font fallback | `font-render` | `font-smoke`, `zoom` |
| Images, stylesheets, script/module request policy | `image-smoke` or `stylesheet-smoke` | the sibling request-policy suite |
| Canvas or WebGL | `canvas-smoke` | `layout-smoke` |
| Downloads or file upload | `downloads` or `file-upload` | `attachment-downloads`, `browser-pages` |
| Cookies, localStorage, IndexedDB, session scope | matching persistence suite | `tabs`, `browser-pages` |
| Fetch abort, credentials, WebSocket runtime | matching network suite | the sibling network suite |
| Saved or attached localhost HTML replay | `local-html-fixtures` or `attached-html-target-bundle` | `manual-user` |

When you already know the broad area, print the router recommendation directly:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

## Issue #3 gate ladder

Issue `#3` is the headed Windows Google input and submit reliability track.
Do not jump straight from localhost probes to a manual Google homepage retest.
Use the bounded gates in this order.

1. Print the current issue `#3` routing set.

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
```

2. Fail fast on the reduced localhost Google-style suite.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_investigation_next_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_investigation_next_validation_flow.ps1
```

3. Run the smallest real-surface title and reduced-home gates.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1
```

4. Move into the saved homepage fixture and submit-timing slices.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1
```

5. Finish with the smallest shared Enter-order gate before the broader shared
   ladder.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1
```

6. Only after the bounded gates are green, use the live-trace and manual follow
   ups.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Read this focused note when the issue `#3` ladder has already been narrowed to
just the quick and reduced-home stage:

- `docs/GOOGLE_QUICK_AND_REDUCED_HOME_VALIDATION.md`

## Attached HTML bundle gate

When the current task is specifically about the saved three-page attached HTML
compatibility bundle, use the bundle-aware path instead of the broader attached
HTML helper first.

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

If the current pages are not the known three-page bundle, fall back to the more
open-ended attached-page flow:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
```

## Minimal widening rule

Use this order whenever a gate fails:

1. Re-run the matching surface checker.
2. Re-read the suite flow helper.
3. Run the smallest wrapper again.
4. Widen to the neighboring shared suite only if the failure crosses that
   boundary.

Examples:

- `form-controls` failure that only affects wrapped later-row controls: widen to
  `inline-flow`.
- `google-home` failure that only appears after the saved homepage fixture:
  widen to `google-homepage-fixture`, not straight to live trace.
- attached HTML bundle failure on just one page script path: keep the bundle
  runner, then widen to `manual-user` only after the pinned bundle route is
  understood.

## Done signal

A validation slice is ready to hand off when all of these are true:

- the first bounded suite is green
- the next neighboring suite is either green or clearly not needed
- the chosen flow helper still matches the scripts present on the branch
- any later manual or real-site step has an explicit bounded gate in front of it
