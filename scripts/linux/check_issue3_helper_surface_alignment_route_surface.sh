#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_helper_surface_alignment_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local helper-surface alignment route for the blocked
issue #3 Linux or WSL re-entry lane still has its required notes, helpers, and
command snippets in place before a run relies on it.
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
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|file|Read-first helper-surface alignment route note for blocked issue #3 Linux or WSL re-entry work."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 progress-tracker handoff note that should stay visible while helper drift is being resolved."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Saved-Memory route note that should stay visible when the alignment failure points at the preflight helper."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot route note that should stay visible when the restore helper surface is the drift source."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Restored-checkout re-entry note that should stay visible when a synced checkout needs re-validation."
    "scripts/linux/check_issue3_helper_surface_alignment_route_surface.sh|file|Fail-fast surface checker for the helper-surface alignment route."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|file|Compact route printer for the helper-surface alignment route."
    "scripts/check_issue3_helper_surface_alignment.py|file|Alignment helper that compares the restore, saved-memory, and restored-checkout inventories."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper that is one of the alignment inputs."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that is one of the alignment inputs."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper whose sync surface defines the current helper inventory."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Follow-up route printer when the saved-memory helper inventory is stale."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Follow-up route printer when the restore-helper inventory is stale."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|check_issue3_helper_surface_alignment_route_surface.sh|The helper-surface alignment note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|show_issue3_helper_surface_alignment_route.sh|The helper-surface alignment note keeps the compact route printer visible."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|check_issue3_helper_surface_alignment.py|The helper-surface alignment note keeps the alignment checker visible."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The helper-surface alignment note keeps the saved-memory preflight visible as an alignment target."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|scripts/check_issue3_restored_checkout.py|The helper-surface alignment note keeps the restored-checkout helper visible as an alignment target."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|scripts/linux/restore_saved_browser_snapshot.sh|The helper-surface alignment note keeps the restore helper visible as the source inventory."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|issue `#11`|The helper-surface alignment note keeps the low-volume progress tracker visible."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|show_issue3_saved_memory_inputs_route.sh|The helper-surface alignment note keeps the saved-memory follow-up route visible."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The helper-surface alignment note keeps the restore follow-up route visible."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|check_issue3_helper_surface_alignment_route_surface.sh|The route printer points back to the dedicated route surface checker."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|check_issue3_helper_surface_alignment.py|The route printer still prints the alignment helper command."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|show_issue3_saved_memory_inputs_route.sh|The route printer still exposes the saved-memory follow-up route."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer still exposes the restore follow-up route."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|issue #11 progress-tracker handoff|The route printer keeps the issue #11 handoff visible in its working rules."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|alignment_check|The route printer JSON output exposes the alignment-check command explicitly."
    "scripts/check_issue3_helper_surface_alignment.py|CRITICAL_ALIGNMENT_PATHS|The alignment checker still guards the critical helper-surface paths explicitly."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-helper-surface-alignment-route-surface")"
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

echo "Issue #3 helper-surface alignment route surface check"
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
echo "All helper-surface alignment route surfaces are present."
