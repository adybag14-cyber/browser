#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF_USAGE'
Usage:
  scripts/linux/restore_saved_rust_toolchain.sh \
    [--browser-root /path/to/browser-repo] \
    [--dependencies-root /path/to/dependencies] \
    [--toolchain-root /path/to/toolchains/rust-1.79.0] \
    [--toolchain-parent /path/to/toolchains] \
    [--offline-deps-root /path/to/offline-deps] \
    [--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz] \
    [--check-only] \
    [--json] \
    [--force]

Restore the saved Rust 1.79.0 Linux toolchain archive used by the headed-mode
browser fork's offline Linux build workflow, or print the derived paths without
extracting it.

Defaults:
  browser root       parent of this script
  dependencies root  <browser-root>/../memory/repo_archives/browser/dependencies
  archive            <dependencies-root>/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz
  toolchain root     <browser-root>/../toolchains/rust-1.79.0
  toolchain parent   <browser-root>/../toolchains
  offline deps root  <browser-root>/../offline-deps

The archive extracts to:
  <toolchain-root>

After restore, the script prints the exact PATH/CARGO/RUSTC commands to reuse
with scripts/linux/check_offline_build_prereqs.sh and zig build.
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
DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"
DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"
DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"
PREBUILT_V8_GLOB="libc_v8_*.a"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
DEPENDENCIES_ROOT=""
TOOLCHAIN_ROOT=""
TOOLCHAIN_PARENT=""
OFFLINE_DEPS_ROOT=""
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
        --dependencies-root)
            DEPENDENCIES_ROOT="$2"
            shift 2
            ;;
        --toolchain-root)
            TOOLCHAIN_ROOT="$2"
            shift 2
            ;;
        --toolchain-parent)
            TOOLCHAIN_PARENT="$2"
            shift 2
            ;;
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
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

if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi
BROWSER_ROOT="$(cd "${BROWSER_ROOT}" && pwd)"
WORKSPACE_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
if [[ -z "${DEPENDENCIES_ROOT}" ]]; then
    DEPENDENCIES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${TOOLCHAIN_PARENT}" ]]; then
    TOOLCHAIN_PARENT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${TOOLCHAIN_ROOT}" ]]; then
    TOOLCHAIN_ROOT="${TOOLCHAIN_PARENT}/${DEFAULT_TOOLCHAIN_DIR_NAME}"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${DEPENDENCIES_ROOT}/${DEFAULT_ARCHIVE_NAME}"
fi

if [[ ! -d "${DEPENDENCIES_ROOT}" ]]; then
    echo "Dependencies root does not exist: ${DEPENDENCIES_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Rust toolchain archive does not exist: ${ARCHIVE_PATH}" >&2
    exit 1
fi

TOOLCHAIN_PARENT="$(python3 - "${TOOLCHAIN_PARENT}" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
TOOLCHAIN_ROOT="$(python3 - "${TOOLCHAIN_ROOT}" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
OFFLINE_DEPS_ROOT="$(python3 - "${OFFLINE_DEPS_ROOT}" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
if [[ "${CHECK_ONLY}" != "true" ]]; then
    mkdir -p "${TOOLCHAIN_PARENT}"
fi
PREBUILT_V8_PATH=""
if [[ -d "${OFFLINE_DEPS_ROOT}" ]]; then
    PREBUILT_V8_PATH="$(find "${OFFLINE_DEPS_ROOT}" -maxdepth 1 -type f -name "${PREBUILT_V8_GLOB}" | sort | head -n 1 || true)"
fi
CARGO_BIN="${TOOLCHAIN_ROOT}/cargo/bin/cargo"
RUSTC_BIN="${TOOLCHAIN_ROOT}/rustc/bin/rustc"
RUSTDOC_BIN="${TOOLCHAIN_ROOT}/rust-docs/bin/rustdoc"
TOOLCHAIN_PATH="${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin"
if [[ -x "${RUSTDOC_BIN}" ]]; then
    TOOLCHAIN_PATH="${TOOLCHAIN_PATH}:${TOOLCHAIN_ROOT}/rust-docs/bin"
fi

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "browser_root": %s,\n' "$(python3 - "$BROWSER_ROOT" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "dependencies_root": %s,\n' "$(python3 - "$DEPENDENCIES_ROOT" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "archive_path": %s,\n' "$(python3 - "$ARCHIVE_PATH" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "toolchain_parent": %s,\n' "$(python3 - "$TOOLCHAIN_PARENT" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "toolchain_root": %s,\n' "$(python3 - "$TOOLCHAIN_ROOT" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "offline_deps_root": %s,\n' "$(python3 - "$OFFLINE_DEPS_ROOT" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "prebuilt_v8_path": %s,\n' "$(python3 - "$PREBUILT_V8_PATH" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "cargo_bin": %s,\n' "$(python3 - "$CARGO_BIN" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "rustc_bin": %s,\n' "$(python3 - "$RUSTC_BIN" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "toolchain_path": %s,\n' "$(python3 - "$TOOLCHAIN_PATH" <<'PY'
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '  "force_restore": %s,\n' "$([[ "${FORCE_RESTORE}" == "true" ]] && echo true || echo false)"
    printf '  "toolchain_exists": %s\n' "$([[ -d "${TOOLCHAIN_ROOT}" ]] && echo true || echo false)"
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved Rust toolchain restore surface check passed."
    echo "Browser root:       ${BROWSER_ROOT}"
    echo "Dependencies root:  ${DEPENDENCIES_ROOT}"
    echo "Rust archive:       ${ARCHIVE_PATH}"
    echo "Toolchain parent:   ${TOOLCHAIN_PARENT}"
    echo "Toolchain root:     ${TOOLCHAIN_ROOT}"
    echo "Offline deps root:  ${OFFLINE_DEPS_ROOT}"
    echo "Prebuilt V8 archive:${PREBUILT_V8_PATH:- not found}"
    echo
    echo "Suggested shell setup:"
    printf "  export PATH='%s:\$PATH'\n" "${TOOLCHAIN_PATH}"
    printf "  export CARGO='%s'\n" "${CARGO_BIN}"
    printf "  export RUSTC='%s'\n" "${RUSTC_BIN}"
    exit 0
fi

if [[ -d "${TOOLCHAIN_ROOT}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${TOOLCHAIN_ROOT}"
    else
        echo "Rust toolchain already exists at ${TOOLCHAIN_ROOT}"
    fi
fi

if [[ ! -d "${TOOLCHAIN_ROOT}" ]]; then
    mkdir -p "${TOOLCHAIN_ROOT}"
    tar -xJf "${ARCHIVE_PATH}" -C "${TOOLCHAIN_ROOT}" --strip-components=1
fi

if [[ ! -x "${CARGO_BIN}" ]]; then
    echo "Restored toolchain is missing cargo: ${CARGO_BIN}" >&2
    exit 1
fi

if [[ ! -x "${RUSTC_BIN}" ]]; then
    echo "Restored toolchain is missing rustc: ${RUSTC_BIN}" >&2
    exit 1
fi

if [[ -x "${RUSTDOC_BIN}" ]]; then
    TOOLCHAIN_PATH="${TOOLCHAIN_PATH}:${TOOLCHAIN_ROOT}/rust-docs/bin"
fi

echo
echo "Saved Rust toolchain is ready."
echo "Toolchain root: ${TOOLCHAIN_ROOT}"
echo "Offline deps root: ${OFFLINE_DEPS_ROOT}"
echo "Prebuilt V8 archive: ${PREBUILT_V8_PATH:-not found}"
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
if [[ -n "${PREBUILT_V8_PATH}" ]]; then
    printf "  ZIG=/absolute/path/to/zig CARGO='%s' RUSTC='%s' zig build --summary all -Dprebuilt_v8_path='%s'\n" "${CARGO_BIN}" "${RUSTC_BIN}" "${PREBUILT_V8_PATH}"
else
    printf "  ZIG=/absolute/path/to/zig CARGO='%s' RUSTC='%s' zig build --summary all\n" "${CARGO_BIN}" "${RUSTC_BIN}"
    echo "  Note: no prebuilt V8 archive was found under ${OFFLINE_DEPS_ROOT}; run the offline build-inputs route first if this branch still expects one."
fi