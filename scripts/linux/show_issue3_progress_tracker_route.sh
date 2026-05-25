#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_progress_tracker_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #11 progress-tracker route for the blocked issue #3 Linux or
WSL re-entry lane.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
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
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ISSUE_NUMBER=11
ISSUE_URL="https://github.com/adybag14-cyber/browser/issues/11"
ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_progress_tracker_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ZIG_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ZIG_ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_RECOVERY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

START_COMMENT_TEMPLATE=$'Goal: <state the exact Linux/WSL re-entry helper or environment gate work>\nStarted: <UTC timestamp>\nNext: <state the first concrete helper, validation check, or branch-safe change you are about to make>'
COMPLETION_COMMENT_TEMPLATE=$'Achieved: <state what route, helper, or branch-safe re-entry improvement landed>\nCompleted: <UTC timestamp>\nCommit: <commit sha>\nValidation: <state the focused helper check, self-test, or follow-up route that now applies>'

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 issue #11 progress-tracker route",
    "repo_root": ${REPO_ROOT@Q},
    "issue_number": ${ISSUE_NUMBER},
    "issue_url": ${ISSUE_URL@Q},
    "route_note_path": ${ROUTE_NOTE_PATH@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "saved_zig_archive_route_surface": ${SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND@Q},
        "saved_memory_inputs_route": ${SAVED_MEMORY_ROUTE_COMMAND@Q},
        "saved_zig_archive_candidates_route": ${SAVED_ZIG_ARCHIVE_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_ROUTE_COMMAND@Q},
        "zig_toolchain_recovery_route": ${ZIG_RECOVERY_ROUTE_COMMAND@Q}
    },
    "start_comment_template": ${START_COMMENT_TEMPLATE@Q},
    "completion_comment_template": ${COMPLETION_COMMENT_TEMPLATE@Q},
    "notes": [
        "Run route_surface first so note drift or helper drift fails fast before a scheduled run trusts issue #11 as its progress target.",
        "Use issue #11 while the Linux or WSL re-entry lane is still blocked on saved-input, toolchain, or offline dependency gates.",
        "When the immediate slice is about choosing or restoring a saved Zig 0.15.x archive, surface the dedicated saved-Zig route before falling back to the broader Zig recovery note.",
        "Thread --fallback-zig-archive through this route when the attached archive is not beside the repo workspace so nested saved-input, saved-Zig, build-readiness, and Zig recovery helpers all inspect the same surfaced path.",
        "Keep the start comment compact with Goal, Started, and Next.",
        "Post the completion comment only after the branch commit exists, and keep it compact with Achieved, Completed, Commit, and Validation.",
        "When the next step is still environment-gated, follow the saved-memory, saved-Zig, build-readiness, or Zig recovery routes instead of reopening the direct Page.zig plus win32_backend.zig patch."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 issue #11 progress-tracker route

Repo root:             ${REPO_ROOT}
Issue:                 #${ISSUE_NUMBER}
Issue URL:             ${ISSUE_URL}
Route note:            ${ROUTE_NOTE_PATH}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Saved Zig route surface check:
    ${SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND}

  Saved-Memory follow-up route:
    ${SAVED_MEMORY_ROUTE_COMMAND}

  Saved Zig archive candidates route:
    ${SAVED_ZIG_ARCHIVE_ROUTE_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Zig toolchain recovery route:
    ${ZIG_RECOVERY_ROUTE_COMMAND}

Start comment template
======================
Goal: <state the exact Linux/WSL re-entry helper or environment gate work>
Started: <UTC timestamp>
Next: <state the first concrete helper, validation check, or branch-safe change you are about to make>

Completion comment template
===========================
Achieved: <state what route, helper, or branch-safe re-entry improvement landed>
Completed: <UTC timestamp>
Commit: <commit sha>
Validation: <state the focused helper check, self-test, or follow-up route that now applies>

Working rules
=============
  - Run the route surface check first so note drift or helper drift fails fast before a scheduled run trusts issue #11 as its progress target.
  - Use issue #11 while the Linux or WSL re-entry lane is still blocked on saved-input, toolchain, or offline dependency gates.
  - When the immediate slice is about choosing or restoring a saved Zig 0.15.x archive, surface the dedicated saved-Zig route before falling back to the broader Zig recovery note.
  - Thread --fallback-zig-archive through this route when the attached archive is not beside the repo workspace so nested saved-input, saved-Zig, build-readiness, and Zig recovery helpers all inspect the same surfaced path.
  - Keep the start comment compact with Goal, Started, and Next.
  - Post the completion comment only after the branch commit exists, and keep it compact with Achieved, Completed, Commit, and Validation.
  - When the next step is still environment-gated, follow the saved-Memory, saved-Zig, build-readiness, or Zig recovery routes instead of reopening the direct Page.zig plus win32_backend.zig patch.
EOF