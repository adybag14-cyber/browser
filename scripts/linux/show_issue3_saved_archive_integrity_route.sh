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

Print the saved-archive-integrity route for the blocked issue #3 restore and
Linux build-readiness path.
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

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
INTEGRITY_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --agent-files-root $(format_shell_arg "${AGENT_FILES_ROOT}")"
PRESENCE_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PRESENCE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi
if [[ "${REQUIRE_FALLBACK_ZIG}" -eq 1 ]]; then
    INTEGRITY_COMMAND+=" --require-fallback-zig"
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
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_archive_integrity": ${INTEGRITY_COMMAND@Q},
        "saved_memory_presence": ${PRESENCE_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run surface_check first so missing docs or helper drift fails fast before checksum work starts.",
        "Run saved_archive_integrity next when the route needs proof that the saved snapshot and dependency bundles still match the expected SHA-256 fingerprints.",
        "Use --require-fallback-zig when the attached Zig bundle is part of the route contract rather than an optional fallback.",
        "Run saved_memory_presence after checksum success when the route still needs the broader saved-file presence surface in one helper step.",
        "Move to saved_browser_snapshot_route when the next step is extracting a disposable checkout from the verified snapshot.",
        "Move to linux_build_readiness_route when the next step is offline staging, toolchain recovery, or readiness checks against the verified archives."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved archive integrity route

Repo root:             ${REPO_ROOT}
Memory root:           ${MEMORY_ROOT}
Agent files root:      ${AGENT_FILES_ROOT}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Require fallback Zig:  $([[ "${REQUIRE_FALLBACK_ZIG}" -eq 1 ]] && echo yes || echo no)

Read first
==========
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved archive integrity check:
    ${INTEGRITY_COMMAND}

  Saved Memory presence check:
    ${PRESENCE_COMMAND}

  Saved-browser-snapshot route:
    ${SNAPSHOT_ROUTE_COMMAND}

  Linux build-readiness route:
    ${BUILD_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails fast before checksum work starts.
  - Treat checksum mismatch as an input problem first, not as proof that the source tree or toolchain regressed.
  - Use --require-fallback-zig only when the attached Zig bundle is a real route requirement rather than an optional fallback surface.
  - Move to the saved-browser-snapshot route when the next step is extracting a disposable checkout from the verified snapshot.
  - Move to the Linux build-readiness route when the next step is offline staging, toolchain recovery, or broader readiness checks against the verified archives.
EOF
