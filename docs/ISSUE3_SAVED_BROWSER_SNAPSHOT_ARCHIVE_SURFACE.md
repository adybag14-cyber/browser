# Issue #3 Saved Browser Snapshot Archive Surface

Use this helper when the saved Memory snapshot exists, but the next Linux or
WSL replay needs to know whether that archive already contains the current issue
#3 restore and runtime helper surface.

This keeps one repeat blocker on a small branch-local command surface:

- the saved repo snapshot can lag newer helper docs and route scripts even when
  the zip is still readable
- a plain restore can look valid even when the restored checkout is missing the
  helper surface needed for the next follow-up commands
- future runs should know up front when `--sync-helper-surface` is the safer
  restore mode

Companion helpers:

- `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## Usage

From the browser repo root:

```bash
python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py
python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --json
```

Use `--memory-root /path/to/memory` or `--archive /path/to/snapshot.zip` when
the saved snapshot lives outside the default agent layout.

## What It Reports

The helper inspects the saved archive and reports:

- the resolved snapshot archive path
- the inferred top-level folder inside the zip
- whether the current helper surface is already present inside the archive
- which helper paths are missing when the archive is stale
- whether a plain restore is safe or `--sync-helper-surface` should be used

The required helper surface mirrors the synced helper contract from
`scripts/linux/restore_saved_browser_snapshot.sh`, including:

- `build.zig.zon`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/windows/HeadedValidationHelpers.ps1`
- `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1`
- `scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- `scripts/windows/start_attached_pages_catalog.ps1`
- `tmp-browser-smoke/attached-pages/README.md`
- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
- `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/restore_saved_rust_toolchain.sh`
- `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/prepare_offline_build_inputs.sh`

## Working Rules

- Prefer a plain restore only when the helper reports that the archive already
  contains the current restore and runtime helper surface.
- Prefer `--sync-helper-surface` when one or more helper paths are missing from
  the saved archive.
- Keep the live helper root for the next follow-up commands whenever the archive
  helper surface is stale.
- Treat this helper as a fast restore-route preflight, not as proof that Linux
  or WSL validation is already ready to reopen the direct runtime lane.