#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_helper_surface_sync_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local helper-surface sync recovery route for issue #3
still has its required docs, helper scripts, and sync-only command snippets in
place before a run trusts the in-place refresh path.
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
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|file|Read-first note for in-place helper-surface repair on an existing restored checkout."
    "scripts/linux/check_issue3_helper_surface_sync_route_surface.sh|file|Fail-fast surface checker for the helper-surface sync recovery route."
    "scripts/linux/show_issue3_helper_surface_sync_route.sh|file|Compact route printer for the helper-surface sync recovery route."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Saved-browser restore helper that owns the --sync-only refresh path."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that should run immediately after the refresh."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper that should run after the restored-checkout check."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that should run before Linux or WSL staging is trusted."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux or WSL build-readiness route that should stay visible after helper refresh."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime re-entry route that should stay visible after helper refresh."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|restore_saved_browser_snapshot.sh --sync-only --check-only|The helper-surface sync note keeps the sync-only surface check visible."
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|restore_saved_browser_snapshot.sh --sync-only|The helper-surface sync note keeps the in-place refresh command visible."
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|show_issue3_helper_surface_sync_route.sh|The helper-surface sync note keeps the route printer visible."
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|check_issue3_restored_checkout.py|The helper-surface sync note keeps the restored-checkout readiness helper visible."
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|check_issue3_saved_memory_inputs.py|The helper-surface sync note keeps the saved-Memory preflight visible."
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|check_issue3_saved_archive_integrity.py|The helper-surface sync note keeps the saved-archive integrity preflight visible."
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|show_issue3_linux_build_readiness_route.sh|The helper-surface sync note keeps the Linux or WSL build-readiness route visible."
    "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The helper-surface sync note keeps the direct runtime re-entry route visible."
    "scripts/linux/show_issue3_helper_surface_sync_route.sh|--sync-only|The route printer keeps the in-place helper refresh command visible."
    "scripts/linux/show_issue3_helper_surface_sync_route.sh|check_issue3_restored_checkout.py|The route printer keeps the restored-checkout follow-up visible."
    "scripts/linux/show_issue3_helper_surface_sync_route.sh|check_issue3_saved_memory_inputs.py|The route printer keeps the saved-Memory preflight visible."
    "scripts/linux/show_issue3_helper_surface_sync_route.sh|check_issue3_saved_archive_integrity.py|The route printer keeps the saved-archive integrity preflight visible."
    "scripts/linux/show_issue3_helper_surface_sync_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer keeps the Linux or WSL build-readiness route visible."
    "scripts/linux/show_issue3_helper_surface_sync_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer keeps the direct runtime route visible."
    "scripts/linux/restore_saved_browser_snapshot.sh|--sync-only|The restore helper still exposes the sync-only refresh path."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-helper-surface-sync-route-surface")"
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

echo "Issue #3 helper-surface sync route surface check"
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

if [[ ${#content_rows[@]} -gt 0 ]]; then
    echo
    echo "Content expectations:"
    for row in "${content_rows[@]}"; do
        IFS="|" read -r relative_path snippet purpose exists <<<"${row}"
        status="FAIL"
        [[ "${exists}" -eq 1 ]] && status="PASS"
        echo "[${status}] ${relative_path}"
        echo "  ${purpose}"
    done
fi

if [[ "${missing_count}" -gt 0 ]]; then
    echo
    echo "Helper-surface sync route surface check failed." >&2
    echo "Suggested next step: restore the missing route note or helper scripts before trusting sync-only recovery on an existing restored checkout." >&2
    exit 1
fi

echo
echo "Helper-surface sync route surface check passed."
