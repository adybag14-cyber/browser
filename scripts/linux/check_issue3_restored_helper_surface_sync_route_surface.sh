#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the restored-helper-surface sync route for the blocked issue #3
Linux or WSL follow-up lane still has its required docs, helpers, and command
snippets in place before a run trusts the route.
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
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|Read-first sync-route note for a stale restored checkout."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Restore-route companion note used when the restored checkout does not exist yet."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the restored helper-surface sync route visible before runtime work resumes."
    "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|Fail-fast surface checker for the restored helper-surface sync route."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|Compact route printer for the restored helper-surface sync route."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight that detects restored helper-surface drift."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper used to repair the restored checkout with --sync-helper-surface."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Restore route printer used when the restored checkout is still missing."
    "scripts/check_issue3_saved_archive_integrity.py|file|Follow-up archive-integrity check after the helper surface is synced."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Follow-up Linux or WSL build-readiness route after helper sync."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Follow-up runtime re-entry route after helper sync."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync_route_surface.sh|The sync-route note keeps the dedicated surface checker visible."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|show_issue3_restored_helper_surface_sync_route.sh|The sync-route note keeps the compact route printer visible."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_saved_memory_inputs.py|The sync-route note keeps the saved-Memory drift check visible."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|restore_saved_browser_snapshot.sh --sync-helper-surface --force|The sync-route note keeps the synced restore repair path visible."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The sync-route note points back to the restore route when no restored checkout exists."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|win32_backend.zig|The sync-route note keeps the direct runtime target visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|saved archive can lag the current branch-local helper surface|The gate note still warns about restored helper drift."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|check_issue3_saved_memory_inputs.py|The route printer still anchors drift detection on the saved-Memory preflight."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|restore_saved_browser_snapshot.sh|The route printer still prints the synced restore repair command."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer still points back to the restore route."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still prints the build-readiness follow-up."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer still prints the runtime re-entry follow-up."
    "scripts/check_issue3_saved_memory_inputs.py|helper_surface_sync|The saved-Memory preflight still exposes helper-surface sync results."
    "scripts/check_issue3_saved_memory_inputs.py|re-run the saved-browser restore with --sync-helper-surface|The saved-Memory preflight still suggests the synced restore repair path."
    "scripts/linux/restore_saved_browser_snapshot.sh|--sync-helper-surface|The restore helper still supports synced helper repair."
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

echo "Issue #3 restored helper surface sync route surface check"
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
echo "All restored helper surface sync route surfaces are present."
