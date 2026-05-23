#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/run_issue3_linux_build_readiness_preflight.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz]

Run the non-mutating Linux or WSL preflight sequence for the blocked issue #3
runtime lane in one place:

1. branch-local surface check
2. saved-archive readiness preflight
3. offline dependency restore surface check
4. saved Rust restore surface check

This helper intentionally stops before extraction or build execution.
EOF
}

quote_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT=""
SAVED_ARCHIVES_ROOT=""
RUST_TOOLCHAIN_DIR=""
FALLBACK_ZIG_ARCHIVE=""

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

if [[ -z "${REPO_ROOT}" ]]; then
    REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi
REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"

if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
fi

if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(cd "${REPO_ROOT}/.." && pwd)/toolchains/rust-1.79.0"
fi

if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    candidate_archive="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${candidate_archive}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${candidate_archive}"
    fi
fi

DEPENDENCIES_ROOT="${SAVED_ARCHIVES_ROOT}/dependencies"
HTML5EVER_ARCHIVE="${DEPENDENCIES_ROOT}/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
BORINGSSL_ARCHIVE="${DEPENDENCIES_ROOT}/03-boringssl-zig-main.zip"
BROWSER_DEPS_ARCHIVE="${DEPENDENCIES_ROOT}/04-zig-browser-depo.tar.zip"

declare -a SAVED_ARCHIVE_PREFLIGHT=(
    python3
    scripts/check_linux_build_readiness.py
    --repo-root "${REPO_ROOT}"
    --skip-zig-check
    --expect-saved-archives
    --saved-archives-root "${DEPENDENCIES_ROOT}"
)
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_ARCHIVE_PREFLIGHT+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

declare -a OFFLINE_SURFACE_CHECK=(
    bash
    scripts/linux/prepare_offline_build_inputs.sh
    --browser-root "${REPO_ROOT}"
    --browser-deps-archive "${BROWSER_DEPS_ARCHIVE}"
    --boringssl-archive "${BORINGSSL_ARCHIVE}"
)
if [[ -f "${HTML5EVER_ARCHIVE}" ]]; then
    OFFLINE_SURFACE_CHECK+=(--html5ever-archive "${HTML5EVER_ARCHIVE}")
fi
OFFLINE_SURFACE_CHECK+=(--check-only)

declare -a RUST_SURFACE_CHECK=(
    bash
    scripts/linux/restore_saved_rust_toolchain.sh
    --browser-root "${REPO_ROOT}"
    --dependencies-root "${DEPENDENCIES_ROOT}"
    --toolchain-root "${RUST_TOOLCHAIN_DIR}"
    --check-only
)

declare -a ROUTE_PRINTER=(
    bash
    scripts/linux/show_issue3_linux_build_readiness_route.sh
    --repo-root "${REPO_ROOT}"
    --saved-archives-root "${SAVED_ARCHIVES_ROOT}"
    --rust-toolchain-dir "${RUST_TOOLCHAIN_DIR}"
)
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    ROUTE_PRINTER+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

format_command() {
    local parts=()
    local piece
    for piece in "$@"; do
        parts+=("$(quote_arg "${piece}")")
    done
    local joined=""
    local index
    for index in "${!parts[@]}"; do
        if [[ "${index}" -gt 0 ]]; then
            joined+=" "
        fi
        joined+="${parts[${index}]}"
    done
    printf '%s\n' "${joined}"
}

run_step() {
    local label="$1"
    shift
    echo
    echo "== ${label} =="
    echo "Command:"
    echo "  $(format_command "$@")"
    "$@"
}

echo "Issue #3 Linux build-readiness preflight"
echo
echo "Repo root: ${REPO_ROOT}"
echo "Saved archive root: ${SAVED_ARCHIVES_ROOT}"
echo "Rust toolchain dir: ${RUST_TOOLCHAIN_DIR}"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    echo "Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE}"
else
    echo "Fallback Zig archive: not supplied"
fi

run_step \
    "Surface check" \
    bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root "${REPO_ROOT}"

run_step \
    "Saved-archive readiness preflight" \
    "${SAVED_ARCHIVE_PREFLIGHT[@]}"

run_step \
    "Offline dependency restore surface check" \
    "${OFFLINE_SURFACE_CHECK[@]}"

run_step \
    "Saved Rust restore surface check" \
    "${RUST_SURFACE_CHECK[@]}"

echo
echo "Preflight passed."
echo "Suggested next command:"
echo "  $(format_command "${ROUTE_PRINTER[@]}")"
