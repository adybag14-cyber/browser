#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local Linux build-readiness route for the blocked issue
#3 Enter-submit runtime lane still has its required docs, helpers, and command
snippets in place before a run reopens offline staging or focused Zig checks.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --json)
            JSON=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"

declare -a REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should point Linux or WSL reruns at the build-readiness route before focused Zig checks."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should stay paired with the Linux readiness route."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot restore note that should stay visible when no reusable checkout exists yet."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|file|Workspace-context note that should stay visible when nested or restored checkouts need surfaced roots before later route overrides are rebuilt."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Read-first restored-checkout re-entry note that should stay visible before the route trusts a reusable saved snapshot checkout."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Saved-Memory-inputs note that should stay visible before restore, build-readiness, or runtime follow-up commands are trusted."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Read-first issue #11 handoff note that should stay visible while the Linux or WSL lane is still environment-gated."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Read-first saved-archive-integrity note that should stay visible before raw checksum verification commands are trusted."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Read-first saved Rust toolchain note for the blocked issue #3 Linux or WSL route."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note for the blocked issue #3 runtime lane."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig toolchain recovery note for the blocked issue #3 Linux or WSL route."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Read-first Zig archive restore note when a real 0.15.x toolchain archive exists but is not staged yet."
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Read-first offline build-inputs note for the blocked issue #3 Linux or WSL route."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that proves a reusable saved snapshot checkout is safe to trust before wider follow-up helpers."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight that checks the repo snapshot, notes, dependency archives, and fallback Zig surface before offline staging starts."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved archive integrity helper that proves the saved repo snapshot and dependency bundles still match their expected exact artifacts before offline staging starts."
    "scripts/check_issue3_workspace_context.py|file|Workspace-context helper that surfaces the nearest toolchains, saved-archives, and fallback Zig roots before later route overrides are rebuilt by hand."
    "scripts/check_linux_build_readiness.py|file|Python helper that checks saved archives, sibling deps, offline deps, and toolchain readiness."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Fail-fast saved-browser-snapshot checker used when no reusable checkout exists yet."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact saved-browser-snapshot route printer for restoring a disposable checkout before Linux or WSL staging continues."
    "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh|file|Fail-fast restored-checkout re-entry checker used before the route trusts a reusable saved snapshot checkout."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|file|Compact restored-checkout re-entry route printer for validating a reusable saved snapshot checkout before wider follow-up helpers."
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh|file|Fail-fast saved-Memory-inputs checker used before restore, build-readiness, or runtime follow-up routes are trusted."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Compact saved-Memory-inputs route printer for surfacing the preflight and follow-up helper chain on one branch-local surface."
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh|file|Fail-fast issue #11 progress-tracker checker used before the Linux or WSL lane trusts that lower-volume status route."
    "scripts/linux/show_issue3_progress_tracker_route.sh|file|Compact issue #11 progress-tracker route printer that keeps the lower-volume status lane and its follow-up helpers on one branch-local surface."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Fail-fast saved-archive-integrity checker used before raw checksum verification commands are trusted."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Compact saved-archive-integrity route printer that keeps the checksum helper chain on one branch-local surface."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that keeps the saved repo snapshot extraction path on one branch-local surface."
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Fail-fast Zig toolchain recovery checker used before the route blames the fallback Zig bundle."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Compact Zig toolchain recovery route printer for selecting a branch-compatible Zig line."
    "scripts/linux/restore_zig_toolchain_archive.sh|file|Generic Zig archive restore helper for staging a real 0.15.x archive under ../toolchains before rerunning discovery."
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Fail-fast saved Rust route checker used before the route reuses the saved Rust archive."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Compact saved Rust route printer for reusing the saved Rust archive."
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|file|Fail-fast offline build-inputs checker used before the route stages saved archives into sibling dependencies."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Compact offline build-inputs route printer for staging sibling dependencies from the saved archives."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer for the saved-archive-first recovery path."
    "scripts/linux/restore_saved_rust_toolchain.sh|file|Saved Rust restore helper that should keep the check-only and restore commands on one branch-local surface."
    "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper that stages zig-v8-fork, boringssl-zig, and offline-deps."
    "build.zig.zon|file|Manifest surface that defines the branch minimum Zig line and sibling path dependencies."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The gate note keeps the Linux build-readiness note in the direct issue #3 read-first surface."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|The gate note keeps the Linux route printer visible before focused Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|The gate note keeps the saved-Memory input preflight visible before offline staging or focused Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_linux_build_readiness.py|The gate note keeps the Linux readiness helper visible before focused Zig validation."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The Linux build-readiness note keeps the saved-browser-snapshot restore note visible when no reusable checkout exists yet."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|The Linux build-readiness note keeps the workspace-context route note visible before route overrides are rebuilt by hand."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_workspace_context.py|The Linux build-readiness note keeps the workspace-context helper named explicitly before route overrides are rebuilt by hand."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_workspace_context.py --repo-root .|The Linux build-readiness note keeps the exact workspace-context helper command visible before route overrides are rebuilt by hand."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|The Linux build-readiness note keeps the saved-Memory-inputs note visible before the raw preflight is trusted."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|The Linux build-readiness note keeps the issue #11 handoff note visible before broader build-readiness or Zig follow-up output is treated as the plan."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|The Linux build-readiness note keeps the saved Rust toolchain note visible before the archive restore route."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The Linux build-readiness note keeps the Zig recovery note visible before fallback Zig is blamed."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|The Linux build-readiness note keeps the dedicated offline-inputs route visible before raw archive staging."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_browser_snapshot_route_surface.sh|The Linux build-readiness note keeps the saved-browser-snapshot surface checker visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The Linux build-readiness note keeps the saved-browser-snapshot route printer visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|restore_saved_browser_snapshot.sh|The Linux build-readiness note keeps the saved-browser-snapshot restore helper visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_linux_build_readiness_route_surface.sh|The Linux build-readiness note keeps its own fail-fast surface checker visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_memory_inputs_route_surface.sh|The Linux build-readiness note keeps the saved-Memory route surface checker visible before the raw preflight."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_memory_inputs_route.sh|The Linux build-readiness note keeps the saved-Memory route printer visible before the raw preflight."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_progress_tracker_route_surface.sh|The Linux build-readiness note keeps the progress-tracker route surface checker visible before issue #11 is treated as the current status lane."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_progress_tracker_route.sh|The Linux build-readiness note keeps the progress-tracker route printer visible before issue #11 is treated as the current status lane."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh|The Linux build-readiness note keeps the exact progress-tracker surface-check command visible before issue #11 is treated as the current status lane."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|bash ./scripts/linux/show_issue3_progress_tracker_route.sh|The Linux build-readiness note keeps the exact progress-tracker route command visible before issue #11 is treated as the current status lane."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The Linux build-readiness note keeps the saved-Memory input preflight named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The Linux build-readiness note keeps the saved-archive integrity helper named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|The Linux build-readiness note keeps the exact saved-archive integrity command visible before offline staging starts."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The Linux build-readiness note keeps the Zig recovery route named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|The Linux build-readiness note keeps the saved Rust route surface checker named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|The Linux build-readiness note keeps the saved Rust route named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_offline_build_inputs_route.sh|The Linux build-readiness note keeps the offline build-inputs route named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_linux_build_readiness.py|The Linux build-readiness note keeps the readiness helper named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|The Linux build-readiness note keeps the route printer named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|saved Rust 1.79.0 restore command|The Linux build-readiness note keeps the saved Rust restore step visible before trusting Linux or WSL Zig output."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The Linux build-readiness note keeps the attached fallback Zig archive visible as a surfaced input."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The Linux route printer keeps the saved-browser-snapshot note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|The Linux route printer keeps the workspace-context note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|The Linux route printer keeps the restored-checkout re-entry note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|The Linux route printer keeps the saved-Memory-inputs note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|The Linux route printer keeps the issue #11 handoff note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|The Linux route printer keeps the saved-archive-integrity note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|The Linux route printer keeps the saved Rust note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The Linux route printer keeps the Zig recovery note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|The Linux route printer keeps the Zig archive restore note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|The Linux route printer keeps the offline build-inputs note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_workspace_context.py|The Linux route printer keeps the workspace-context helper visible before later route overrides are rebuilt by hand."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|WORKSPACE_CONTEXT_COMMAND|The Linux route printer keeps a dedicated workspace-context command before the saved-browser-snapshot route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Workspace-context helper when the checkout sits deeper than the default sibling layout:|The Linux route printer still prints the workspace-context handoff before the saved-browser-snapshot route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_browser_snapshot_route.sh|The Linux route printer keeps a saved-browser-snapshot restore route visible before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_restored_checkout_reentry_route_surface.sh|The Linux route printer keeps a restored-checkout route surface checker visible before wider saved-input follow-up helpers."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_restored_checkout_reentry_route.sh|The Linux route printer keeps a restored-checkout re-entry route visible before wider saved-input follow-up helpers."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_saved_memory_inputs_route_surface.sh|The Linux route printer keeps a saved-Memory route surface checker visible before the raw preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_memory_inputs_route.sh|The Linux route printer keeps a saved-Memory route printer visible before the raw preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_progress_tracker_route_surface.sh|The Linux route printer keeps a progress-tracker route surface checker visible before the wider Linux or WSL lane treats issue #11 as its current status route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_progress_tracker_route.sh|The Linux route printer keeps a progress-tracker route visible before the wider Linux or WSL lane treats issue #11 as its current status route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND|The Linux route printer keeps a dedicated progress-tracker route surface-check command before the raw saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|PROGRESS_TRACKER_ROUTE_COMMAND|The Linux route printer keeps a dedicated progress-tracker route command before the raw saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Progress-tracker route surface check:|The Linux route printer still prints the progress-tracker route surface step before the raw saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Progress-tracker route:|The Linux route printer still prints the progress-tracker route step before the raw saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|issue #11 should stay visible as the current status lane|The Linux route printer still keeps the issue #11 status-lane rule in its working notes."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_saved_archive_integrity_route_surface.sh|The Linux route printer keeps the saved-archive-integrity surface checker visible before raw checksum verification."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_archive_integrity_route.sh|The Linux route printer keeps the saved-archive-integrity route visible before raw checksum verification."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The Linux route printer keeps the Zig toolchain recovery helper visible before trusting fallback Zig."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|restore_zig_toolchain_archive.sh|The Linux route printer keeps the Zig archive restore helper visible when a real 0.15.x archive exists but is not staged yet."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|The Linux route printer keeps a dedicated saved Rust surface-check command before the saved Rust route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_rust_toolchain_route.sh|The Linux route printer keeps the saved Rust route printer visible before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_offline_build_inputs_route.sh|The Linux route printer keeps the offline build-inputs helper visible before the raw prepare command."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved-browser-snapshot route when no reusable checkout exists yet:|The Linux route printer still prints the saved-browser-snapshot recovery step before the saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|RESTORED_CHECKOUT_ROUTE_SURFACE_COMMAND|The Linux route printer keeps a dedicated restored-checkout route surface-check command before the raw saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|RESTORED_CHECKOUT_ROUTE_COMMAND|The Linux route printer keeps a dedicated restored-checkout re-entry command before the raw saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_MEMORY_ROUTE_SURFACE_COMMAND|The Linux route printer keeps a dedicated saved-Memory route surface-check command before the raw preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_MEMORY_ROUTE_COMMAND|The Linux route printer keeps a dedicated saved-Memory route command before the raw preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_MEMORY_INPUTS_COMMAND|The Linux route printer keeps a dedicated saved-Memory preflight command before the broader saved-archive preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND|The Linux route printer keeps a dedicated saved-archive-integrity surface-check command before raw checksum verification."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_ARCHIVE_ROUTE_COMMAND|The Linux route printer keeps a dedicated saved-archive-integrity route command before raw checksum verification."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_ARCHIVE_INTEGRITY_COMMAND|The Linux route printer keeps a dedicated saved-archive integrity command before the broader saved-archive preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|TOOLCHAIN_ROUTE_COMMAND|The Linux route printer keeps a dedicated Zig recovery command before the broader saved-archive preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|ZIG_ARCHIVE_RESTORE_CHECK_COMMAND|The Linux route printer keeps a dedicated Zig archive restore surface command when a real 0.15.x archive exists but is not staged yet."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_RUST_SURFACE_COMMAND|The Linux route printer keeps a dedicated saved Rust surface-check command before the saved Rust route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|OFFLINE_ROUTE_COMMAND|The Linux route printer keeps a dedicated offline build-inputs command before the broader saved-archive preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_memory_inputs.py|The Linux route printer still points at the saved-Memory input preflight helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_archive_integrity.py|The Linux route printer still points at the saved-archive integrity helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Restored-checkout route surface check:|The Linux route printer still prints the restored-checkout route surface step before the raw saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Restored-checkout re-entry route:|The Linux route printer still prints the restored-checkout re-entry step before the raw saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory route surface check:|The Linux route printer still prints the saved-Memory route surface step before the raw preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory route:|The Linux route printer still prints the saved-Memory route step before the raw preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory input preflight:|The Linux route printer still prints the saved-Memory preflight step before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved archive integrity route surface check:|The Linux route printer still prints the saved-archive-integrity surface-check step before raw checksum verification."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved archive integrity route:|The Linux route printer still prints the saved-archive-integrity route step before raw checksum verification."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved archive integrity preflight:|The Linux route printer still prints the saved-archive integrity step before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Zig toolchain recovery route:|The Linux route printer still prints the Zig toolchain recovery step before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Zig archive restore route when a real 0.15.x archive exists but is not staged yet:|The Linux route printer still prints the Zig archive restore step before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Rust route surface check:|The Linux route printer still prints the saved Rust route surface-check step before the saved Rust route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Offline build-inputs route:|The Linux route printer still prints the offline build-inputs step before the raw prepare command."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux route printer points back to the fail-fast surface checker."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_linux_build_readiness.py|The Linux route printer still points at the readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|restore_saved_rust_toolchain.sh|The Linux route printer still points at the saved Rust restore helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|fallback-zig-archive|The Linux route printer still supports an explicit attached fallback Zig archive override."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Fallback Zig archive:|The Linux route printer still prints the attached fallback Zig archive surface."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|The saved-Memory input preflight still checks for the saved repo snapshot before route replay."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-Memory input preflight still checks for blocker intelligence before route replay."
    "scripts/check_issue3_saved_memory_inputs.py|--fallback-zig-archive|The saved-Memory input preflight still supports an explicit fallback Zig archive override."
    "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|The saved-Memory input preflight still reports a clear pass surface."
    "scripts/check_issue3_saved_archive_integrity.py|Saved archive integrity check passed.|The saved-archive integrity helper still reports a clear pass surface."
    "scripts/check_linux_build_readiness.py|saved Rust toolchain archive|The readiness helper still knows the saved Rust archive contract."
    "scripts/check_linux_build_readiness.py|saved browser dependency archive|The readiness helper still knows the saved browser dependency archive contract."
    "scripts/linux/restore_saved_rust_toolchain.sh|--check-only|The saved Rust restore helper still supports surface-only validation without extraction."
    "scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|The saved Rust restore helper still prints the PATH/CARGO/RUSTC handoff surface."
    "scripts/linux/prepare_offline_build_inputs.sh|--check-only|The offline prep helper still supports surface-only validation without mutation."
)

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

reference_rows=()
content_rows=()
missing_count=0

for entry in "${REFERENCE_PATHS[@]}"; do
    IFS="|" read -r relative_path kind purpose <<<"${entry}"
    full_path="${REPO_ROOT}/${relative_path}"
    exists=0
    if [[ "${kind}" == "directory" ]]; then
        [[ -d "${full_path}" ]] && exists=1
    else
        [[ -f "${full_path}" ]] && exists=1
    fi
    if [[ "${exists}" -eq 0 ]]; then
        missing_count=$((missing_count + 1))
    fi
    reference_rows+=("${relative_path}|${kind}|${purpose}|${exists}")
done

for entry in "${CONTENT_EXPECTATIONS[@]}"; do
    IFS="|" read -r relative_path snippet purpose <<<"${entry}"
    full_path="${REPO_ROOT}/${relative_path}"
    exists=0
    if [[ -f "${full_path}" ]] && grep -Fq -- "${snippet}" "${full_path}"; then
        exists=1
    fi
    if [[ "${exists}" -eq 0 ]]; then
        missing_count=$((missing_count + 1))
    fi
    content_rows+=("${relative_path}|${snippet}|${purpose}|${exists}")
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-linux-build-readiness-route-surface")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "reference_count": %d,\n' "${#reference_rows[@]}"
    printf '  "content_check_count": %d,\n' "${#content_rows[@]}"
    printf '  "missing_count": %d,\n' "${missing_count}"
    printf '  "references": [\n'
    for index in "${!reference_rows[@]}"; do
        IFS="|" read -r relative_path kind purpose exists <<<"${reference_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"path": %s, "kind": %s, "purpose": %s, "exists": %s}' \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${kind}")" \
            "$(json_escape "${purpose}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ],\n'
    printf '  "content_checks": [\n'
    for index in "${!content_rows[@]}"; do
        IFS="|" read -r relative_path snippet purpose exists <<<"${content_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"path": %s, "snippet": %s, "purpose": %s, "exists": %s}' \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${snippet}")" \
            "$(json_escape "${purpose}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ]\n'
    printf '}\n'
    if [[ "${missing_count}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Issue #3 Linux build-readiness route surface check"
echo
echo "Repo root: ${REPO_ROOT}"
echo

for row in "${reference_rows[@]}"; do
    IFS="|" read -r relative_path kind purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Helper source expectations:"
for row in "${content_rows[@]}"; do
    IFS="|" read -r relative_path snippet purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
done

if [[ "${missing_count}" -gt 0 ]]; then
    echo
    echo "Missing checks: ${missing_count}"
    exit 1
fi

echo

echo "All Linux build-readiness surfaces are present."
