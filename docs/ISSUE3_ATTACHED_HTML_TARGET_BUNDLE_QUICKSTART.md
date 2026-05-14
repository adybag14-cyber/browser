# Issue #3 Attached HTML Target Bundle Quickstart

Use this note when the next headed localhost replay should stay pinned to the known three-page compatibility bundle instead of widening immediately into the broader attached-page helper chain.

Keep these companion notes nearby:
- `docs/HEADED_MODE_VALIDATION_GATES.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`

## Known bundle

Treat the current pinned attached-HTML compatibility bundle as these saved pages under `agent_files/`:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

The bundle checker already knows these targets by intent:
- Google-branded content-heavy page
- form-heavy Anthropic application page
- dense document and script-heavy UAP page

## Default read-first route

Use this compact route when the current replay should stay on the pinned three-page bundle from the first attached-HTML gate onward:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:
- the current input set is exactly the known three-page compatibility bundle
- you want the helper chain to fail fast before launch if a guide, checker, helper, or delegated runner drifted
- you want the same locked input paths carried through the flow helper and the localhost runner

## Context-preserving variants

If the replay is running from a non-default checkout, from explicit saved-page paths, or from a staged bundle outside the default search roots, keep that context attached from the start:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1 -RepoRoot '<repo-root>' -InputPath '<page-1>' '<page-2>' '<page-3>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<page-1>' '<page-2>' '<page-3>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<page-1>' '<page-2>' '<page-3>' -Wait
```

Use that route when:
- `LIGHTPANDA_REPO_ROOT` should stay aligned with a non-default working tree
- the bundle has already been copied to an alternate location
- you want the printed flow and the delegated runner to reuse the same explicit paths without rediscovery

## What the bundle route already does

The existing helpers already provide these pieces:
- `check_attached_html_target_bundle_validation_surface.ps1` verifies the guide, router, checker, helper, runner, and delegated attached-HTML surfaces still exist before you trust the pinned route.
- `check_attached_html_target_bundle.ps1` resolves the known three targets, prints the recommended first bounded step for each page, and keeps the Google Safety Centre page first when the Google-style route should stay aligned with issue `#3`.
- `show_attached_html_target_bundle_validation_flow.ps1` prints the exact bundle-pinned command ladder, including the deep asset-closure check and the delegated runner.
- `run_attached_html_target_bundle_validation.ps1` launches the bundle through the correct attached-page runner after the earlier checks are green.

## When to widen

Stay on the bundle route when the current pages are still the known three-page compatibility set.

Widen only when one of these is true:
- the current saved-page set is not the known three-page bundle: use `show_headed_validation_suites.ps1 -ChangeArea attached-html`
- the next replay should stay explicitly Google-shaped first: use `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`
- the broader Windows runbook has already narrowed the route for you: reopen `docs/WINDOWS_FULL_USE.md` and `show_google_issue3_windows_full_use_attached_html_route.ps1`
- the replay has already narrowed into the shorter issue `#3` attached-page chain: reopen `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md` or `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`

## Practical rule

If the next local headed compatibility pass is specifically about the three attached pages currently living under `agent_files/`, start with the bundle-aware route above instead of the broader attached-page helpers. That keeps the exact targets, the preferred first page, and the localhost replay commands pinned together from the first check through the actual run.
