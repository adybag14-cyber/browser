# Issue #3 Bare Local HTML Startup Workaround

Use this note when issue #3 replay needs to launch a saved local HTML or XHTML page directly in headed mode, but the current startup diagnostics still risk classifying a bare filename such as `attached-page.html` as an implicit remote host.

## Why this exists

The current `src/main.zig` startup classifier still treats some dotted bare local filenames as if they were scheme-less remote hosts before the later local-path fallback runs.

Affected examples include:

- `attached-page.html`
- `attached-page.html?case=1`
- `attached-page.xhtml#focus-probe`
- `report.v1.html`
- `report.v1.xhtml#focus-probe`

That means the direct launch can still print remote-style target diagnostics even when the intent was to open a local saved page.

## Safe launch shapes right now

Prefer one of these forms until the classifier fix lands:

1. A relative path that includes a slash:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed .\user_files\attached-page.html
.\zig-out\bin\lightpanda.exe browse --browser_mode headed .\agent_files\report.v1.xhtml
```

2. A `file://` URL:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed file:///C:/work/browser/user_files/attached-page.html
```

3. The existing localhost replay route from the current branch helpers:

```powershell
python -m http.server 8139 --bind 127.0.0.1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8139/attached-page.html
```

## Avoid for direct local launch

Avoid these forms when you want trustworthy startup diagnostics for a saved page:

- `attached-page.html`
- `attached-page.xhtml#focus-probe`
- `report.v1.html`
- `report.v1.xhtml#focus-probe`

They can still be misreported as implicit remote targets on the current branch.

## Recommended issue #3 route

For the current three-page attached compatibility bundle, prefer the branch's existing localhost-first helpers instead of bare filenames:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use the slash-based or `file://` launch forms only when the replay needs a quick direct headed open before the fuller localhost helper chain is reopened.

## Companion notes

Keep these nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `tmp-browser-smoke/attached-pages/README.md`
