# Attached Pages Server Self-Check

Use this note when headed-mode work depends on the attached-pages localhost
catalog under `tmp-browser-smoke/attached-pages/` and you want a short repeatable
check before opening the browser.

The matching helper script is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_server_self_check.ps1
```

## Goal

Keep the attached-pages harness honest before a manual headed replay by checking:

- the Python files still parse
- the focused harness test still passes
- the current bundle still produces the expected manifest
- the current bundle still reports missing local assets before launch
- the localhost catalog can be started with one stable command

## Default Route

When the current workspace already carries the attached HTML bundle under
`agent_files/`, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_server_self_check.ps1
python -m py_compile .\tmp-browser-smoke\attached-pages\attached_pages_server.py .\tmp-browser-smoke\attached-pages\test_attached_pages_server.py
python .\tmp-browser-smoke\attached-pages\test_attached_pages_server.py
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root .\agent_files --print-manifest
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root .\agent_files --audit-assets
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root .\agent_files --port 8235
```

Use this route when you want the generated catalog and short `/pages/...` routes
for the current attached HTML files without hand-typing a long exported filename.

## Pinned Bundle Route

When the replay should stay pinned to the known issue `#3` compatibility set,
pass the exact saved exports instead of relying on every `.html` file under the
folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_server_self_check.ps1 `
  -InputPath ".\agent_files\Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html", `
             ".\agent_files\Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html", `
             ".\agent_files\Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html"
```

That helper prints the same syntax-check, focused-test, manifest, asset-audit,
and localhost-start commands with the resolved `--input` list already locked in.

## Explicit Page Root

When the bundle lives somewhere else, point the helper at the folder or saved
page root directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_server_self_check.ps1 `
  -PageRoot C:\path\to\saved-html `
  -Port 8235
```

Use this route when the replay is working from a prepared saved-page directory
outside the default workspace attachments.

## Allow-Missing Audit

If you need a best-effort replay after confirming that some sidecar assets are
already missing, keep that fact visible in logs and use:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root .\agent_files --audit-assets --allow-missing-assets
```

Use this only when the missing local assets are already understood and you still
want the short-route localhost catalog for a narrower headed compatibility pass.

## Companion References

Keep these nearby when the attached-pages server is part of a broader headed
validation flow:

- `tmp-browser-smoke/attached-pages/README.md`
- `docs/HEADED_ATTACHED_HTML_VALIDATION.md`
- `tmp-browser-smoke/manual-user/README.md`
- `scripts/windows/show_google_attached_html_validation_flow.ps1`
