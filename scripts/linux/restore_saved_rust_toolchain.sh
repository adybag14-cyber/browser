#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/linux/restore_saved_rust_toolchain.sh \
    [--browser-root /path/to/browser-repo] \
    [--dependencies-root /path/to/dependencies] \
    [--toolchain-parent /path/to/parent-dir] \
    [--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz] \
    [--force]

Restore the saved Rust 1.79.0 Linux toolchain archive used by the headed-mode
browser fork's offline Linux build workflow.

Defaults:
  browser root       parent of this script
  dependencies root  /workspace/memory/repo_archives/browser/dependencies
  archive            <dependencies-root>/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz
  toolchain parent   parent of the browser root

The archive extracts to:
  <toolchain-parent>/rust-1.79.0-x86_64-unknown-linux-gnu

After restore, the script prints the exact PATH/CARGO/RUSTC commands to reuse
with scripts/linux/check_offline_build_prereqs.sh and zig build.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_DEPENDENCIES_ROOT="/workspace/memory/repo_archives/browser/dependencies"
DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"
DEFAULT_ARCHIVE_NAME="01-${DEFAULT_TOOLCHAIN_DIR_NAME}.tar.xz"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
DEPENDENCIES_ROOT="${DEFAULT_DEPENDENCIES_ROOT}"
TOOLCHAIN_PARENT=""
ARCHIVE_PATH=""
FORCE_RESTORE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --dependencies-root)
            DEPENDENCIES_ROOT="$2"
            shift 2
            ;;
        --toolchain-parent)
            TOOLCHAIN_PARENT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
            shift 2
            ;;
        --force)
            FORCE_RESTORE=true
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

if [[ -z "${TOOLCHAIN_PARENT}" ]]; then
    TOOLCHAIN_PARENT="$(cd "${BROWSER_ROOT}/.." && pwd)"
fi

if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${DEPENDENCIES_ROOT}/${DEFAULT_ARCHIVE_NAME}"
fi

if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Rust toolchain archive does not exist: ${ARCHIVE_PATH}" >&2
    exit 1
fi

mkdir -p "${TOOLCHAIN_PARENT}"

TOOLCHAIN_ROOT="${TOOLCHAIN_PARENT}/${DEFAULT_TOOLCHAIN_DIR_NAME}"
CARGO_BIN="${TOOLCHAIN_ROOT}/cargo/bin/cargo"
RUSTC_BIN="${TOOLCHAIN_ROOT}/rustc/bin/rustc"
RUSTDOC_BIN="${TOOLCHAIN_ROOT}/rust-docs/bin/rustdoc"

if [[ -d "${TOOLCHAIN_ROOT}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${TOOLCHAIN_ROOT}"
    else
        echo "Rust toolchain already exists at ${TOOLCHAIN_ROOT}"
    fi
fi

if [[ ! -d "${TOOLCHAIN_ROOT}" ]]; then
    tar -xJf "${ARCHIVE_PATH}" -C "${TOOLCHAIN_PARENT}"
fi

if [[ ! -x "${CARGO_BIN}" ]]; then
    echo "Restored toolchain is missing cargo: ${CARGO_BIN}" >&2
    exit 1
fi

if [[ ! -x "${RUSTC_BIN}" ]]; then
    echo "Restored toolchain is missing rustc: ${RUSTC_BIN}" >&2
    exit 1
fi

TOOLCHAIN_PATH="${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin"
if [[ -x "${RUSTDOC_BIN}" ]]; then
    TOOLCHAIN_PATH="${TOOLCHAIN_PATH}:${TOOLCHAIN_ROOT}/rust-docs/bin"
fi

echo
echo "Saved Rust toolchain is ready."
echo "Toolchain root: ${TOOLCHAIN_ROOT}"
echo "cargo: ${CARGO_BIN}"
echo "rustc: ${RUSTC_BIN}"
echo "cargo version: $("${CARGO_BIN}" --version | tr -d '\r')"
echo "rustc version: $("${RUSTC_BIN}" --version | tr -d '\r')"
echo
echo "Suggested shell setup:"
printf "  export PATH='%s:\$PATH'\n" "${TOOLCHAIN_PATH}"
printf "  export CARGO='%s'\n" "${CARGO_BIN}"
printf "  export RUSTC='%s'\n" "${RUSTC_BIN}"
echo
echo "Suggested preflight:"
printf "  ZIG=/absolute/path/to/zig CARGO='%s' RUSTC='%s' scripts/linux/check_offline_build_prereqs.sh\n" "${CARGO_BIN}" "${RUSTC_BIN}"
echo
echo "Suggested build:"
printf "  ZIG=/absolute/path/to/zig CARGO='%s' RUSTC='%s' zig build --summary all -Dprebuilt_v8_path='../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a'\n" "${CARGO_BIN}" "${RUSTC_BIN}"
