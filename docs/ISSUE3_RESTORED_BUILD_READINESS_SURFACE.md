# Issue #3 Restored Build-Readiness Surface Check

Use this note when a Linux or WSL issue `#11` re-entry run is working from a
restored browser snapshot and needs to confirm that the newer build-readiness
route files were synced into that checkout.

This check exists because an older restored snapshot can still look like a
usable browser repo while missing the newer staged-toolchain and offline-input
route helpers that the current build-readiness lane depends on.

## Run The Helper

From the restored checkout root:

```bash
python ./scripts/check_issue3_restored_build_readiness_surface.py --repo-root .
```

Use `--json` when another helper wants the missing-path list as structured
output.

## What It Checks

The helper verifies that the restored checkout includes:

- `docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
- `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
- `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`

## Working Rule

If this helper fails, refresh the restored checkout helper surface from a live
helper root before trusting the issue `#11` Linux or WSL build-readiness routes.