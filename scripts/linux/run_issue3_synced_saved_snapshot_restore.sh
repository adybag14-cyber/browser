#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/run_issue3_synced_saved_snapshot_restore.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--check-only] \
    [--skip-archive-integrity] \
    [--json]

Restore the saved browser snapshot with the current helper surface synced into
that checkout, run the saved-Memory preflight, optionally run the saved-archive
integrity check, and print the next Linux build-readiness and runtime route
commands rooted at the restored checkout.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
FALLBACK_ZIG_ARCHIVE=""
CHECK_ONLY=false
SKIP_ARCHIVE_INTEGRITY=false
JSON=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --helper-root)
            HELPER_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
            shift 2
            ;;
        --destination)
            DESTINATION="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        --skip-archive-integrity)
            SKIP_ARCHIVE_INTEGRITY=true
            shift
            ;;
        --json)
            JSON=true
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
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/${DEFAULT_ARCHIVE_NAME}"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_DESTINATION_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

RESTORE_SCRIPT="${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh"
SAVED_MEMORY_INPUTS_SCRIPT="${DESTINATION}/scripts/check_issue3_saved_memory_inputs.py"
SAVED_ARCHIVE_INTEGRITY_SCRIPT="${DESTINATION}/scripts/check_issue3_saved_archive_integrity.py"
BUILD_ROUTE_SCRIPT="${DESTINATION}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
RUNTIME_ROUTE_SCRIPT="${DESTINATION}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"

if [[ ! -f "${RESTORE_SCRIPT}" ]]; then
    echo "Restore helper is missing: ${RESTORE_SCRIPT}" >&2
    exit 1
fi

RESTORE_CHECK_COMMAND=(
    bash "${RESTORE_SCRIPT}"
    --browser-root "${REPO_ROOT}"
    --helper-root "${HELPER_ROOT}"
    --memory-root "${MEMORY_ROOT}"
    --archive "${ARCHIVE_PATH}"
    --destination "${DESTINATION}"
    --sync-helper-surface
    --check-only
)
RESTORE_COMMAND=(
    bash "${RESTORE_SCRIPT}"
    --browser-root "${REPO_ROOT}"
    --helper-root "${HELPER_ROOT}"
    --memory-root "${MEMORY_ROOT}"
    --archive "${ARCHIVE_PATH}"
    --destination "${DESTINATION}"
    --sync-helper-surface
)
SAVED_MEMORY_COMMAND=(
    python "${SAVED_MEMORY_INPUTS_SCRIPT}"
    --repo-root "${DESTINATION}"
    --helper-root "${DESTINATION}"
)
SAVED_ARCHIVE_COMMAND=(
    python "${SAVED_ARCHIVE_INTEGRITY_SCRIPT}"
    --repo-root "${DESTINATION}"
)
BUILD_ROUTE_COMMAND=(
    bash "${BUILD_ROUTE_SCRIPT}"
    --repo-root "${DESTINATION}"
)
RUNTIME_ROUTE_COMMAND=(
    bash "${RUNTIME_ROUTE_SCRIPT}"
    --repo-root "${DESTINATION}"
)

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    RESTORE_CHECK_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    RESTORE_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    SAVED_MEMORY_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    SAVED_ARCHIVE_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    BUILD_ROUTE_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    RUNTIME_ROUTE_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

restore_check_text="$(printf '%q ' "${RESTORE_CHECK_COMMAND[@]}")"
restore_text="$(printf '%q ' "${RESTORE_COMMAND[@]}")"
saved_memory_text="$(printf '%q ' "${SAVED_MEMORY_COMMAND[@]}")"
saved_archive_text="$(printf '%q ' "${SAVED_ARCHIVE_COMMAND[@]}")"
build_route_text="$(printf '%q ' "${BUILD_ROUTE_COMMAND[@]}")"
runtime_route_text="$(printf '%q ' "${RUNTIME_ROUTE_COMMAND[@]}")"
restore_check_text="${restore_check_text% }"
restore_text="${restore_text% }"
saved_memory_text="${saved_memory_text% }"
saved_archive_text="${saved_archive_text% }"
build_route_text="${build_route_text% }"
runtime_route_text="${runtime_route_text% }"

if [[ "${JSON}" == "true" ]]; then
    python3 - <<PY3
import json
print(json.dumps({
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "destination": ${DESTINATION@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "check_only": ${CHECK_ONLY@Q},
    "skip_archive_integrity": ${SKIP_ARCHIVE_INTEGRITY@Q},
    "commands": {
        "restore_check": ${restore_check_text@Q},
        "restore": ${restore_text@Q},
        "saved_memory_preflight": ${saved_memory_text@Q},
        "saved_archive_integrity": ${saved_archive_text@Q},
        "linux_build_route": ${build_route_text@Q},
        "runtime_route": ${runtime_route_text@Q}
    }
}, indent=2))
PY3
    exit 0
fi

"${RESTORE_CHECK_COMMAND[@]}"

if [[ "${CHECK_ONLY}" == "true" ]]; then
    cat <<EOF
Issue #3 synced saved snapshot restore route (check-only)

Restore helper check:
  ${restore_check_text}

Would run after a synced restore:
  ${restore_text}
  ${saved_memory_text}
EOF
    if [[ "${SKIP_ARCHIVE_INTEGRITY}" == "true" ]]; then
        cat <<EOF
  ${build_route_text}
  ${runtime_route_text}
EOF
    else
        cat <<EOF
  ${saved_archive_text}
  ${build_route_text}
  ${runtime_route_text}
EOF
    fi
    exit 0
fi

"${RESTORE_COMMAND[@]}"
"${SAVED_MEMORY_COMMAND[@]}"

if [[ "${SKIP_ARCHIVE_INTEGRITY}" != "true" ]]; then
    "${SAVED_ARCHIVE_COMMAND[@]}"
fi

cat <<EOF
Issue #3 synced saved snapshot restore route completed

Restored checkout:
  ${DESTINATION}

Completed:
  ${restore_text}
  ${saved_memory_text}
EOF
if [[ "${SKIP_ARCHIVE_INTEGRITY}" == "true" ]]; then
    cat <<EOF

Skipped:
  ${saved_archive_text}
EOF
else
    cat <<EOF
  ${saved_archive_text}
EOF
fi
cat <<EOF

Next:
  ${build_route_text}
  ${runtime_route_text}
EOF
