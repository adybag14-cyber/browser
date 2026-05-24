#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restored_checkout_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local restored-checkout helper surface for the blocked
issue #3 Linux or WSL recovery path still has its required docs, helpers, and
route snippets in place before a run trusts a restored snapshot checkout.
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
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot note that explains how the restored checkout is produced."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that keeps restored-checkout work behind the publication and toolchain checks."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that should fail fast on missing repo surfaces or helper drift."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight that should follow the restored-checkout check."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that should run after the restored-checkout check when the route still depends on Memory bundles."
    "scripts/linux/check_issue3_restored_checkout_route_surface.sh|file|Fail-fast restored-checkout route surface checker."
    "scripts/linux/show_issue3_restored_checkout_route.sh|file|Compact restored-checkout route printer."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Companion Linux or WSL build-readiness route after the restored checkout is trusted."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Companion direct runtime route after the restored checkout and toolchain gates are green."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/linux/show_issue3_restored_checkout_route.sh|check_issue3_restored_checkout.py|The route printer still points at the restored-checkout readiness helper."
    "scripts/linux/show_issue3_restored_checkout_route.sh|check_issue3_saved_memory_inputs.py|The route printer still keeps the saved-Memory preflight visible after the restored-checkout check."
    "scripts/linux/show_issue3_restored_checkout_route.sh|check_issue3_saved_archive_integrity.py|The route printer still keeps the saved-archive integrity helper visible after the restored-checkout check."
    "scripts/linux/show_issue3_restored_checkout_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still keeps the Linux or WSL build-readiness route visible."
    "scripts/linux/show_issue3_restored_checkout_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer still keeps the direct runtime re-entry route visible."
    "scripts/linux/show_issue3_restored_checkout_route.sh|self-contained synced helper surface|The route printer still explains when the restored checkout can become its own helper root."
    "scripts/linux/show_issue3_restored_checkout_route.sh|restored_checkout_check|The route printer still exposes the restored-checkout check in JSON output."
    "scripts/linux/show_issue3_restored_checkout_route.sh|synced_restored_checkout_check|The route printer still exposes the synced restored-checkout check in JSON output."
    "scripts/linux/show_issue3_restored_checkout_route.sh|Fallback Zig archive:|The route printer still prints the surfaced fallback Zig archive before follow-up helper commands."
    "scripts/linux/show_issue3_restored_checkout_route.sh|Working rules|The route printer still prints the compact replay rules for the restored checkout."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-restored-checkout-route-surface")"
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

echo "Issue #3 restored checkout route surface check"
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
echo "All restored-checkout route surfaces are present."
