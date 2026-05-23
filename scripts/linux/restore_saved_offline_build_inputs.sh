#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF_USAGE'
Usage:
  scripts/linux/restore_saved_offline_build_inputs.sh \
    [--browser-root /path/to/browser-repo] \
    [--dependencies-root /path/to/memory/repo_archives/browser/dependencies] \
    [--browser-deps-archive /path/to/04-zig-browser-depo.tar.zip] \
    [--boringssl-archive /path/to/03-boringssl-zig-main.zip] \
    [--html5ever-archive /path/to/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip] \
    [--offline-deps-root /path/to/offline-deps] \
    [--check-only] \
    [--json]

Restore the saved offline Linux or WSL build inputs used by the headed-mode
browser fork's issue #3 recovery path, or print the derived paths without
extracting anything.

Defaults:
  browser root         parent of this script
  dependencies root    <browser-root>/../memory/repo_archives/browser/dependencies
  browser deps archive <dependencies-root>/04-zig-browser-depo.tar.zip
  boringssl archive    <dependencies-root>/03-boringssl-zig-main.zip
  html5ever archive    <dependencies-root>/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip
  offline deps root    <browser-root>/../offline-deps

This wrapper keeps the saved-Memory archive defaults on one command surface and
reuses scripts/linux/prepare_offline_build_inputs.sh for the actual staging.
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
DEFAULT_BROWSER_DEPS_ARCHIVE_NAME="04-zig-browser-depo.tar.zip"
DEFAULT_BORINGSSL_ARCHIVE_NAME="03-boringssl-zig-main.zip"
DEFAULT_HTML5EVER_ARCHIVE_NAME="02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
DEPENDENCIES_ROOT=""
BROWSER_DEPS_ARCHIVE=""
BORINGSSL_ARCHIVE=""
HTML5EVER_ARCHIVE=""
OFFLINE_DEPS_ROOT=""
CHECK_ONLY=false
JSON=false

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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
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
if [[ -z "${DEPENDENCIES_ROOT}" ]]; then
    DEPENDENCIES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${BROWSER_DEPS_ARCHIVE}" ]]; then
    BROWSER_DEPS_ARCHIVE="${DEPENDENCIES_ROOT}/${DEFAULT_BROWSER_DEPS_ARCHIVE_NAME}"
fi
if [[ -z "${BORINGSSL_ARCHIVE}" ]]; then
    BORINGSSL_ARCHIVE="${DEPENDENCIES_ROOT}/${DEFAULT_BORINGSSL_ARCHIVE_NAME}"
fi
if [[ -z "${HTML5EVER_ARCHIVE}" ]]; then
    HTML5EVER_ARCHIVE="${DEPENDENCIES_ROOT}/${DEFAULT_HTML5EVER_ARCHIVE_NAME}"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi

if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi
if [[ ! -d "${DEPENDENCIES_ROOT}" ]]; then
    echo "Dependencies root does not exist: ${DEPENDENCIES_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${BROWSER_DEPS_ARCHIVE}" ]]; then
    echo "Browser dependency archive does not exist: ${BROWSER_DEPS_ARCHIVE}" >&2
    exit 1
fi
if [[ ! -f "${BORINGSSL_ARCHIVE}" ]]; then
    echo "BoringSSL archive does not exist: ${BORINGSSL_ARCHIVE}" >&2
    exit 1
fi
if [[ ! -f "${HTML5EVER_ARCHIVE}" ]]; then
    echo "html5ever archive does not exist: ${HTML5EVER_ARCHIVE}" >&2
    exit 1
fi
if [[ ! -f "${BROWSER_ROOT}/scripts/linux/prepare_offline_build_inputs.sh" ]]; then
    echo "prepare_offline_build_inputs.sh is missing from ${BROWSER_ROOT}" >&2
    exit 1
fi

CHECK_COMMAND=(
    bash
    "${BROWSER_ROOT}/scripts/linux/prepare_offline_build_inputs.sh"
    --browser-root "${BROWSER_ROOT}"
    --browser-deps-archive "${BROWSER_DEPS_ARCHIVE}"
    --boringssl-archive "${BORINGSSL_ARCHIVE}"
    --html5ever-archive "${HTML5EVER_ARCHIVE}"
    --check-only
)

RESTORE_COMMAND=(
    bash
    "${BROWSER_ROOT}/scripts/linux/prepare_offline_build_inputs.sh"
    --browser-root "${BROWSER_ROOT}"
    --browser-deps-archive "${BROWSER_DEPS_ARCHIVE}"
    --boringssl-archive "${BORINGSSL_ARCHIVE}"
    --html5ever-archive "${HTML5EVER_ARCHIVE}"
)

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "browser_root": %s,\n' "$(json_escape "${BROWSER_ROOT}")"
    printf '  "dependencies_root": %s,\n' "$(json_escape "${DEPENDENCIES_ROOT}")"
    printf '  "browser_deps_archive": %s,\n' "$(json_escape "${BROWSER_DEPS_ARCHIVE}")"
    printf '  "boringssl_archive": %s,\n' "$(json_escape "${BORINGSSL_ARCHIVE}")"
    printf '  "html5ever_archive": %s,\n' "$(json_escape "${HTML5EVER_ARCHIVE}")"
    printf '  "offline_deps_root": %s,\n' "$(json_escape "${OFFLINE_DEPS_ROOT}")"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '  "prepare_check_command": %s,\n' "$(json_escape "${CHECK_COMMAND[*]}")"
    printf '  "prepare_restore_command": %s\n' "$(json_escape "${RESTORE_COMMAND[*]}")"
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved offline build-input restore surface check passed."
    echo "Browser root:         ${BROWSER_ROOT}"
    echo "Dependencies root:    ${DEPENDENCIES_ROOT}"
    echo "Browser deps archive: ${BROWSER_DEPS_ARCHIVE}"
    echo "BoringSSL archive:    ${BORINGSSL_ARCHIVE}"
    echo "html5ever archive:    ${HTML5EVER_ARCHIVE}"
    echo "Offline deps root:    ${OFFLINE_DEPS_ROOT}"
    echo
    "${CHECK_COMMAND[@]}"
    exit 0
fi

"${RESTORE_COMMAND[@]}"

echo
echo "Saved offline build inputs are ready."
echo "Expected sibling targets:"
echo "  zig-v8-fork   -> ${WORKSPACE_ROOT}/zig-v8-fork"
echo "  boringssl-zig -> ${WORKSPACE_ROOT}/boringssl-zig"
echo "  offline-deps  -> ${OFFLINE_DEPS_ROOT}"
echo
echo "Suggested next steps:"
echo "  bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh --browser-root ${BROWSER_ROOT}"
echo "  bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root ${BROWSER_ROOT} --saved-archives-root ${DEPENDENCIES_ROOT} --offline-deps-root ${OFFLINE_DEPS_ROOT}"
echo "  python scripts/check_linux_build_readiness.py --repo-root ${BROWSER_ROOT} --skip-zig-check --expect-saved-archives --saved-archives-root ${DEPENDENCIES_ROOT} --expect-offline-deps --offline-deps-root ${OFFLINE_DEPS_ROOT}"