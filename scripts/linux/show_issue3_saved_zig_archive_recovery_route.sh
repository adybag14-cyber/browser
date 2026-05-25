#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_zig_archive_recovery_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--extra-search-root /path/to/other/archive-dir] \
    [--json]

Print the branch-local recovery route for finding a real Zig 0.15.x archive
before the issue #3 Linux or WSL re-entry lane reuses the fallback Zig 0.17
bundle as route-discovery-only input.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TOOLCHAINS_ROOT=""
SAVED_ARCHIVES_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0
EXTRA_SEARCH_ROOTS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --extra-search-root)
            EXTRA_SEARCH_ROOTS+=("$2")
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
PYTHON_CMD=(
    python3
    "${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_recovery.py"
    --repo-root "${REPO_ROOT}"
)

if [[ -n "${TOOLCHAINS_ROOT}" ]]; then
    PYTHON_CMD+=(--toolchains-root "${TOOLCHAINS_ROOT}")
fi
if [[ -n "${SAVED_ARCHIVES_ROOT}" ]]; then
    PYTHON_CMD+=(--saved-archives-root "${SAVED_ARCHIVES_ROOT}")
fi
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    PYTHON_CMD+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi
for extra_root in "${EXTRA_SEARCH_ROOTS[@]}"; do
    PYTHON_CMD+=(--extra-search-root "${extra_root}")
done
if [[ "${JSON}" == "1" ]]; then
    PYTHON_CMD+=(--json)
fi

if [[ "${JSON}" == "1" ]]; then
    exec "${PYTHON_CMD[@]}"
fi

echo "Issue #3 saved Zig archive recovery route"
echo
echo "1. Confirm the recovery helper surface is present:"
echo "   bash ${REPO_ROOT}/scripts/linux/show_issue3_saved_zig_archive_recovery_route.sh --json >/dev/null"
echo
echo "2. Surface saved and fallback Zig candidates:"
printf '   %q' "${PYTHON_CMD[0]}"
for ((i = 1; i < ${#PYTHON_CMD[@]}; i++)); do
    printf ' %q' "${PYTHON_CMD[i]}"
done
printf '\n'
