# Issue #3 Enter-Submit Runtime Revalidation Quickstart

Use this note when the branch is already narrowed back to the remaining Google
headed Enter-submit runtime bug and the next run needs the shortest honest path
back into that slice.

Read this alongside:

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

## Scope

Keep the runtime change focused to:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

The revalidation goal is still the same:

- typed text stays in the focused Google query input
- Enter keydown alone does not submit too early
- later keypress-time DOM behavior is what allows submit
- stale queued text-input suppression does not drop real later text

## Fast route

Run the branch-local surface checker first so the helper, note, reduced probe,
and target files are all still present before editing anything:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
```

Then print the runtime helper surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

Keep the shared Enter-order ladder nearby so the smaller bounded probes stay
visible before the direct runtime replay:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1
```

## Reduced replay order

Use this order before widening back out to the live homepage:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

Only reopen the live homepage after the reduced probe and reduced fixture agree
on the same keypress-before-submit ordering:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed https://www.google.com/
```

## Focused test follow-up

After replaying the runtime patch in a writable checkout, keep the direct source
surfaces small and recheck them first:

```powershell
zig test .\src\browser\Page.zig
zig test .\src\display\win32_backend.zig -target x86_64-windows-gnu
```

## Known practical blockers

- Prefer a writable checkout for `Page.zig` and `win32_backend.zig` because the
  large existing-file publication path is still sensitive.
- Prefer a project-compatible Zig toolchain or the branch's normal build path
  before treating untouched Zig compatibility failures as headed-runtime
  regressions.

## Working rule

If the current runtime cannot land the direct source edit safely, stop at the
helper, reduced probe, and quickstart surface above rather than widening into a
larger speculative runtime rewrite.
