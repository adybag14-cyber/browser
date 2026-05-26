#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_progress_tracker_followup_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the issue #11 progress-tracker follow-up routes still expose the
saved-Memory, saved-archive-integrity, and saved-Rust archive-candidate route
notes and helpers before a scheduled Linux or WSL re-entry run depends on them.
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
    "docs/ISSUE3_PROGRESS_TRACKER_FOLLOWUP_ROUTES.md|file|Read-first note for the progress-tracker follow-up route surface."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Primary issue #11 handoff note that should keep the follow-up routes visible."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Saved-Memory follow-up route note."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Saved-archive-integrity follow-up route note."
    "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md|file|Saved-Rust archive-candidate follow-up route note."
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh|file|Fail-fast saved-Memory route surface checker."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Saved-Memory route printer."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Fail-fast saved-archive-integrity route surface checker."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Saved-archive-integrity route printer."
    "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh|file|Fail-fast saved-Rust archive-candidate route surface checker."
    "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh|file|Saved-Rust archive-candidate route printer."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_PROGRESS_TRACKER_FOLLOWUP_ROUTES.md|docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|The follow-up note keeps the saved-Memory route note visible."
    "docs/ISSUE3_PROGRESS_TRACKER_FOLLOWUP_ROUTES.md|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|The follow-up note keeps the saved-archive-integrity route note visible."
    "docs/ISSUE3_PROGRESS_TRACKER_FOLLOWUP_ROUTES.md|docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md|The follow-up note keeps the saved-Rust archive-candidate route note visible."
    "docs/ISSUE3_PROGRESS_TRACKER_FOLLOWUP_ROUTES.md|check_issue3_saved_memory_inputs_route_surface.sh|The follow-up note keeps the saved-Memory surface checker visible."
    "docs/ISSUE3_PROGRESS_TRACKER_FOLLOWUP_ROUTES.md|check_issue3_saved_archive_integrity_route_surface.sh|The follow-up note keeps the saved-archive-integrity surface checker visible."
    "docs/ISSUE3_PROGRESS_TRACKER_FOLLOWUP_ROUTES.md|check_issue3_saved_rust_archive_candidates_route_surface.sh|The follow-up note keeps the saved-Rust archive-candidate surface checker visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|The main progress-tracker note keeps the saved-archive-integrity note visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_archive_integrity_route.sh|The main progress-tracker note keeps the saved-archive-integrity route visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md|The main progress-tracker note keeps the saved-Rust archive-candidate note visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_rust_archive_candidates_route.sh|The main progress-tracker note keeps the saved-Rust archive-candidate route visible."
    "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_saved_memory_inputs_route.sh|The route printer keeps the saved-Memory route visible."
    "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_saved_archive_integrity_route.sh|The route printer keeps the saved-archive-integrity route visible."
    "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_saved_rust_archive_candidates_route.sh|The route printer keeps the saved-Rust archive-candidate route visible."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-progress-tracker-followup-route-surface")"
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

echo "Issue #3 progress-tracker follow-up route surface check"
echo
echo "Repo root: ${REPO_ROOT}"
echo

for row in "${reference_rows[@]}"; do
    IFS="|" read -r relative_path _kind purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Content expectations:"
for row in "${content_rows[@]}"; do
    IFS="|" read -r relative_path _snippet purpose exists <<<"${row}"
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

echo "All progress-tracker follow-up route surfaces are present."
