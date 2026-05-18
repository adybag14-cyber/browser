# Issue #3 Google Attached HTML Wrapper Sidecar Preflight

Use this note when the next headed localhost replay is already on the
Google-shaped attached-page lane and you want the smallest wrapper-backed
preflight surface available before reopening the broader helper chain.

This note matches:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_wrapper_sidecar_preflight.ps1
```

Use that helper when you want one short command surface that:

- runs the Windows wrapper-backed Google-style sidecar audit before the broader
  attached-page flow helper
- keeps the wrapper-backed manifest print and strict launch nearby
- preserves `-RepoRoot` and `-InputPath` context when the replay is already
  pinned to a non-default checkout or explicit attached bundle paths
- keeps the lower-level Python launcher visible only as a fallback when the
  wrapper itself needs to be bypassed intentionally

Keep these companion surfaces nearby:

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `scripts/windows/check_google_attached_html_wrapper_sidecar_preflight_validation_surface.ps1`
- `scripts/windows/show_google_attached_html_validation_flow.ps1`
- `scripts/windows/start_attached_pages_catalog.ps1`
- `tmp-browser-smoke/attached-pages/README.md`
- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`

## Goal

Start with the compact preflight checker, rerun the wrapper-backed Google-style
sidecar audit first, print the manifest when you need to confirm which attached
pages the wrapper will serve, use the strict launch only after the sidecar
bundle is complete enough that missing sibling `_files` directories should stop
the route immediately, then widen back into
`show_google_attached_html_validation_flow.ps1` when the broader attached-page
surface still needs to stay visible.

## Surface check

Run this first when the compact note, helper output, or nearby launcher paths
may have drifted:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_wrapper_sidecar_preflight_validation_surface.ps1
```

Use that check when:

- the next replay depends on this compact wrapper-backed ladder being intact
- the branch recently gained nearby attached-page helper changes and you want a
  smaller fail-fast guard before trusting the preflight
- the broader Google attached-page flow is still available, but you want the
  cheaper wrapper-backed preflight reopened first

## Default read-first route

Use this route when no explicit bundle inputs or non-default repo root need to
take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_wrapper_sidecar_preflight_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_wrapper_sidecar_preflight.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use that route when:

- the current attached-page set is already Google-shaped
- you want the wrapper-backed sidecar audit reopened before the broader helper
  surface takes over
- a quick manifest print would help confirm the launch order before moving on
- the route is still early enough that missing sidecars are a more likely cause
  than a deeper headed-browser regression

## Preserve replay context

If the replay already carries a non-default repo root or pinned attached-page
inputs, keep that same context attached to the compact preflight surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_wrapper_sidecar_preflight_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_wrapper_sidecar_preflight.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -GoogleStyle -RequireCompleteSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- explicit attached-page inputs are already pinned to the current replay
- the route should fail fast on the wrapper-backed sidecar audit before the
  broader Google attached-page flow is reopened

## Lower-level fallback

Use the raw Python launcher directly only when you need to bypass the wrapper
while keeping the same Google-style sidecar-first intent:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --repo-root '<repo-root>' --input '<bundle-html-or-folder>' --google-style --audit-sidecars
```

Use that fallback when the wrapper itself is the thing under suspicion and the
route still needs the same lower-level launcher context preserved.

## Pick the next helper quickly

1. `show_google_attached_html_validation_flow.ps1`

Use this when the wrapper-backed sidecar audit is already settled and you want
the broader Google attached-page helper surface reprinted before the route
widens further.

2. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -PrintManifest`

Use this when you want to confirm the wrapper-backed launch order before a
strict localhost start.

3. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -RequireCompleteSidecars`

Use this when the sidecar audit is clean enough that missing sibling `_files`
bundles should stop the route immediately.

4. `python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --google-style --audit-sidecars`

Use this only when the wrapper itself needs to be bypassed deliberately while
keeping the same Google-style attached-page preflight intent.

## Practical rule

When the attached localhost replay is already clearly on the Google-shaped
branch, rerun
`check_google_attached_html_wrapper_sidecar_preflight_validation_surface.ps1`,
then reopen `show_google_attached_html_wrapper_sidecar_preflight.ps1`, then run
`start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars` before the
broader `show_google_attached_html_validation_flow.ps1` helper. Only widen
further once the wrapper-backed sidecar audit is clean enough that a deeper
headed-browser diagnosis is worth the time.
