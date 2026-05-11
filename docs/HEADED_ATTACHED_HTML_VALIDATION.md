# Headed Attached HTML Validation

This guide keeps attached localhost HTML follow-up in the same bounded order as
the headed Windows Google issue `#3` investigation.

Use it when a run already has saved or attached HTML pages and the next step is
to prove whether the current headed behavior matches those pages before moving
back to the full live-site pass.

## When To Use This Guide

Use this flow when all of these are true:

- the current task is about headed typing, focus, submit timing, or form
  behavior
- the run includes attached or saved HTML pages that should be replayed on
  localhost
- the matching bounded localhost suite is already the best next proof step

Do not start here for a fresh issue. First run the narrowest bounded suite for
the subsystem that changed.

## Known Compatibility Bundle

The current attached-page compatibility target bundle is the three-page set that
ships with this workspace context:

- `Control your online safety and privacy – Google Safety Centre`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic`
- `Presidential Unsealing and Reporting System for UAP Encounters`

Before you rely on an attached-page localhost pass as proof for those saved-page
targets, confirm the bundle is still discoverable:

- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1`

This checker verifies that all three known targets can still be found under the
attached HTML search roots and reports their current paths, page titles, and
shallow missing-asset counts. It does not replace the deeper asset-closure
check; it just makes sure the expected compatibility bundle is actually present
before the broader replay path starts.

## Issue #3 Order

For the Google search-box investigation, keep this order:

1. Run the current bounded issue `#3` ladder first:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1`
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1`
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1`
2. When the earlier title and reduced-homepage gates are already green and you
   only need the later saved-homepage-fixture, submit-timing, and shared
   Enter-order slices, jump to:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1`
3. Run the dedicated Google attached-page surface check and the deep local
   asset-closure audit, then print the attached-page flow so the next pass uses
   the same current-run input set:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1`
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle`
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1`
4. Run the dedicated Google attached-page localhost helper so the same attached
   set stays on the issue `#3` bounded order instead of falling back to the
   generic manual router:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait`
5. Only after the attached localhost pass is understood, move to the reduced
   trace or live Google follow-up.

The dedicated Google attached-page runner now reruns the deep asset-closure
check automatically for attached-file modes before launch. Keeping the explicit
command in the guide still makes missing nested CSS, JavaScript module, image,
and font assets obvious before the headed window starts.

## Generic Attached-Page Order

When the task is not specifically the Google homepage issue, keep this order:

1. Run the narrowest bounded suite for the changed subsystem.
2. Confirm the known target bundle or the intended attached-page set is present:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1`
3. Print the attached-page flow:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1`
4. Run the deep attached-page asset audit when saved files are part of the
   replay:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1`
5. Run the attached localhost helper:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1`
6. If a saved folder is being replayed instead of current-run attached files,
   use:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_saved_page_localhost_validation.ps1 -InputPath '<saved-html-or-folder>'`

## What To Capture

Keep these with the validation result:

- the exact helper or probe script name
- the HTML input source that was used
- the first visible failure or success marker
- any screenshot or page-title artifact produced by the helper

## Why This Exists

The branch already has strong bounded Google probes and shared validation
helpers. What tends to get lost is the handoff from those bounded probes into
the current-run attached HTML pages. This guide keeps that handoff short,
repeatable, and localhost-first.