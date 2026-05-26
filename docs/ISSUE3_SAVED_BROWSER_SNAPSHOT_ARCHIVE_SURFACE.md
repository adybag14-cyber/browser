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
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_workspace_context.py`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `scripts/linux/check_issue3_zig_toolchain_match.sh`
- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/linux/show_issue3_windows_runtime_handoff_route.sh`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`

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

The checker mirrors the current helper-surface contract from
`scripts/linux/restore_saved_browser_snapshot.sh`, so this note should stay in
step with the synced restore route rather than an older static path list.

The required helper surface mirrors the synced helper contract from
`scripts/linux/restore_saved_browser_snapshot.sh`, including:

- `build.zig.zon`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_workspace_context.py`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
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
- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `scripts/linux/check_issue3_zig_toolchain_match.sh`
- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/restore_saved_rust_toolchain.sh`
- `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/prepare_offline_build_inputs.sh`
- `scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh`
- `scripts/linux/show_issue3_windows_runtime_handoff_route.sh`

## Practical Stale-Archive Symptom

During live validation against the saved Memory snapshot, a plain restore could
still bring back `build.zig.zon` while exposing only a tiny legacy Windows
helper surface under `scripts/windows/`, such as:

- `scripts/windows/check_lightpanda_windows_prereqs.ps1`
- `scripts/windows/manage_build_artifacts.ps1`
- `scripts/windows/package_bare_metal_image.ps1`

Treat that shape as archive age, not restore corruption. The snapshot is still
historically valid, but it is too old to act as the sole helper root for the
current issue `#11` Linux or WSL follow-up commands. Prefer
`--sync-helper-surface`, keep the live helper root visible for the next
commands, and use `--sync-only` when the restored checkout already exists and
only the helper surface needs to catch up.

## Working Rules

- Prefer a plain restore only when the helper reports that the archive already
  contains the current restore and runtime helper surface.
- Prefer `--sync-helper-surface` when one or more helper paths are missing from
  the saved archive, especially the Zig matching-line or archive-restore guard
  scripts.
- Keep the live helper root for the next follow-up commands whenever the archive
  helper surface is stale.
- Treat this helper as a fast restore-route preflight, not as proof that Linux
  or WSL validation is already ready to reopen the direct runtime lane.