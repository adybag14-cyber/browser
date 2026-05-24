#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_reentry_route_stack_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local issue #3 re-entry route stack still has the
expected notes, helper scripts, and route printers before a Linux or WSL run
tries to reopen restore, build-readiness, or runtime revalidation work.
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

declare -a REFERENCE_PATHS=(
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|file|Top-level stack note that should keep the restore, archive, build-readiness, and runtime route order on one small surface."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that keeps the direct issue #3 runtime patch blocked until publication and toolchain gates are green."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot restore note for runs that still lack a reusable checkout."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Restored-checkout note for runs that need to trust or refresh a reusable checkout."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Saved-archive checksum note for runs that depend on the saved repo and dependency bundles."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness note for the blocked issue #3 runtime lane."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note for the direct Page.zig and win32_backend.zig patch."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory input preflight helper for the blocked issue #3 route."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper for the blocked issue #3 route."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper for saved-snapshot follow-up work."
    "scripts/check_linux_build_readiness.py|file|Linux or WSL readiness helper for toolchain and offline-dependency staging."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Fail-fast saved-browser-snapshot surface check."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot route printer."
    "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh|file|Fail-fast restored-checkout route surface check."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|file|Restored-checkout route printer."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Fail-fast saved-archive-integrity surface check."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Saved-archive-integrity route printer."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Fail-fast Linux build-readiness surface check."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer."
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|Fail-fast Linux runtime revalidation surface check."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Linux runtime revalidation route printer."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|file|Linux-to-Windows handoff route printer for the narrowed issue #3 replay ladder."
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1|file|Windows runtime route helper for the narrowed issue #3 replay ladder."
    "build.zig.zon|file|Manifest surface that still defines the branch Zig and sibling dependency shape."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|scripts/linux/check_issue3_reentry_route_stack_surface.sh|The stack note should point back to its own fail-fast surface checker."
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|scripts/linux/show_issue3_reentry_route_stack.sh|The stack note should point at the companion route printer."
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|docs/ISSUE3_RUNTIME_REENTRY_GATES.md|The stack note should keep the gate note visible."
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The stack note should keep the saved-browser-snapshot route visible."
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|The stack note should keep the restored-checkout route visible."
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|The stack note should keep the saved-archive-integrity route visible."
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The stack note should keep the Linux build-readiness route visible."
    "docs/ISSUE3_REENTRY_ROUTE_STACK.md|docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|The stack note should keep the runtime revalidation route visible."
    "scripts/linux/show_issue3_reentry_route_stack.sh|check_issue3_reentry_route_stack_surface.sh|The route printer should point back to the fail-fast stack checker."
    "scripts/linux/show_issue3_reentry_route_stack.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer should keep the saved-browser-snapshot route visible."
    "scripts/linux/show_issue3_reentry_route_stack.sh|show_issue3_restored_checkout_reentry_route.sh|The route printer should keep the restored-checkout route visible."
    "scripts/linux/show_issue3_reentry_route_stack.sh|check_issue3_saved_memory_inputs.py|The route printer should keep the saved-Memory preflight visible."
    "scripts/linux/show_issue3_reentry_route_stack.sh|show_issue3_saved_archive_integrity_route.sh|The route printer should keep the saved-archive-integrity route visible."
    "scripts/linux/show_issue3_reentry_route_stack.sh|show_issue3_linux_build_readiness_route.sh|The route printer should keep the Linux build-readiness route visible."
    "scripts/linux/show_issue3_reentry_route_stack.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer should keep the Linux runtime revalidation route visible."
    "scripts/linux/show_issue3_reentry_route_stack.sh|show_issue3_windows_runtime_handoff_route.sh|The route printer should keep the Windows handoff route visible."
)

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
    printf '  "profile": %s,\n' "$(json_escape "issue3-reentry-route-stack-surface")"
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

echo "Issue #3 re-entry route stack surface check"
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
echo "All issue #3 re-entry route stack surfaces are present."
