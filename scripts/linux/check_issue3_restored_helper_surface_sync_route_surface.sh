#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash check_issue3_restored_helper_surface_sync_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local helper-surface sync route for the blocked
issue #3 restored-checkout path still has its required docs, helpers, and
route printer surface in place before a run refreshes a restored checkout in
place with `--sync-only`.
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
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|Read-first helper-surface sync note for the restored-checkout recovery path."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Companion restored-checkout route note that the sync route should hand back into."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved snapshot restore note that should stay paired with the sync-only helper refresh path."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the helper-sync route in the broader issue #3 ladder."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that already owns the --sync-only behavior."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that should prove the refreshed helper surface is trustworthy."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-memory preflight that should run after the refreshed restored checkout passes."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that should stay visible after the helper refresh."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route that should remain the next hop after a successful helper refresh."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime re-entry route that should remain the final narrowed handoff."
    "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|Fail-fast helper-surface sync route surface checker."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|Compact helper-surface sync route printer."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|restore_saved_browser_snapshot.sh|The sync route note still points at the restore helper."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|--sync-only|The sync route note still centers the in-place helper refresh."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|scripts/check_issue3_restored_checkout.py|The sync route note still requires the restored-checkout helper after refresh."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The sync route note still points at the saved-memory preflight."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The sync route note still points at the saved-archive integrity helper."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The sync route note still points at Linux build readiness."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The sync route note still points at the narrowed runtime handoff."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|The route printer keeps the helper-surface sync note in its read-first list."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|--sync-only|The route printer still emits the sync-only helper refresh command."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|--sync-helper-surface|The route printer still emits the full synced restore fallback."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|STALE_SURFACE_DIAGNOSIS_COMMAND|The route printer still emits a dedicated stale-surface diagnosis step."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|SYNC_ONLY_ROUTE_COMMAND|The route printer still builds an explicit sync-only command."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|FULL_SYNC_RESTORE_CHECK_COMMAND|The route printer still emits a full synced restore fallback check."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|FULL_SYNC_RESTORE_COMMAND|The route printer still emits a full synced restore fallback command."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|RESTORED_CHECK_COMMAND|The route printer still emits the restored-checkout verification step."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|SAVED_MEMORY_PREFLIGHT_COMMAND|The route printer still emits the saved-memory preflight step."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|SAVED_ARCHIVE_INTEGRITY_COMMAND|The route printer still emits the saved-archive integrity step."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|LINUX_BUILD_ROUTE_COMMAND|The route printer still emits the Linux build-readiness handoff."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|RUNTIME_ROUTE_COMMAND|The route printer still emits the direct runtime handoff."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|Snapshot archive:|The route printer still prints the snapshot archive path."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|Current stale-surface diagnosis:|The route printer still prints a human-readable stale-surface diagnosis step."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|Sync-only helper-surface refresh:|The route printer still prints a human-readable sync-only step."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|Full synced restore fallback:|The route printer still prints a human-readable full fallback step."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|Restored-checkout verification after refresh:|The route printer still prints a human-readable restored-checkout verification step."
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

echo "Issue #3 restored helper-surface sync route surface check"
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

echo "All restored helper-surface sync route surfaces are present."
