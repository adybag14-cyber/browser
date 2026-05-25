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
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md|file|Archive-surface note that explains when the saved snapshot already carries the current helper surface and when sync-helper-surface is safer."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Restored-checkout companion note that should stay visible once the snapshot restore succeeds and the next question is whether the restored checkout is safe to trust."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Archive-integrity companion note that should remain visible before the restored checkout trusts saved repo and dependency bundles."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Companion Linux or WSL build-readiness note that should follow the restore route."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the saved-checkout route visible before reopening focused runtime work."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Fail-fast surface checker for the saved-browser-snapshot restore route."
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py|file|Archive-surface helper that should answer whether the saved snapshot already carries the current helper surface before restore mode is chosen."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Saved browser snapshot restore helper that should keep the check-only and extraction commands on one branch-local surface."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact route printer for the saved-browser-snapshot restore path."
    "scripts/check_issue3_restored_checkout.py|file|Restored-checkout readiness helper that should fail fast on missing repo surfaces or helper drift after extraction."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight that checks the repo snapshot, notes, blocker file, and dependency bundles before route replay."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper that should fail fast on checksum drift before Linux or WSL follow-up work."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Fail-fast surface checker for the saved-archive integrity route used right after the saved-Memory preflight."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Companion route printer for the saved-archive integrity follow-up after restore."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Companion route printer for the Linux or WSL build-readiness path after the restore step."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Companion route printer for reopening the narrowed Page.zig plus win32_backend.zig runtime lane after restore."
    "build.zig.zon|file|Manifest surface that should exist in the restored checkout before deeper validation starts."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|The saved-browser-snapshot note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_browser_snapshot_archive_surface.py|The saved-browser-snapshot note keeps the archive-surface helper visible before restore mode is chosen."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py|The saved-browser-snapshot note prints the archive-surface helper command."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only|The saved-browser-snapshot note keeps the restore helper surface check visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The saved-browser-snapshot note keeps the compact route printer visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_restored_checkout.py|The saved-browser-snapshot note keeps the restored-checkout readiness helper visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The saved-browser-snapshot note keeps the saved-Memory input preflight visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The saved-browser-snapshot note keeps the saved-archive integrity helper visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|check_issue3_saved_browser_snapshot_archive_surface.py reports|The saved-browser-snapshot note explains that the archive-surface helper can force the synced restore path."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Do not switch into the restored checkout|The saved-browser-snapshot note warns that the restored snapshot may not carry the newest route scripts unless helper sync is enabled."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md|scripts/check_issue3_saved_browser_snapshot_archive_surface.py|The archive-surface note keeps its companion helper visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md|Prefer `--sync-helper-surface` when one or more helper paths are missing|The archive-surface note still explains the preferred stale-archive fallback."
    "scripts/linux/restore_saved_browser_snapshot.sh|--sync-helper-surface|The restore helper still supports copying the current helper surface into the restored checkout."
    "scripts/linux/restore_saved_browser_snapshot.sh|check_issue3_restored_checkout.py|The restore helper still prints the restored-checkout readiness follow-up command."
    "scripts/linux/restore_saved_browser_snapshot.sh|check_issue3_saved_archive_integrity.py|The restore helper still prints the saved-archive integrity follow-up command."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_saved_browser_snapshot_route_surface.sh|The route printer points back to the dedicated route surface checker."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_saved_browser_snapshot_archive_surface.py|The route printer exposes the archive-surface helper before restore mode is chosen."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Snapshot archive helper-surface check:|The route printer keeps the archive-surface preflight visible in the human-readable route."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|archive_surface|The route printer exposes the archive-surface command in JSON output for downstream tooling."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md|The route printer keeps the archive-surface note in the read-first companion set."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|sync-helper-surface is safer|The route printer explains when the archive-surface helper should drive a synced restore choice."
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
EOF