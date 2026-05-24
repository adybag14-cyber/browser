#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_synced_restored_checkout_refresh_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local synced restored-checkout refresh route for the
blocked issue #3 Linux or WSL path still has its required docs, helpers, and
route-printer surface in place before a run trusts --sync-only refresh work.
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
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|file|Read-first note for refreshing an existing restored checkout helper surface in place."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved snapshot restore note that should remain the fallback when the restored checkout is missing."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Restored-checkout re-entry note that should remain the next step after helper refresh."
    "scripts/linux/check_issue3_synced_restored_checkout_refresh_route_surface.sh|file|Fail-fast surface checker for the synced restored-checkout refresh route."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|file|Compact route printer for the synced restored-checkout refresh route."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that owns the --sync-only refresh path."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that should prove the refreshed helper surface is complete."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper that should run after the refreshed restored-checkout check."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that should run after the saved-Memory preflight."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|file|Compact re-entry route that should stay visible after the synced refresh."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux build-readiness route that should stay visible after the synced refresh."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Compact runtime re-entry route that should stay visible after the synced refresh."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|scripts/linux/check_issue3_synced_restored_checkout_refresh_route_surface.sh|The synced-refresh note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|show_issue3_synced_restored_checkout_refresh_route.sh|The synced-refresh note keeps the compact route printer visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|restore_saved_browser_snapshot.sh --sync-only --check-only|The synced-refresh note keeps the dry-run helper refresh command visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|restore_saved_browser_snapshot.sh --sync-only|The synced-refresh note keeps the real helper refresh command visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface|The synced-refresh note keeps the post-refresh restored-checkout check visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot|The synced-refresh note keeps the saved-Memory preflight visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot|The synced-refresh note keeps the saved-archive integrity check visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|show_issue3_restored_checkout_reentry_route.sh --repo-root ../browser-memory-snapshot|The synced-refresh note keeps the restored-checkout re-entry route visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot|The synced-refresh note keeps the Linux build-readiness route visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot|The synced-refresh note keeps the direct runtime route visible."
    "docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md|If ../browser-memory-snapshot is missing, do not use this route first.|The synced-refresh note still explains when runs must fall back to the saved snapshot restore route."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|check_issue3_synced_restored_checkout_refresh_route_surface.sh|The route printer points back to the dedicated synced-refresh surface checker."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|restore_saved_browser_snapshot.sh|The route printer still prints the exact helper-refresh invocation."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|--sync-only --check-only|The route printer still prints the dry-run helper refresh command."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|--sync-only|The route printer still prints the real helper refresh command."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|check_issue3_restored_checkout.py|The route printer still prints the post-refresh restored-checkout helper."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|check_issue3_saved_memory_inputs.py|The route printer still prints the saved-Memory preflight."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|check_issue3_saved_archive_integrity.py|The route printer still prints the saved-archive integrity preflight."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|show_issue3_restored_checkout_reentry_route.sh|The route printer still keeps the restored-checkout re-entry route visible."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still keeps the Linux build-readiness route visible."
    "scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer still keeps the direct runtime route visible."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-synced-restored-checkout-refresh-route-surface")"
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

echo "Issue #3 synced restored-checkout refresh route surface check"
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

echo "All synced restored-checkout refresh route surfaces are present."
