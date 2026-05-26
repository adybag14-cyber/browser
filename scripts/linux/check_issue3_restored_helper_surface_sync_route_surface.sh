#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local restored-helper-surface sync route for the issue #11
Linux or WSL re-entry lane still has its required note, helper, and route
printer in place before a run trusts a restored checkout as its own helper root.
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
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|Read-first note for comparing a restored checkout helper surface against the live issue #11 helper root."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved snapshot restore note that should keep the sync-check route visible after restore."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Broader restored-checkout re-entry note that should hand runs into this narrower sync route."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 tracker note that explains why this narrower sync route matters."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the restored-helper sync route on the environment-readiness side of issue #3."
    "scripts/check_issue3_restored_helper_surface_sync.py|file|Narrower restored-helper comparison helper that reports missing or drifted issue #11 route files."
    "scripts/check_issue3_restored_checkout.py|file|Broader restored-checkout readiness helper that should stay paired with the narrower sync helper."
    "scripts/check_issue11_saved_memory_helper_contract.py|file|Issue #11 saved-memory helper contract checker that should stay in the restored-helper sync lane before broader follow-up helpers run."
    "scripts/check_issue11_reentry_inventory_consistency.py|file|Issue #11 re-entry inventory checker that should stay in the restored-helper sync lane before broader follow-up helpers run."
    "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|Fail-fast surface checker for this restored-helper sync route."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|Compact route printer for this restored-helper sync route."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that should stay visible when the next fix is a --sync-only refresh."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync_route_surface.sh|The route note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|show_issue3_restored_helper_surface_sync_route.sh|The route note keeps the compact route printer visible."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync.py|The route note keeps the narrower sync helper visible."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue11_saved_memory_helper_contract.py|The route note keeps the issue #11 saved-memory helper contract checker visible before broader follow-up helpers run."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue11_reentry_inventory_consistency.py|The route note keeps the issue #11 re-entry inventory checker visible before broader follow-up helpers run."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|restore_saved_browser_snapshot.sh|The route note keeps the helper-surface refresh path visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|check_issue3_restored_helper_surface_sync.py|The broader restored-checkout route still points runs at the narrower sync helper."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|check_issue3_restored_helper_surface_sync.py|The route printer keeps the narrower sync helper visible."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|check_issue11_saved_memory_helper_contract.py|The route printer keeps the issue #11 saved-memory helper contract checker visible."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|check_issue11_reentry_inventory_consistency.py|The route printer keeps the issue #11 re-entry inventory checker visible."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|restore_saved_browser_snapshot.sh|The route printer keeps the sync-only refresh helper visible."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|issue11_saved_memory_contract|The route printer JSON output exposes the issue #11 saved-memory contract command explicitly."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|issue11_reentry_inventory|The route printer JSON output exposes the issue #11 re-entry inventory command explicitly."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_check|The route printer JSON output exposes the sync-check command explicitly."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_refresh|The route printer JSON output exposes the sync-refresh command explicitly."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-restored-helper-surface-sync-route-surface")"
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

echo "Issue #3 restored-helper-surface sync route surface check"
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

echo "All restored-helper-surface sync route surfaces are present."
