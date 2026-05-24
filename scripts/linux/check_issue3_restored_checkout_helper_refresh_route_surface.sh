#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restored_checkout_helper_refresh_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local helper-refresh route for an already-restored issue
#3 checkout still has its required docs, helpers, and route printer in place
before a run trusts the in-place sync-only refresh path.
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
    "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|file|Read-first helper-refresh note for the stale helper-surface case."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Restore route note that explains the broader saved-snapshot extraction path."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Restored-checkout re-entry note that should stay visible after a helper refresh."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the refresh path subordinate to the real runtime gates."
    "scripts/linux/check_issue3_restored_checkout_helper_refresh_route_surface.sh|file|Fail-fast surface checker for the helper-refresh route."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|file|Compact route printer for the in-place helper refresh path."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that already supports --sync-only for the existing restored checkout."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that should run immediately after refresh."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight that should run from the refreshed restored checkout."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that should run after the saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route that should remain the next stop after refresh."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime route that should remain the narrow follow-up after refresh."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|--sync-only --check-only|The helper-refresh note keeps the sync-only dry-run visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|restore_saved_browser_snapshot.sh --sync-only|The helper-refresh note keeps the sync-only refresh command visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|check_issue3_restored_checkout.py|The helper-refresh note keeps the restored-checkout readiness helper visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|check_issue3_saved_memory_inputs.py|The helper-refresh note keeps the saved-Memory preflight visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|check_issue3_saved_archive_integrity.py|The helper-refresh note keeps the saved-archive integrity helper visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The helper-refresh note keeps the Linux build-readiness route visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The helper-refresh note keeps the direct runtime route visible."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md|The route printer keeps the helper-refresh note in its read-first list."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|--sync-only|The route printer centers the sync-only refresh path."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|REFRESH_CHECK_COMMAND|The route printer still emits a dedicated sync-only dry-run."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|REFRESH_COMMAND|The route printer still emits a dedicated sync-only refresh command."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|RESTORED_CHECKOUT_CHECK_COMMAND|The route printer still emits the restored-checkout readiness helper."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|SAVED_MEMORY_PREFLIGHT_COMMAND|The route printer still emits the saved-Memory preflight."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|SAVED_ARCHIVE_INTEGRITY_COMMAND|The route printer still emits the saved-archive integrity helper."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|LINUX_BUILD_ROUTE_COMMAND|The route printer still emits the Linux build-readiness route."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|RUNTIME_ROUTE_COMMAND|The route printer still emits the direct runtime route."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|Helper-refresh dry run:|The route printer still prints a human-readable sync-only dry-run step."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|Helper-refresh command:|The route printer still prints a human-readable sync-only refresh step."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|Restored-checkout readiness check:|The route printer still prints a human-readable restored-checkout follow-up."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|Saved-Memory preflight against the refreshed restored checkout:|The route printer still prints the saved-Memory follow-up."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|Saved-archive integrity preflight against the refreshed restored checkout:|The route printer still prints the saved-archive integrity follow-up."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|Linux or WSL build-readiness route from the refreshed restored checkout:|The route printer still prints the Linux build-readiness handoff."
    "scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh|Direct runtime re-entry route from the refreshed restored checkout:|The route printer still prints the direct runtime handoff."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-restored-checkout-helper-refresh-route-surface")"
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

echo "Issue #3 restored-checkout helper-refresh route surface check"
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

echo "All restored-checkout helper-refresh surfaces are present."
