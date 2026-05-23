#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_runtime_reentry_preflight.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Run the saved-Memory, direct-runtime surface, and Linux build-readiness surface
checks that should pass before a run reopens the blocked issue #3 Enter-submit
runtime route.
EOF
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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

declare -a CHECKS=(
    "saved_memory_inputs|Saved Memory input check|python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
    "runtime_surface|Runtime surface check|bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh --repo-root ${REPO_ROOT}"
    "linux_build_surface|Linux build-readiness surface check|bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
)

check_ids=()
check_labels=()
check_commands=()
check_statuses=()
failures=0

for entry in "${CHECKS[@]}"; do
    IFS="|" read -r check_id label command <<<"${entry}"
    check_ids+=("${check_id}")
    check_labels+=("${label}")
    check_commands+=("${command}")
    if (cd "${REPO_ROOT}" && eval "${command}" >/dev/null 2>&1); then
        check_statuses+=("pass")
    else
        check_statuses+=("fail")
        failures=$((failures + 1))
    fi
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-runtime-reentry-preflight")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "ok": %s,\n' "$([[ "${failures}" -eq 0 ]] && echo true || echo false)"
    printf '  "failure_count": %d,\n' "${failures}"
    printf '  "checks": [\n'
    for index in "${!check_ids[@]}"; do
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"id": %s, "label": %s, "status": %s, "command": %s}' \
            "$(json_escape "${check_ids[$index]}")" \
            "$(json_escape "${check_labels[$index]}")" \
            "$(json_escape "${check_statuses[$index]}")" \
            "$(json_escape "${check_commands[$index]}")"
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
echo

for index in "${!check_ids[@]}"; do
    status="PASS"
    if [[ "${check_statuses[$index]}" != "pass" ]]; then
        status="FAIL"
    fi
    echo "[${status}] ${check_labels[$index]}"
    echo "  ${check_commands[$index]}"
done

if [[ "${failures}" -gt 0 ]]; then
    echo
    echo "Preflight failed: ${failures} check(s) need attention before the direct issue #3 runtime patch is reopened." >&2
    echo "Suggested next step: print the relevant route helper and fix the first failing gate before trusting focused Zig or headed replay results." >&2
    exit 1
fi

echo
echo "All issue #3 runtime re-entry preflight checks passed."
