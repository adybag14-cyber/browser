# Issue #3 Attached HTML Asset Audit

Use this note when the headed localhost replay is already narrowed to the
attached-page compatibility bundle and you want one short, explicit checkpoint
for missing sidecar assets before you spend time reading a replay failure as a
browser regression.

## Why this exists

The branch already has two different asset-closure paths:

- `scripts/windows/check_attached_html_local_asset_closure.ps1` for the
  Windows-first helper flow
- `tmp-browser-smoke/attached-pages/attached_pages_server.py --audit-assets`
  for a shell-agnostic Python audit

Both routes recursively inspect local HTML, CSS, and module-script references.
They are meant to catch missing sibling assets before a headed replay launches.

## Current known degraded bundle state

The current three-page compatibility bundle is still usable for replay, but one
page is known to be incomplete as an export bundle:

- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

At the time this note was written, the saved bundle was missing the page's
expected sibling `_files` asset directory and the recursive audit reported `69`
missing local assets.

Treat that result as a bundle-quality warning first, not immediate proof of a
headed runtime regression.

## Read-first commands

Use the bundle route first when the known three-page compatibility set is still
the active input set:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_asset_audit.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --input '<bundle-html-or-folder>' --audit-assets
```

If both audits are clean, continue into the broader bundle replay helpers.

## Degraded-mode rule

Only allow degraded replay when the missing assets are already understood and
the goal is to keep the localhost path moving while preserving a truthful note
about bundle completeness.

Use these escape hatches deliberately:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle -AllowMissingAssets
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --input '<bundle-html-or-folder>' --audit-assets --allow-missing-assets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -AllowMissingLocalAssets -Wait
```

## Practical rule

If the audit fails only on the known incomplete UAP export, keep the failure
attached to the bundle-quality lane and note that the headed replay may be
visually degraded for reasons outside the runtime. If the audit is clean and the
headed replay still breaks, route the follow-up back into the shared input,
rendering, or navigation subsystem that actually failed.
