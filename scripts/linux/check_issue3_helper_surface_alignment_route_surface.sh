#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_helper_surface_alignment_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the issue #3 helper-surface alignment route still has its required
docs, helpers, and command snippets in place before a run trusts the saved
browser snapshot sync path.
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
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|file|Read-first note for the helper-surface alignment route."
    "scripts/check_issue3_helper_surface_alignment.py|file|Alignment helper that compares restore, saved-memory, and restored-checkout inventories."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|file|Route printer that keeps the alignment and synced-restore commands on one compact surface."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Restore note that the alignment route should send operators back through."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Runtime gate note that should remain the next step after helper-surface alignment is green."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that should follow the alignment route."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|scripts/check_issue3_helper_surface_alignment.py|The route note explicitly names the alignment helper."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|scripts/linux/show_issue3_helper_surface_alignment_route.sh|The route note points back to the compact route printer."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|scripts/linux/show_issue3_saved_browser_snapshot_route.sh|The route note keeps the saved-browser-snapshot route visible."
    "docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md|scripts/check_issue3_restored_checkout.py|The route note keeps the restored-checkout readiness helper visible."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|scripts/check_issue3_helper_surface_alignment.py|The route printer keeps the alignment helper command visible."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|scripts/linux/show_issue3_saved_browser_snapshot_route.sh|The route printer keeps the saved-browser-snapshot route visible."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|scripts/check_issue3_restored_checkout.py|The route printer keeps the restored-checkout readiness helper visible."
    "scripts/linux/show_issue3_helper_surface_alignment_route.sh|--sync-helper-surface|The route printer keeps the synced restore path visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The runtime gate note still sends reruns through the saved-browser-snapshot route."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-helper-surface-alignment-route-surface")"
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

echo "Issue #3 helper-surface alignment route surface check"
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
echo "All helper-surface alignment route surfaces are present."
