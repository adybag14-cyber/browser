# Issue #3 Saved Rust Build-Readiness Bridge Route

Use this note when the blocked issue `#3` Linux or WSL re-entry lane has
already narrowed down to the saved Rust toolchain path and the next run wants a
compact bridge back into the broader issue `#11` build-readiness route.

This route keeps the lower-volume issue `#11` status lane, the saved Rust
archive-selection helpers, the staged Rust candidate helper, the saved Rust
restore route, and the broader Linux build-readiness route on one branch-local
surface.

Companion helpers:

- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
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

## Surface Saved Rust Archive Candidates

When the immediate slice is choosing the saved archive:

```bash
bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
```

## Surface Staged Rust Toolchain Candidates

Before unpacking the saved archive again, check whether a reusable Rust
`1.79.x` toolchain is already staged:

```bash
python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred staged candidate or its
recommended shell exports as structured output.

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
