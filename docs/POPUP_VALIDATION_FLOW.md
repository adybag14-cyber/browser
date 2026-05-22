# Popup Validation Flow

Use this guide when a headed-mode change touched popup creation, named-target
navigation, form-submit popup behavior, or script-driven popup policy and you
need the smallest reliable Windows validation ladder before widening further.

Read this together with:
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_VALIDATION_MATRIX.md`

## Working Rules

- Start with the router-backed `popup` change area before jumping into deeper helpers.
- Keep the first pass on the real headed window with the checkout-portable popup probes.
- Widen one proof at a time so you can separate anchor-launch regressions from named-target reuse, form-submit behavior, and script-popup policy.
- If a helper fails before browser behavior is exercised, normalize the repo-root or browser-exe path first instead of treating it as a popup regression.
- Reuse the same disposable profile family until the popup policy question is settled, then widen into other browser-shell checks only after the popup ladder is green.

## Fast Route

Run the smallest committed popup route first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-anchor-probe.ps1
```

Use this route when the change touched popup creation at all and you first need
to prove that a normal anchor-driven popup still opens a headed tab on the live
branch.

## Widening Ladder

After the anchor route is green, widen in this order:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-named-anchor-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-form-enter-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-form-post-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-script-policy-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-script-policy-block-probe.ps1
```

Use `chrome-popup-named-anchor-probe.ps1` when the change touched named targets,
reused popup tabs, or cross-link popup reuse.

Use `chrome-popup-form-enter-probe.ps1` when Enter-driven form submit should
open a popup result and you need the smaller keyboard path before testing wider
form flows.

Use `chrome-popup-form-post-probe.ps1` when the popup behavior depends on POST
submission rather than the smaller Enter-submit GET-style surface.

Use `chrome-popup-script-policy-probe.ps1` when the settings overlay or popup
allow-list behavior changed and you need to confirm that the script-popup
setting can still be toggled and saved on the headed shell.

Use `chrome-popup-script-policy-block-probe.ps1` when the same work should also
prove that blocked script popups stay blocked until the setting is re-enabled.

## What Each Probe Proves

| Probe | Main proof |
| --- | --- |
| `show_headed_validation_suites.ps1 -ChangeArea popup` | Reprints the current first-line popup route from the branch's validation router. |
| `chrome-popup-anchor-probe.ps1` | A direct anchor click opens the popup result tab on the real headed surface. |
| `chrome-popup-named-anchor-probe.ps1` | Named-target popup tabs can be created, revisited, and reused without losing the source tab. |
| `chrome-popup-form-enter-probe.ps1` | Enter-driven popup form submission still opens the expected popup result. |
| `chrome-popup-form-post-probe.ps1` | POST-based popup submission still opens and routes correctly. |
| `chrome-popup-script-policy-probe.ps1` | The headed settings surface can persist the script-popup allow/deny toggle. |
| `chrome-popup-script-policy-block-probe.ps1` | Script-driven popup blocking still holds when the deny path is active. |

## Troubleshooting Signals

- If `chrome-popup-anchor-probe.ps1` fails, keep the replay narrow and treat the failure as basic popup creation or window/tab routing first.
- If the anchor probe passes but `chrome-popup-named-anchor-probe.ps1` fails, focus on named-target reuse, source-tab return, or popup tab selection rather than generic popup creation.
- If the named-anchor probes pass but the form probes fail, treat the issue as popup form activation or submission ordering rather than popup window policy.
- If the form probes pass but the script-policy probes fail, focus on settings persistence, chrome keyboard shortcut routing, or the popup allow/deny gate.
- If a popup helper fails only because the browser binary or repo root could not be found, fix the local checkout pathing and rerun before filing a headed-mode regression.

## Manual Widening

After the full popup ladder is green:

1. Re-run the nearest real headed flow that motivated the change.
2. Pair the popup ladder with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell` when the same work also touched tabs, settings, or restore behavior.
3. Only widen into saved-page replay or broader browser-shell helpers after you know whether the first failing rung is creation, named-target reuse, form submit, or script-popup policy.
