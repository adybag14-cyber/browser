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

For the current one-command bounded pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
```

That wrapper keeps the current localhost-first issue `#3` path together:
`localhost`, `title`, reduced `home`, `submit-timing`, `shared-enter-order`,
and `watch`, with the same optional saved-page follow-up parameters.

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

Preferred one-command bounded pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
```

Run the stepwise flow when you want to narrow the failure one phase at a time:

1. `localhost`
2. `quick`
3. `google-home`
4. `submit-timing`
5. `shared-enter-order`
6. `manual`
7. `trace`

Use these commands through the main runner or the bounded probe directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase localhost
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase quick
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase home
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-google-submit-timing-probe.ps1
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
- `submit-timing`: the bounded headed Win32 layout-smoke probe still clicks the
  Google-shaped shell, types `QZ`, reaches the submitted page, and preserves
  `keydown,keypress,submit` ordering in the submitted title trace before the
  broader shared gates.
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

The recommended wrapper simply runs the current bounded phases in the same
order without making you restate the longer flag bundle each time.

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

When you want the same saved-page inputs routed through the current one-command
bounded pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 `
  -ManualPort 8123 `
  -ManualInitialPage google-saved-page.html `
  -ManualInputPath C:\path\to\saved-page.html, C:\path\to\saved-folder
```

## 5) Working rule

Do not treat a saved-page manual pass as the first evidence for issue `#3`.

Use the bounded localhost, reduced homepage, submit-timing, and shared
Enter-order passes first, then use the saved-page or live-Google follow-up only
when those gates already agree.

Use `run_google_issue3_recommended_validation.ps1` when you want the current
bounded issue `#3` flow in one reusable command. Drop back to the stepwise
`run_google_input_validation.ps1` phases when you need to narrow the exact step
that regressed.

For Enter-order work, do not accept a reduced-title pass as green unless the
keydown edge still reads `KEYDOWN:<text>|13|13` before the final
`SUBMIT:<text>` marker.

## 6) Reduced title probe signals

Use the dedicated reduced-fixture title probe when you want one fast headed pass
that exposes where the Google-style interaction stopped drifting:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_title_probe.ps1
```

Read the title markers in this order:

- `Q=INPUT:q`: the reduced page bound the query input and named-form access is alive.
- `A=INPUT:q...`: the query field became the active element.
- `V=<text>`: visible text landed in the input value.
- `KEYDOWN:<text>|13|13`: the Enter keydown edge still arrived before submit.
- `SUBMIT:<text>`: the reduced form submit completed.
- `|E=KP:` inside the final submit title: submit still happened after the matching keypress path.

Use those markers to narrow failures quickly:

- Missing `Q=INPUT:q` points at fixture bootstrap, legacy named access, or early page-state setup.
- Missing `A=INPUT:q...` after bind points at startup focus or activation ordering.
- Missing `V=<text>` after focus points at headed text delivery or duplicate suppression.
- Reaching `SUBMIT:<text>` without `|E=KP:` points at Enter ordering drift even if submit still happened.

This probe is not the final acceptance target for issue `#3`, but it is the
fastest bounded headed check when you need to decide whether the regression is
in focus, typing, or Enter sequencing before moving back to the broader manual
or live-Google passes.
