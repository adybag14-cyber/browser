# Headed Google Validation on Windows

This guide is the shortest reliable path for issue `#3` follow-up on
`fork/headed-mode-foundation`.

Use it when you need to validate Google-style headed text entry, Enter submit,
or saved-page follow-up without starting from the full live homepage first.

Use `docs/HEADED_ATTACHED_HTML_VALIDATION.md` when the next follow-up
should start from attached HTML snapshots under `agent_files/` instead of a
manually enumerated saved-page list.

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

For the same bounded flow plus the attached-page follow-up when the current run
already has HTML snapshots under `user_files/` or `agent_files/`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle
```

That keeps the localhost-first issue `#3` order intact and only folds in the
attached-page manual follow-up after the bounded phases are green.

For the fast title-plus-watch pass through its own dedicated helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_quick_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1
```

Use the printed quick helper when you want the bounded title markers and the
watch handoff spelled out before you execute the faster wrapper.

For attached HTML snapshots that should stay on the same Google-style follow-up
route without manually restating each file path first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

Those dedicated helpers auto-discover nested attached `.html` files under
`user_files/` first and then `agent_files/`, prefer a Google-like page first
when one is present, and keep the same bounded Google-style localhost flow in
front of the manual headed follow-up.

For saved localhost HTML pages that live outside the attached-file folders, keep
using the explicit saved-page helper:

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
2. `title`
3. `quick-flow`
4. `quick`
5. `google-home`
6. `submit-timing`
7. `shared-enter-order`
8. `manual`
9. `trace`

Use these commands through the main runner or the bounded helpers directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase localhost
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_quick_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase home
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-google-submit-timing-probe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order
```

When the question is whether the shared Enter path already agrees with the
reduced Google probes, use the form-controls wrapper before the broader manual
follow-up:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_form_controls_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_form_controls_validation.ps1 -Probe google-enter-order
```

That wrapper keeps the shared label-click, immediate Enter, deferred Enter,
reduced Google-home submit, and stricter localhost Enter-order gates on one
command surface.

Only move to `manual` or `trace` after those bounded phases are green.

## 3) What the phases prove

- `localhost`: the reduced Google-style probes still cover focus churn, typing,
  delayed readiness, and submit ordering on deterministic local fixtures.
- `quick-flow`: the dedicated helper still prints the bounded title-plus-watch
  order before you launch the faster wrapper.
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

## 4a) Attached HTML auto-discovery

When the current run already has attached HTML snapshots under `agent_files/`,
use the dedicated Google-attached helpers instead of manually restating each
path first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle
```

The dedicated flow helper auto-discovers nested `.html` files anywhere under
`user_files/` and `agent_files/`, prefers a Google-like page first when one is
present, and keeps the same localhost-first issue `#3` order before the broader
manual headed follow-up.

Use `show_google_attached_html_validation_flow.ps1 -PreferredInitialPage <saved-page>`
when the auto-selected first page is not the one you want, and use
`docs/HEADED_ATTACHED_HTML_VALIDATION.md` when you want the full
attached-page command map, override patterns, and staging rules in one place.

## 5) Working rule

Do not treat a saved-page manual pass as the first evidence for issue `#3`.

Use the bounded localhost, reduced homepage, submit-timing, and shared
Enter-order passes first, then use the saved-page or live-Google follow-up only
when those gates already agree.

Use `run_google_issue3_recommended_validation.ps1` when you want the current
bounded issue `#3` flow in one reusable command. Drop back to the stepwise
`run_google_input_validation.ps1` phases when you need to narrow the exact step
that regressed.

Use `show_google_quick_validation_flow.ps1` when you want the fast title-plus-watch
stack spelled out before you run the quicker wrapper entrypoint.

For attached HTML snapshots that already live under `agent_files/`, start with
`show_google_attached_html_validation_flow.ps1` so the same pages route through
the bounded Google-first helper order before you inspect them manually, and use
`run_google_attached_html_validation.ps1 -Wait` when you want the same attached
set reopened directly on that Google-style localhost path.

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
