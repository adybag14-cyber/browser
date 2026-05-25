# Issue #3 Saved Rust Archive Candidates Route

Use this note when the blocked issue `#3` Linux or WSL recovery path still
needs to choose or confirm the saved Rust `1.79.0` archive before the broader
saved-Rust restore route or Linux build-readiness route should continue.

This route keeps the saved-Rust archive discovery helper, the staged-toolchain
candidate helper, the compact saved-Rust restore route, and the issue `#11`
progress-tracker handoff on one branch-local surface so future reruns do not
need to rebuild the archive-selection path by hand.

## Companion Surfaces

- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- the next rerun needs to confirm which saved Rust archive should drive the
  restore command
- the saved Rust archive exists in Memory, but the run wants the preferred
  archive report and the staged-toolchain candidate check on one compact helper
  surface before unpacking anything
- issue `#11` is still tracking toolchain reuse or restore work and the exact
  saved Rust archive-selection path needs a lower-volume route of its own

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Compact Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
```

Use `--json` when another helper wants the route, preferred archive follow-up,
and next-step commands as structured output.

## Run The Helper

From the browser repo root:

```bash
python scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred archive, saved-archives
root, or surfaced restore commands as structured output.

## Also Check For A Reusable Staged Toolchain

Before unpacking the archive again, surface the staged-toolchain candidates:

```bash
python scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred staged candidate and its
`PATH`, `CARGO`, and `RUSTC` exports as structured output.

## Working Rules

- Run the route surface check first so missing docs or helper drift fails before
  the saved archive itself is blamed.
- Use the compact route when the immediate slice is archive selection rather
  than the full saved-Rust restore flow.
- Run the staged-toolchain helper before restore so the route can reuse an
  already-staged Rust `1.79.0` candidate when one is present.
- Hand off to `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md` once the preferred
  archive or staged candidate is known and the next step is the restore surface,
  restore command, or shell export reuse.
- Keep using `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md` and issue `#11` when this
  slice is still part of the environment-gated Linux or WSL re-entry lane.
- Return to `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md` once the saved Rust
  archive choice is settled and the next rerun needs the broader build-readiness
  ladder again.
