#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local restored-checkout re-entry route for the blocked
issue #3 Linux or WSL path still has its note, helper, and follow-up surfaces
in place before a run trusts a restored checkout.
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
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Read-first restored-checkout re-entry note for the blocked issue #3 Linux or WSL lane."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot note that should stay visible before the restored-checkout checkpoint runs."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the restored-checkout checkpoint visible before direct runtime replay widens."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Saved-archive note that should stay visible after the restored-checkout checkpoint passes."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness note that should follow the restored-checkout checkpoint."
    "scripts/check_issue3_restored_checkout.py|file|Python helper that verifies restored-checkout shape and optional synced-helper drift."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight that should follow the restored-checkout checkpoint."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that should follow the restored-checkout checkpoint when exact bundle provenance still matters."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that should remain the source of the restored checkout before this checkpoint runs."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot route printer that should stay reachable before this checkpoint runs."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux or WSL build-readiness route printer that should stay reachable after this checkpoint passes."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime route printer that should stay reachable after this checkpoint passes."
    "build.zig.zon|file|Manifest surface that should exist in a healthy restored checkout before deeper validation starts."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|scripts/check_issue3_restored_checkout.py|The route note keeps the restored-checkout readiness helper visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The route note keeps the saved-browser-snapshot route visible before the restored-checkout checkpoint."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|restore_saved_browser_snapshot.sh|The route note keeps the restore helper visible before the restored-checkout checkpoint."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The route note keeps the Linux or WSL build-readiness route visible after the restored-checkout checkpoint."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The route note keeps the direct runtime route visible after the restored-checkout checkpoint."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|python ./scripts/check_issue3_restored_checkout.py|The route note keeps the restored-checkout check command visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|--helper-root .|The route note keeps the synced helper-root comparison visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|--expect-helper-surface|The route note keeps the synced helper-surface requirement visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|saved-memory preflight|The route note keeps the saved-memory follow-up visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|saved-archive integrity helper|The route note keeps the saved-archive integrity follow-up visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|The route note keeps the direct runtime follow-up command visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_restored_checkout.py|The saved-browser-snapshot note keeps the restored-checkout helper visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Run the restored-checkout readiness check first|The saved-browser-snapshot note still enforces the restored-checkout checkpoint before archive-focused preflights."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|The gate note keeps the restored-checkout route note visible before runtime re-entry."
    "scripts/check_issue3_restored_checkout.py|--expect-helper-surface|The helper still supports explicit synced-helper validation."
    "scripts/check_issue3_restored_checkout.py|matches_helper_root|The helper still reports helper-root drift state."
    "scripts/check_issue3_restored_checkout.py|Suggested next step: rerun restore_saved_browser_snapshot.sh with --sync-helper-surface|The helper still reports synced-restore recovery guidance."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Restored-checkout readiness check:|The saved-browser-snapshot route printer still prints the restored-checkout checkpoint."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced restored-checkout readiness check:|The saved-browser-snapshot route printer still prints the synced restored-checkout checkpoint."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|follow_up_helper_root|The saved-browser-snapshot route printer still exposes the follow-up helper root for downstream tooling."
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

echo "Issue #3 restored checkout re-entry route surface check"
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
echo "All restored checkout re-entry route surfaces are present."
