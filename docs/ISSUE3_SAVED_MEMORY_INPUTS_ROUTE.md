# Issue #3 Saved Memory Inputs Route

Use this note when a Linux, WSL, or scheduled headed-mode run needs to prove the
saved Memory inputs are present before it reopens checkout restore, build-
readiness, or the direct issue `#3` runtime lane.

This route keeps the saved repo snapshot, notes, blocker file, dependency
archives, optional fallback Zig bundle, and the immediate next helper routes on
one compact branch-local surface.

Companion helpers:

- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when any of these are true:

- a scheduled run starts by checking Memory first and needs a compact preflight
  before choosing restore, build-readiness, or runtime follow-up
- the next Linux or WSL route depends on the saved repo snapshot and dependency
  archives, and the run wants the exact preflight command plus follow-up routes
  on one surface
- the current checkout may not sit beside the default `memory/` or
  `agent_files/` folders and the run wants one helper that resolves those paths
  explicitly

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Print The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
```

If the checkout, Memory folder, or attached files live somewhere unusual,
override the paths:

```bash
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh \
  --repo-root /path/to/browser \
  --memory-root /path/to/memory \
  --agent-files-root /path/to/agent_files
```

Use `--fallback-zig-archive` when the attached
`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle should come from an
explicit path instead of the default `../agent_files/` probe beside the repo
workspace.

Use `--json` when another helper wants the resolved command set as structured
output.

## What The Route Surfaces

The helper prints:

1. a fail-fast surface-check command for
   `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
2. the exact `scripts/check_issue3_saved_memory_inputs.py` command with the
   resolved repo, Memory, and agent-files roots
3. the resolved saved repo snapshot path
4. the resolved blocker-intelligence path
5. the resolved dependency-archive root
6. the resolved fallback Zig archive path or a clear missing-state message
7. the saved-browser-snapshot restore route for runs that still lack a reusable
   checkout
8. the Linux build-readiness route for runs that already have a usable checkout
9. the direct runtime re-entry route for runs that have already cleared the
   restore and toolchain gates

## Working Rules

- Run the surface check first so missing docs or helper drift fails before the
  run blames missing Memory inputs.
- Run the saved-Memory preflight before restore, build-readiness, or runtime
  helpers when the route depends on the saved repo snapshot and dependency
  bundles.
- Use the saved-browser-snapshot route when the saved archive exists but there
  is still no reusable checkout for Linux or WSL follow-up.
- Use the Linux build-readiness route after the saved-Memory preflight passes
  and the next blocker is still Rust, Zig, offline dependency staging, or
  prebuilt V8 readiness.
- Use the direct runtime re-entry route only after the saved checkout exists and
  the environment gates are no longer the blocker.
- Treat the attached Zig `0.17` dev bundle as surfaced fallback input only; do
  not treat it as honest issue `#3` validation evidence for this branch.
