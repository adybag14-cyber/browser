#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved-browser-snapshot restore route for the
blocked issue #3 runtime lane still has its required docs, helpers, and command
snippets in place before a run reopens restore, build-readiness, or runtime
re-entry work.
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
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Read-first saved-browser-snapshot restore note for the blocked issue #3 runtime lane."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Companion Linux or WSL build-readiness note that should follow the restore route."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the saved-checkout route visible before reopening focused runtime work."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Fail-fast surface checker for the saved-browser-snapshot restore route."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Saved browser snapshot restore helper that should keep the check-only and extraction commands on one branch-local surface."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact route printer for the saved-browser-snapshot restore path."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight that checks the repo snapshot, notes, blocker file, and dependency bundles before route replay."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Companion route printer for the Linux or WSL build-readiness path after the restore step."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Companion route printer for reopening the narrowed Page.zig plus win32_backend.zig runtime lane after restore."
    "build.zig.zon|file|Manifest surface that should exist in the restored checkout before deeper validation starts."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|The saved-browser-snapshot note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|The saved-browser-snapshot note prints the dedicated route surface-check command."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|The saved-browser-snapshot note keeps the restore helper surface check visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The saved-browser-snapshot note keeps the compact route printer visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The saved-browser-snapshot note keeps the saved-Memory input preflight visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The saved-browser-snapshot note keeps the Linux or WSL build-readiness route visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The saved-browser-snapshot note keeps the direct runtime re-entry route visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--helper-root /path/to/live/browser|The saved-browser-snapshot note keeps the live helper-root override visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--sync-helper-surface|The saved-browser-snapshot note keeps the helper-surface sync mode visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Recommended Self-Contained Restore|The saved-browser-snapshot note keeps the synced restore route visible as its own section."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|the saved archive can lag the current|The saved-browser-snapshot note explains why the synced restore route is often the safer follow-up."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Do not switch into the restored checkout|The saved-browser-snapshot note warns that the restored snapshot may not carry the newest route scripts unless helper sync is enabled."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The gate note keeps the saved-browser-snapshot route in the read-first companion set."
    "scripts/linux/restore_saved_browser_snapshot.sh|--check-only|The restore helper still supports surface-only validation without extraction."
    "scripts/linux/restore_saved_browser_snapshot.sh|--helper-root|The restore helper still supports a live helper-root override for newer route scripts."
    "scripts/linux/restore_saved_browser_snapshot.sh|--fallback-zig-archive|The restore helper still supports an explicit fallback Zig archive override for follow-up helpers."
    "scripts/linux/restore_saved_browser_snapshot.sh|--sync-helper-surface|The restore helper still supports copying the current helper surface into the restored checkout."
    "scripts/linux/restore_saved_browser_snapshot.sh|Follow-up helper root:|The restore helper still prints the follow-up helper root it will use after restore."
    "scripts/linux/restore_saved_browser_snapshot.sh|Fallback Zig archive:|The restore helper still prints the surfaced fallback Zig archive path or absence."
    "scripts/linux/restore_saved_browser_snapshot.sh|Helper surface sync:|The restore helper still prints whether helper-surface sync is enabled."
    "scripts/linux/restore_saved_browser_snapshot.sh|Suggested follow-up checks:|The restore helper still prints its next-step checks."
    "scripts/linux/restore_saved_browser_snapshot.sh|show_issue3_linux_build_readiness_route.sh|The restore helper still anchors the Linux build-readiness follow-up to the chosen helper root."
    "scripts/linux/restore_saved_browser_snapshot.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The restore helper still anchors the runtime follow-up to the chosen helper root."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_saved_browser_snapshot_route_surface.sh|The route printer points back to the dedicated route surface checker."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|restore_saved_browser_snapshot.sh|The route printer still prints the exact restore helper invocation."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--helper-root|The route printer still supports a live helper-root override."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--sync-helper-surface|The route printer still supports helper-surface sync mode."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|follow_up_helper_root|The route printer still exposes the follow-up helper root in JSON output for downstream tooling."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Sync helper surface:|The route printer still prints whether helper-surface sync is enabled."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Recommended synced restore when the archive helper surface is stale:|The route printer keeps the safer synced restore path visible when the archive lags live helpers."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced saved-Memory preflight:|The route printer keeps the synced saved-Memory preflight visible for self-contained restores."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced Linux or WSL build-readiness route:|The route printer keeps the synced Linux follow-up route visible for self-contained restores."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced direct runtime re-entry route:|The route printer keeps the synced runtime follow-up route visible for self-contained restores."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-Memory preflight against the restored checkout:|The route printer still prints the saved-Memory preflight step."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still prints the Linux or WSL build-readiness follow-up."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer still prints the direct runtime follow-up."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|fallback-zig-archive|The route printer still supports an explicit fallback Zig archive override."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|current issue #3 helper docs and scripts|The route printer still explains what helper-surface sync changes."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|The saved-Memory input preflight still checks for the saved repo snapshot."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-Memory input preflight still checks for blocker intelligence."
    "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|The saved-Memory input preflight still reports a clear pass surface."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-browser-snapshot-route-surface")"
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

echo "Issue #3 saved browser snapshot route surface check"
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
echo "All saved-browser-snapshot route surfaces are present."
