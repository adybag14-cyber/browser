# Headed Google Validation on Windows

This guide is the shortest reliable path for issue `#3` follow-up on
`fork/headed-mode-foundation`.

Use it when you need to validate Google-style headed text entry, Enter submit,
or saved-page follow-up without starting from the full live homepage first.

## 1) Start with the printed flow map

For the general reduced-Google flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

For saved or attached localhost HTML pages:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 `
  -InputPath C:\path\to\saved-page.html, C:\path\to\saved-folder `
  -PreferredInitialPage google-saved-page.html
```

That saved-page helper keeps the same preferred first page threaded through the
manual headed follow-up commands so later reruns do not drift onto a different
HTML file.

## 2) Recommended validation order

Run the smallest bounded gate first:

1. `localhost`
2. `quick`
3. `google-home`
4. `shared-enter-order`
5. `manual`
6. `trace`

Use these commands through the main runner:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase localhost
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase quick
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase home
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order
```

Only move to `manual` or `trace` after those bounded phases are green.

## 3) What the phases prove

- `localhost`: the reduced Google-style probes still cover focus churn, typing,
  delayed readiness, and submit ordering on deterministic local fixtures.
- `quick`: the fast title-plus-watch path still reaches the reduced ready
  markers without a long manual session.
- `google-home`: the reduced homepage probe still reaches the headed title
  markers `FOCUSED`, `TYPED:QZ`, and `SUBMIT:QZ`.
- `shared-enter-order`: the shared label baseline, submit gates, and stricter
  keypress-before-submit wrapper still agree with the reduced Google path, and
  the reduced title probe should stay at a `KEYDOWN:<text>|13|13` marker on the
  Enter keydown edge before it finally advances to `SUBMIT:<text>` after the
  matching keypress path.
- `manual`: the saved or attached localhost HTML pages can now be compared
  against the bounded passes under the same manual port and preferred initial
  page.
- `trace`: the live Google homepage is only needed when the bounded phases are
  green but the real homepage still diverges.

## 4) Saved-page follow-up

When the HTML pages are already in one directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_localhost_html_validation.ps1 `
  -PageRoot C:\path\to\saved-pages `
  -InitialPage google-saved-page.html `
  -LaunchBrowser `
  -Wait
```

When the inputs are spread across standalone files and folders:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_staged_localhost_html_validation.ps1 `
  -InputPath C:\path\to\saved-page.html, C:\path\to\saved-folder `
  -InitialPage google-saved-page.html `
  -LaunchBrowser `
  -Wait
```

When you want the same saved-page inputs routed through the full Google flow
map:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1 `
  -ManualPort 8123 `
  -ManualInitialPage google-saved-page.html `
  -ManualInputPath C:\path\to\saved-page.html, C:\path\to\saved-folder
```

## 5) Working rule

Do not treat a saved-page manual pass as the first evidence for issue `#3`.

Use the bounded localhost, reduced homepage, and shared Enter-order passes
first, then use the saved-page or live-Google follow-up only when those gates
already agree.

For Enter-order work, do not accept a reduced-title pass as green unless the
keydown edge still reads `KEYDOWN:<text>|13|13` before the final
`SUBMIT:<text>` marker.
