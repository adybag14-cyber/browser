#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_build_readiness_rerun_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local build-readiness rerun route still exposes the
issue #11 progress tracker, the staged Zig helper, the matching-line gate, the
exact rerun helper, and the broader Linux build-readiness route.
EOF
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

declare -a REFERENCE_PATHS=(
    "docs/ISSUE3_BUILD_READINESS_RERUN_ROUTE.md|file|Read-first rerun note for the exact Linux or WSL readiness command."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 status-lane note that should stay visible while the route is still environment-gated."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Broader Linux build-readiness note that should stay visible as the next handoff after the rerun command is known."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig recovery note that should stay visible when no matching staged toolchain exists yet."
    "scripts/linux/show_issue3_build_readiness_rerun_route.sh|file|Build-readiness rerun route printer."
    "scripts/check_issue3_build_readiness_rerun.py|file|Exact branch-compatible readiness rerun helper."
    "scripts/check_issue3_staged_zig_toolchain_candidates.py|file|Staged Zig candidate helper."
    "scripts/linux/check_issue3_zig_toolchain_match.sh|file|Matching-line Zig gate."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig recovery route printer."
    "scripts/check_linux_build_readiness.py|file|Broader Linux build-readiness helper."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_BUILD_READINESS_RERUN_ROUTE.md|scripts/check_issue3_build_readiness_rerun.py|The rerun note keeps the exact rerun helper visible."
    "docs/ISSUE3_BUILD_READINESS_RERUN_ROUTE.md|scripts/check_issue3_staged_zig_toolchain_candidates.py|The rerun note keeps the staged Zig helper visible."
    "docs/ISSUE3_BUILD_READINESS_RERUN_ROUTE.md|scripts/linux/check_issue3_zig_toolchain_match.sh|The rerun note keeps the matching-line gate visible."
    "docs/ISSUE3_BUILD_READINESS_RERUN_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|The rerun note keeps the issue #11 route visible."
    "docs/ISSUE3_BUILD_READINESS_RERUN_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The rerun note keeps the recovery fallback visible."
    "scripts/linux/show_issue3_build_readiness_rerun_route.sh|check_issue3_staged_zig_toolchain_candidates.py|The rerun route printer keeps the staged Zig helper visible."
    "scripts/linux/show_issue3_build_readiness_rerun_route.sh|check_issue3_zig_toolchain_match.sh|The rerun route printer keeps the matching-line gate visible."
    "scripts/linux/show_issue3_build_readiness_rerun_route.sh|check_issue3_build_readiness_rerun.py|The rerun route printer keeps the exact rerun helper visible."
    "scripts/linux/show_issue3_build_readiness_rerun_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The rerun route printer keeps the Zig recovery route visible."
    "scripts/linux/show_issue3_build_readiness_rerun_route.sh|show_issue3_linux_build_readiness_route.sh|The rerun route printer keeps the broader Linux build-readiness route visible."
    "scripts/linux/show_issue3_build_readiness_rerun_route.sh|Matching-line gate:|The rerun route printer still prints the matching-line step."
    "scripts/linux/show_issue3_build_readiness_rerun_route.sh|Exact readiness rerun helper:|The rerun route printer still prints the exact rerun step."
)

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

reference_rows=()
content_rows=()
missing_count=0

for entry in "${REFERENCE_PATHS[@]}"; do
    IFS="|" read -r relative_path kind purpose <<<"${entry}"
    full_path="${REPO_ROOT}/${relative_path}"
    exists=0
    if [[ "${kind}" == "directory" ]]; then
        [[ -d "${full_path}" ]] && exists=1
    else
        [[ -f "${full_path}" ]] && exists=1
    fi
    if [[ "${exists}" -eq 0 ]]; then
        missing_count=$((missing_count + 1))
    fi
    reference_rows+=("${relative_path}|${kind}|${purpose}|${exists}")
 done

for entry in "${CONTENT_EXPECTATIONS[@]}"; do
    IFS="|" read -r relative_path snippet purpose <<<"${entry}"
    full_path="${REPO_ROOT}/${relative_path}"
    exists=0
    if [[ -f "${full_path}" ]] && grep -Fq -- "${snippet}" "${full_path}"; then
        exists=1
    fi
    if [[ "${exists}" -eq 0 ]]; then
        missing_count=$((missing_count + 1))
    fi
    content_rows+=("${relative_path}|${snippet}|${purpose}|${exists}")
 done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-build-readiness-rerun-route-surface")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "reference_count": %d,\n' "${#reference_rows[@]}"
    printf '  "content_check_count": %d,\n' "${#content_rows[@]}"
    printf '  "missing_count": %d,\n' "${missing_count}"
    printf '  "references": [\n'
    for index in "${!reference_rows[@]}"; do
        IFS="|" read -r relative_path kind purpose exists <<<"${reference_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"path": %s, "kind": %s, "purpose": %s, "exists": %s}' \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${kind}")" \
            "$(json_escape "${purpose}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ],\n'
    printf '  "content_checks": [\n'
    for index in "${!content_rows[@]}"; do
        IFS="|" read -r relative_path snippet purpose exists <<<"${content_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"path": %s, "snippet": %s, "purpose": %s, "exists": %s}' \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${snippet}")" \
            "$(json_escape "${purpose}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ]\n'
    printf '}\n'
    [[ "${missing_count}" -eq 0 ]]
    exit $?
fi

echo "Issue #3 build-readiness rerun route surface check"
echo
echo "Repo root: ${REPO_ROOT}"
echo
for row in "${reference_rows[@]}"; do
    IFS="|" read -r relative_path _kind purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
 done

echo
echo "Content expectations:"
for row in "${content_rows[@]}"; do
    IFS="|" read -r relative_path _snippet purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
 done

if [[ "${missing_count}" -gt 0 ]]; then
    echo
    echo "Missing checks: ${missing_count}"
    exit 1
fi

echo
echo "All build-readiness rerun route surfaces are present."
