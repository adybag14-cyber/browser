#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_zig_archive_route.sh \
    [--repo-root /path/to/browser] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--json]

Print the saved Zig archive recovery route for the blocked Linux/WSL issue #3 lane.
EOF
}

normalize_saved_archives_root() {
    local raw_root="$1"
    if [[ -d "${raw_root}/dependencies" ]]; then
        raw_root="${raw_root}/dependencies"
    fi
    if [[ -d "${raw_root}" ]]; then
        (
            cd "${raw_root}"
            pwd
        )
        return 0
    fi
    printf '%s\n' "${raw_root}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
JSON=0

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
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --json)
            JSON=1
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
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi

HELPER_PATH="${REPO_ROOT}/scripts/check_issue3_saved_zig_archives.py"
CHECK_SURFACE_PATH="${REPO_ROOT}/scripts/linux/check_issue3_saved_zig_archive_route_surface.sh"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - "${REPO_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${TOOLCHAINS_ROOT}" "${HELPER_PATH}" "${CHECK_SURFACE_PATH}" <<'PY'
import json
import sys

print(json.dumps({
    "repo_root": sys.argv[1],
    "saved_archives_root": sys.argv[2],
    "toolchains_root": sys.argv[3],
    "surface_check": f"bash {sys.argv[5]} --repo-root {sys.argv[1]}",
    "discovery": (
        f"python {sys.argv[4]} --repo-root {sys.argv[1]} "
        f"--saved-archives-root {sys.argv[2]} --toolchains-root {sys.argv[3]}"
    ),
}, indent=2))
PY
    exit 0
fi

echo "Issue #3 saved Zig archive recovery route"
echo
echo "Repo root:            ${REPO_ROOT}"
echo "Saved archives root:  ${SAVED_ARCHIVES_ROOT}"
echo "Toolchains root:      ${TOOLCHAINS_ROOT}"
echo
echo "Read first"
echo "=========="
echo "  docs/ISSUE3_SAVED_ZIG_ARCHIVE_ROUTE.md"
echo "  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
echo "  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
echo
echo "Surface check"
echo "============="
echo "  bash ${CHECK_SURFACE_PATH} --repo-root ${REPO_ROOT}"
echo
echo "Saved archive discovery"
echo "======================="
echo "  python ${HELPER_PATH} --repo-root ${REPO_ROOT} --saved-archives-root ${SAVED_ARCHIVES_ROOT} --toolchains-root ${TOOLCHAINS_ROOT}"
echo
echo "Working rules"
echo "============="
echo "  - Run the surface check first so missing docs or helper drift fails before the route blames the fallback Zig bundle."
echo "  - Prefer a saved Zig 0.15.x archive over the attached Zig 0.17 fallback when one is available."
echo "  - Use the printed restore_zig_toolchain_archive.sh commands instead of rebuilding the extraction command by hand."
echo "  - After restoring a matching Zig line under ../toolchains, rerun the broader Linux build-readiness helper."
