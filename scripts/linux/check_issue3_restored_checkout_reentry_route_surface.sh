#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash check_issue3_restored_checkout_reentry_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local restored-checkout re-entry route for the blocked
issue #3 Linux or WSL path still has its required docs, helpers, and route
printer surface in place before a run trusts the restored checkout.
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
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Read-first restored-checkout note that should anchor the post-restore Linux or WSL route."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Restore route note that should stay paired with the restored-checkout route."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the restored-checkout route in the broader issue #3 re-entry ladder."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that proves the restored snapshot is safe to trust."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory preflight that should run after the restored-checkout readiness check."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that should run after the restored-checkout and saved-memory checks."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that materializes the reusable saved snapshot checkout."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact restore route printer that should stay visible before restored-checkout follow-up commands."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Linux build-readiness surface checker that should remain the next stop after the restored checkout is ready."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux build-readiness route printer that should stay visible after the restored checkout is ready."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Compact runtime re-entry route printer that should stay visible after the restored checkout and Linux build-readiness routes pass."
    "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh|file|Fail-fast restored-checkout re-entry surface checker."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|file|Compact restored-checkout re-entry route printer."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|scripts/check_issue3_restored_checkout.py|The restored-checkout note still names the readiness helper explicitly."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The restored-checkout note still points back to the saved-browser-snapshot route."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The restored-checkout note still points at the saved-Memory preflight."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The restored-checkout note still points at the saved-archive integrity helper."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The restored-checkout note still points at the Linux build-readiness route."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The restored-checkout note still points at the direct runtime re-entry route."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|--sync-only|The restored-checkout note still surfaces the helper-surface refresh-only route for existing restored checkouts."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|The route printer keeps the restored-checkout note in its read-first list."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer keeps the saved-browser-snapshot route visible before restored-checkout follow-up commands."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|--memory-root|The route printer still threads the explicit Memory root through the saved-browser-snapshot route and saved-memory preflight."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|--restored-checkout-root|The route printer still threads the explicit restored-checkout root through the saved-memory preflight."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|--sync-only|The route printer still surfaces the helper-surface refresh-only route for existing restored checkouts."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|SYNC_ONLY_SAVED_SNAPSHOT_ROUTE_COMMAND|The route printer still emits a dedicated helper-surface refresh-only route."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|RESTORED_CHECKOUT_CHECK_COMMAND|The route printer still emits a dedicated restored-checkout readiness command."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|PREFERRED_RESTORED_CHECKOUT_CHECK_COMMAND|The route printer still emits an explicit preferred restored-checkout check based on sync expectations."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|SAVED_MEMORY_PREFLIGHT_COMMAND|The route printer still emits a saved-Memory preflight against the restored checkout."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|SAVED_ARCHIVE_INTEGRITY_COMMAND|The route printer still emits a saved-archive integrity preflight against the restored checkout."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|LINUX_BUILD_ROUTE_COMMAND|The route printer still emits the next Linux build-readiness route."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|RUNTIME_ROUTE_COMMAND|The route printer still emits the direct runtime re-entry route."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|Helper-surface refresh-only route:|The route printer still prints a human-readable helper-surface refresh-only step."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|Restored-checkout readiness check:|The route printer still prints a human-readable restored-checkout readiness step."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|Saved-Memory preflight against the restored checkout:|The route printer still prints the saved-Memory step after the restored-checkout check."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|Saved-archive integrity preflight against the restored checkout:|The route printer still prints the saved-archive integrity step."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|Linux or WSL build-readiness route from the restored checkout:|The route printer still prints the Linux build-readiness handoff."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|Direct runtime re-entry route from the restored checkout:|The route printer still prints the direct runtime handoff."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-restored-checkout-reentry-route-surface")"
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

echo "Issue #3 restored-checkout re-entry route surface check"
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

echo "All restored-checkout re-entry surfaces are present."
