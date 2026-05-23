#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_archives_root.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--run] \
    [--json] \
    [-- extra args for check_linux_build_readiness.py]

Resolve the saved dependency archive root used by the Linux or WSL issue #3
build-readiness route. By default this prefers the current workspace layout:

  ../memory/repo_archives/browser/dependencies

and falls back to:

  ../memory/repo_archives/browser

Use --run to execute scripts/check_linux_build_readiness.py with the resolved
root and any extra forwarded arguments.
EOF
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
RUN_CHECK=0
JSON=0
FORWARD_ARGS=()

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
        --run)
            RUN_CHECK=1
            shift
            ;;
        --json)
            JSON=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            FORWARD_ARGS=("$@")
            break
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
WORKSPACE_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"

declare -a REQUIRED_ARCHIVES=(
    "01-rust-*.tar.xz|saved Rust toolchain archive"
    "03-boringssl-zig-main.zip|saved BoringSSL archive"
    "04-zig-browser-depo.tar.zip|saved browser dependency archive"
)

declare -a CANDIDATE_ROOTS=()
if [[ -n "${SAVED_ARCHIVES_ROOT}" ]]; then
    CANDIDATE_ROOTS+=("${SAVED_ARCHIVES_ROOT}")
else
    CANDIDATE_ROOTS+=(
        "${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
        "${WORKSPACE_ROOT}/memory/repo_archives/browser"
    )
fi

root_is_usable() {
    local root="$1"
    local entry pattern label
    [[ -d "${root}" ]] || return 1
    for entry in "${REQUIRED_ARCHIVES[@]}"; do
        IFS="|" read -r pattern label <<<"${entry}"
        compgen -G "${root}/${pattern}" > /dev/null || return 1
    done
    return 0
}

resolved_root=""
for candidate_root in "${CANDIDATE_ROOTS[@]}"; do
    if root_is_usable "${candidate_root}"; then
        resolved_root="$(cd "${candidate_root}" && pwd)"
        break
    fi
done

check_command=(
    python
    scripts/check_linux_build_readiness.py
    --repo-root
    "${REPO_ROOT}"
    --expect-saved-archives
)
if [[ -n "${resolved_root}" ]]; then
    check_command+=(--saved-archives-root "${resolved_root}")
fi
if [[ ${#FORWARD_ARGS[@]} -gt 0 ]]; then
    check_command+=("${FORWARD_ARGS[@]}")
fi

command_string=""
for part in "${check_command[@]}"; do
    if [[ -n "${command_string}" ]]; then
        command_string+=" "
    fi
    command_string+="$(format_shell_arg "${part}")"
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "candidate_roots": [\n'
    for index in "${!CANDIDATE_ROOTS[@]}"; do
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    %s' "$(json_escape "${CANDIDATE_ROOTS[$index]}")"
    done
    printf '\n  ],\n'
    printf '  "resolved_root": %s,\n' "$(json_escape "${resolved_root}")"
    printf '  "command": %s,\n' "$(json_escape "${command_string}")"
    printf '  "run": %s\n' "$([[ "${RUN_CHECK}" -eq 1 ]] && echo true || echo false)"
    printf '}\n'
    if [[ -z "${resolved_root}" ]]; then
        exit 1
    fi
    if [[ "${RUN_CHECK}" -eq 1 ]]; then
        (cd "${REPO_ROOT}" && "${check_command[@]}")
    fi
    exit 0
fi

echo "Issue #3 saved dependency archive root resolver"
echo
echo "Repo root: ${REPO_ROOT}"
echo
echo "Candidate roots:"
for candidate_root in "${CANDIDATE_ROOTS[@]}"; do
    state="missing"
    if [[ -d "${candidate_root}" ]]; then
        state="present"
    fi
    if [[ -n "${resolved_root}" && "$(cd "${candidate_root}" 2>/dev/null && pwd || true)" == "${resolved_root}" ]]; then
        state="selected"
    fi
    echo "  - ${candidate_root} [${state}]"
done

if [[ -z "${resolved_root}" ]]; then
    echo
    echo "No usable saved dependency archive root was found." >&2
    echo "Expected required archives:" >&2
    for entry in "${REQUIRED_ARCHIVES[@]}"; do
        IFS="|" read -r pattern label <<<"${entry}"
        echo "  - ${label}: ${pattern}" >&2
    done
    exit 1
fi

echo
echo "Resolved saved archive root: ${resolved_root}"
echo
echo "Suggested readiness command:"
echo "  ${command_string}"

if [[ "${RUN_CHECK}" -eq 1 ]]; then
    echo
    (cd "${REPO_ROOT}" && "${check_command[@]}")
fi
