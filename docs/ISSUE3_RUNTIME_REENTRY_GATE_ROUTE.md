# Issue #3 Runtime Re-entry Gate Route

Use this route when the next run needs one compact command surface for deciding
whether the direct issue `#3` runtime patch is ready to reopen.

This route sits one level above the direct checker in
`scripts/check_issue3_runtime_reentry_gates.py`.

It does not replace the saved-browser restore route, the Zig toolchain recovery
route, the Linux build-readiness route, or the narrowed runtime revalidation
route. Its job is to keep those pieces connected in one short re-entry path so
scheduled runs do not guess their way back into the blocked `Page.zig` plus
`win32_backend.zig` slice.

Companion helpers:

- `scripts/linux/check_issue3_runtime_reentry_gates_surface.sh`
- `scripts/linux/show_issue3_runtime_reentry_gates_route.sh`
- `scripts/check_issue3_runtime_reentry_gates.py`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`

## When To Use It

Use this route when any of these are true:

- the next intended work still targets the direct issue `#3` runtime patch in
  `src/browser/Page.zig` and `src/display/win32_backend.zig`
- the run needs a quick answer on whether the publication and toolchain gates
  are open
- the run needs to switch cleanly from restore or toolchain recovery back into
  the narrowed runtime revalidation ladder

## Surface Check

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_runtime_reentry_gates_surface.sh
bash ./scripts/linux/show_issue3_runtime_reentry_gates_route.sh
```

The first command verifies that the route note, route printer, direct checker,
and its required follow-up helpers still exist on the branch-local surface.

The second command prints the compact command sequence for the gate checker and
the adjacent recovery routes.

Use `--json` when another helper needs structured command output.

## Gate Check

Run the direct checker from the current repo root:

```bash
python ./scripts/check_issue3_runtime_reentry_gates.py --repo-root .
```

If the publication gate is closed, use the saved-browser snapshot route next:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

If the toolchain gate is closed, use the Zig toolchain recovery route next:

```bash
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
```

If the gate checker still says the branch needs saved Memory staging or Linux
build readiness work, keep following the printed build-readiness route before
returning to the direct runtime patch:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```

Only after the gate checker passes should the run reopen the narrowed runtime
revalidation route:

```bash
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```

## Working Rules

- Run the surface checker first so missing route pieces fail fast.
- Treat the gate checker as the truth surface for whether the direct runtime
  patch is ready, not as a replacement for the restore or toolchain routes.
- Use the saved-browser snapshot route when the missing piece is still a
  reusable checkout.
- Use the Zig toolchain recovery route when the missing piece is still the
  branch-compatible Zig line or staged offline inputs.
- Use the Linux build-readiness route when saved inputs exist but broader staging
  is still incomplete.
- Reopen the narrowed runtime revalidation route only after the gate checker is green.
