#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue11_linux_reentry_quickstart.sh \
    [--repo-root /path/to/browser-repo] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print one compact issue #11 Linux/WSL re-entry helper surface for the saved-
archive, progress-tracker, restore, build-readiness, and Zig-recovery routes.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
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

PROGRESS_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_progress_tracker_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PROGRESS_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    ARCHIVE_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": 11,
    "profile": "issue11-linux-reentry-quickstart",
    "repo_root": ${REPO_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "progress_surface": ${PROGRESS_SURFACE@Q},
        "progress_route": ${PROGRESS_ROUTE@Q},
        "archive_surface": ${ARCHIVE_SURFACE@Q},
        "archive_route": ${ARCHIVE_ROUTE@Q},
        "snapshot_surface": ${SNAPSHOT_SURFACE@Q},
        "snapshot_route": ${SNAPSHOT_ROUTE@Q},
        "build_surface": ${BUILD_SURFACE@Q},
        "build_route": ${BUILD_ROUTE@Q},
        "zig_surface": ${ZIG_SURFACE@Q},
        "zig_route": ${ZIG_ROUTE@Q}
    },
    "notes": [
        "Use issue #11 as the current status lane for Linux or WSL re-entry work.",
        "Run the archive-integrity route before trusting saved Memory inputs.",
        "Run the saved-browser-snapshot route when no reusable checkout exists yet.",
        "Run the Linux build-readiness route after the saved inputs are trusted.",
        "Run the Zig recovery route when the staged toolchain still does not match build.zig.zon."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #11 Linux re-entry quickstart

Repo root:            ${REPO_ROOT}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not set}

Read first
==========
  docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md

Suggested order
===============
  Issue #11 progress-tracker surface:
    ${PROGRESS_SURFACE}

  Issue #11 progress-tracker route:
    ${PROGRESS_ROUTE}

  Saved-archive integrity surface:
    ${ARCHIVE_SURFACE}

  Saved-archive integrity route:
    ${ARCHIVE_ROUTE}

  Saved-browser-snapshot restore surface:
    ${SNAPSHOT_SURFACE}

  Saved-browser-snapshot restore route:
    ${SNAPSHOT_ROUTE}

  Linux or WSL build-readiness surface:
    ${BUILD_SURFACE}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE}

  Zig toolchain recovery surface:
    ${ZIG_SURFACE}

  Zig toolchain recovery route:
    ${ZIG_ROUTE}

Working rules
=============
  - Treat issue #11 as the current status lane for Linux or WSL re-entry work.
  - Run the archive-integrity route before trusting saved Memory inputs.
  - Run the saved-browser-snapshot route when no reusable checkout exists yet.
  - Run the Linux build-readiness route only after the saved inputs are trusted.
  - Run the Zig recovery route before treating the attached Zig 0.17 bundle as branch-compatible validation evidence.
EOF