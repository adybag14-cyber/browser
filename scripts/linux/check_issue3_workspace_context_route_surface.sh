#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_workspace_context_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the workspace-context route for the blocked issue #3 Linux or WSL
re-entry lane still has its required note, helper surface, and follow-up route
references in place.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|file|Read-first note for nested-checkout workspace-context recovery."
    "scripts/linux/check_issue3_workspace_context_route_surface.sh|file|Fail-fast surface checker for the workspace-context route."
    "scripts/linux/show_issue3_workspace_context_route.sh|file|Compact route printer for the workspace-context handoff."
    "scripts/check_issue3_workspace_context.py|file|Workspace-context helper that resolves the practical shared roots."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 progress-tracker handoff note that workspace-context reruns can chain into."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved browser-snapshot route note for restored checkouts."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness note for the next environment-gate rerun."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig recovery note for the next matching-line rerun."
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|file|Saved Zig archive-candidates note for pre-restore selection."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|check_issue3_workspace_context_route_surface.sh|The route note keeps the dedicated workspace-context surface checker visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_workspace_context_route.sh|The route note keeps the compact workspace-context route printer visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|check_issue3_workspace_context.py|The route note still points at the underlying workspace-context helper."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|The route note keeps the saved Zig archive-candidates route visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The route note keeps the saved browser-snapshot follow-up visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The route note keeps the Zig recovery follow-up visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|issue `#11` progress-tracker route command|The route note keeps the issue #11 follow-up visible."
    "scripts/linux/show_issue3_workspace_context_route.sh|workspace-context route|The route printer still introduces the workspace-context handoff clearly."
    "scripts/linux/show_issue3_workspace_context_route.sh|check_issue3_workspace_context.py|The route printer still prints the underlying helper command."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_progress_tracker_route.sh|The route printer still exposes the issue #11 follow-up route."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer still exposes the saved browser-snapshot follow-up route."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The route printer still exposes the Zig recovery follow-up route."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_saved_zig_archive_candidates_route.sh|The route printer still exposes the saved Zig archive-candidates follow-up route."
    "scripts/linux/show_issue3_workspace_context_route.sh|resolved_roots|The route printer JSON output exposes the resolved roots explicitly."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-workspace-context-route-surface")"
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

echo "Issue #3 workspace-context route surface check"
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
echo "All workspace-context route surfaces are present."
