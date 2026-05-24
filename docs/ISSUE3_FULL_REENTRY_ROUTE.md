# Issue #3 Full Recovery Route

Use this note when the direct issue `#3` runtime patch is still blocked, but the
run can still move the branch forward by reopening the saved-browser-snapshot,
saved-archive, toolchain, and offline-dependency routes in one exact order.

This route is intentionally narrower than the broad production guide and more
compact than reading each Linux or WSL helper note separately. Its job is to
keep the next replay on one branch-local surface until the environment stops
being the blocker for:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

Companion helpers:

- `scripts/linux/show_issue3_full_reentry_route.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`

## When To Use It

Use this route when any of these are true:

- the next run needs a single command surface for the saved-browser-snapshot,
  toolchain, and offline-input ladders
- the direct issue `#3` runtime patch is still blocked on Linux or WSL restore,
  archive, Rust, Zig, or offline dependency staging
- the next writable checkout should avoid re-planning the same recovery order
  from scratch before returning to the Windows runtime probes

## Run The Helper

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_full_reentry_route.sh
```

If the repo, toolchains, or saved browser archive roots live somewhere unusual,
override them explicitly:

```bash
bash ./scripts/linux/show_issue3_full_reentry_route.sh \
  --repo-root /path/to/browser \
  --saved-browser-archives-root /path/to/memory/repo_archives/browser \
  --toolchains-root /path/to/toolchains \
  --rust-toolchain-dir /path/to/toolchains/rust-1.79.0 \
  --offline-deps-root /path/to/offline-deps
```

Use `--fallback-zig-archive` when the attached
`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle lives somewhere other
than the default `../agent_files/` location beside the repo workspace.

Use `--json` when another helper wants the full command stack as structured
output.

## What The Route Surfaces

The helper keeps the recovery order compact:

1. a fail-fast Linux build-readiness surface check
2. the saved-browser-snapshot restore route
3. the preferred synced saved-browser-snapshot route for stale helper surfaces
4. the saved-Memory preflight
5. the saved-archive integrity preflight
6. the Zig line recovery route
7. the saved Rust toolchain route
8. the offline build-inputs route
9. the Linux or WSL build-readiness route
10. the Windows runtime surface handoff
11. the Windows runtime route handoff

## Working Rules

- Run this full route when the recovery order itself is the blocker, not only
  one individual helper.
- If no reusable checkout exists beside the workspace, use the saved-browser-
  snapshot route before the broader Linux or WSL routes.
- Prefer the synced saved-browser-snapshot route when the restored checkout
  should become its own follow-up root because the archive can lag the live
  helper surface.
- Run the saved-Memory preflight before the archive-integrity check when the
  route depends on the saved repo snapshot and dependency bundles.
- Run the Zig line recovery route before trusting the attached Zig `0.17`
  fallback or any mismatched staged Zig candidate as issue `#3` evidence.
- Run the saved Rust toolchain route and the offline build-inputs route before
  the broader Linux or WSL readiness route when the run still depends on saved
  archives.
- Return to the Windows runtime surface and then the Windows runtime route as
  soon as the Linux or WSL path stops reporting the environment as the blocker.
- Reopen the direct `Page.zig` plus `win32_backend.zig` runtime patch only
  after this route and the reduced Windows replay agree that the environment is
  ready.