# Issue #3 Linux Re-entry Status Route

Use this note when the Linux or WSL headed runtime re-entry lane needs one quick
status answer before a run chooses its next helper route.

This route keeps the workspace-context helper, saved-Memory preflight, Zig
matching-line gate, Linux build-readiness helper, and issue `#11` handoff on
one branch-local surface so future runs do not have to rediscover which gate is
still closed by hand.

## Companion Surfaces

- `scripts/linux/check_issue3_linux_reentry_status_route_surface.sh`
- `scripts/linux/show_issue3_linux_reentry_status_route.sh`
- `scripts/check_issue3_linux_reentry_status.py`
- `scripts/check_issue3_workspace_context.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/check_issue3_zig_toolchain_match.sh`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_workspace_context_route.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`

## When To Use It

Use this route when any of these are true:

- a scheduled run wants the shortest honest answer about which Linux or WSL
  gate is still failing
- a restored or nested checkout may be pointing later helpers at the wrong
  shared roots
- the next issue `#11` update should be grounded in the current helper state,
  not stale assumptions from a previous run
- the route needs to decide whether to stay on workspace discovery,
  saved-Memory validation, Zig recovery, broader build-readiness, or hand back
  to the direct runtime revalidation lane

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_linux_reentry_status_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Compact Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_linux_reentry_status_route.sh
```

Use `--json` when another helper wants the surfaced commands and follow-up notes
as structured output.

## Run The Helper

From the browser repo root:

```bash
python ./scripts/check_issue3_linux_reentry_status.py --repo-root .
```

Use `--json` when another helper wants the component gate results and the
suggested next step as structured output.

## Working Rules

- Run the route surface check first so missing docs or helper drift fails before
  a scheduled run trusts the quick-status helper.
- Use the quick-status helper before reopening broader route notes when the only
  immediate question is which gate is still closed right now.
- If the quick-status helper says workspace context is failing, hand off to
  `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md` instead of guessing roots by hand.
- If the quick-status helper says saved-Memory inputs are failing, hand off to
  `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md` before widening back out to Zig or
  build-readiness work.
- If the quick-status helper says the Zig matching-line gate is failing, hand
  off to `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md` or the saved-Zig route
  rather than blaming the runtime patch.
- If the quick-status helper says broader Linux build-readiness is failing,
  reopen `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md` before using focused
  file-level Zig output as evidence.
- Keep using issue `#11` while this route is still about saved inputs,
  toolchain recovery, or Linux or WSL readiness gates rather than the direct
  `Page.zig` plus `win32_backend.zig` runtime patch.
- Hand back to the direct runtime route only after the quick-status helper says
  all environment gates are green.
