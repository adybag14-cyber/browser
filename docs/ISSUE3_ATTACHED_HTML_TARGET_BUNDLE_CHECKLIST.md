# Issue #3 Attached HTML Target Bundle Checklist

Use this note when issue `#3` follow-up is already narrowed to the saved attached HTML compatibility bundle and you want the smallest practical manual checklist before widening back into broader headed debugging.

Start with the pinned bundle route first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Keep `docs/HEADED_MODE_VALIDATION_GATES.md`, `docs/WINDOWS_FULL_USE.md`, and `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` nearby when you need the broader route context around this checklist.

## Page checks

### Google Safety Centre

Target file:
- `Control your online safety and privacy – Google Safety Centre (...).html`

Manual checks:
- the page stays visibly nonblank after load and after the first scroll
- cookie or consent controls remain clickable when present
- long-form scrolling stays smooth enough to reach deeper sections without the surface going blank
- SVG-heavy sections, media containers, and large cards stay painted instead of collapsing to empty regions
- obvious top-of-page interactive controls still react to pointer input

### Anthropic application

Target file:
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (...).html`

Manual checks:
- text inputs take focus and keep typed text visible after the first click
- focus stays on the active field while moving through longer form sections
- comboboxes or dropdown-style controls open and remain usable
- scrolling deeper into the form does not break later input fields
- the primary application flow remains reachable without losing interactivity in the form body

### Department of War UAP page

Target file:
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Manual checks:
- the page stays painted after load, especially around the header and search affordance
- the search affordance expands or focuses correctly
- typed text remains visible in the search field
- the submit control or search action reacts to pointer or keyboard activation
- large navigation or menu hit targets stay clickable instead of drifting away from the visible surface

## Failure routing

Route follow-up by the shared subsystem that broke:

- blank, missing, or collapsing sections usually belong to rendering and DOM compatibility
- lost focus, swallowed typing, or non-working submit behavior usually belongs to input, focus, and interaction delivery
- broken menus, incorrect hit targets, or pointer mismatch usually belong to rendering or page-lifecycle interaction boundaries
- asset holes across more than one page usually belong to shared resource loading instead of one saved page

Do not special-case one page if the same headed subsystem would explain failures across the other two pages.

## Evidence to keep

When a manual pass fails, preserve:
- the exact target page name
- whether the failure happened on first load, after scroll, or after interaction
- whether the same symptom appears on the other saved pages
- the smallest validation helper that still reproduces the failure

That evidence is usually enough to decide whether the next run should stay on the bundle route, widen into the attached-page helper chain, or jump back to the narrower shared input or rendering gates first.
