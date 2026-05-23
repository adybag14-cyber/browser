#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the compact Linux or WSL route printer for the direct issue #3
Enter-submit runtime lane still references the expected docs, helper scripts,
source checks, focused test commands, and Windows follow-up probes before a run
trusts that route as the main re-entry surface.
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
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should stay read-first before the direct runtime route is trusted."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should keep the direct Page.zig and win32_backend.zig target narrow."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot route note that should stay visible when no reusable checkout exists yet."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness note that should stay visible when the toolchain gate is still closed."
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh|file|Fail-fast checker for the compact Linux or WSL direct runtime route printer."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Compact Linux or WSL route printer for the direct issue #3 runtime lane."
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|Broader Linux or WSL direct runtime surface checker that should remain reachable from the compact route."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Saved-browser-snapshot surface checker used when no reusable checkout exists yet."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot route printer used when no reusable checkout exists yet."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper for the repo snapshot, dependency archives, and fallback Zig bundle."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Linux build-readiness surface checker used before focused Zig output is trusted."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer used when the toolchain gate is still closed."
    "scripts/check_linux_build_readiness.py|file|Branch-local build-readiness helper that backs the Linux or WSL route."
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|Source-based checker for the Page.zig and win32_backend.zig runtime bridge markers."
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1|file|Reduced Google follow-up probe that should remain in the Windows handoff."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|docs/ISSUE3_RUNTIME_REENTRY_GATES.md|The compact route keeps the runtime gate note in the read-first set."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|The compact route keeps the runtime revalidation note in the read-first set."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The compact route keeps the saved-browser-snapshot note visible before helper replay moves into a restored checkout."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The compact route keeps the Linux build-readiness note visible when the toolchain gate is still closed."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_revalidation_surface.sh|The compact route prints the broader direct runtime surface checker before replay widens back out."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_saved_browser_snapshot_route_surface.sh|The compact route points back to the saved-browser-snapshot surface checker when no reusable checkout exists yet."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_saved_browser_snapshot_route.sh|The compact route prints the saved-browser-snapshot route before helper replay moves into a restored checkout."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|The compact route prints the source-based runtime contract check."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_saved_memory_inputs.py|The compact route prints the saved-memory preflight before broader build-readiness commands."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The compact route prints the Linux build-readiness surface checker before focused Zig output is trusted."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|The compact route prints the Linux build-readiness route when the toolchain gate is still closed."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_linux_build_readiness.py|The compact route prints the branch-local Linux build-readiness helper."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|fallback-zig-archive|The compact route supports an explicit fallback Zig archive override during saved-checkout re-entry."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|Fallback Zig archive:|The compact route prints the surfaced fallback Zig archive before Linux or WSL follow-up commands."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|zig test src/browser/Page.zig|The compact route prints the focused Page.zig test command for a branch-compatible Zig line."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|zig test src/display/win32_backend.zig -target x86_64-windows-gnu|The compact route prints the focused Win32 test command for a branch-compatible Zig line."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|zig build -Dtarget=x86_64-windows-msvc --summary all|The compact route prints the Windows build handoff after the Linux or WSL gate turns green."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|The compact route keeps the reduced Google Windows follow-up probe visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1|The compact route keeps the reduced Google local fixture handoff visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|https://www.google.com/|The compact route keeps the live Google handoff visible after the reduced probe."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-enter-submit-runtime-revalidation-route-surface")"
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

echo "Issue #3 Enter-submit runtime route surface check"
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
echo "Route content expectations:"
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
echo "All runtime route surfaces are present."
