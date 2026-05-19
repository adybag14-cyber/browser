# Windows Localhost Attached Pages Quickstart

Use this note when the next headed Windows replay should start from the repo's
own bundled localhost smoke pages instead of a larger saved export or the
heavier issue-specific attached-page helper ladder.

This route is intentionally small:

- `tmp-browser-smoke/page1.html`
- `tmp-browser-smoke/next.html`
- `tmp-browser-smoke/links.html`

Those three files give you:

- a click-through first page (`page1.html`)
- a trivial destination page (`next.html`)
- a bordered-box plus nested-link rendering page (`links.html`)

## Read-first helper

Print the compact command map from Windows with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_localhost_attached_pages_quickstart.ps1
```

Choose a different default launch page when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_localhost_attached_pages_quickstart.ps1 -PreferredInitialPage links
```

If the replay is running from a non-default checkout or a non-default headed
binary, keep that context attached:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_localhost_attached_pages_quickstart.ps1 -RepoRoot '<repo-root>' -BrowserExe '<lightpanda.exe>'
```

## Default route

Use this sequence when the bundled three-page set is the quickest honest headed
localhost checkpoint:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_windows_localhost_attached_pages_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '.\tmp-browser-smoke\page1.html' '.\tmp-browser-smoke\next.html' '.\tmp-browser-smoke\links.html' -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '.\tmp-browser-smoke\page1.html' '.\tmp-browser-smoke\next.html' '.\tmp-browser-smoke\links.html' -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '.\tmp-browser-smoke\page1.html' '.\tmp-browser-smoke\next.html' '.\tmp-browser-smoke\links.html' -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '.\tmp-browser-smoke\page1.html' '.\tmp-browser-smoke\next.html' '.\tmp-browser-smoke\links.html' -RequireCompleteSidecars -RequireCompleteAssets -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '.\tmp-browser-smoke\page1.html' '.\tmp-browser-smoke\next.html' '.\tmp-browser-smoke\links.html' -RequireCompleteSidecars -RequireCompleteAssets
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8235/page1.html
```

Use that route when:

- you want the shortest honest headed localhost check before widening into
  saved-export debugging
- the replay should prove simple navigation and link rendering first
- you want the attached-pages catalog wrapper to print or launch the exact
  localhost routes for the bundled set instead of assembling input paths by
  hand

## Which page to start with

Start with `page1.html` when you want the simplest first click-through route:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8235/page1.html
```

Start with `links.html` when you want the bordered box and nested headed link
surface first:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8235/links.html
```

Start with `next.html` only when you want the trivial second-page checkpoint:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8235/next.html
```

## When to widen beyond this route

Move from this quickstart into `docs/WINDOWS_FULL_USE.md` or the broader
attached-page issue notes only after one of these is true:

- the bundled three-page set is green and you need the heavier saved-export
  route next
- the sidecar or asset audit shows that the real saved export is incomplete
- the failure only reproduces on the larger attached bundle or the issue-3
  Google-shaped route
