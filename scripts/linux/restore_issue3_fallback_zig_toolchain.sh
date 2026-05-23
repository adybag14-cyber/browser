#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF_USAGE'
Usage:
  bash scripts/linux/restore_issue3_fallback_zig_toolchain.sh \
    [--browser-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--toolchain-root /path/to/toolchains/zig-0.17.0-dev.299+a76ce7710] \
    [--archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--check-only] \
    [--json] \
    [--force]

Restore the attached fallback Zig bundle into the shared toolchains area used by
the Linux and WSL issue #3 recovery helpers, or print the derived paths without
extracting it.

Defaults:
  browser root    parent of this script
  toolchains root <browser-root>/../toolchains
  toolchain root  <toolchains-root>/zig-0.17.0-dev.299+a76ce7710
  archive         <browser-root>/../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz

This helper only stages the attached fallback bundle so the recovery route can
probe it consistently. The browser branch still expects a Zig 0.15.x line for
honest validation.
EOF_USAGE
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_TOOLCHAIN_DIR_NAME="zig-0.17.0-dev.299+a76ce7710"
DEFAULT_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
TOOLCHAINS_ROOT=""
TOOLCHAIN_ROOT=""
ARCHIVE_PATH=""
CHECK_ONLY=false
JSON=false
FORCE_RESTORE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --toolchain-root)
            TOOLCHAIN_ROOT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        --json)
            JSON=true
            shift
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

BROWSER_ROOT="$(cd "${BROWSER_ROOT}" && pwd)"
WORKSPACE_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${TOOLCHAIN_ROOT}" ]]; then
    TOOLCHAIN_ROOT="${TOOLCHAINS_ROOT}/${DEFAULT_TOOLCHAIN_DIR_NAME}"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${WORKSPACE_ROOT}/agent_files/${DEFAULT_ARCHIVE_NAME}"
fi

if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Fallback Zig archive does not exist: ${ARCHIVE_PATH}" >&2
    exit 1
fi

mkdir -p "${TOOLCHAINS_ROOT}"
ZIG_BIN="${TOOLCHAIN_ROOT}/zig"
if [[ ! -x "${ZIG_BIN}" && -x "${TOOLCHAIN_ROOT}/bin/zig" ]]; then
    ZIG_BIN="${TOOLCHAIN_ROOT}/bin/zig"
fi

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "browser_root": %s,\n' "$(json_escape "${BROWSER_ROOT}")"
    printf '  "toolchains_root": %s,\n' "$(json_escape "${TOOLCHAINS_ROOT}")"
    printf '  "toolchain_root": %s,\n' "$(json_escape "${TOOLCHAIN_ROOT}")"
    printf '  "archive_path": %s,\n' "$(json_escape "${ARCHIVE_PATH}")"
    printf '  "zig_bin": %s,\n' "$(json_escape "${ZIG_BIN}")"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '  "force_restore": %s,\n' "$([[ "${FORCE_RESTORE}" == "true" ]] && echo true || echo false)"
    printf '  "toolchain_exists": %s\n' "$([[ -d "${TOOLCHAIN_ROOT}" ]] && echo true || echo false)"
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Fallback Zig restore surface check passed."
    echo "Browser root:    ${BROWSER_ROOT}"
    echo "Toolchains root: ${TOOLCHAINS_ROOT}"
    echo "Toolchain root:  ${TOOLCHAIN_ROOT}"
    echo "Fallback Zig:    ${ARCHIVE_PATH}"
    echo
    echo "Suggested probe after restore:"
    printf '  %s version\n' "${ZIG_BIN}"
    echo
    echo "Working rule:"
    echo "  Stage this fallback only for route discovery and environment checks. The branch still expects Zig 0.15.x for honest validation."
    exit 0
fi

if [[ -d "${TOOLCHAIN_ROOT}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${TOOLCHAIN_ROOT}"
    else
        echo "Fallback Zig toolchain already exists at ${TOOLCHAIN_ROOT}"
    fi
fi

if [[ ! -d "${TOOLCHAIN_ROOT}" ]]; then
    mkdir -p "${TOOLCHAIN_ROOT}"
    tar -xJf "${ARCHIVE_PATH}" -C "${TOOLCHAIN_ROOT}" --strip-components=1
fi

ZIG_BIN="${TOOLCHAIN_ROOT}/zig"
if [[ ! -x "${ZIG_BIN}" && -x "${TOOLCHAIN_ROOT}/bin/zig" ]]; then
    ZIG_BIN="${TOOLCHAIN_ROOT}/bin/zig"
fi

if [[ ! -x "${ZIG_BIN}" ]]; then
    echo "Restored fallback toolchain is missing zig: ${TOOLCHAIN_ROOT}" >&2
    exit 1
fi

echo
echo "Fallback Zig toolchain is ready."
echo "Toolchain root: ${TOOLCHAIN_ROOT}"
echo "zig: ${ZIG_BIN}"
echo "zig version: $("${ZIG_BIN}" version | tr -d '\r')"
echo
echo "Working rule:"
echo "  This staged toolchain is the attached Zig 0.17 fallback. Keep using the Zig line recovery route before treating it as issue #3 runtime validation evidence."
