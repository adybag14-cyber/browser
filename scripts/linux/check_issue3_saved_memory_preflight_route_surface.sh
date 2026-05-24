#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_memory_preflight_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved-Memory-first recovery route for the blocked
issue #3 runtime lane still has its required helper files and route surfaces in
place before a run tries to restore the snapshot or widen back out to Linux and
runtime re-entry.
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

REPO_ROOT="$(cd "${REPO_ROOT}")" && pwd)

declare -a REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that decides whether a run should stay on helper recovery work instead of reopening the blocked runtime patch."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot route note that keeps the restore and first follow-up checks on one helper surface."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Saved-archive integrity route note that keeps checksum verification on a compact helper surface."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory input preflight that checks the repo snapshot, blocker intelligence, dependency bundles, and fallback Zig surface."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that proves the saved repo snapshot and dependency bundles still match their expected exact artifacts."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that fails fast on missing build.zig.zon or helper drift."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that can materialize the saved repo snapshot into a reusable checkout."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact saved-browser-snapshot route printer used before Linux or runtime route widening."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux build-readiness route printer used after the saved-Memory checks pass."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Compact direct runtime re-entry route printer used after the Linux build-readiness route turns green."
    "scripts/linux/check_issue3_saved_memory_preflight_route_surface.sh|file|Fail-fast surface checker for the saved-Memory-first helper chain."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|file|Compact saved-Memory-first route printer that keeps restore, preflight, and re-entry commands on one surface."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|check_issue3_saved_memory_preflight_route_surface.sh|The route printer points back to its fail-fast surface checker."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer keeps the saved-browser-snapshot route visible before deeper helper stages."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|restore_saved_browser_snapshot.sh|The route printer keeps the raw restore helper visible when the run wants an immediate checkout restore."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|check_issue3_restored_checkout.py|The route printer keeps the restored-checkout readiness check ahead of the archive-focused preflights."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|check_issue3_saved_memory_inputs.py|The route printer keeps the saved-Memory input preflight visible."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|check_issue3_saved_archive_integrity.py|The route printer keeps the saved-archive integrity check visible."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer widens from saved-Memory checks into the Linux build-readiness route."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer widens from Linux build readiness into the direct runtime re-entry route."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|Saved-Memory input preflight:|The route printer still prints a dedicated saved-Memory preflight step."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|Saved-archive integrity check:|The route printer still prints a dedicated saved-archive integrity step."
    "scripts/linux/show_issue3_saved_memory_preflight_route.sh|Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz fallback bundle as a surfaced input only|The route printer keeps the fallback Zig warning explicit."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-Memory input preflight still checks blocker intelligence."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/session_entry_register.yaml|The saved-Memory input preflight still checks the session register as an optional Memory input."
    "scripts/check_issue3_saved_archive_integrity.py|Saved archive integrity check passed.|The saved-archive integrity helper still reports a clear pass surface."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-memory-preflight-route-surface")"
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

echo "Issue #3 saved-Memory preflight route surface check"
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
echo "All saved-Memory preflight route surfaces are present."
