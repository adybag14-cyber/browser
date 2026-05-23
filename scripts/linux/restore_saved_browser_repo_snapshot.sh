#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/linux/restore_saved_browser_repo_snapshot.sh \
    [--browser-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--extract-root /path/to/parent-dir] \
    [--checkout-dir /path/to/extracted-checkout] \
    [--check-only] \
    [--json] \
    [--force]

Restore the saved browser repo snapshot used by headed-mode recovery runs into a
writable checkout, or print the derived paths without extracting it.

Defaults:
  browser root        parent of this script
  saved archives root <browser-root>/../memory/repo_archives/browser
  archive             <saved-archives-root>/01-browser-fork-headed-mode-foundation.zip
  extract root        parent of the browser root
  checkout dir        <extract-root>/<top-level folder stored in the zip>

The helper preserves the archived top-level folder name unless --checkout-dir is
given explicitly.
EOF
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

infer_archive_top_level() {
    python3 - "$1" <<'PY'
import pathlib
import sys
import zipfile

archive_path = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(archive_path) as zf:
    for name in zf.namelist():
        stripped = name.strip("/")
        if not stripped:
            continue
        print(stripped.split("/", 1)[0])
        break
    else:
        raise SystemExit("Archive is empty")
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
SAVED_ARCHIVES_ROOT=""
ARCHIVE_PATH=""
EXTRACT_ROOT=""
CHECKOUT_DIR=""
CHECK_ONLY=false
JSON=false
FORCE_RESTORE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
            shift 2
            ;;
        --extract-root)
            EXTRACT_ROOT="$2"
            shift 2
            ;;
        --checkout-dir)
            CHECKOUT_DIR="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)/memory/repo_archives/browser"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${SAVED_ARCHIVES_ROOT}/${DEFAULT_ARCHIVE_NAME}"
fi
if [[ -z "${EXTRACT_ROOT}" ]]; then
    EXTRACT_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
fi

if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi
if [[ ! -d "${SAVED_ARCHIVES_ROOT}" ]]; then
    echo "Saved archives root does not exist: ${SAVED_ARCHIVES_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Saved repo archive does not exist: ${ARCHIVE_PATH}" >&2
    exit 1
fi

ARCHIVE_TOP_LEVEL="$(infer_archive_top_level "${ARCHIVE_PATH}")"
if [[ -z "${CHECKOUT_DIR}" ]]; then
    CHECKOUT_DIR="${EXTRACT_ROOT}/${ARCHIVE_TOP_LEVEL}"
fi

ZIP_LIST_COMMAND="unzip -l '${ARCHIVE_PATH}' | sed -n '1,40p'"
MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root '${CHECKOUT_DIR}'"
BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root '${CHECKOUT_DIR}' --skip-zig-check --expect-saved-archives --saved-archives-root '${SAVED_ARCHIVES_ROOT}/dependencies'"

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "browser_root": %s,\n' "$(json_escape "${BROWSER_ROOT}")"
    printf '  "saved_archives_root": %s,\n' "$(json_escape "${SAVED_ARCHIVES_ROOT}")"
    printf '  "archive_path": %s,\n' "$(json_escape "${ARCHIVE_PATH}")"
    printf '  "archive_top_level": %s,\n' "$(json_escape "${ARCHIVE_TOP_LEVEL}")"
    printf '  "extract_root": %s,\n' "$(json_escape "${EXTRACT_ROOT}")"
    printf '  "checkout_dir": %s,\n' "$(json_escape "${CHECKOUT_DIR}")"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '  "force_restore": %s,\n' "$([[ "${FORCE_RESTORE}" == "true" ]] && echo true || echo false)"
    printf '  "checkout_exists": %s,\n' "$([[ -d "${CHECKOUT_DIR}" ]] && echo true || echo false)"
    printf '  "zip_list_command": %s,\n' "$(json_escape "${ZIP_LIST_COMMAND}")"
    printf '  "saved_memory_inputs_command": %s,\n' "$(json_escape "${MEMORY_INPUTS_COMMAND}")"
    printf '  "build_readiness_command": %s\n' "$(json_escape "${BUILD_READINESS_COMMAND}")"
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved browser repo snapshot restore surface check passed."
    echo "Browser root:         ${BROWSER_ROOT}"
    echo "Saved archives root:  ${SAVED_ARCHIVES_ROOT}"
    echo "Saved repo archive:   ${ARCHIVE_PATH}"
    echo "Archive top-level:    ${ARCHIVE_TOP_LEVEL}"
    echo "Extract root:         ${EXTRACT_ROOT}"
    echo "Checkout dir:         ${CHECKOUT_DIR}"
    echo
    echo "Suggested archive listing:"
    printf "  %s\n" "${ZIP_LIST_COMMAND}"
    echo
    echo "Suggested next steps after extraction:"
    printf "  %s\n" "${MEMORY_INPUTS_COMMAND}"
    printf "  %s\n" "${BUILD_READINESS_COMMAND}"
    exit 0
fi

mkdir -p "${EXTRACT_ROOT}"
if [[ -d "${CHECKOUT_DIR}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${CHECKOUT_DIR}"
    else
        echo "Checkout already exists at ${CHECKOUT_DIR}" >&2
        echo "Re-run with --force to replace it." >&2
        exit 1
    fi
fi

unzip -q "${ARCHIVE_PATH}" -d "${EXTRACT_ROOT}"

if [[ ! -d "${CHECKOUT_DIR}" ]]; then
    echo "Restored checkout is missing: ${CHECKOUT_DIR}" >&2
    exit 1
fi
if [[ ! -f "${CHECKOUT_DIR}/build.zig" ]]; then
    echo "Restored checkout is missing build.zig: ${CHECKOUT_DIR}/build.zig" >&2
    exit 1
fi

echo
echo "Saved browser repo snapshot is ready."
echo "Checkout dir: ${CHECKOUT_DIR}"
echo "Archive top-level: ${ARCHIVE_TOP_LEVEL}"
echo
echo "Suggested next steps:"
printf "  %s\n" "${MEMORY_INPUTS_COMMAND}"
printf "  %s\n" "${BUILD_READINESS_COMMAND}"
