#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/linux/restore_zig_toolchain_archive.sh \
    [--browser-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--archive /path/to/zig-archive.tar.xz] \
    [--destination /path/to/toolchains/zig-0.15.2] \
    [--check-only] \
    [--json] \
    [--force]

Restore a Zig toolchain archive into the shared `../toolchains` layout used by
the issue #3 Linux or WSL recovery helpers, or print the derived paths without
extracting it.

Defaults:
  browser root     parent of this script
  toolchains root  <browser-root>/../toolchains
  archive          <browser-root>/../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz if present
  destination      <toolchains-root>/<archive top-level folder>

Supported archive types:
  .tar, .tar.gz, .tgz, .tar.xz, .zip
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
DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
TOOLCHAINS_ROOT=""
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
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
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

if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi
BROWSER_ROOT="$(cd "${BROWSER_ROOT}" && pwd)"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    CANDIDATE_ARCHIVE="$(cd "${BROWSER_ROOT}/.." && pwd)/agent_files/${DEFAULT_FALLBACK_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_ARCHIVE}" ]]; then
        ARCHIVE_PATH="${CANDIDATE_ARCHIVE}"
    fi
fi

if [[ -z "${ARCHIVE_PATH}" ]]; then
    echo "No Zig archive was provided and the default fallback archive was not found beside the repo workspace." >&2
    exit 1
fi
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Zig archive does not exist: ${ARCHIVE_PATH}" >&2
    exit 1
fi

ARCHIVE_TOP_LEVEL="$(python3 - "${ARCHIVE_PATH}" <<'PY'
from __future__ import annotations

import pathlib
import sys
import tarfile
import zipfile

archive_path = pathlib.Path(sys.argv[1])

def first_top_level(parts: list[str]) -> str:
    names: list[str] = []
    for raw_name in parts:
        if not raw_name or raw_name.startswith("__MACOSX/"):
            continue
        normalized = raw_name[2:] if raw_name.startswith("./") else raw_name
        if normalized:
            names.append(normalized)
    if not names:
        raise SystemExit("archive has no entries")
    top_levels = sorted({name.rstrip("/").split("/", 1)[0] for name in names if name.rstrip("/")})
    if not top_levels:
        raise SystemExit("could not determine archive top-level folder")
    if len(top_levels) != 1:
        joined = ", ".join(top_levels)
        raise SystemExit(f"archive must contain exactly one top-level directory, found: {joined}")
    top_level = top_levels[0]
    if not any(name.startswith(f"{top_level}/") for name in names):
        raise SystemExit(f"archive top-level entry is not a directory: {top_level}")
    return top_level

if zipfile.is_zipfile(archive_path):
    with zipfile.ZipFile(archive_path) as zf:
        print(first_top_level(zf.namelist()))
elif tarfile.is_tarfile(archive_path):
    with tarfile.open(archive_path) as tf:
        print(first_top_level(tf.getnames()))
else:
    raise SystemExit(f"unsupported archive type: {archive_path}")
PY
)"

if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="${TOOLCHAINS_ROOT}/${ARCHIVE_TOP_LEVEL}"
fi

DESTINATION_PARENT_RAW="$(dirname "${DESTINATION}")"
DESTINATION_PARENT="$(python3 - "${DESTINATION_PARENT_RAW}" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
if [[ "${CHECK_ONLY}" != "true" ]]; then
    mkdir -p "${DESTINATION_PARENT}"
fi
FOLLOW_UP_DISCOVERY_SCRIPT="${BROWSER_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
FOLLOW_UP_BUILD_READINESS_SCRIPT="${BROWSER_ROOT}/scripts/check_linux_build_readiness.py"
FOLLOW_UP_DISCOVERY="bash '${FOLLOW_UP_DISCOVERY_SCRIPT}' --repo-root '${BROWSER_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}'"
FOLLOW_UP_BUILD_READINESS_TEMPLATE="python '${FOLLOW_UP_BUILD_READINESS_SCRIPT}' --repo-root '${BROWSER_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}' --zig <restored-zig-path>"

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "browser_root": %s,\n' "$(json_escape "${BROWSER_ROOT}")"
    printf '  "toolchains_root": %s,\n' "$(json_escape "${TOOLCHAINS_ROOT}")"
    printf '  "archive_path": %s,\n' "$(json_escape "${ARCHIVE_PATH}")"
    printf '  "archive_top_level": %s,\n' "$(json_escape "${ARCHIVE_TOP_LEVEL}")"
    printf '  "destination": %s,\n' "$(json_escape "${DESTINATION}")"
    printf '  "follow_up_discovery": %s,\n' "$(json_escape "${FOLLOW_UP_DISCOVERY}")"
    printf '  "follow_up_build_readiness": %s,\n' "$(json_escape "${FOLLOW_UP_BUILD_READINESS_TEMPLATE}")"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '  "force_restore": %s,\n' "$([[ "${FORCE_RESTORE}" == "true" ]] && echo true || echo false)"
    printf '  "destination_exists": %s\n' "$([[ -e "${DESTINATION}" ]] && echo true || echo false)"
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved Zig toolchain restore surface check passed."
    echo "Browser root:        ${BROWSER_ROOT}"
    echo "Toolchains root:     ${TOOLCHAINS_ROOT}"
    echo "Zig archive:         ${ARCHIVE_PATH}"
    echo "Archive top level:   ${ARCHIVE_TOP_LEVEL}"
    echo "Destination:         ${DESTINATION}"
    echo
    echo "Suggested follow-up commands:"
    printf "  %s\n" "${FOLLOW_UP_DISCOVERY}"
    printf "  %s\n" "${FOLLOW_UP_BUILD_READINESS_TEMPLATE}"
    exit 0
fi

if [[ -e "${DESTINATION}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${DESTINATION}"
    else
        echo "Destination already exists: ${DESTINATION}" >&2
        echo "Use --force to replace the existing restored toolchain." >&2
        exit 1
    fi
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if python3 - "${ARCHIVE_PATH}" <<'PY'
import pathlib
import sys
import zipfile

archive_path = pathlib.Path(sys.argv[1])
raise SystemExit(0 if zipfile.is_zipfile(archive_path) else 1)
PY
then
    unzip -q "${ARCHIVE_PATH}" -d "${TMP_DIR}"
else
    tar -xf "${ARCHIVE_PATH}" -C "${TMP_DIR}"
fi

if [[ ! -d "${TMP_DIR}/${ARCHIVE_TOP_LEVEL}" ]]; then
    echo "Expected extracted top-level folder was not found: ${TMP_DIR}/${ARCHIVE_TOP_LEVEL}" >&2
    exit 1
fi

mv "${TMP_DIR}/${ARCHIVE_TOP_LEVEL}" "${DESTINATION}"

ZIG_BIN=""
if [[ -x "${DESTINATION}/zig" ]]; then
    ZIG_BIN="${DESTINATION}/zig"
elif [[ -x "${DESTINATION}/bin/zig" ]]; then
    ZIG_BIN="${DESTINATION}/bin/zig"
else
    echo "Restored toolchain is missing a zig executable under ${DESTINATION}" >&2
    exit 1
fi

echo
echo "Saved Zig toolchain is ready."
echo "Destination: ${DESTINATION}"
echo "zig: ${ZIG_BIN}"
echo "zig version: $("${ZIG_BIN}" version | tr -d '\r')"
echo
echo "Suggested follow-up commands:"
printf "  %s\n" "${FOLLOW_UP_DISCOVERY}"
printf "  python '%s' --repo-root '%s' --toolchains-root '%s' --zig '%s'\n" \
    "${FOLLOW_UP_BUILD_READINESS_SCRIPT}" "${BROWSER_ROOT}" "${TOOLCHAINS_ROOT}" "${ZIG_BIN}"
