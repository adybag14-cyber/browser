#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_archives_root.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/memory] \
    [--json]

Detect the saved issue #3 dependency archive directory from either the normal
workspace layout or a scratch checkout restored from the saved repo zip, then
print the exact build-readiness commands that should use it.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

append_candidate() {
    local candidate="$1"
    [[ -z "${candidate}" ]] && return 0
    CANDIDATES+=("${candidate}")
}

looks_like_saved_archives_root() {
    local candidate="$1"
    [[ -d "${candidate}" ]] || return 1
    compgen -G "${candidate}/01-rust-*.tar.xz" > /dev/null || return 1
    compgen -G "${candidate}/03-boringssl-zig-main.zip" > /dev/null || return 1
    compgen -G "${candidate}/04-zig-browser-depo.tar.zip" > /dev/null || return 1
    return 0
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
MEMORY_ROOT=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
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

declare -a CANDIDATES=()
if [[ -n "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${MEMORY_ROOT}" && pwd)"
    append_candidate "${MEMORY_ROOT}/repo_archives/browser/dependencies"
    append_candidate "${MEMORY_ROOT}/browser/dependencies"
else
    current="${REPO_ROOT}"
    while true; do
        append_candidate "${current}/memory/repo_archives/browser/dependencies"
        parent="$(dirname "${current}")"
        [[ "${parent}" == "${current}" ]] && break
        current="${parent}"
    done
    append_candidate "/workspace/memory/repo_archives/browser/dependencies"
fi

declare -A SEEN=()
declare -a UNIQUE_CANDIDATES=()
for candidate in "${CANDIDATES[@]}"; do
    [[ -n "${candidate}" ]] || continue
    if [[ -n "${SEEN[${candidate}]:-}" ]]; then
        continue
    fi
    SEEN["${candidate}"]=1
    UNIQUE_CANDIDATES+=("${candidate}")
done

RESOLVED_SAVED_ARCHIVES_ROOT=""
for candidate in "${UNIQUE_CANDIDATES[@]}"; do
    if looks_like_saved_archives_root "${candidate}"; then
        RESOLVED_SAVED_ARCHIVES_ROOT="${candidate}"
        break
    fi
done

if [[ -z "${RESOLVED_SAVED_ARCHIVES_ROOT}" ]]; then
    if [[ "${JSON}" -eq 1 ]]; then
        printf '{\n'
        printf '  "resolved": false,\n'
        printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
        printf '  "candidates": [\n'
        for index in "${!UNIQUE_CANDIDATES[@]}"; do
            [[ "${index}" -gt 0 ]] && printf ',\n'
            printf '    %s' "$(json_escape "${UNIQUE_CANDIDATES[$index]}")"
        done
        printf '\n  ]\n'
        printf '}\n'
    else
        echo "Could not resolve a saved issue #3 archive directory."
        echo
        echo "Repo root: ${REPO_ROOT}"
        echo
        echo "Candidates checked:"
        for candidate in "${UNIQUE_CANDIDATES[@]}"; do
            echo "  - ${candidate}"
        done
    fi
    exit 1
fi

SAVED_ARCHIVE_BROWSER_ROOT="$(cd "${RESOLVED_SAVED_ARCHIVES_ROOT}/.." && pwd)"
CHECKER_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${RESOLVED_SAVED_ARCHIVES_ROOT}")"
ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVE_BROWSER_ROOT}")"

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "resolved": true,\n'
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "saved_archives_root": %s,\n' "$(json_escape "${RESOLVED_SAVED_ARCHIVES_ROOT}")"
    printf '  "saved_archive_browser_root": %s,\n' "$(json_escape "${SAVED_ARCHIVE_BROWSER_ROOT}")"
    printf '  "commands": {\n'
    printf '    "checker": %s,\n' "$(json_escape "${CHECKER_COMMAND}")"
    printf '    "route": %s\n' "$(json_escape "${ROUTE_COMMAND}")"
    printf '  }\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 saved archive root helper

Repo root:                 ${REPO_ROOT}
Saved archives root:       ${RESOLVED_SAVED_ARCHIVES_ROOT}
Saved archive browser dir: ${SAVED_ARCHIVE_BROWSER_ROOT}

Suggested commands
==================
  Saved-archive preflight:
    ${CHECKER_COMMAND}

  Full route printer:
    ${ROUTE_COMMAND}

Notes
=====
  - Use this helper when the browser repo came from the saved zip and is not sitting beside the normal workspace memory folder.
  - The checker command keeps the saved dependency archive directory explicit before Zig or Rust availability is blamed.
  - The route command keeps the broader Linux or WSL re-entry ladder pointed at the matching browser archive root.
EOF
