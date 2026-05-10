# Saved Page Local Asset Checks

Use `scripts/windows/check_saved_page_local_assets.ps1` before a headed localhost
compatibility pass when the saved-page bundle may be incomplete.

This helper scans `.html` and `.htm` files for relative `src=` and `href=`
references and reports which local files or folders are missing next to the
saved page.

## Why this matters

Some saved snapshots are only partial captures. A localhost run can still be
useful for focused input or shell checks, but missing sibling assets can make a
page look broken for reasons that are not browser regressions.

Use the helper to separate:

- genuine headed-mode compatibility failures
- incomplete saved-page bundles with missing CSS, scripts, images, or sibling
  asset folders

## Basic usage

Check one saved-page directory directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_saved_page_local_assets.ps1 `
  -PageRoot C:\path\to\saved-pages
```

Check a mixed input set before the staged localhost runner:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_saved_page_local_assets.ps1 `
  -InputPath C:\path\to\saved-page.html, C:\path\to\saved-folder
```

The helper writes a JSON summary under:

- `tmp-browser-smoke\manual-user\localhost-html-validation\`

## Reading the result

Treat pages with missing local references as partial snapshot validation only
until the missing files or folders are restored.

That means:

1. Keep using the closest bounded suite first.
2. Use the localhost saved-page pass for the parts of the page that are still
   meaningful.
3. Do not blame missing layout, missing scripts, or missing images on the
   browser until the saved bundle is complete.
