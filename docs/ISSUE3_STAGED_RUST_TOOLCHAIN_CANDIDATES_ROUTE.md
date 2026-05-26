# Issue #3 Staged Rust Toolchain Candidates Route

Use this note when the Linux or WSL headed runtime re-entry lane needs to prove
whether a reusable Rust `1.79.x` toolchain is already staged under
`../toolchains` before it falls back to saved-archive restore work.

This route keeps the staged-toolchain candidate helper, the saved Rust archive
selection route, the saved Rust restore route, the saved-Rust build-readiness
bridge, and the issue `#11` handoff on one branch-local surface so future runs
do not have to rebuild the staged-toolchain reuse path by hand.

## Companion Surfaces

- `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- a run wants to know whether a staged Rust toolchain already satisfies the
  expected `1.79.x` line before unpacking any archive again
- the next rerun needs the preferred staged Rust candidate and its shell exports
  on one compact helper surface
- the saved Rust archive route is visible, but the immediate slice is staged
  toolchain reuse rather than archive selection
- issue `#11` is still tracking Rust-side build readiness work and this staged
  reuse slice needs its own lower-volume branch-local route

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Compact Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh
```

Use `--json` when another helper wants the route, staged-candidate discovery,
and handoff commands as structured output.

## Run The Helper

From the browser repo root:

```bash
python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred staged candidate and its
`PATH`, `CARGO`, and `RUSTC` exports as structured output.

## Working Rules

- Run the route surface check first so missing docs or helper drift fails before
  the run trusts staged-toolchain discovery output.
- Use the staged-toolchain candidate helper before saved-archive restore so a
  matching Rust `1.79.x` toolchain can be reused instead of unpacked again.
- If a staged candidate is already good enough, surface the saved-Rust restore
  route only when the exact restore and shell-export ladder is still needed.
- If no matching staged candidate exists, hand off to
  `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md` or the saved-Rust
  build-readiness bridge instead of rebuilding restore commands by hand.
- Keep using issue `#11` when this slice is still about saved inputs,
  toolchain reuse, or Linux or WSL readiness gates rather than the direct
  `Page.zig` plus `win32_backend.zig` runtime patch.
