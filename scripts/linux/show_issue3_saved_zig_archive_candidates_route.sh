#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the saved Zig archive candidates route for the blocked issue #3 Linux or
WSL re-entry lane.
EOF
}

normalize_saved_archives_root() {
    local raw_root="$1"
    if [[ -d "${raw_root}/dependencies" ]]; then
        raw_root="${raw_root}/dependencies"
    fi
    if [[ -d "${raw_root}" ]]; then
        (
            cd "${raw_root}"
            pwd
        )
        return 0
    fi
    printf '%s\n' "${raw_root}"
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
CANDIDATE_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
MATCHING_LINE_GATE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
ARCHIVE_RESTORE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_COMMAND="${CANDIDATE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    MATCHING_LINE_GATE_COMMAND="${MATCHING_LINE_GATE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RECOVERY_ROUTE_COMMAND="${RECOVERY_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Zig archive candidates route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "route_note_path": ${ROUTE_NOTE_PATH@Q},
    "commands": {
        "surface_check": ${SURFACE_COMMAND@Q},
        "candidate_discovery": ${CANDIDATE_COMMAND@Q},
        "matching_line_gate": ${MATCHING_LINE_GATE_COMMAND@Q},
        "archive_restore_surface_check": ${ARCHIVE_RESTORE_SURFACE_COMMAND@Q},
        "zig_recovery_route": ${RECOVERY_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface check first so route drift fails before the run trusts saved Zig archive discovery output.",
        "Use the candidate discovery helper before hand-picking a saved Zig archive from the dependencies folder.",
        "Run the matching-line gate after any restore so the staged toolchains directory has to prove a real 0.15.x candidate exists before broader readiness is trusted again.",
        "Prefer an exact 0.15.2 archive when one exists, otherwise prefer the newest saved archive on the same 0.15.x line.",
        "Keep the work on issue #11 while the lane is still about saved inputs, toolchain recovery, or Linux/WSL readiness gates.",
        "Run the archive-restore surface check before staging a chosen saved archive under ../toolchains.",
        "Return to the broader Zig recovery route after a matching archive is selected or staged.",
        "The saved_archives_root override accepts either repo_archives/browser or repo_archives/browser/dependencies and is normalized before discovery runs."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved Zig archive candidates route

Repo root:            ${REPO_ROOT}
Saved archives root:  ${SAVED_ARCHIVES_ROOT}
Toolchains root:      ${TOOLCHAINS_ROOT}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Route note:           ${ROUTE_NOTE_PATH}

Read first
==========
  docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md

Suggested route
===============
  Route surface check:
    ${SURFACE_COMMAND}

  Saved archive candidate discovery:
    ${CANDIDATE_COMMAND}

  Matching-line gate after any restore:
    ${MATCHING_LINE_GATE_COMMAND}

  Archive restore surface check:
    ${ARCHIVE_RESTORE_SURFACE_COMMAND}

  Broader Zig recovery route:
    ${RECOVERY_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails before the run trusts saved Zig archive discovery output.
  - Use the candidate discovery helper before hand-picking a saved Zig archive from the dependencies folder.
  - Run the matching-line gate after any restore so the staged toolchains root has to prove a real branch-compatible Zig candidate exists.
  - Prefer an exact 0.15.2 archive when one exists, otherwise prefer the newest saved archive on the same 0.15.x line.
  - Keep the work on issue #11 while the lane is still about saved inputs, toolchain recovery, or Linux or WSL readiness gates.
  - Run the archive-restore surface check before staging a chosen saved archive under ../toolchains.
  - Return to the broader Zig recovery route after a matching archive is selected or staged.
  - The saved-archives root override accepts either repo_archives/browser or repo_archives/browser/dependencies and is normalized before discovery runs.
EOF
