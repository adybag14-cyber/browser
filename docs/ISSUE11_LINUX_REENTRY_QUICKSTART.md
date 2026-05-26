# Issue #11 Linux Re-entry Quickstart

Use this note when the Linux or WSL headed-mode re-entry lane is active and the
run needs one compact reminder of the issue `#11` helper order before broader
build-readiness or runtime replay is reopened.

This quickstart keeps the main issue `#11` recovery surfaces together:

- `scripts/linux/show_issue11_linux_reentry_quickstart.sh`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`

## Use It When

Use this quickstart when any of these are true:

- the run needs to reopen issue `#11` rather than the comment-capped issue `#2`
  or issue `#3` threads
- the saved Memory archives should be trusted before restore or offline staging
- there is still no reusable checkout restored from the saved repo snapshot
- Linux or WSL build-readiness work is blocked on a mismatched Zig line

## Suggested Order

From the browser repo root:

```bash
bash ./scripts/linux/show_issue11_linux_reentry_quickstart.sh
```

That quickstart keeps this compact order visible:

1. Reopen the issue `#11` progress-tracker route.
2. Reopen the saved-archive integrity route before trusting saved inputs.
3. Reopen the saved-browser-snapshot route when no reusable checkout exists.
4. Reopen the Linux build-readiness route after the saved inputs are trusted.
5. Reopen the Zig toolchain recovery route when the staged Zig line still does
   not match `build.zig.zon`.

## Working Rules

- Treat issue `#11` as the current status lane for Linux or WSL re-entry work.
- Prefer the archive-integrity route before restore or offline dependency
  staging when the run depends on saved Memory bundles.
- Prefer the saved-browser-snapshot route when the repo archive exists but no
  reusable checkout is already present beside the workspace.
- Reopen the Zig recovery route before treating the attached Zig `0.17` bundle
  as meaningful validation evidence for a branch that still expects Zig `0.15.x`.
- Hand control back to the direct Windows runtime re-entry route only after the
  Linux or WSL environment gates stop being the blocker.