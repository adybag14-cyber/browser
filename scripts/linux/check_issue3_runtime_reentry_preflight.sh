#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_runtime_reentry_preflight.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--saved-archives-root /path/to/workspace/memory/repo_archives/browser] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--include-zig-check] \
    [--show-output] \
    [--json]

Run the saved-Memory, direct-runtime surface, and Linux build-readiness surface
checks that should pass before a run reopens the blocked issue #3 Enter-submit
runtime route.

Use --include-zig-check to append the fuller Linux build-readiness helper so the
current Zig and Rust toolchain state is reported together with the surface
checks.
Use --show-output to print captured check output even when the helper is not in
JSON mode.
EOF
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

shell_escape() {
    printf '%q' "$1"
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
MEMORY_ROOT=""
SAVED_ARCHIVES_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
INCLUDE_ZIG_CHECK=0
SHOW_OUTPUT=0
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
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --include-zig-check)
            INCLUDE_ZIG_CHECK=1
            shift
            ;;
        --show-output)
            SHOW_OUTPUT=1
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
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"

saved_memory_command="python scripts/check_issue3_saved_memory_inputs.py --repo-root $(shell_escape "${REPO_ROOT}")"
if [[ -n "${MEMORY_ROOT}" ]]; then
    saved_memory_command+=" --memory-root $(shell_escape "${MEMORY_ROOT}")"
fi
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    saved_memory_command+=" --fallback-zig-archive $(shell_escape "${FALLBACK_ZIG_ARCHIVE}")"
fi

runtime_surface_command="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh --repo-root $(shell_escape "${REPO_ROOT}")"
linux_build_surface_command="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root $(shell_escape "${REPO_ROOT}")"

declare -a CHECKS=(
    "saved_memory_inputs|Saved Memory input check|${saved_memory_command}"
    "runtime_surface|Runtime surface check|${runtime_surface_command}"
    "linux_build_surface|Linux build-readiness surface check|${linux_build_surface_command}"
)

if [[ "${INCLUDE_ZIG_CHECK}" -eq 1 ]]; then
    linux_readiness_command="python scripts/check_linux_build_readiness.py --repo-root $(shell_escape "${REPO_ROOT}") --expect-saved-archives"
    if [[ -n "${SAVED_ARCHIVES_ROOT}" ]]; then
        linux_readiness_command+=" --saved-archives-root $(shell_escape "${SAVED_ARCHIVES_ROOT}")"
    fi
    if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
        linux_readiness_command+=" --fallback-zig-archive $(shell_escape "${FALLBACK_ZIG_ARCHIVE}")"
    fi
    CHECKS+=("linux_readiness|Linux build-readiness helper|${linux_readiness_command}")
fi

check_ids=()
check_labels=()
check_commands=()
check_statuses=()
check_outputs=()
failures=0

for entry in "${CHECKS[@]}"; do
    IFS="|" read -r check_id label command <<<"${entry}"
    check_ids+=("${check_id}")
    check_labels+=("${label}")
    check_commands+=("${command}")
    if output="$(cd "${REPO_ROOT}" && eval "${command}" 2>&1)"; then
        check_statuses+=("pass")
    else
        check_statuses+=("fail")
        failures=$((failures + 1))
    fi
    check_outputs+=("${output}")
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-runtime-reentry-preflight")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "memory_root_override": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "saved_archives_root_override": %s,\n' "$(json_escape "${SAVED_ARCHIVES_ROOT}")"
    printf '  "fallback_zig_archive_override": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "include_zig_check": %s,\n' "$([[ "${INCLUDE_ZIG_CHECK}" -eq 1 ]] && echo true || echo false)"
    printf '  "ok": %s,\n' "$([[ "${failures}" -eq 0 ]] && echo true || echo false)"
    printf '  "failure_count": %d,\n' "${failures}"
    printf '  "checks": [\n'
    for index in "${!check_ids[@]}"; do
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"id": %s, "label": %s, "status": %s, "command": %s, "output": %s}' \
            "$(json_escape "${check_ids[$index]}")" \
            "$(json_escape "${check_labels[$index]}")" \
            "$(json_escape "${check_statuses[$index]}")" \
            "$(json_escape "${check_commands[$index]}")" \
            "$(json_escape "${check_outputs[$index]}")"
    done
    printf '\n  ]\n'
    printf '}\n'
    if [[ "${failures}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Issue #3 runtime re-entry preflight"
echo
echo "Repo root: ${REPO_ROOT}"
if [[ -n "${MEMORY_ROOT}" ]]; then
    echo "Memory root override: ${MEMORY_ROOT}"
fi
if [[ -n "${SAVED_ARCHIVES_ROOT}" ]]; then
    echo "Saved archives root override: ${SAVED_ARCHIVES_ROOT}"
fi
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    echo "Fallback Zig archive override: ${FALLBACK_ZIG_ARCHIVE}"
fi
echo

for index in "${!check_ids[@]}"; do
    status="PASS"
    if [[ "${check_statuses[$index]}" != "pass" ]]; then
        status="FAIL"
    fi
    echo "[${status}] ${check_labels[$index]}"
    echo "  ${check_commands[$index]}"
    if [[ "${SHOW_OUTPUT}" -eq 1 || "${check_statuses[$index]}" != "pass" ]]; then
        while IFS= read -r line; do
            echo "    ${line}"
        done <<<"${check_outputs[$index]}"
    fi
done

if [[ "${failures}" -gt 0 ]]; then
    echo
    echo "Preflight failed: ${failures} check(s) need attention before the direct issue #3 runtime patch is reopened." >&2
    echo "Suggested next step: start with the first failing check above and run the printed route helper or readiness command directly until that gate is green." >&2
    exit 1
fi

echo
echo "All issue #3 runtime re-entry preflight checks passed."
