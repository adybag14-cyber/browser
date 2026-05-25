#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_helper_surface_parity_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the issue #3 helper-surface parity route still has its required
branch-local helper scripts in place before a run trusts restore, sync-only, or
restored-checkout follow-up commands.
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
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot restore route note that should stay adjacent to this parity step."
    "scripts/check_issue3_helper_surface_parity.py|file|Helper-surface parity checker that compares the restore-script and Python manifests."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-memory preflight helper whose helper-surface tuple must stay aligned."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout helper whose helper-surface tuple must stay aligned."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that owns the synced helper-surface copy path."
    "scripts/linux/check_issue3_helper_surface_parity_route_surface.sh|file|Fail-fast route surface checker for the parity step."
    "scripts/linux/show_issue3_helper_surface_parity_route.sh|file|Compact route printer for the parity step."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/check_issue3_helper_surface_parity.py|scripts/linux/restore_saved_browser_snapshot.sh|The parity helper still compares the restore helper manifest."
    "scripts/check_issue3_helper_surface_parity.py|scripts/check_issue3_saved_memory_inputs.py|The parity helper still compares the saved-memory helper manifest."
    "scripts/check_issue3_helper_surface_parity.py|scripts/check_issue3_restored_checkout.py|The parity helper still compares the restored-checkout helper manifest."
    "scripts/linux/show_issue3_helper_surface_parity_route.sh|check_issue3_helper_surface_parity_route_surface.sh|The route printer still points back to this fail-fast surface check."
    "scripts/linux/show_issue3_helper_surface_parity_route.sh|check_issue3_helper_surface_parity.py|The route printer still exposes the parity helper command."
    "scripts/linux/show_issue3_helper_surface_parity_route.sh|restore_saved_browser_snapshot.sh|The route printer still keeps the restore helper visible as the next step after parity."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-helper-surface-parity-route-surface")"
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

echo "Issue #3 helper-surface parity route surface check"
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
echo "Content expectations:"
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
echo "All helper-surface parity route surfaces are present."
