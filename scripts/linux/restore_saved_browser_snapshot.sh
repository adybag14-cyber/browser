#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/restore_saved_browser_snapshot.sh \
    [--browser-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--check-only] \
    [--json] \
    [--force]

Restore the saved browser repo snapshot from Memory into a reusable local
checkout for Linux or WSL validation work, or print the derived paths without
extracting it.

Defaults:
  browser root  parent of this script
  memory root   <browser-root>/../memory
  archive       <memory-root>/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip
  destination   <browser-root>/../browser-memory-snapshot

Use --check-only to confirm the saved archive is present and to print the exact
restore and follow-up commands without mutating the filesystem.
EOF
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
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
CHECK_ONLY=false
JSON=false
FORCE_RESTORE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
            shift 2
            ;;
        --destination)
            DESTINATION="$2"
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/${DEFAULT_ARCHIVE_NAME}"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(cd "${BROWSER_ROOT}/.." && pwd)/${DEFAULT_DESTINATION_NAME}"
fi

if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi
if [[ ! -d "${MEMORY_ROOT}" ]]; then
    echo "Memory root does not exist: ${MEMORY_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Saved browser snapshot archive does not exist: ${ARCHIVE_PATH}" >&2
    exit 1
fi

TOP_LEVEL_ENTRY="$(python3 - "${ARCHIVE_PATH}" <<'PY'
import pathlib
import sys
import zipfile

archive_path = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(archive_path) as zf:
    names = [name for name in zf.namelist() if name and not name.startswith("__MACOSX/")]
if not names:
    raise SystemExit("archive has no entries")
top_level = names[0].split("/", 1)[0]
if not top_level:
    raise SystemExit("could not determine top-level folder")
print(top_level)
PY
)"

FOLLOW_UP_MEMORY_CHECK="python scripts/check_issue3_saved_memory_inputs.py --repo-root '${DESTINATION}'"
FOLLOW_UP_ROUTE="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root '${DESTINATION}'"

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "browser_root": %s,\n' "$(json_escape "${BROWSER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "archive_path": %s,\n' "$(json_escape "${ARCHIVE_PATH}")"
    printf '  "destination": %s,\n' "$(json_escape "${DESTINATION}")"
    printf '  "archive_top_level": %s,\n' "$(json_escape "${TOP_LEVEL_ENTRY}")"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '  "force_restore": %s,\n' "$([[ "${FORCE_RESTORE}" == "true" ]] && echo true || echo false)"
    printf '  "destination_exists": %s\n' "$([[ -e "${DESTINATION}" ]] && echo true || echo false)"
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved browser snapshot restore surface check passed."
    echo "Browser root:       ${BROWSER_ROOT}"
    echo "Memory root:        ${MEMORY_ROOT}"
    echo "Snapshot archive:   ${ARCHIVE_PATH}"
    echo "Archive top level:  ${TOP_LEVEL_ENTRY}"
    echo "Destination:        ${DESTINATION}"
    echo
    echo "Suggested restore command:"
    printf "  bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root '%s' --destination '%s'\n" "${BROWSER_ROOT}" "${DESTINATION}"
    echo
    echo "Suggested follow-up checks:"
    printf "  %s\n" "${FOLLOW_UP_MEMORY_CHECK}"
    printf "  %s\n" "${FOLLOW_UP_ROUTE}"
    exit 0
fi

DESTINATION_PARENT="$(cd "$(dirname "${DESTINATION}")" && pwd)"
mkdir -p "${DESTINATION_PARENT}"

if [[ -e "${DESTINATION}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${DESTINATION}"
    else
        echo "Destination already exists: ${DESTINATION}" >&2
        echo "Use --force to replace the existing restored checkout." >&2
        exit 1
    fi
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

unzip -q "${ARCHIVE_PATH}" -d "${TMP_DIR}"
if [[ ! -d "${TMP_DIR}/${TOP_LEVEL_ENTRY}" ]]; then
    echo "Expected extracted top-level folder was not found: ${TMP_DIR}/${TOP_LEVEL_ENTRY}" >&2
    exit 1
fi

mv "${TMP_DIR}/${TOP_LEVEL_ENTRY}" "${DESTINATION}"

if [[ ! -f "${DESTINATION}/build.zig.zon" ]]; then
    echo "Restored checkout is missing build.zig.zon: ${DESTINATION}/build.zig.zon" >&2
    exit 1
fi

echo
echo "Saved browser snapshot is ready."
echo "Destination: ${DESTINATION}"
echo "Archive top level: ${TOP_LEVEL_ENTRY}"
echo
echo "Suggested follow-up checks:"
printf "  %s\n" "${FOLLOW_UP_MEMORY_CHECK}"
printf "  %s\n" "${FOLLOW_UP_ROUTE}"
