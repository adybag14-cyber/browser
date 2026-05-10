# Attached HTML Validation on Windows

This guide is the shortest route from attached HTML snapshots to a headed
localhost follow-up on `fork/headed-mode-foundation`.

Use it when the current run already has saved `.html` pages under `user_files/`
or `agent_files/`, or when issue `#3` follow-up should start from attached
Google-like pages instead of manually enumerated saved-page paths.

Read this with:
- `docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md`
- `docs/WINDOWS_FULL_USE.md`
- `tmp-browser-smoke/manual-user/README.md`

## 1) Print the attached-page flow first

For a general attached-page localhost pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
```

For attached pages that look Google-like and should stay on the issue `#3`
localhost-first route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1 -GoogleStyle
```

That helper:
- auto-discovers nested `.html` files anywhere under `user_files/` first and then `agent_files/`
- prefers a Google-like page first when `-GoogleStyle` is used
- forwards the same input set into the saved-page Google flow helper instead of
  making you restate each file path by hand

## 2) Recommended order for Google-like attached pages

1. Print the flow with `show_attached_html_validation_flow.ps1 -GoogleStyle`.
2. Run the bounded issue `#3` pass and keep the same attached-page follow-up on
   the bundled manual phase:
   `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle`
3. If you want to reopen the same attached HTML set directly after the bundled
   pass, rerun the attached localhost helper:
   `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 -GoogleStyle -Wait`
4. If the bounded phases are green but the attached page still diverges, rerun
   the printed Google-style saved-page flow with the same preferred page and
   manual input set.
5. Only move to the live Google trace or full homepage pass after the bounded
   localhost-first phases and the attached-page follow-up agree.

The recommended runner already knows how to keep the Google-style attached-page
follow-up in the same localhost-first order, so you do not need to restate the
attached file paths just to carry that manual phase along.

## 3) Override the first page when needed

If the auto-selected Google-like page is not the one you want first, pin it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1 `
  -GoogleStyle `
  -PreferredInitialPage C:\path\to\attached-google-page.html
```

For a direct attached-page run with the same override:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 `
  -GoogleStyle `
  -PreferredInitialPage C:\path\to\attached-google-page.html `
  -Wait
```

For the one-command bounded issue `#3` pass with the same preferred first page:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 `
  -ManualGoogleStyle `
  -ManualInitialPage C:\path\to\attached-google-page.html
```

## 4) Switch to explicit saved-page inputs when auto-discovery is not enough

If the HTML pages live outside `user_files/` and `agent_files/`, or the run
should use a precise mix of standalone files and folders, switch to the
saved-page Google helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 `
  -InputPath C:\path\to\saved-page.html, C:\path\to\saved-folder `
  -PreferredInitialPage google-saved-page.html
```

Keep the same inputs on the one-command bounded pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 `
  -ManualPort 8123 `
  -ManualInitialPage google-saved-page.html `
  -ManualInputPath C:\path\to\saved-page.html, C:\path\to\saved-folder
```

## 5) Working rule

Do not treat the attached-page localhost run as the first proof for issue `#3`.

Run the bounded localhost-first Google phases first, then use the attached-page
localhost follow-up to compare the more realistic page snapshots under the same
headed validation route.

If the attached pages are not Google-like, use
`show_attached_html_validation_flow.ps1` without `-GoogleStyle` and follow the
recommended bounded suite for the subsystem that changed before the manual pass.
