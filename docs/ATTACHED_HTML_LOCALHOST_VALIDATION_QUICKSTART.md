# Attached HTML Localhost Validation Quickstart

Use this note when the next headed validation pass is centered on saved or attached localhost HTML pages and you want the shortest stable route before widening into the larger issue-specific helper chain.

Keep these references nearby:

- `docs/HEADED_MODE_VALIDATION_GATES.md`
- `tmp-browser-smoke/README.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`

## Known three-page compatibility bundle

Use this first when the current input is still the pinned three-page compatibility bundle.

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/windows/show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File ./scripts/windows/check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/windows/show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/windows/run_attached_html_target_bundle_validation.ps1 -Wait
```

Stay on this bundle-first path when only one page in the known three-page set is failing and you still want the locked input set preserved all the way through the bounded localhost runner.

## Reusable fixed-list localhost replay

Use this route when you already have a fixed set of exported pages and you want screenshot-plus-title proof before the broader attached-page helpers.

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/windows/check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1 -FixturePaths '<html-path-1>','<html-path-2>','<html-path-3>'
```

Use the direct fixture probe when the replay inputs are already known and you do not need the helper chain to rediscover attached files under `agent_files/`.

## Auto-routed attached or saved pages

Use the shared runner when the next replay should auto-pick the attached or saved localhost route for the current inputs.

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/windows/run_localhost_html_validation_recommended.ps1 -Wait
```

Use this path when the input set is no longer the pinned three-page bundle or when you want the shared helper chain to choose between attached-page discovery and saved-page replay for you.

## Google-style attached-page follow-up for issue #3

When the next pass is part of the Google search-box issue `#3` ladder, keep the bounded attached-page route in front of the broader manual replay.

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/windows/show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File ./scripts/windows/check_google_validation_surface.ps1 -Profile attached-html
powershell -ExecutionPolicy Bypass -File ./scripts/windows/show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/windows/run_localhost_html_validation_recommended.ps1 -GoogleStyle -Wait
```

Use this route when the attached localhost pass needs to stay on the issue `#3` bounded ladder before widening into the saved-page Google follow-up or the live homepage investigation.

## When to widen

1. Keep the bundle-first route if the failure is still isolated to the known three-page compatibility set.
2. Move to `run_localhost_html_validation_recommended.ps1` when the inputs are broader than the pinned bundle or need auto-discovery.
3. Reopen the issue `#3` route notes only after the bounded localhost pass is green and the next question is saved-page or live-site follow-up.