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
| Saved or attached localhost HTML replay | `local-html-fixtures`, `attached-html-target-bundle`, or `google-attached-html` | `manual-user`, `run_localhost_html_validation_recommended.ps1` |

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

1. Print the current issue `#3` routing set and full reusable ladder.

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

2. Fail fast on the reduced localhost Google-style suite.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_investigation_next_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_investigation_next_validation_flow.ps1
```

3. Run the smallest real-surface title and reduced-home gates.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile title
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1
```

4. Move into the saved homepage fixture and later submit-path slices.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile homepage-fixture
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile submit-path
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1
```

If the saved homepage fixture is already green and you only need the narrower
keydown, keypress, and submit-order slice before the shared Enter-order ladder,
use `show_google_submit_timing_validation_flow.ps1` or
`run_google_submit_timing_validation.ps1` inside this later submit-path phase
instead of jumping back to the earlier title gates.

5. Finish with the dedicated shared Enter-order gate before the broader shared
   ladder.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1
```

6. Use the saved recommended-runner helper chain before widening back out.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_probe_triage.ps1
```

Treat that helper chain as the bounded handoff state for the next Windows replay:

- read the saved summary guide first when you need the initial phase boundary from a fresh recommended-validation replay
- use the manifest, artifact-bundle, refresh-status, and handoff helpers to confirm the saved JSON pointers still match the current summary before rerunning a narrower stage
- if `show_google_issue3_validation_refresh_status.ps1` reports `status = ready` and `handoff_ready = True`, open the handoff helper next and follow its `next_artifact_to_open` path instead of widening back out
- if the refresh-status helper says it is using manifest-backed refresh or handoff pointers for the current summary, treat the missing summary-side pointer fields as follow-up cleanup instead of a reason to restart a broader replay
- if the refresh-status, artifact-bundle, or handoff helper says the chain is stale, missing, or still using an untrusted fallback pointer, run `refresh_google_issue3_validation_handoff_chain.ps1`, reopen the saved handoff JSON, and only then rerun the narrower step it names

7. Only after the bounded gates are green and the saved helper chain agrees,
   use the live-trace and attached or saved-page follow-ups.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle -Wait
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

If you want one command that auto-selects the pinned bundle route when the
current inputs match it, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle -Wait
```

Use the `-GoogleStyle` form when the next attached-page pass should prefer the
Google-like page first and stay on the issue `#3` bounded ladder before the
manual headed replay.

## Minimal widening rule

Use this order whenever a gate fails:

1. Re-run the matching surface checker.
2. Re-read the suite flow helper.
3. Re-open the saved issue-specific summary, bundle, refresh, or handoff artifact when that ladder now persists a bounded helper chain.
4. Run the smallest wrapper again.
5. Widen to the neighboring shared suite only if the failure crosses that
   boundary.

Examples:

- `form-controls` failure that only affects wrapped later-row controls: widen to
  `inline-flow`.
- `google-home` failure that only appears after the saved homepage fixture:
  widen to `google-homepage-fixture`, not straight to live trace.
- issue `#3` helper-chain mismatch where the saved refresh or handoff artifact no longer matches the current summary: run `refresh_google_issue3_validation_handoff_chain.ps1`, reopen the saved handoff JSON, then choose the narrower replay from there.
- attached HTML bundle failure on just one page script path: keep the bundle
  runner, then widen to `manual-user` only after the pinned bundle route is
  understood.

## Done signal

A validation slice is ready to hand off when all of these are true:

- the first bounded suite is green
- the next neighboring suite is either green or clearly not needed
- the chosen flow helper still matches the scripts present on the branch
- any later manual or real-site step has an explicit bounded gate in front of it
