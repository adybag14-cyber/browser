#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue11_saved_snapshot_reentry_chain_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the compact issue #11 saved-snapshot re-entry chain still has the
docs, helpers, and command snippets needed to move from snapshot restore to the
restored-checkout checkpoint and then into Linux build readiness.
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
    "docs/ISSUE11_SAVED_SNAPSHOT_REENTRY_CHAIN.md|file|Compact issue #11 note for the saved snapshot re-entry chain."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot route note that starts the chain."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Restored-checkout route note that must stay in the middle of the chain."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Saved-Memory route note that follows the restored-checkout checkpoint."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness route note that follows the restored-checkout checkpoint."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Runtime gate note that receives the handoff after Linux build readiness."
    "scripts/linux/check_issue11_saved_snapshot_reentry_chain_surface.sh|file|Fail-fast checker for the compact issue #11 chain."
    "scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|file|Compact issue #11 chain printer."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot route printer."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Saved snapshot restore helper."
    "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh|file|Restored-checkout route surface checker."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|file|Restored-checkout route printer."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Saved-Memory route printer."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory raw preflight helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE11_SAVED_SNAPSHOT_REENTRY_CHAIN.md|docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|The issue #11 note keeps the restored-checkout route note in the compact chain."
    "docs/ISSUE11_SAVED_SNAPSHOT_REENTRY_CHAIN.md|scripts/check_issue3_restored_checkout.py|The issue #11 note keeps the restored-checkout helper visible before wider follow-up steps."
    "docs/ISSUE11_SAVED_SNAPSHOT_REENTRY_CHAIN.md|scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|The issue #11 note points at the compact chain printer."
    "scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|The compact chain printer keeps the restored-checkout route note in its read-first list."
    "scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|show_issue3_restored_checkout_reentry_route.sh|The compact chain printer keeps the restored-checkout route printer visible."
    "scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|scripts/check_issue3_restored_checkout.py|The compact chain printer keeps the restored-checkout helper visible."
    "scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|show_issue3_saved_browser_snapshot_route.sh|The compact chain printer keeps the saved-browser-snapshot route visible."
    "scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|show_issue3_saved_memory_inputs_route.sh|The compact chain printer keeps the saved-Memory route visible after the restored-checkout checkpoint."
    "scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|show_issue3_linux_build_readiness_route.sh|The compact chain printer keeps the Linux build-readiness route visible after the restored-checkout checkpoint."
    "scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh|show_google_issue3_enter_submit_runtime_revalidation.ps1|The compact chain printer keeps the final Windows runtime handoff visible."
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
    printf '  "profile": %s,\n' "$(json_escape "issue11-saved-snapshot-reentry-chain-surface")"
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

echo "Issue #11 saved-snapshot re-entry chain surface check"
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
    echo "  snippet: ${snippet}"
    echo "  ${purpose}"
done

if [[ "${missing_count}" -gt 0 ]]; then
    echo
    echo "Surface check failed with ${missing_count} missing items." >&2
    exit 1
fi

echo
echo "Issue #11 saved-snapshot re-entry chain surface check passed."
