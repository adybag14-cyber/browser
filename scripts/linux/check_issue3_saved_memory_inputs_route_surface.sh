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
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Read-first saved-Memory-inputs note for the blocked issue #3 route."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Companion restore note that should stay linked from the Memory-inputs route."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Companion Linux or WSL build-readiness note that should stay linked from the Memory-inputs route."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should stay visible before the direct runtime lane is reopened."
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh|file|Fail-fast surface checker for the saved-Memory-inputs route."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Compact route printer for the saved-Memory-inputs route."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper that checks the repo snapshot, notes, blocker file, and dependency bundles."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Companion restore route printer for runs that still lack a reusable checkout."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Companion Linux or WSL build-readiness route printer after the saved-Memory preflight passes."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Companion direct runtime route printer after restore and build-readiness gates pass."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|check_issue3_saved_memory_inputs_route_surface.sh|The saved-Memory-inputs note still points at its dedicated surface checker."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_saved_memory_inputs_route.sh|The saved-Memory-inputs note still points at the compact route helper."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The saved-Memory-inputs note still points at the preflight helper."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The saved-Memory-inputs note still points at the restore route."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The saved-Memory-inputs note still points at the Linux build-readiness route."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The saved-Memory-inputs note still points at the direct runtime route."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|--agent-files-root /path/to/agent_files|The saved-Memory-inputs note still documents the explicit agent-files override."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The saved-Memory-inputs note still names the fallback Zig bundle."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|check_issue3_saved_memory_inputs_route_surface.sh|The route printer still points back to its dedicated surface checker."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|scripts/check_issue3_saved_memory_inputs.py|The route printer still points at the saved-Memory preflight helper."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|--memory-root|The route printer still supports an explicit Memory-root override."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|--agent-files-root|The route printer still supports an explicit agent-files-root override."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|--fallback-zig-archive|The route printer still supports an explicit fallback Zig archive override."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|saved_browser_snapshot_route|The route printer JSON output still exposes the restore route command."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|linux_build_readiness_route|The route printer JSON output still exposes the Linux build-readiness route command."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|runtime_reentry_route|The route printer JSON output still exposes the direct runtime route command."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|Fallback Zig archive:|The route printer still prints the surfaced fallback Zig archive path or absence."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|The saved-Memory preflight still checks for the saved repo snapshot."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-Memory preflight still checks for blocker intelligence."
    "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|The saved-Memory preflight still reports a clear pass surface."
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
echo "All saved-Memory-inputs route surfaces are present."
