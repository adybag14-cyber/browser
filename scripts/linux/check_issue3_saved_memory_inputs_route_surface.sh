#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved-Memory-inputs route for the blocked issue #3
runtime lane still has its required docs, helpers, and command snippets in
place before a run reopens restore, build-readiness, or runtime re-entry work.
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
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Read-first saved-Memory-inputs route note for the blocked issue #3 recovery path."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Low-volume issue #11 progress-tracker handoff note for Linux or WSL re-entry work that is still blocked on environment gates."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Dedicated saved-archive integrity route note for checksum and saved-snapshot helper-surface drift follow-up."
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|file|Dedicated saved Zig archive candidate route note for picking the best branch-compatible saved toolchain before wider recovery."
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh|file|Fail-fast surface checker for the saved-Memory-inputs route."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Compact route printer for the saved-Memory-inputs preflight."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight helper that checks the repo snapshot, notes, blocker file, dependency bundles, and fallback Zig surface."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Fail-fast surface checker for the saved-archive integrity follow-up route."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Compact route printer for the saved-archive integrity follow-up."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved archive integrity helper that checks SHA-256 fingerprints plus snapshot archive surface drift."
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh|file|Fail-fast surface checker for the saved Zig archive candidate follow-up route."
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|file|Compact route printer for the saved Zig archive candidate follow-up."
    "scripts/check_issue3_saved_zig_archive_candidates.py|file|Saved Zig archive candidate helper that picks the best branch-compatible archive before broader recovery."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Follow-up route printer when the saved inputs are green but no restored checkout exists yet."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Follow-up route printer when toolchain or offline dependency staging is still the blocker."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Follow-up route printer when the narrowed runtime lane is ready to reopen."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|The saved-Memory-inputs note keeps the issue #11 handoff note visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|The saved-Memory-inputs note keeps the dedicated saved-archive integrity handoff visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|The saved-Memory-inputs note keeps the dedicated saved Zig archive candidate handoff visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|issue `#11`|The saved-Memory-inputs note keeps issue #11 visible as the scheduled-run progress target while the runtime lane is still blocked."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|check_issue3_saved_memory_inputs_route_surface.sh|The saved-Memory-inputs note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_saved_memory_inputs_route.sh|The saved-Memory-inputs note keeps the compact route printer visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .|The saved-Memory-inputs note keeps the main preflight command visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_saved_archive_integrity_route.sh|The saved-Memory-inputs note keeps the saved-archive integrity follow-up route visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_saved_zig_archive_candidates_route.sh|The saved-Memory-inputs note keeps the saved Zig archive candidates follow-up route visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|nearest ancestor|The saved-Memory-inputs note keeps the nearest-ancestor workspace-root guidance visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|falls back to sibling defaults|The saved-Memory-inputs note explains the sibling fallback after nearest-ancestor discovery."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|--skip-archive-integrity-check|The saved-Memory-inputs note keeps the quick presence-only mode visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|--restored-checkout-root ../browser-memory-snapshot|The saved-Memory-inputs note keeps the restored-checkout override visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|--repo-root ../browser-memory-snapshot|The saved-Memory-inputs note keeps the live-helper restored-checkout example visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|--helper-root .|The saved-Memory-inputs note keeps the live helper-root override visible for restored checkouts."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The saved-Memory-inputs note keeps the saved-browser-snapshot follow-up route visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The saved-Memory-inputs note keeps the Linux or WSL build-readiness follow-up route visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The saved-Memory-inputs note keeps the direct runtime follow-up route visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The saved-Memory-inputs note still names the fallback Zig bundle."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|issue `#11`|The progress-tracker handoff note still points scheduled Linux or WSL re-entry work at issue #11."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|The route printer keeps the issue #11 handoff note in the read-first surface."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|The route printer keeps the saved-archive integrity note in the read-first surface."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|The route printer keeps the saved Zig archive candidate note in the read-first surface."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|issue #11 progress-update handoff|The route printer keeps the issue #11 progress handoff visible in its working rules."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|check_issue3_saved_memory_inputs_route_surface.sh|The route printer points back to the dedicated route surface checker."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|check_issue3_saved_memory_inputs.py|The route printer still prints the saved-input preflight command."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|show_issue3_saved_archive_integrity_route.sh|The route printer still exposes the saved-archive integrity follow-up."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|show_issue3_saved_zig_archive_candidates_route.sh|The route printer still exposes the saved Zig archive candidates follow-up."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|Saved-archive integrity route:|The route printer still prints the saved-archive integrity route section."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|Saved Zig archive candidates route:|The route printer still prints the saved Zig archive candidates route section."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|live_helper_restored_checkout_preflight|The route printer JSON output still exposes the live-helper restored-checkout preflight command."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|Live-helper preflight from the restored checkout itself:|The route printer still prints the live-helper restored-checkout preflight section."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|extracted snapshot may lag behind the live helper surface|The route printer still warns about stale restored snapshots before follow-up route commands run from the restored tree."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|saved_archive_integrity_route|The route printer JSON output exposes the saved-archive integrity route explicitly."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|saved_zig_archive_candidates_route|The route printer JSON output exposes the saved Zig archive candidates route explicitly."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|--skip-archive-integrity-check|The route printer still supports the quick presence-only mode."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|--restored-checkout-root|The route printer still supports the restored-checkout override."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer still exposes the saved-browser-snapshot follow-up."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still exposes the Linux or WSL build-readiness follow-up."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer still exposes the direct runtime follow-up."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|restored_checkout_saved_input_preflight|The route printer JSON output still exposes the restored-checkout preflight command."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|progress_tracker_route_path|The route printer JSON output exposes the tracker route path explicitly."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|The saved-input preflight still checks for the saved repo snapshot."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-input preflight still checks for blocker intelligence."
    "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|The saved-input preflight still reports a clear pass surface."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-memory-inputs-route-surface")"
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

echo "Issue #3 saved Memory inputs route surface check"
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

echo "All saved-Memory-input route surfaces are present."
