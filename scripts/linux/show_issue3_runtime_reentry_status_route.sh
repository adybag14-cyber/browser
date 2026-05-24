#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cat <<EOF
Issue #3 runtime re-entry status route

Repo root:
  ${REPO_ROOT}

Surface check:
  bash ./scripts/linux/check_issue3_runtime_reentry_status_route_surface.sh

Quick saved-input plus readiness summary:
  python scripts/check_issue3_runtime_reentry_status.py \
    --repo-root . \
    --skip-zig-check \
    --skip-rust-check

Full Linux/WSL readiness summary:
  python scripts/check_issue3_runtime_reentry_status.py \
    --repo-root . \
    --expect-offline-deps \
    --require-prebuilt-v8

If the summary stops on the publication gate:
  Confirm a safe writable publication route for:
    - src/browser/Page.zig
    - src/display/win32_backend.zig

If the summary stops on Zig line recovery:
  bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh

If the summary stops on offline Linux/WSL inputs:
  bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh

If the summary stops on the restored checkout helper surface:
  bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface
EOF
