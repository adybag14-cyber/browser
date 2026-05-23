#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local Linux or WSL helper surface for the direct issue #3
Enter-submit runtime route still has its required docs, helpers, and command
snippets in place before a run reopens the blocked Page.zig and
win32_backend.zig lane.
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
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should stay read-first before the direct runtime route is reopened."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should keep the Page.zig and win32_backend.zig target narrow."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness companion used when the direct runtime route is blocked on toolchain staging."
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|Fail-fast Linux or WSL surface checker for the direct issue #3 runtime route."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Compact Linux or WSL route printer for the direct issue #3 runtime lane."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Fail-fast Linux build-readiness checker used before offline staging is blamed on source changes."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer used before focused Zig output is trusted."
    "scripts/check_linux_build_readiness.py|file|Branch-local build-readiness helper used by the Linux or WSL recovery route."
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|Source-based checker for the direct Page.zig and win32_backend.zig runtime bridge markers."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|The gate note keeps the Linux or WSL runtime surface checker visible before the direct runtime patch is reopened."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|The gate note keeps the compact Linux or WSL runtime helper visible before the direct runtime patch is reopened."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|The Linux or WSL runtime helper prints the source-based runtime contract check."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux or WSL runtime helper keeps the build-readiness surface check visible before focused Zig output is trusted."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|The Linux or WSL runtime helper keeps the build-readiness route printer visible when the toolchain gate is still closed."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|The Linux or WSL runtime helper still prints the reduced Google Windows follow-up probe."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-enter-submit-runtime-revalidation-surface")"
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
    if [[ "${missing_count}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Issue #3 Enter-submit runtime revalidation surface check"
echo
echo "Repo root: ${REPO_ROOT}"
echo

for row in "${reference_rows[@]}"; do
    IFS="|" read -r relative_path kind purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Helper source expectations:"
for row in "${content_rows[@]}"; do
    IFS="|" read -r relative_path snippet purpose exists <<<"${row}"
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
echo "All runtime revalidation surfaces are present."
