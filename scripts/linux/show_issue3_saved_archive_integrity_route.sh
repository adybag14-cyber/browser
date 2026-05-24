#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_archive_integrity_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--agent-files-root /path/to/workspace/agent_files] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--require-fallback-zig] \
    [--json]

Print the saved-archive-integrity route for the blocked issue #3 recovery path.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
MEMORY_ROOT=""
AGENT_FILES_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
REQUIRE_FALLBACK_ZIG=0
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --agent-files-root)
            AGENT_FILES_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --require-fallback-zig)
            REQUIRE_FALLBACK_ZIG=1
            shift
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${AGENT_FILES_ROOT}" ]]; then
    AGENT_FILES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/agent_files"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${AGENT_FILES_ROOT}/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
VERIFY_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
STRICT_VERIFY_COMMAND="${VERIFY_COMMAND} --require-fallback-zig"
SNAPSHOT_SURFACE_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_browser_snapshot_archive_surface.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PRESENCE_PREFLIGHT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    VERIFY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    STRICT_VERIFY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PRESENCE_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved archive integrity route",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "agent_files_root": ${AGENT_FILES_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "require_fallback_zig": ${REQUIRE_FALLBACK_ZIG},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "verify": ${VERIFY_COMMAND@Q},
        "verify_strict": ${STRICT_VERIFY_COMMAND@Q},
        "snapshot_surface": ${SNAPSHOT_SURFACE_COMMAND@Q},
        "presence_preflight": ${PRESENCE_PREFLIGHT_COMMAND@Q},
        "restore_route": ${RESTORE_ROUTE_COMMAND@Q},
        "build_route": ${BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing note, helper, or follow-up drift fails fast before the route is trusted.",
        "Run verify next to confirm the saved repo snapshot and dependency bundles match their expected SHA-256 fingerprints.",
        "Use verify_strict when the fallback Zig archive must also exist and match before the route is considered green.",
        "Run snapshot_surface after checksum verification to confirm the saved snapshot zip already carries the current issue #3 restore and runtime helper surface.",
        "Run presence_preflight after the checksum and snapshot-surface checks so path and readability checks complement the exact archive fingerprints and helper-surface drift check.",
        "Use restore_route when the next blocked step still needs a disposable restored checkout from Memory.",
        "Use build_route when the next blocked step is Linux or WSL dependency staging or toolchain recovery.",
        "Use runtime_route only after the saved archives are trusted and the next run is ready to reopen the narrowed Page.zig plus win32_backend.zig lane."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved archive integrity route

Repo root:            ${REPO_ROOT}
Memory root:          ${MEMORY_ROOT}
Agent files root:     ${AGENT_FILES_ROOT}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Require fallback Zig: $([[ "${REQUIRE_FALLBACK_ZIG}" -eq 1 ]] && echo yes || echo no)

Read first
==========
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Verify saved archive SHA-256 fingerprints:
    ${VERIFY_COMMAND}

  Strict archive verification when fallback Zig must also match:
    ${STRICT_VERIFY_COMMAND}

  Saved snapshot archive surface:
    ${SNAPSHOT_SURFACE_COMMAND}

  Saved-Memory presence preflight:
    ${PRESENCE_PREFLIGHT_COMMAND}

  Saved-browser-snapshot restore route:
    ${RESTORE_ROUTE_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing note or helper drift fails fast before the route is trusted.
  - Run the SHA-256 verification before the saved-snapshot archive-surface check when the run needs to trust the exact archive contents.
  - Use the strict verification form when fallback Zig must be present for the next route replay.
  - Run the saved-snapshot archive-surface check before the saved-Memory presence preflight so a readable but stale snapshot fails fast.
  - Treat checksum mismatch as an environment problem first, not as proof that the issue #3 runtime patch regressed.
  - Continue into the restore, build-readiness, or runtime routes only after the checksum, snapshot-surface, and presence checks agree.
EOF