#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/run_issue3_linux_build_readiness_bundle.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--logs-dir /path/to/log-dir] \
    [--require-fallback-zig] \
    [--skip-route-print]

Run the Linux build-readiness route for the blocked issue #3 runtime lane in
one ordered pass, capture each step under a log directory, and stop at the
first failure.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY2'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY2
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
RUST_TOOLCHAIN_DIR=""
FALLBACK_ZIG_ARCHIVE=""
LOGS_DIR=""
REQUIRE_FALLBACK_ZIG=0
SKIP_ROUTE_PRINT=0

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
        --rust-toolchain-dir)
            RUST_TOOLCHAIN_DIR="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --logs-dir)
            LOGS_DIR="$2"
            shift 2
            ;;
        --require-fallback-zig)
            REQUIRE_FALLBACK_ZIG=1
            shift
            ;;
        --skip-route-print)
            SKIP_ROUTE_PRINT=1
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
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(cd "${REPO_ROOT}/.." && pwd)/toolchains/rust-1.79.0"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi
if [[ -z "${LOGS_DIR}" ]]; then
    LOGS_DIR="${REPO_ROOT}/tmp-browser-smoke/logs/issue3-linux-build-readiness"
fi

mkdir -p "${LOGS_DIR}"

SURFACE_CHECK_COMMAND=(
    bash
    "${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
    --repo-root
    "${REPO_ROOT}"
)
SAVED_MEMORY_COMMAND=(
    python3
    "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
    --repo-root
    "${REPO_ROOT}"
)
SAVED_ARCHIVE_INTEGRITY_COMMAND=(
    python3
    "${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py"
    --repo-root
    "${REPO_ROOT}"
)
SAVED_RUST_SURFACE_COMMAND=(
    bash
    "${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
    --repo-root
    "${REPO_ROOT}"
)
OFFLINE_SURFACE_COMMAND=(
    bash
    "${REPO_ROOT}/scripts/linux/check_issue3_offline_build_inputs_route_surface.sh"
    --repo-root
    "${REPO_ROOT}"
)
READINESS_COMMAND=(
    python3
    "${REPO_ROOT}/scripts/check_linux_build_readiness.py"
    --repo-root
    "${REPO_ROOT}"
    --skip-zig-check
    --expect-saved-archives
    --saved-archives-root
    "${SAVED_ARCHIVES_ROOT}/dependencies"
)
ROUTE_COMMAND=(
    bash
    "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
    --repo-root
    "${REPO_ROOT}"
    --saved-archives-root
    "${SAVED_ARCHIVES_ROOT}"
    --rust-toolchain-dir
    "${RUST_TOOLCHAIN_DIR}"
)

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    READINESS_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    ROUTE_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

if [[ "${REQUIRE_FALLBACK_ZIG}" -eq 1 ]]; then
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=(--require-fallback-zig)
fi

run_step() {
    local step_name="$1"
    shift
    local log_path="${LOGS_DIR}/${step_name}.log"

    echo "==> ${step_name}"
    printf 'Command:'
    for arg in "$@"; do
        printf ' %s' "$(format_shell_arg "${arg}")"
    done
    printf '\n'

    if "$@" >"${log_path}" 2>&1; then
        echo "PASS ${step_name} (${log_path})"
        return 0
    fi

    echo "FAIL ${step_name} (${log_path})" >&2
    echo "--- log tail ---" >&2
    tail -n 40 "${log_path}" >&2 || true
    return 1
}

run_step "01-surface-check" "${SURFACE_CHECK_COMMAND[@]}"
run_step "02-saved-memory-inputs" "${SAVED_MEMORY_COMMAND[@]}"
run_step "03-saved-archive-integrity" "${SAVED_ARCHIVE_INTEGRITY_COMMAND[@]}"
run_step "04-saved-rust-surface" "${SAVED_RUST_SURFACE_COMMAND[@]}"
run_step "05-offline-surface" "${OFFLINE_SURFACE_COMMAND[@]}"
run_step "06-readiness-skip-zig" "${READINESS_COMMAND[@]}"

if [[ "${SKIP_ROUTE_PRINT}" -eq 0 ]]; then
    run_step "07-route-print" "${ROUTE_COMMAND[@]}"
fi

echo
echo "Issue #3 Linux build-readiness bundle completed."
echo "Logs: ${LOGS_DIR}"
echo
echo "Suggested next commands:"
echo "  bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
echo "  bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
echo "  bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
