#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/stage_issue3_saved_build_readiness.sh \
    [--repo-root /path/to/browser-repo] \
    [--working-repo-root /path/to/restored/browser-checkout] \
    [--memory-root /path/to/workspace/memory] \
    [--toolchains-root /path/to/workspace/toolchains] \
    [--rust-toolchain-root /path/to/toolchains/rust-1.79.0] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--check-only] \
    [--force-snapshot] \
    [--force-rust] \
    [--skip-snapshot-restore] \
    [--skip-offline-prepare] \
    [--skip-rust-restore] \
    [--skip-readiness]

Restore and stage the saved Linux or WSL build inputs for the blocked issue #3
runtime lane by driving the branch-local helper scripts in the correct order.

This helper intentionally runs the latest scripts from the current checkout
against a working repo root, which can be a restored Memory snapshot beside the
workspace when no reusable writable checkout already exists.
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
WORKING_REPO_ROOT=""
MEMORY_ROOT=""
TOOLCHAINS_ROOT=""
RUST_TOOLCHAIN_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
CHECK_ONLY=0
FORCE_SNAPSHOT=0
FORCE_RUST=0
SKIP_SNAPSHOT_RESTORE=0
SKIP_OFFLINE_PREPARE=0
SKIP_RUST_RESTORE=0
SKIP_READINESS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --working-repo-root)
            WORKING_REPO_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --rust-toolchain-root)
            RUST_TOOLCHAIN_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=1
            shift
            ;;
        --force-snapshot)
            FORCE_SNAPSHOT=1
            shift
            ;;
        --force-rust)
            FORCE_RUST=1
            shift
            ;;
        --skip-snapshot-restore)
            SKIP_SNAPSHOT_RESTORE=1
            shift
            ;;
        --skip-offline-prepare)
            SKIP_OFFLINE_PREPARE=1
            shift
            ;;
        --skip-rust-restore)
            SKIP_RUST_RESTORE=1
            shift
            ;;
        --skip-readiness)
            SKIP_READINESS=1
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

if [[ -z "${WORKING_REPO_ROOT}" ]]; then
    WORKING_REPO_ROOT="${WORKSPACE_ROOT}/browser-memory-snapshot"
fi
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="${WORKSPACE_ROOT}/memory"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${RUST_TOOLCHAIN_ROOT}" ]]; then
    RUST_TOOLCHAIN_ROOT="${TOOLCHAINS_ROOT}/rust-1.79.0"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    DEFAULT_FALLBACK_ZIG="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${DEFAULT_FALLBACK_ZIG}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${DEFAULT_FALLBACK_ZIG}"
    fi
fi

SAVED_BROWSER_ARCHIVE="${MEMORY_ROOT}/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
DEPENDENCIES_ROOT="${SAVED_ARCHIVES_ROOT}/dependencies"

if [[ ! -d "${REPO_ROOT}" ]]; then
    echo "Repo root does not exist: ${REPO_ROOT}" >&2
    exit 1
fi

ROUTE_SURFACE_CHECK=(
    bash
    "${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
    --repo-root
    "${REPO_ROOT}"
)
SNAPSHOT_SURFACE_CHECK=(
    bash
    "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh"
    --browser-root
    "${REPO_ROOT}"
    --memory-root
    "${MEMORY_ROOT}"
    --destination
    "${WORKING_REPO_ROOT}"
    --check-only
)
SNAPSHOT_RESTORE=(
    bash
    "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh"
    --browser-root
    "${REPO_ROOT}"
    --memory-root
    "${MEMORY_ROOT}"
    --destination
    "${WORKING_REPO_ROOT}"
)
if [[ "${FORCE_SNAPSHOT}" -eq 1 ]]; then
    SNAPSHOT_RESTORE+=(--force)
fi

TARGET_REPO_ROOT="${REPO_ROOT}"
if [[ "${SKIP_SNAPSHOT_RESTORE}" -eq 0 ]]; then
    TARGET_REPO_ROOT="${WORKING_REPO_ROOT}"
fi

SAVED_INPUT_CHECK=(
    python3
    "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
    --repo-root
    "${TARGET_REPO_ROOT}"
)

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_INPUT_CHECK+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

ZIG_ROUTE_JSON=(
    bash
    "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    --repo-root
    "${TARGET_REPO_ROOT}"
    --toolchains-root
    "${TOOLCHAINS_ROOT}"
    --json
)
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    ZIG_ROUTE_JSON+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

OFFLINE_PREPARE_CHECK=(
    bash
    "${REPO_ROOT}/scripts/linux/prepare_offline_build_inputs.sh"
    --browser-root
    "${TARGET_REPO_ROOT}"
    --browser-deps-archive
    "${DEPENDENCIES_ROOT}/04-zig-browser-depo.tar.zip"
    --boringssl-archive
    "${DEPENDENCIES_ROOT}/03-boringssl-zig-main.zip"
    --html5ever-archive
    "${DEPENDENCIES_ROOT}/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
    --check-only
)
OFFLINE_PREPARE=(
    bash
    "${REPO_ROOT}/scripts/linux/prepare_offline_build_inputs.sh"
    --browser-root
    "${TARGET_REPO_ROOT}"
    --browser-deps-archive
    "${DEPENDENCIES_ROOT}/04-zig-browser-depo.tar.zip"
    --boringssl-archive
    "${DEPENDENCIES_ROOT}/03-boringssl-zig-main.zip"
    --html5ever-archive
    "${DEPENDENCIES_ROOT}/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
)

RUST_RESTORE_CHECK=(
    bash
    "${REPO_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh"
    --browser-root
    "${TARGET_REPO_ROOT}"
    --dependencies-root
    "${DEPENDENCIES_ROOT}"
    --toolchain-root
    "${RUST_TOOLCHAIN_ROOT}"
    --check-only
)
RUST_RESTORE=(
    bash
    "${REPO_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh"
    --browser-root
    "${TARGET_REPO_ROOT}"
    --dependencies-root
    "${DEPENDENCIES_ROOT}"
    --toolchain-root
    "${RUST_TOOLCHAIN_ROOT}"
)
if [[ "${FORCE_RUST}" -eq 1 ]]; then
    RUST_RESTORE+=(--force)
fi

if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    printf 'Issue #3 saved build-readiness stage surface\n\n'
    printf 'Current repo root:    %s\n' "${REPO_ROOT}"
    printf 'Working repo root:    %s\n' "${TARGET_REPO_ROOT}"
    printf 'Memory root:          %s\n' "${MEMORY_ROOT}"
    printf 'Saved browser zip:    %s\n' "${SAVED_BROWSER_ARCHIVE}"
    printf 'Dependencies root:    %s\n' "${DEPENDENCIES_ROOT}"
    printf 'Toolchains root:      %s\n' "${TOOLCHAINS_ROOT}"
    printf 'Rust toolchain root:  %s\n' "${RUST_TOOLCHAIN_ROOT}"
    printf 'Fallback Zig archive: %s\n' "${FALLBACK_ZIG_ARCHIVE:-not found beside the workspace}"
    printf '\n'
    printf 'Surface checks\n'
    printf '==============\n'
    printf '  %s\n' "$(printf '%q ' "${ROUTE_SURFACE_CHECK[@]}")"
    if [[ "${SKIP_SNAPSHOT_RESTORE}" -eq 0 ]]; then
        printf '  %s\n' "$(printf '%q ' "${SNAPSHOT_SURFACE_CHECK[@]}")"
    fi
    printf '  %s\n' "$(printf '%q ' "${SAVED_INPUT_CHECK[@]}")"
    if [[ "${SKIP_OFFLINE_PREPARE}" -eq 0 ]]; then
        printf '  %s\n' "$(printf '%q ' "${OFFLINE_PREPARE_CHECK[@]}")"
    fi
    if [[ "${SKIP_RUST_RESTORE}" -eq 0 ]]; then
        printf '  %s\n' "$(printf '%q ' "${RUST_RESTORE_CHECK[@]}")"
    fi
    printf '\n'
    printf 'Actions\n'
    printf '=======\n'
    if [[ "${SKIP_SNAPSHOT_RESTORE}" -eq 0 ]]; then
        printf '  %s\n' "$(printf '%q ' "${SNAPSHOT_RESTORE[@]}")"
    fi
    if [[ "${SKIP_OFFLINE_PREPARE}" -eq 0 ]]; then
        printf '  %s\n' "$(printf '%q ' "${OFFLINE_PREPARE[@]}")"
    fi
    if [[ "${SKIP_RUST_RESTORE}" -eq 0 ]]; then
        printf '  %s\n' "$(printf '%q ' "${RUST_RESTORE[@]}")"
    fi
    printf '  %s\n' "$(printf '%q ' "${ZIG_ROUTE_JSON[@]}")"
    exit 0
fi

echo "Running Linux build-readiness route surface check..."
"${ROUTE_SURFACE_CHECK[@]}"

if [[ "${SKIP_SNAPSHOT_RESTORE}" -eq 0 ]]; then
    echo "Checking saved browser snapshot surface..."
    "${SNAPSHOT_SURFACE_CHECK[@]}"
    if [[ ! -f "${TARGET_REPO_ROOT}/build.zig.zon" || "${FORCE_SNAPSHOT}" -eq 1 ]]; then
        echo "Restoring saved browser snapshot into ${TARGET_REPO_ROOT}..."
        "${SNAPSHOT_RESTORE[@]}"
    else
        echo "Using existing working repo root at ${TARGET_REPO_ROOT}"
    fi
fi

echo "Checking saved Memory inputs against ${TARGET_REPO_ROOT}..."
"${SAVED_INPUT_CHECK[@]}"

if [[ "${SKIP_OFFLINE_PREPARE}" -eq 0 ]]; then
    echo "Checking offline dependency restore surface..."
    "${OFFLINE_PREPARE_CHECK[@]}"
    echo "Restoring offline dependency inputs..."
    "${OFFLINE_PREPARE[@]}"
fi

if [[ "${SKIP_RUST_RESTORE}" -eq 0 ]]; then
    echo "Checking saved Rust restore surface..."
    "${RUST_RESTORE_CHECK[@]}"
    echo "Restoring saved Rust toolchain..."
    "${RUST_RESTORE[@]}"
fi

ZIG_ROUTE_OUTPUT="$(${ZIG_ROUTE_JSON[@]})"
MATCHING_ZIG_CANDIDATE="$({
    python3 - "${ZIG_ROUTE_OUTPUT}" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
print(payload.get("matching_candidate", ""))
PY
})"

if [[ "${SKIP_READINESS}" -eq 0 ]]; then
    READINESS_COMMAND=(
        python3
        "${REPO_ROOT}/scripts/check_linux_build_readiness.py"
        --repo-root
        "${TARGET_REPO_ROOT}"
        --cargo
        "${RUST_TOOLCHAIN_ROOT}/cargo/bin/cargo"
        --rustc
        "${RUST_TOOLCHAIN_ROOT}/rustc/bin/rustc"
        --expect-saved-archives
        --saved-archives-root
        "${DEPENDENCIES_ROOT}"
        --expect-offline-deps
        --require-prebuilt-v8
        --toolchains-root
        "${TOOLCHAINS_ROOT}"
    )
    if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
        READINESS_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    fi
    if [[ -n "${MATCHING_ZIG_CANDIDATE}" ]]; then
        READINESS_COMMAND+=(--zig "${MATCHING_ZIG_CANDIDATE}")
        echo "Running full readiness check with matching Zig candidate ${MATCHING_ZIG_CANDIDATE}..."
    else
        READINESS_COMMAND+=(--skip-zig-check)
        echo "No matching Zig candidate is staged yet; running readiness without a Zig probe..."
    fi
    "${READINESS_COMMAND[@]}"
fi

echo
echo "Issue #3 saved build-readiness staging is complete."
echo "Working repo root: ${TARGET_REPO_ROOT}"
if [[ -n "${MATCHING_ZIG_CANDIDATE}" ]]; then
    echo "Matching Zig candidate: ${MATCHING_ZIG_CANDIDATE}"
else
    echo "Matching Zig candidate: none staged yet"
    echo "Next helper: bash ${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root $(format_shell_arg "${TARGET_REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
fi
