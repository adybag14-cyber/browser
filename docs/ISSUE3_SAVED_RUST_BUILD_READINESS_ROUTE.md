# Issue #3 Saved Rust Build-Readiness Bridge Route

Use this note when the blocked issue `#3` Linux or WSL re-entry lane has
already narrowed down to the saved Rust toolchain path and the next run wants a
compact bridge back into the broader issue `#11` build-readiness route.

This route keeps the lower-volume issue `#11` status lane, the saved-memory
preflight handoff, the nested-workspace saved-memory rerun helper, the
workspace-context root-discovery handoff, the toolchains-root candidate helper,
the saved Rust archive-selection helpers, the staged Rust route note and
route-surface helpers, the staged Rust candidate helper, the saved Rust restore
route, and the broader Linux build-readiness route on one branch-local surface.

Companion helpers:

- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `scripts/check_issue11_toolchains_root_candidates.py`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh`
- `scripts/linux/check_issue3_workspace_context_route_surface.sh`
- `scripts/linux/show_issue3_workspace_context_route.sh`
- `scripts/check_issue3_workspace_context.py`
- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
- `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_linux_build_readiness.py`

## When To Use It

Use this route when any of these are true:

- the Linux or WSL re-entry lane is still environment-gated and issue `#11`
  should stay visible as the current status lane
- the next step is choosing or restoring the saved Rust toolchain before the
  broader Linux build-readiness route is replayed
- a staged Rust `1.79.x` toolchain may already exist under `../toolchains` and
  should be surfaced before the saved archive is unpacked again
- the current checkout may be nested or restored deeply enough that the Rust
  bridge should reconfirm the saved-memory and workspace roots before it trusts
  archive-selection or restore output

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Keep Issue #11 Visible

Before treating Rust archive selection or Rust restore output as the current
lane, reopen the lower-volume tracker surface:

```bash
bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh
bash ./scripts/linux/show_issue3_progress_tracker_route.sh
```

## Reconfirm Saved-Memory Inputs Before The Rust Bridge Widens

When the run has not yet revalidated the saved repo snapshot, dependency
archives, helper roots, or restored-checkout path for this workspace layout,
reopen the saved-memory route before choosing or restoring Rust inputs:

```bash
bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
```

If the checkout sits deeper than the default sibling layout and the run wants a
one-command rerun that surfaces the practical helper, Memory, agent-files, and
restored-checkout roots before the saved-memory preflight runs, prefer:

```bash
bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh
```

When the run only needs a fast branch decision before it widens into Rust
archive selection or staged-toolchain reuse, use the quick-presence variant:

```bash
bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh \
  --skip-archive-integrity-check
```

If the workspace layout is unusual and the run needs to inspect the surfaced
shared roots directly before trusting the nested-workspace rerun, reopen the
workspace-context route first:

```bash
bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh
bash ./scripts/linux/show_issue3_workspace_context_route.sh
python ./scripts/check_issue3_workspace_context.py --repo-root .
```

## Surface The Toolchains Root Before Rust Helpers Guess It

When both `toolchains/` and `.toolchains/` may be visible above the checkout,
stop guessing before the saved-Rust archive, staged-Rust, or broader Linux
build-readiness helpers inherit the wrong root:

```bash
python ./scripts/check_issue11_toolchains_root_candidates.py --repo-root .
```

Use its preferred `--toolchains-root` override before rerunning the saved-Rust
archive helper, staged-Rust helper, or Linux build-readiness helper from the
same workspace layout.

## Surface Saved Rust Archive Candidates

When the immediate slice is choosing the saved archive:

```bash
bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
```

## Surface Staged Rust Toolchain Candidates

Before unpacking the saved archive again, reopen the narrower staged-Rust route
so the route surface and compact handoff stay visible first:

```bash
bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh
```

Then check whether a reusable Rust `1.79.x` toolchain is already staged:

```bash
python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred staged candidate or its
recommended shell exports as structured output.

If no staged candidate is good enough, fall back to the saved Rust archive
route instead of rebuilding restore commands by hand.

## Reopen The Saved Rust Route

When the saved archive still needs to be restored, or when the staged candidate
output should be paired back to the exact restore and export surface:

```bash
bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
```

## Hand Back To Linux Build Readiness

Once the Rust route is no longer the blocker, reopen the broader Linux or WSL
build-readiness route:

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
python ./scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```

That keeps the Rust bridge narrow while still handing control back to the full
saved-archive, offline-inputs, Zig-line, and Windows-runtime handoff route as
soon as the Rust toolchain stops being the main gate.
