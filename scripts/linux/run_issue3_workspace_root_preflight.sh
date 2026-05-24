#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash run_issue3_workspace_root_preflight.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/helper-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--agent-files-root /path/to/workspace/agent_files] \
    [--restored-checkout-root /path/to/workspace/browser-memory-snapshot] \
    [--saved-archives-root /path/to/workspace/memory/repo_archives/browser] \
    [--toolchains-root /path/to/workspace/toolchains] \
    [--fallback-zig-archive /path/to/zig.tar.xz] \
    [--expect-helper-surface] \
    [--expect-offline-deps] \
    [--require-prebuilt-v8] \
    [--skip-saved-memory] \
    [--skip-archive-integrity] \
    [--skip-restored-checkout] \
    [--skip-build-readiness] \
    [--check-only]

Workspace-aware wrapper for the issue #3 saved-memory and Linux build-readiness
helpers. It computes the workspace companion paths explicitly and forwards them
to the existing Python helpers so they still work when the browser checkout is
mounted directly at the workspace root.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

find_workspace_anchor() {
    local root="$1"
    local current="$1"

    while true; do
        if [[ -d "${current}/memory" || -d "${current}/agent_files" || "$(basename "${current}")" == "workspace" ]]; then
            printf '%s\n' "${current}"
            return
        fi

        local parent
        parent="$(dirname "${current}")"
        if [[ "${parent}" == "${current}" ]]; then
            break
        fi
        current="${parent}"
    done

    printf '%s\n' "$(cd "${root}/.." && pwd)"
}

resolve_workspace_companion_path() {
    local root="$1"
    local name="$2"
    local anchor

    anchor="$(find_workspace_anchor "${root}")"
    printf '%s\n' "${anchor}/${name}"
}

append_optional_path_arg() {
    local -n cmd_ref="$1"
    local flag="$2"
    local value="$3"
    if [[ -n "${value}" ]]; then
        cmd_ref+=("${flag}" "${value}")
    fi
}

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
DEFAULT_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_FALLBACK_ZIG_ARCHIVE="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
AGENT_FILES_ROOT=""
RESTORED_CHECKOUT_ROOT=""
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""

EXPECT_HELPER_SURFACE=false
EXPECT_OFFLINE_DEPS=false
REQUIRE_PREBUILT_V8=false
SKIP_SAVED_MEMORY=false
SKIP_ARCHIVE_INTEGRITY=false
SKIP_RESTORED_CHECKOUT=false
SKIP_BUILD_READINESS=false
CHECK_ONLY=false

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
        --agent-files-root)
            AGENT_FILES_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --expect-helper-surface)
            EXPECT_HELPER_SURFACE=true
            shift
            ;;
        --expect-offline-deps)
            EXPECT_OFFLINE_DEPS=true
            shift
            ;;
        --require-prebuilt-v8)
            REQUIRE_PREBUILT_V8=true
            shift
            ;;
        --skip-saved-memory)
            SKIP_SAVED_MEMORY=true
            shift
            ;;
        --skip-archive-integrity)
            SKIP_ARCHIVE_INTEGRITY=true
            shift
            ;;
        --skip-restored-checkout)
            SKIP_RESTORED_CHECKOUT=true
            shift
            ;;
        --skip-build-readiness)
            SKIP_BUILD_READINESS=true
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
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
    MEMORY_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "memory")"
fi
if [[ -z "${AGENT_FILES_ROOT}" ]]; then
    AGENT_FILES_ROOT="$(resolve_workspace_companion_path "${HELPER_ROOT}" "agent_files")"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "browser-memory-snapshot")"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "toolchains")"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "offline-deps")"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    local_candidate="${AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE}"
    if [[ -f "${local_candidate}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${local_candidate}"
    fi
fi

required_helpers=(
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/check_issue3_saved_archive_integrity.py"
    "scripts/check_issue3_restored_checkout.py"
    "scripts/check_linux_build_readiness.py"
)

for relative_path in "${required_helpers[@]}"; do
    if [[ ! -f "${HELPER_ROOT}/${relative_path}" ]]; then
        echo "Helper root is missing ${relative_path}: ${HELPER_ROOT}" >&2
        exit 1
    fi
done

saved_memory_cmd=(
    python
    "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
    --repo-root "${REPO_ROOT}"
    --helper-root "${HELPER_ROOT}"
    --memory-root "${MEMORY_ROOT}"
    --agent-files-root "${AGENT_FILES_ROOT}"
    --restored-checkout-root "${RESTORED_CHECKOUT_ROOT}"
)
append_optional_path_arg saved_memory_cmd --fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}"
if [[ "${SKIP_ARCHIVE_INTEGRITY}" == "true" ]]; then
    saved_memory_cmd+=(--skip-archive-integrity-check)
fi

archive_integrity_cmd=(
    python
    "${HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py"
    --repo-root "${REPO_ROOT}"
    --memory-root "${MEMORY_ROOT}"
    --agent-files-root "${AGENT_FILES_ROOT}"
)
append_optional_path_arg archive_integrity_cmd --fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}"

restored_checkout_cmd=(
    python
    "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py"
    --repo-root "${RESTORED_CHECKOUT_ROOT}"
)
if [[ "${EXPECT_HELPER_SURFACE}" == "true" ]]; then
    restored_checkout_cmd+=(--helper-root "${HELPER_ROOT}" --expect-helper-surface)
fi

build_readiness_cmd=(
    python
    "${HELPER_ROOT}/scripts/check_linux_build_readiness.py"
    --repo-root "${REPO_ROOT}"
    --skip-zig-check
    --skip-rust-check
    --expect-saved-archives
    --saved-archives-root "${SAVED_ARCHIVES_ROOT}"
    --toolchains-root "${TOOLCHAINS_ROOT}"
)
append_optional_path_arg build_readiness_cmd --fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}"
if [[ "${EXPECT_OFFLINE_DEPS}" == "true" ]]; then
    build_readiness_cmd+=(--expect-offline-deps --offline-deps-root "${OFFLINE_DEPS_ROOT}")
fi
if [[ "${REQUIRE_PREBUILT_V8}" == "true" ]]; then
    build_readiness_cmd+=(--require-prebuilt-v8)
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Issue #3 workspace-root preflight surface check passed."
    echo "Wrapper:               ${SCRIPT_PATH}"
    echo "Repo root:             ${REPO_ROOT}"
    echo "Helper root:           ${HELPER_ROOT}"
    echo "Memory root:           ${MEMORY_ROOT}"
    echo "Agent files root:      ${AGENT_FILES_ROOT}"
    echo "Restored checkout:     ${RESTORED_CHECKOUT_ROOT}"
    echo "Saved archives root:   ${SAVED_ARCHIVES_ROOT}"
    echo "Toolchains root:       ${TOOLCHAINS_ROOT}"
    echo "Offline deps root:     ${OFFLINE_DEPS_ROOT}"
    echo "Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the helper root}"
    echo "Expect helper surface: $([[ "${EXPECT_HELPER_SURFACE}" == "true" ]] && echo yes || echo no)"
    echo "Expect offline deps:   $([[ "${EXPECT_OFFLINE_DEPS}" == "true" ]] && echo yes || echo no)"
    echo "Require prebuilt V8:   $([[ "${REQUIRE_PREBUILT_V8}" == "true" ]] && echo yes || echo no)"
    echo
    if [[ "${SKIP_SAVED_MEMORY}" != "true" ]]; then
        echo "Saved-memory preflight:"
        printf "  %s\n" "$(format_shell_arg "${saved_memory_cmd[0]}") $(printf '%s ' "${saved_memory_cmd[@]:1}" | sed 's/ $//')"
    fi
    if [[ "${SKIP_ARCHIVE_INTEGRITY}" != "true" ]]; then
        echo "Saved-archive integrity preflight:"
        printf "  %s\n" "$(format_shell_arg "${archive_integrity_cmd[0]}") $(printf '%s ' "${archive_integrity_cmd[@]:1}" | sed 's/ $//')"
    fi
    if [[ "${SKIP_RESTORED_CHECKOUT}" != "true" ]]; then
        echo "Restored-checkout preflight:"
        printf "  %s\n" "$(format_shell_arg "${restored_checkout_cmd[0]}") $(printf '%s ' "${restored_checkout_cmd[@]:1}" | sed 's/ $//')"
    fi
    if [[ "${SKIP_BUILD_READINESS}" != "true" ]]; then
        echo "Linux build-readiness preflight:"
        printf "  %s\n" "$(format_shell_arg "${build_readiness_cmd[0]}") $(printf '%s ' "${build_readiness_cmd[@]:1}" | sed 's/ $//')"
    fi
    exit 0
fi

if [[ "${SKIP_SAVED_MEMORY}" != "true" ]]; then
    "${saved_memory_cmd[@]}"
fi

if [[ "${SKIP_ARCHIVE_INTEGRITY}" != "true" ]]; then
    "${archive_integrity_cmd[@]}"
fi

if [[ "${SKIP_RESTORED_CHECKOUT}" != "true" ]]; then
    if [[ -d "${RESTORED_CHECKOUT_ROOT}" || "${EXPECT_HELPER_SURFACE}" == "true" ]]; then
        "${restored_checkout_cmd[@]}"
    else
        echo "Skipping restored-checkout preflight because ${RESTORED_CHECKOUT_ROOT} does not exist yet."
    fi
fi

if [[ "${SKIP_BUILD_READINESS}" != "true" ]]; then
    "${build_readiness_cmd[@]}"
fi
