#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_toolchain_gate_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser] \
    [--toolchains-root /path/to/toolchains] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact Linux or WSL toolchain-gate route for the blocked issue #3
Enter-submit runtime lane.
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
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
RUST_TOOLCHAIN_DIR=""
OFFLINE_DEPS_ROOT=""
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
        --rust-toolchain-dir)
            RUST_TOOLCHAIN_DIR="$2"
            shift 2
            ;;
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
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
WORKSPACE_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="${TOOLCHAINS_ROOT}/rust-1.79.0"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

MINIMUM_ZIG="$(
    python3 - "${REPO_ROOT}/build.zig.zon" <<'PY'
from __future__ import annotations

import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
match = re.search(r'\.minimum_zig_version\s*=\s*"([^"]+)"', text)
if match is None:
    raise SystemExit(f"Could not find minimum_zig_version in {path}")
print(match.group(1))
PY
)"
MINIMUM_ZIG_LINE="${MINIMUM_ZIG%.*}.x"

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_INPUTS_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
ZIG_TOOLCHAIN_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
LIGHT_READINESS_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_linux_build_readiness.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
FULL_READINESS_TEMPLATE="python $(format_shell_arg "${REPO_ROOT}/scripts/check_linux_build_readiness.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --zig /path/to/zig --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --expect-offline-deps --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}") --require-prebuilt-v8 --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_TOOLCHAIN_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LIGHT_READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FULL_READINESS_TEMPLATE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 toolchain-gate route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "minimum_zig": ${MINIMUM_ZIG@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "saved_rust_route": ${SAVED_RUST_ROUTE_COMMAND@Q},
        "zig_toolchain_route": ${ZIG_TOOLCHAIN_ROUTE_COMMAND@Q},
        "offline_build_inputs_route": ${OFFLINE_ROUTE_COMMAND@Q},
        "light_readiness": ${LIGHT_READINESS_COMMAND@Q},
        "full_readiness_template": ${FULL_READINESS_TEMPLATE@Q}
    },
    "notes": [
        "Run the surface check first so missing helper drift fails before the toolchain gate blames archives or Zig line mismatches.",
        "Run the saved-memory and saved-archive checks before replaying restore routes when this run depends on the saved snapshot and dependency bundles.",
        "Use the saved Rust route and Zig toolchain route together when the direct runtime patch is blocked on branch-compatible validation tooling.",
        "Use the offline build-inputs route when sibling dependency staging still blocks the first honest Linux or WSL readiness pass.",
        "Only treat the full readiness rerun as meaningful after a real Zig ${MINIMUM_ZIG_LINE} path is available."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 toolchain-gate route

Repo root:            ${REPO_ROOT}
Saved archive root:   ${SAVED_ARCHIVES_ROOT}
Toolchains root:      ${TOOLCHAINS_ROOT}
Rust toolchain dir:   ${RUST_TOOLCHAIN_DIR}
Offline deps root:    ${OFFLINE_DEPS_ROOT}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Minimum Zig line:     ${MINIMUM_ZIG}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved Memory input preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  Saved archive integrity preflight:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Saved Rust toolchain route:
    ${SAVED_RUST_ROUTE_COMMAND}

  Zig toolchain recovery route:
    ${ZIG_TOOLCHAIN_ROUTE_COMMAND}

  Offline build-inputs route:
    ${OFFLINE_ROUTE_COMMAND}

  Lightweight readiness rerun before a real Zig path is selected:
    ${LIGHT_READINESS_COMMAND}

  Full readiness rerun after a real Zig ${MINIMUM_ZIG_LINE} path is staged:
    ${FULL_READINESS_TEMPLATE}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails before the toolchain gate starts blaming archive or Zig state.
  - Run the saved Memory preflight and then the saved archive integrity check when this replay still depends on the saved snapshot and dependency bundles.
  - Use the saved Rust route and the Zig toolchain recovery route together when the direct runtime patch is blocked on branch-compatible validation tooling.
  - Use the offline build-inputs route when sibling dependency staging still blocks the first honest Linux or WSL readiness pass.
  - Treat the attached Zig 0.17 dev bundle as a surfaced fallback only, not as honest validation evidence for this branch.
  - Only reopen the direct Page.zig plus win32_backend.zig patch after the full readiness rerun stops reporting the environment as the blocker.
EOF
