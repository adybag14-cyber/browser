# Headed Browser-Shell And Popup Validation

Use this guide when a headed change touches browser-shell behavior, popup
creation, named-target routing, or popup policy and you want the smallest
bounded Windows validation route before widening into a full manual replay.

Read this together with:

- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_VALIDATION_MATRIX.md`
- `docs/FULL_BROWSER_MASTER_TRACKER.md`

## Goal

Keep Gate 1 browser-shell work on the smallest honest proof surface:

- start from the router when the current change still fits the branch's named
  change areas
- stay on the bounded browser-shell or popup probes until the first failure is
  clear
- widen into deeper shell or popup probes only after the first router-selected
  surface is green
- keep popup-policy regressions separate from anchor, form-submit, and
  named-target regressions

## Fast picks

| If the change touched... | Start here | Good follow-up |
| --- | --- | --- |
| tabs, reopen-closed, duplicate, restore, shell shortcuts, internal browser pages, or settings persistence | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-start-shell-probe.ps1` |
| `_blank` anchors, named targets, script popups, popup policy, popup forms, or launcher-page callbacks after popup open | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-anchor-probe.ps1` |

## Browser-shell route

Use the router first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell
```

Then stay on this ladder:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-start-shell-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-tabs-recovery-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-home-restore-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-title-fidelity-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\tabs\chrome-tabs-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\tabs\chrome-duplicate-tab-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\tabs\chrome-reopen-closed-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\tabs\chrome-session-restore-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\settings\chrome-settings-home-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\settings\chrome-settings-restore-off-probe.ps1
```

Use that order on purpose:

1. `chrome-browser-pages-start-shell-probe.ps1` for homepage routing,
   `browser://start`, and shell-entry regressions.
2. `chrome-browser-pages-tabs-recovery-probe.ps1` for tab lifecycle,
   reopen/restore, and browser-pages recovery paths.
3. `chrome-browser-pages-home-restore-probe.ps1` when startup restore,
   homepage persistence, or restart handoff changed.
4. `chrome-browser-pages-title-fidelity-probe.ps1` when titles drift across
   internal pages, restart, or recovery.
5. `chrome-tabs-probe.ps1`, `chrome-duplicate-tab-probe.ps1`,
   `chrome-reopen-closed-probe.ps1`, and `chrome-session-restore-probe.ps1`
   once the browser-pages shell surface is green and the change still touches
   wider tab/session behavior.
6. `chrome-settings-home-probe.ps1` and
   `chrome-settings-restore-off-probe.ps1` for settings-backed shell changes.

## Popup route

Use the router first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup
```

Then choose the smallest direct popup proof that matches the changed path:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-anchor-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-named-anchor-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-form-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-form-enter-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-form-post-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-script-blank-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-script-named-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-script-policy-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-script-policy-block-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-background-timer-probe.ps1
```

Use these splits:

- `chrome-popup-anchor-probe.ps1` first for plain `_blank` anchor regressions.
- `chrome-popup-named-anchor-probe.ps1` when target reuse or named-target
  routing changed.
- `chrome-popup-form-probe.ps1`, `chrome-popup-form-enter-probe.ps1`, and
  `chrome-popup-form-post-probe.ps1` for popup form submit timing, Enter
  activation, and POST flows.
- `chrome-popup-script-blank-probe.ps1` and
  `chrome-popup-script-named-probe.ps1` for script-driven popup creation.
- `chrome-popup-script-policy-probe.ps1` and
  `chrome-popup-script-policy-block-probe.ps1` when the regression sits in
  allow/block popup policy rather than creation itself.
- `chrome-popup-background-timer-probe.ps1` when the launcher page needs to
  keep callbacks alive after popup open.

## Choose by symptom

| Symptom | First probe | Why |
| --- | --- | --- |
| `browser://start` or shell shortcuts regress | `chrome-browser-pages-start-shell-probe.ps1` | Confirms the headed shell still enters the internal page surface cleanly. |
| duplicate/reopen/restore drift after tab changes | `chrome-browser-pages-tabs-recovery-probe.ps1` | Keeps the first proof on the native browser-pages shell before widening into generic tab probes. |
| homepage or restart restore picks the wrong page | `chrome-browser-pages-home-restore-probe.ps1` | Isolates startup persistence and restore state. |
| title/state drift across browser pages | `chrome-browser-pages-title-fidelity-probe.ps1` | Keeps the failure on the shell-title path first. |
| `_blank` anchors stop opening correctly | `chrome-popup-anchor-probe.ps1` | Smallest popup creation proof. |
| named-target reuse regresses | `chrome-popup-named-anchor-probe.ps1` | Separates target reuse from generic popup creation. |
| form submit opens the wrong window or fails on Enter | `chrome-popup-form-enter-probe.ps1` | Smallest Enter-driven popup checkpoint. |
| policy blocks or allows the wrong script popup path | `chrome-popup-script-policy-block-probe.ps1` or `chrome-popup-script-policy-probe.ps1` | Keeps popup-policy failures separate from general script-popup creation. |
| opener callbacks die after popup activation | `chrome-popup-background-timer-probe.ps1` | Checks the post-open callback survival path directly. |

## Manual widening

Only widen after the matching bounded probe is green:

1. Re-run the matching router change area so the current branch surface is still
   printed honestly.
2. Run the smallest direct probe in the matching ladder above.
3. Widen to the next probe in the same family only if the first failure is
   still unclear.
4. Move to a manual headed replay with `.\zig-out\bin\lightpanda.exe browse --headed ...`
   only after the bounded shell or popup family is green or after the current
   evidence proves the failure sits beyond those smaller gates.

## Practical rule

For browser-shell and popup work, prefer proving the internal headed shell or
popup helper first instead of jumping straight to a larger manual replay. That
keeps Gate 1 regressions smaller, separates popup-policy drift from popup
creation drift, and leaves a clearer next step when the real headed window
still diverges.
