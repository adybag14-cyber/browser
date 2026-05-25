#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue11_runtime_reentry_tracker_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the issue #11 Linux runtime re-entry tracker route still has its
required docs, helper scripts, and command snippets in place.
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
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|file|Read-first note for the issue #11 Linux or WSL environment re-entry lane."
    "scripts/linux/check_issue11_runtime_reentry_tracker_route_surface.sh|file|Fail-fast surface checker for the issue #11 route itself."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|file|Compact route printer for the issue #11 Linux or WSL re-entry lane."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that the issue #11 route must hand back to once the environment stops being the blocker."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved browser snapshot restore route used when no reusable checkout exists yet."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|file|Restored-checkout route used immediately after snapshot restore."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Saved-Memory route used before raw preflights are trusted."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Saved-archive integrity route used before deeper staging."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig recovery route used when only fallback Zig is visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux or WSL build-readiness route used after the narrower environment questions are settled."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|check_issue11_runtime_reentry_tracker_route_surface.sh|The issue #11 note keeps the dedicated surface checker visible."
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|show_issue11_runtime_reentry_tracker_route.sh|The issue #11 note keeps the compact route printer visible."
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The issue #11 note keeps the saved-browser-snapshot route visible."
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|show_issue3_restored_checkout_reentry_route.sh|The issue #11 note keeps the restored-checkout route visible."
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|show_issue3_saved_memory_inputs_route.sh|The issue #11 note keeps the saved-Memory route visible."
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|show_issue3_saved_archive_integrity_route.sh|The issue #11 note keeps the saved-archive route visible."
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The issue #11 note keeps the Zig recovery route visible."
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The issue #11 note keeps the Linux build-readiness route visible."
    "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md|docs/ISSUE3_RUNTIME_REENTRY_GATES.md|The issue #11 note keeps the final runtime handoff note visible."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|check_issue11_runtime_reentry_tracker_route_surface.sh|The route printer points back to the dedicated issue #11 surface checker."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer keeps the saved-browser-snapshot route visible."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|show_issue3_restored_checkout_reentry_route.sh|The route printer keeps the restored-checkout route visible."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|show_issue3_saved_memory_inputs_route.sh|The route printer keeps the saved-Memory route visible."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|show_issue3_saved_archive_integrity_route.sh|The route printer keeps the saved-archive route visible."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The route printer keeps the Zig recovery route visible."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer keeps the Linux build-readiness route visible."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|docs/ISSUE3_RUNTIME_REENTRY_GATES.md|The route printer keeps the runtime gate handoff visible."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|saved_browser_snapshot_route_synced|The route printer exposes the synced snapshot route in JSON output."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|fallback_zig_archive|The route printer exposes the fallback Zig location in JSON output."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|Restored-checkout route:|The route printer still prints the restored-checkout step."
    "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh|Saved archive integrity route:|The route printer still prints the archive-integrity step."
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
    printf '  "profile": %s,\n' "$(json_escape "issue11-runtime-reentry-tracker-route-surface")"
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

echo "Issue #11 runtime re-entry tracker surface check"
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
echo "All issue #11 runtime re-entry route surfaces are present."
