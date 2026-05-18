# Attached Pages Offline Readiness

Use this helper when localhost headed-mode validation needs a quick answer to a
specific question before blaming the browser:

- is the saved bundle missing local sidecars?
- does the saved bundle still depend on the network?
- is the bundle self-contained enough for an honest offline localhost replay?

## Python helper

From the repo root:

```powershell
python .\tmp-browser-smoke\attached-pages\check_attached_pages_offline_readiness.py --root C:\path\to\saved-html
```

Or pin the exact replay bundle with repeated `--input` arguments:

```powershell
python .\tmp-browser-smoke\attached-pages\check_attached_pages_offline_readiness.py `
  --input ".\agent_files\Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html" `
  --input ".\agent_files\Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html" `
  --input ".\agent_files\Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html"
```

The command exits with:

- `0` when every selected fixture is self-contained for offline localhost replay
- `1` when any selected fixture is missing local assets or still depends on external network assets

Add `--json` when another helper needs structured output instead of the text summary.

## Windows wrapper

From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_pages_offline_readiness.ps1
```

Useful variants:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_pages_offline_readiness.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_pages_offline_readiness.ps1 -Json
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_pages_offline_readiness.ps1 -InputPath '.\agent_files\saved-page.html'
```

The wrapper reuses the same repo-root and attached-page auto-discovery rules as
other headed validation helpers, so the offline-readiness gate can run on the
same pinned bundle before a broader issue #3 replay.

## Status meanings

- `offline-ready`: the fixture has no missing local sidecars and no external network dependencies
- `missing-local-assets`: the fixture references missing local files
- `needs-network`: the fixture has all known local sidecars but still references external URLs
- `missing-local-assets-and-needs-network`: both local sidecars and external dependencies are still in play

Use this stricter gate when the ordinary asset audit is not enough because the
next replay should prove the localhost bundle can stand on its own without
quietly leaning on the network.
