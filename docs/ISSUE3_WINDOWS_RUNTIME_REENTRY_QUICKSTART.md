# Issue #3 Windows Runtime Re-entry Quickstart

Use this note when the next headed-mode replay is already narrowed to the direct
issue `#3` runtime lane and you want the shortest Windows-first route that keeps
the real gate checks, the saved-snapshot recovery path, the Linux or WSL
build-readiness fallback, the shared Enter-order ladder, and the reduced Google
probe visible before anyone reopens `src/browser/Page.zig` or
`src/display/win32_backend.zig`.

Keep these companion notes nearby:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

## Goal

Start from the fail-fast runtime surface check, reprint the compact Windows
runtime helper, keep the saved-browser-snapshot and saved-archive routes nearby
when the current run still lacks a reusable checkout, keep the Linux or WSL
build-readiness route nearby when the current run still lacks a branch-matched
Zig line or staged sibling dependencies, then replay the shared Enter-order
ladder and the reduced Google fixture before widening back out to live Google or
the broader attached localhost bundle.

## Read-first route

Use this route when the next replay should stay on the direct runtime lane:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

Use the checker first when the branch moved recently and you want the note
pointers, helper surfaces, route commands, and reduced Google replay artifacts
re-validated before trusting any narrower runtime output.

Use the route printer second when you want one compact command surface that
keeps all of these together:

- the read-first notes for the direct runtime lane
- the saved-browser-snapshot route when no reusable checkout exists yet
- the saved-archive integrity route when the Memory bundles still need to be
  re-proved
- the saved-memory preflight and Linux or WSL build-readiness helpers
- the focused `Page.zig` and `win32_backend.zig` contract checks
- the shared Enter-order ladder
- the reduced Google title probe and reduced Google fixture

## If the publication gate is still closed

Do not reopen `Page.zig` or `win32_backend.zig` through a brittle full-body
replacement flow.

Run these helpers first instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

Then keep these route outputs open from the same helper surface:

- `Saved snapshot surface`
- `Saved snapshot route`
- `Saved archive surface`
- `Saved archive route`
- `Saved archive verification`
- `Saved-memory preflight`

Use that branch when the next run still needs a disposable checkout restored
from the saved Memory snapshot or when the current saved repo and dependency
archives still need to be re-verified before Linux or WSL follow-up work is
trusted.

## If the toolchain gate is still closed

Treat untouched-source Zig failure as an environment problem first.

Keep this route nearby:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

From the printed output, follow these commands in order:

1. `Linux runtime surface`
2. `Linux runtime route`
3. `Linux readiness (skip Zig)`
4. `Linux readiness (full)` only after a matching Zig line is staged

Use that order when the branch still expects sibling-path dependencies,
restaged saved archives, or a `0.15.x` Zig line before focused file-level tests
can be treated as evidence.

## Shared replay ladder

Once the gates are green enough to replay behavior instead of only recovering
the environment, keep this ladder tight:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -DeferredEnter
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
```

Use the default form-controls probe first to prove the baseline Enter-submit
path. Use `-DeferredEnter` when the change touched delayed native submit
bridging. Use `-GoogleEnterOrder` when the keypress-before-submit ordering is
still the main question. Use `-GoogleEnterOrder -ClickFocus` when the replay
must stay on the click-first boundary that most closely matches the real Google
homepage failure. Only use the reduced Google title probe after the shared
ladder agrees on the same failure point.

## When to reopen the real code patch

Only reopen the direct `Page.zig` plus `win32_backend.zig` patch when both of
these are true:

- the run has a safe publication path for those two large existing files
- the run has a branch-compatible build and validation route, not just any Zig
  archive that happens to exist nearby

When both gates are green, reopen:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

Then keep `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` and the output from
`show_google_issue3_enter_submit_runtime_revalidation.ps1` beside the change so
focused tests, shared Enter-order replay, and reduced Google replay stay on the
same boundary.

## Practical rule

Use this quickstart when the next useful work is still the direct issue `#3`
runtime route, but the run needs the smallest honest Windows-first ladder back
in front of it before deeper replay begins. If the route widens back into the
broader Windows validation catalog, reopen `docs/WINDOWS_FULL_USE.md`. If the
route narrows into the saved attached localhost bundle instead, reopen
`docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` or
`docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md` instead of forcing the
runtime-only path to answer the wrong question.
