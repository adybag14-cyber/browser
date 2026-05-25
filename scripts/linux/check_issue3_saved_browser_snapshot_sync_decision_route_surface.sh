#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the saved-browser-snapshot sync-decision route keeps its note,
helper, companion restore surface, and follow-up commands visible before issue
#11 Linux or WSL re-entry work chooses a restore mode.
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

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

declare -a REFERENCE_PATHS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|file|Read-first note for choosing plain restore, sync-helper-surface, sync-only, or reuse-existing-checkout."
    "scripts/check_issue3_saved_browser_snapshot_sync_decision.py|file|Helper that compares the live helper surface against the saved snapshot archive and current restore destination."
    "scripts/linux/check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh|file|Fail-fast surface checker for the saved-browser-snapshot sync-decision route."
    "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh|file|Compact route printer for the saved-browser-snapshot sync-decision path."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that executes the restore mode chosen by the sync-decision helper."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout follow-up helper used after a decision-driven restore."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Broader saved-browser-snapshot restore route note that the sync-decision route feeds into."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 progress-route note that keeps the Linux or WSL re-entry tracker visible."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|scripts/check_issue3_saved_browser_snapshot_sync_decision.py|The route note keeps the sync-decision helper visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|plain-restore|The route note still lists the plain-restore recommendation."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|sync-helper-surface|The route note still lists the synced restore recommendation."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|sync-only|The route note still lists the in-place helper refresh recommendation."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|reuse-existing-checkout|The route note still lists the direct reuse recommendation."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|restore_saved_browser_snapshot.sh --sync-helper-surface|The route note keeps the synced restore command visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|restore_saved_browser_snapshot.sh --sync-only|The route note keeps the sync-only refresh command visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md|check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot|The route note keeps the restored-checkout follow-up visible."
    "scripts/check_issue3_saved_browser_snapshot_sync_decision.py|RESTORE_HELPER_PATH = \"scripts/linux/restore_saved_browser_snapshot.sh\"|The helper still points at the saved-browser-snapshot restore helper."
    "scripts/check_issue3_saved_browser_snapshot_sync_decision.py|\"sync-helper-surface\"|The helper still emits the synced restore recommendation."
    "scripts/check_issue3_saved_browser_snapshot_sync_decision.py|\"sync-only\"|The helper still emits the in-place refresh recommendation."
    "scripts/check_issue3_saved_browser_snapshot_sync_decision.py|\"reuse-existing-checkout\"|The helper still emits the direct reuse recommendation."
    "scripts/check_issue3_saved_browser_snapshot_sync_decision.py|\"plain-restore\"|The helper still emits the plain restore recommendation."
    "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh|check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh|The route printer points back to the dedicated route surface checker."
    "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh|check_issue3_saved_browser_snapshot_sync_decision.py|The route printer exposes the sync-decision helper command."
    "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh|restore_saved_browser_snapshot.sh --sync-helper-surface|The route printer keeps the synced restore command visible."
    "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh|restore_saved_browser_snapshot.sh --sync-only|The route printer keeps the sync-only refresh command visible."
    "scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh|check_issue3_restored_checkout.py|The route printer keeps the restored-checkout follow-up visible."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-browser-snapshot-sync-decision-route-surface")"
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

echo "Issue #3 saved browser snapshot sync-decision route surface check"
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
echo "All saved-browser-snapshot sync-decision route surfaces are present."
