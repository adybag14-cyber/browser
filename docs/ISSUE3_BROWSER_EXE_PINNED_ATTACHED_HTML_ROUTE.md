# Issue 3 BrowserExe-Pinned Attached HTML Route

Use this note when issue `#3` replay must stay pinned to a non-default headed
browser build instead of drifting back to `.\zig-out\bin\lightpanda.exe`.

This is the current compact route helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_browser_exe_pinned_attached_html_route.ps1 -BrowserExe "C:\path\to\lightpanda.exe"
```

Add `-InputPath` when the replay should stay pinned to the known three-page
compatibility bundle or another explicit saved-page set:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_browser_exe_pinned_attached_html_route.ps1 -BrowserExe "C:\path\to\lightpanda.exe" -InputPath "C:\path\to\bundle"
```

Add `-RepoRoot` and `-SummaryPath` when the replay is running from a non-default
checkout or should keep a saved validation summary visible:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_browser_exe_pinned_attached_html_route.ps1 -RepoRoot "C:\path\to\browser" -SummaryPath "C:\path\to\summary.json" -BrowserExe "C:\path\to\lightpanda.exe"
```

## What this helper keeps pinned

- the broader validation-router re-entry for `google-attached-html`
- the broader Google-shaped attached-page flow helper
- the top-level issue `#3` attached-page quickstart
- the pinned bundle-first issue `#3` helper

## When to use it

- the replay must use a non-default `lightpanda.exe`
- the branch output being validated lives outside the current checkout's
  `zig-out\bin\lightpanda.exe`
- the replay should stay on the Google-shaped attached-page route or the known
  three-page compatibility bundle without retyping `-BrowserExe` at each step

## Related notes

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
