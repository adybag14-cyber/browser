# Issue #3 Linux Environment Re-entry Route

Use this note when the direct issue `#3` runtime lane is still blocked by Linux
or WSL environment setup, and the next run needs one compact branch-local path
from the saved Memory snapshot through restored-checkout readiness, archive
trust, build readiness, and back into the narrowed runtime route.

This route does not replace the narrower helpers that already exist on the
branch. Its job is to keep them in the right order so a rerun does not skip from
saved archives straight into focused Zig commands or the blocked
`Page.zig` plus `win32_backend.zig` lane.

Keep these nearby:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/linux/show_issue3_linux_environment_reentry_route.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when all of these are true:

- the run still depends on the saved Memory repo snapshot or dependency bundles
- Linux or WSL is the current staging surface for issue `#3`
- the next direct runtime change is still blocked until the environment gates are
  green
- the saved snapshot may need to become its own follow-up checkout root for the
  next run

## Practical Order

1. Fail fast on branch-local helper drift before touching the saved snapshot:

```bash
bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh
bash ./scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
```

2. Print the compact wrapper route so the whole environment ladder stays on one
   surface:

```bash
bash ./scripts/linux/show_issue3_linux_environment_reentry_route.sh
```

3. Prefer the synced saved-snapshot restore path when the restored checkout
   should become its own follow-up root:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface
```

4. Run the restored-checkout route immediately after restore so checkout drift is
   caught before archive or toolchain work widens back out:

```bash
bash ./scripts/linux/show_issue3_restored_checkout_reentry_route.sh --expect-helper-surface
```

5. Once the restored checkout carries the synced helper surface, keep the next
   commands rooted in that restored checkout:

```bash
bash ../browser-memory-snapshot/scripts/linux/show_issue3_saved_archive_integrity_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

## Why The Synced Restore Is Preferred

The saved archive is a stable historical checkpoint, but it can lag the live
helper surface on `fork/headed-mode-foundation`.

If the next run wants the restored checkout to be its own command root, a plain
archive restore is not enough. The helper surface should be synced into the
restored checkout first so the saved-archive, build-readiness, and runtime route
printers all describe the same branch-local state.

## Working Rule

For issue `#3` Linux or WSL recovery, do not jump directly from saved-archive
presence checks into focused Zig validation.

Keep the route ordered like this:

- saved snapshot surface
- restored-checkout readiness
- saved-archive integrity
- Linux build readiness
- narrowed runtime re-entry

If one of those gates is still closed, stay on the helper route that owns that
gate instead of forcing the `Page.zig` and `win32_backend.zig` patch path too
early.
