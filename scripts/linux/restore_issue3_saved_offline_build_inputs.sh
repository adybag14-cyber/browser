#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/restore_issue3_saved_offline_build_inputs.sh \
    [--browser-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--offline-deps-root /path/to/offline-deps] \
    [--browser-deps-archive /path/to/zig-browser-depo.tar.zip] \
    [--boringssl-archive /path/to/boringssl-zig-main.zip] \
    [--html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip] \
    [--check-only] \
    [--json]

Restore the saved offline Linux or WSL build inputs for issue #3 from the
default Memory dependency archive paths, or print the derived command surface
without mutating the workspace.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_BROWSER_DEPS_ARCHIVE_NAME="04-zig-browser-depo.tar.zip"
DEFAULT_BORINGSSL_ARCHIVE_NAME="03-boringssl-zig-main.zip"
DEFAULT_HTML5EVER_ARCHIVE_NAME="02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
SAVED_ARCHIVES_ROOT=""
OFFLINE_DEPS_ROOT=""
BROWSER_DEPS_ARCHIVE=""
BORINGSSL_ARCHIVE=""
HTML5EVER_ARCHIVE=""
CHECK_ONLY=false
JSON=false

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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --browser-deps-archive)
            BROWSER_DEPS_ARCHIVE="$2"
            shift 2
            ;;
        --boringssl-archive)
            BORINGSSL_ARCHIVE="$2"
            shift 2
            ;;
        --html5ever-archive)
            HTML5EVER_ARCHIVE="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${BROWSER_DEPS_ARCHIVE}" ]]; then
    BROWSER_DEPS_ARCHIVE="${SAVED_ARCHIVES_ROOT}/${DEFAULT_BROWSER_DEPS_ARCHIVE_NAME}"
fi
if [[ -z "${BORINGSSL_ARCHIVE}" ]]; then
    BORINGSSL_ARCHIVE="${SAVED_ARCHIVES_ROOT}/${DEFAULT_BORINGSSL_ARCHIVE_NAME}"
fi
if [[ -z "${HTML5EVER_ARCHIVE}" ]]; then
    DEFAULT_HTML5EVER_ARCHIVE="${SAVED_ARCHIVES_ROOT}/${DEFAULT_HTML5EVER_ARCHIVE_NAME}"
    if [[ -f "${DEFAULT_HTML5EVER_ARCHIVE}" ]]; then
        HTML5EVER_ARCHIVE="${DEFAULT_HTML5EVER_ARCHIVE}"
    fi
fi

PREPARE_SCRIPT="${SCRIPT_DIR}/prepare_offline_build_inputs.sh"
if [[ ! -f "${PREPARE_SCRIPT}" ]]; then
    echo "Offline build-input helper is missing: ${PREPARE_SCRIPT}" >&2
    exit 1
fi
if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi
if [[ ! -d "${SAVED_ARCHIVES_ROOT}" ]]; then
    echo "Saved archives root does not exist: ${SAVED_ARCHIVES_ROOT}" >&2
    exit 1
fi

PREPARE_ARGS=(
    bash
    "${PREPARE_SCRIPT}"
    --browser-root "${BROWSER_ROOT}"
    --browser-deps-archive "${BROWSER_DEPS_ARCHIVE}"
    --boringssl-archive "${BORINGSSL_ARCHIVE}"
    --offline-deps-root "${OFFLINE_DEPS_ROOT}"
)

if [[ -n "${HTML5EVER_ARCHIVE}" ]]; then
    PREPARE_ARGS+=(--html5ever-archive "${HTML5EVER_ARCHIVE}")
fi
if [[ "${CHECK_ONLY}" == "true" ]]; then
    PREPARE_ARGS+=(--check-only)
fi

if [[ "${JSON}" == "true" ]]; then
    python3 - "${PREPARE_ARGS[@]}" "${BROWSER_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${OFFLINE_DEPS_ROOT}" "${BROWSER_DEPS_ARCHIVE}" "${BORINGSSL_ARCHIVE}" "${HTML5EVER_ARCHIVE}" "${CHECK_ONLY}" <<'PY'
from __future__ import annotations

import json
import shlex
import sys

prepare_args = sys.argv[1:-7]
browser_root, saved_archives_root, offline_deps_root, browser_deps_archive, boringssl_archive, html5ever_archive, check_only = sys.argv[-7:]

print(
    json.dumps(
        {
            "browser_root": browser_root,
            "saved_archives_root": saved_archives_root,
            "offline_deps_root": offline_deps_root,
            "browser_deps_archive": browser_deps_archive,
            "boringssl_archive": boringssl_archive,
            "html5ever_archive": html5ever_archive,
            "check_only": check_only == "true",
            "prepare_command": " ".join(shlex.quote(arg) for arg in prepare_args),
        },
        indent=2,
    )
)
PY
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Issue #3 saved offline build-inputs helper check"
    echo "Browser root:         ${BROWSER_ROOT}"
    echo "Saved archives root:  ${SAVED_ARCHIVES_ROOT}"
    echo "Offline deps root:    ${OFFLINE_DEPS_ROOT}"
    echo "Browser deps archive: ${BROWSER_DEPS_ARCHIVE}"
    echo "BoringSSL archive:    ${BORINGSSL_ARCHIVE}"
    echo "html5ever archive:    ${HTML5EVER_ARCHIVE:-not present under saved archives root}"
    echo
fi

exec "${PREPARE_ARGS[@]}"
