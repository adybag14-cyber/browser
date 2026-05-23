# Issue #3 Saved Build Workspace Bootstrap

Use this helper when the saved browser snapshot and dependency archives are
present, but the next Linux or WSL run still needs several manual steps before
it can honestly reopen the headed runtime lane.

Helper:

- `scripts/linux/bootstrap_issue3_saved_build_workspace.sh`

## Goal

Keep the common saved-archive recovery path on one executable surface:

- optionally restore the saved browser snapshot into a disposable checkout
- rerun the saved-Memory preflight against the target checkout
- restore the saved Rust `1.79.0` toolchain
- stage the offline sibling dependencies expected by `build.zig.zon`
- rerun the Linux build-readiness helper before the route widens back out

## Typical Use

From the live `fork/headed-mode-foundation` checkout:

```bash
bash ./scripts/linux/bootstrap_issue3_saved_build_workspace.sh --check-only
bash ./scripts/linux/bootstrap_issue3_saved_build_workspace.sh --restore-snapshot-first
```

Use `--restore-snapshot-first` when the route should restore
`../browser-memory-snapshot` from the saved Memory archive before staging the
toolchain and offline dependencies. Leave that flag off when the current
checkout is already the target workspace.

Add `--zig /path/to/zig` when a branch-compatible Zig toolchain is available
and the helper should rerun the full readiness check instead of
`--skip-zig-check`.

## Working Rules

- Run this helper from the live branch checkout so it can keep using the newest
  branch-local helper scripts even when the target workspace is a restored
  snapshot.
- Treat the builder-attached Zig `0.17` archive as a surfaced fallback only.
  Without `--zig`, this helper intentionally leaves the Zig-line decision to
  the dedicated recovery route instead of claiming honest focused validation.
- After the bootstrap succeeds, hand back to
  `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh` before
  widening back out to larger attached-page or live-Google replay.
