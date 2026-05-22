# Issue #3 Windows Full-Use Enter-Submit Runtime Bridge

Use this note when `docs/WINDOWS_FULL_USE.md` already narrowed replay to the
Google-shaped Enter-submit boundary and the next honest question is whether the
remaining issue lives in the direct `Page.zig` and `win32_backend.zig` runtime
bridge instead of the broader attached-page or live-homepage lanes.

Keep these nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/windows/show_google_issue3_windows_full_use_enter_submit_runtime_bridge.ps1`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `tmp-browser-smoke/form-controls/enter-submit-probe.ps1`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`

## When to use this bridge

Use this bridge after the Windows full-use route already says the replay should
stay close to issue `#3`, especially when one of these is true:

- the shared Enter-order ladder is the current narrowing surface
- the reduced Google title probe is the next replay candidate
- the direct runtime slice in `src/browser/Page.zig` and
  `src/display/win32_backend.zig` is the smallest remaining suspected gap
- a writable checkout exists for source edits, but the route back into the
  runtime-first helper needs to stay explicit and repeatable

Do not use this bridge when the replay still belongs on the broader attached
HTML catalog, the pinned three-page compatibility bundle, or a browser-shell /
rendering / network lane that is not yet narrowed to the Google Enter-submit
boundary.

## Recommended order

1. Run the runtime revalidation surface check first.
2. Run the source-based runtime contract checker next.
3. Reopen the shared Enter-order ladder before touching the reduced Google
   probe or live homepage.
4. Use the reduced Google probe before the direct fixture URL or live Google.
5. Run focused Zig tests only when the current checkout already has a branch-
   compatible Zig toolchain.
6. Reopen live Google last.

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
python .\tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py --page .\src\browser\Page.zig --win32 .\src\display\win32_backend.zig
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed https://www.google.com/
```

## Practical rule

If the focused Zig tests fail in untouched branch files before the new runtime
assertions run, keep the route honest by relying on the surface checker, the
source-based contract checker, the shared Enter-order ladder, and the reduced
Google probe. Only treat the direct runtime patch as ready to widen back out to
live Google after those narrower checkpoints agree on the same keypress-before-
submit behavior.
