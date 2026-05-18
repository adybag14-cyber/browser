# Issue #3 Attached Pages Sidecar-Audit Launcher

Use this note when the current issue `#3` replay may be failing before the browser ever gets a fair shot because one or more saved attached HTML exports are missing their sibling `_files` sidecar bundle.

This note is the read-first companion for the cross-platform launcher mode in:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --audit-sidecars
```

## Goal

Answer the simplest attached-page question first:

- is the current saved export missing its whole sibling `_files` directory?

Use this launcher-backed audit before widening into the deeper local asset crawl, the Google-shaped attached-page flow, the replay-side attached-page quickstarts, or the broader headed-runtime debugging path.

## Why this exists

The broader attached-pages asset audit can report many missing local files, but the practical first split for issue `#3` replay is smaller:

- missing sidecar bundle in the saved export
- broader asset drift inside an otherwise present sidecar bundle
- probable browser-side replay problem

This launcher mode keeps that first split on one small cross-platform command surface.

## Default command

Use this when the launcher should auto-discover the current attached HTML inputs from the repo or workspace:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --audit-sidecars
```

Use that route when:
- the replay is still working from the current attached pages rather than a hand-picked saved-page set
- you want the audit to stop early if a whole sibling `_files` bundle is missing
- you want the same launcher surface future Linux and Windows runs can share

## Google-style command

Use this when one Google-like page should stay first while the audit still checks the whole current attached-page set:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --google-style --audit-sidecars
```

Use that route when the next replay is already leaning toward the Google-shaped attached-page branch and you want the same launcher to keep the strongest Google-like fixture first while it audits sidecar bundles.

## Explicit inputs

Use this when the replay is already pinned to a specific file, folder, or known bundle path:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --input '<attached-html-or-folder>' --audit-sidecars
```

Use repeated `--input` values when the replay is already pinned to the known three-page compatibility set.

## Repo-root preserving form

Use this when the replay is running from a non-default checkout:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --repo-root '<repo-root>' --input '<attached-html-or-folder>' --audit-sidecars
```

Use that form when `LIGHTPANDA_REPO_ROOT` or the current working tree location already matters for the surrounding replay helpers.

## Allow-missing mode

Use this only when the sidecar gap is already understood and the next run still needs a best-effort replay signal:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --audit-sidecars --allow-missing-sidecars
```

Treat this as a degraded path. It is for continuing deliberately after the sidecar problem is already known, not for hiding it.

## JSON output

Use this when another helper, wrapper, or future scheduled run needs a structured answer instead of plain text:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --audit-sidecars-json
```

Pair it with explicit inputs or `--repo-root` when the replay context is already pinned.

## What to do next

If the launcher reports missing sidecars:
- fix or replace the saved export first
- keep headed-runtime conclusions narrow until the export itself is complete
- reopen the broader asset-closure audit only after the sidecar bundle exists

If the launcher passes:
- move to `check_attached_html_local_asset_closure.ps1` when strict local asset coverage still matters
- move to `show_attached_html_validation_flow.ps1` when the replay should stay on the broader attached-page route
- move to `show_google_attached_html_validation_flow.ps1` when the replay is already leaning Google-shaped
- move to `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` or `show_google_issue3_attached_bundle_first_entrypoint.ps1` when the replay is already pinned to the known three-page compatibility set

## Keep Nearby

Keep these notes nearby when you want the launcher audit in the same written route as the broader issue `#3` helper chain:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`

## Practical rule

When attached localhost replay starts looking suspicious, use the sidecar-audit launcher before blaming the browser. If it shows a missing sibling `_files` bundle, treat that as the first blocker. If it passes, then widen into the deeper asset audit, the broader attached-page flow, the Google-shaped attached-page flow, or the pinned bundle route according to the current replay branch.