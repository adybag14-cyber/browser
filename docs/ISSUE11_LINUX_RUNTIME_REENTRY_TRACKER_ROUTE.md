# Issue #11 Linux Runtime Re-entry Tracker Route

Use this note when the direct issue `#3` runtime patch is still blocked, but the
current run can still improve the Linux or WSL re-entry lane tracked by issue
`#11`.

Issue `#11` is the lower-volume progress tracker for the saved-checkout,
toolchain, offline-input, and readiness work that must be green before the next
honest `Page.zig` plus `win32_backend.zig` runtime attempt.

Companion helpers:

- `scripts/linux/check_issue11_runtime_reentry_tracker_route_surface.sh`
- `scripts/linux/show_issue11_runtime_reentry_tracker_route.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## Goal

Keep one compact branch-local route for deciding whether the next run should:

- restore or refresh the saved browser snapshot checkout
- validate the restored-checkout helper surface before deeper staging
- re-check saved Memory inputs and archive integrity before trusting offline work
- reopen the Zig toolchain recovery lane when only fallback Zig is visible
- rerun the Linux or WSL build-readiness route with the same resolved paths
- hand control back to the narrow Windows runtime gates once the environment is
  no longer the blocker

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue11_runtime_reentry_tracker_route_surface.sh
```

Use `--json` when another helper needs the surface-check result as structured
output.

## Print The Tracker Route

After the surface check passes, print the compact route:

```bash
bash ./scripts/linux/show_issue11_runtime_reentry_tracker_route.sh
```

If the checkout, Memory folder, or restored snapshot live somewhere unusual,
override the paths explicitly:

```bash
bash ./scripts/linux/show_issue11_runtime_reentry_tracker_route.sh \
  --repo-root /path/to/browser \
  --memory-root /path/to/workspace/memory \
  --restored-checkout-root /path/to/browser-memory-snapshot \
  --saved-archives-root /path/to/memory/repo_archives/browser
```

Use `--fallback-zig-archive` when the surfaced fallback Zig bundle does not sit
in the default `../agent_files/` location beside the repo workspace.

Use `--json` when another helper needs the resolved command set as structured
output.

## What The Route Surfaces

The route keeps the Linux or WSL re-entry ladder short and ordered:

1. `check_issue11_runtime_reentry_tracker_route_surface.sh`
2. `show_issue3_saved_browser_snapshot_route.sh`
3. `show_issue3_restored_checkout_reentry_route.sh`
4. `show_issue3_saved_memory_inputs_route.sh`
5. `show_issue3_saved_archive_integrity_route.sh`
6. `show_issue3_zig_toolchain_recovery_route.sh`
7. `show_issue3_linux_build_readiness_route.sh`
8. `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` as the final handoff back to the
   narrower runtime lane

## Working Rules

- Run the issue `#11` surface check first so missing docs or helper drift fails
  before the route blames the saved archives or fallback Zig bundle.
- Use the saved-browser-snapshot route when no reusable checkout exists yet or
  when the restored helper surface may need a synced refresh.
- Use the restored-checkout route right after the snapshot route when the next
  question is whether the extracted checkout is safe to trust.
- Use the saved-Memory route before raw Python preflights when the helper chain
  itself may have drifted and the run wants one compact command surface.
- Use the saved-archive integrity route before deeper Linux or WSL staging when
  the saved repo snapshot or dependency bundles may have changed.
- Use the Zig recovery route when only the fallback Zig `0.17` bundle is
  visible or when multiple staged candidates need a quick `0.15.x` decision.
- Use the Linux build-readiness route only after the saved snapshot, restored
  checkout, saved-input, archive-integrity, and Zig-line questions are already
  narrowed.
- Hand back to `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` once the environment route
  stops being the blocker and the next run can honestly reopen the direct
  runtime patch.
