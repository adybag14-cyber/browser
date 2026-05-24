#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_build_workspace_bootstrap_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--snapshot-destination /path/to/restored/browser-memory-snapshot] \
    [--target-repo-root /path/to/repo-to-stage] \
    [--dependencies-root /path/to/memory/repo_archives/browser/dependencies] \
    [--toolchain-root /path/to/toolchains/rust-1.79.0] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--zig /path/to/zig] \
    [--json]

Print the one-command bootstrap route for reopening the Linux or WSL saved-build
workspace used by the blocked Google issue #3 Enter-submit runtime lane.
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
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
SNAPSHOT_DESTINATION=""
TARGET_REPO_ROOT=""
DEPENDENCIES_ROOT=""
TOOLCHAIN_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
ZIG_BIN=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --snapshot-destination)
            SNAPSHOT_DESTINATION="$2"
            shift 2
            ;;
        --target-repo-root)
            TARGET_REPO_ROOT="$2"
            shift 2
            ;;
        --dependencies-root)
            DEPENDENCIES_ROOT="$2"
            shift 2
            ;;
        --toolchain-root)
            TOOLCHAIN_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --zig)
            ZIG_BIN="$2"
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
if [[ -z "${SNAPSHOT_DESTINATION}" ]]; then
    SNAPSHOT_DESTINATION="${WORKSPACE_ROOT}/browser-memory-snapshot"
fi
if [[ -z "${TARGET_REPO_ROOT}" ]]; then
    TARGET_REPO_ROOT="${SNAPSHOT_DESTINATION}"
fi
if [[ -z "${DEPENDENCIES_ROOT}" ]]; then
    DEPENDENCIES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${TOOLCHAIN_ROOT}" ]]; then
    TOOLCHAIN_ROOT="${WORKSPACE_ROOT}/toolchains/rust-1.79.0"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_build_workspace_bootstrap_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LIVE_BOOTSTRAP_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/bootstrap_issue3_saved_build_workspace.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --target-repo-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}") --check-only"
LIVE_BOOTSTRAP_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/bootstrap_issue3_saved_build_workspace.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --target-repo-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}")"
SNAPSHOT_BOOTSTRAP_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/bootstrap_issue3_saved_build_workspace.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --target-repo-root $(format_shell_arg "${TARGET_REPO_ROOT}") --snapshot-destination $(format_shell_arg "${SNAPSHOT_DESTINATION}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}") --restore-snapshot-first --check-only"
SNAPSHOT_BOOTSTRAP_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/bootstrap_issue3_saved_build_workspace.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --target-repo-root $(format_shell_arg "${TARGET_REPO_ROOT}") --snapshot-destination $(format_shell_arg "${SNAPSHOT_DESTINATION}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}") --restore-snapshot-first --force-restore"
ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${DEPENDENCIES_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${TARGET_REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    LIVE_BOOTSTRAP_CHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LIVE_BOOTSTRAP_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_BOOTSTRAP_CHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_BOOTSTRAP_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi
if [[ -n "${ZIG_BIN}" ]]; then
    LIVE_BOOTSTRAP_CHECK_COMMAND+=" --zig $(format_shell_arg "${ZIG_BIN}")"
    LIVE_BOOTSTRAP_COMMAND+=" --zig $(format_shell_arg "${ZIG_BIN}")"
    SNAPSHOT_BOOTSTRAP_CHECK_COMMAND+=" --zig $(format_shell_arg "${ZIG_BIN}")"
    SNAPSHOT_BOOTSTRAP_COMMAND+=" --zig $(format_shell_arg "${ZIG_BIN}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved build workspace bootstrap route",
    "repo_root": ${REPO_ROOT@Q},
    "snapshot_destination": ${SNAPSHOT_DESTINATION@Q},
    "target_repo_root": ${TARGET_REPO_ROOT@Q},
    "dependencies_root": ${DEPENDENCIES_ROOT@Q},
    "toolchain_root": ${TOOLCHAIN_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "zig_bin": ${ZIG_BIN@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "live_checkout_check_only": ${LIVE_BOOTSTRAP_CHECK_COMMAND@Q},
        "live_checkout_execute": ${LIVE_BOOTSTRAP_COMMAND@Q},
        "snapshot_checkout_check_only": ${SNAPSHOT_BOOTSTRAP_CHECK_COMMAND@Q},
        "snapshot_checkout_execute": ${SNAPSHOT_BOOTSTRAP_COMMAND@Q},
        "zig_route": ${ZIG_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface check before trusting the bootstrap helper so missing branch-local scripts fail fast.",
        "Use the live checkout variant when the current repo already has the helper surface and sibling layout you want to stage.",
        "Use the snapshot variant when the saved Memory archive should become a disposable revalidation checkout.",
        "Prefer a Zig 0.15.x toolchain for honest branch validation; only use the surfaced 0.17 fallback for discovery when no better Zig is staged yet.",
        "If the bootstrap helper still cannot complete the Linux readiness pass, reopen the dedicated Zig recovery route before treating the result as a source regression."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved build workspace bootstrap route

Repo root:             ${REPO_ROOT}
Snapshot destination:  ${SNAPSHOT_DESTINATION}
Target repo root:      ${TARGET_REPO_ROOT}
Dependencies root:     ${DEPENDENCIES_ROOT}
Toolchain root:        ${TOOLCHAIN_ROOT}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Zig override:          ${ZIG_BIN:-not supplied}

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Live checkout bootstrap dry run:
    ${LIVE_BOOTSTRAP_CHECK_COMMAND}

  Live checkout bootstrap:
    ${LIVE_BOOTSTRAP_COMMAND}

  Saved snapshot bootstrap dry run:
    ${SNAPSHOT_BOOTSTRAP_CHECK_COMMAND}

  Saved snapshot bootstrap:
    ${SNAPSHOT_BOOTSTRAP_COMMAND}

  If Zig still needs attention:
    ${ZIG_ROUTE_COMMAND}

  When Linux or WSL readiness is green, reopen the runtime route:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so missing helper drift fails fast before staging work starts.
  - Use the live checkout bootstrap when you already trust the current checkout as the staging root.
  - Use the snapshot bootstrap when you want the saved Memory archive to become the disposable staging checkout.
  - Prefer a Zig 0.15.x toolchain for honest branch validation; use the surfaced 0.17 fallback only for discovery when no better Zig has been restored yet.
  - If the bootstrap step still fails after offline inputs and the Rust toolchain are staged, reopen the dedicated Zig recovery route before treating the failure as source evidence.
EOF
