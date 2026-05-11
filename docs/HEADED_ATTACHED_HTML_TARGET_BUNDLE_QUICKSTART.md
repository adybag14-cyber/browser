# Headed Attached HTML Target Bundle Quickstart

Use this quickstart when the current localhost replay target is the known
three-page attached HTML compatibility bundle from the headed-mode workspace.

This keeps the bundle-aware route short and explicit:

- fail fast if the bundle guide, checker, helper, or delegated runner drifted
- confirm the current saved-page set still resolves to the expected targets
- print the exact pinned commands for the current bundle
- launch the headed localhost replay only after the earlier checks stay green

## Known Bundle

The current bundle is the three-page set used for attached-page compatibility
follow-up:

- `Control your online safety and privacy – Google Safety Centre`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic`
- `Presidential Unsealing and Reporting System for UAP Encounters`

## Run Order

1. Check the bundle route surface first.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
```

2. Confirm the current saved-page set still resolves to the expected bundle.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1
```

3. Print the current bundle-pinned flow.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
```

4. Launch the bundle-aware headed localhost replay.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

## What The Bundle Route Gives You

When the bundle resolves cleanly, the checker and flow helper keep these
commands pinned to the same current input set:

- bundle-aware surface check
- bundle-aware deep asset-closure audit
- printed flow helper with the current preferred initial page
- delegated runner for the matching profile

If the Google Safety Centre page is part of the resolved set, the bundle stays
on the Google-style attached HTML route and keeps that page first so the issue
`#3` localhost-first follow-up stays aligned with the current validation ladder.

## When To Fall Back

Use the broader attached-page routes instead when one of these is true:

- one or more expected bundle pages are missing
- the current attached HTML set is not the known three-page compatibility bundle
- you want to replay an explicit saved-page export instead of the auto-discovered bundle

General fallback:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 -Wait
```

Google-style fallback:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

## Capture

Keep these with the validation result:

- the exact bundle helper command that was used
- whether the bundle route stayed on the Google-style or general profile
- the preferred initial page that was pinned for the run
- the first visible failure or success marker from the headed localhost replay

## Why This Exists

The branch already has the bundle-aware checker, flow helper, and delegated
runner. This quickstart makes the intended order easy to reuse when the next
headed compatibility question is about the current attached-page bundle rather
than a brand-new probe slice.
