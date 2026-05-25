#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_workspace_context_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local workspace-context route for the blocked issue #3
Linux or WSL re-entry lane still has its required note, helper surface, and
follow-up route references in place before a run relies on it.
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
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|file|Read-first workspace-context note for nested or restored issue #3 Linux or WSL reruns."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 route note that should stay visible when workspace discovery still leads into environment-gated reruns."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot route note that should stay visible when no reusable checkout exists yet."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness note that should stay visible after workspace roots are surfaced."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig toolchain recovery note that should stay visible after workspace roots are surfaced."
    "scripts/linux/check_issue3_workspace_context_route_surface.sh|file|Fail-fast surface checker for the workspace-context route."
    "scripts/linux/show_issue3_workspace_context_route.sh|file|Compact route printer for the workspace-context handoff."
    "scripts/check_issue3_workspace_context.py|file|Workspace-context helper that resolves the practical shared roots."
    "scripts/linux/show_issue3_progress_tracker_route.sh|file|Issue #11 route printer used when workspace discovery still leads into environment-gated reruns."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot route printer used when no reusable checkout exists yet."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer used after workspace roots are surfaced."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig toolchain recovery route printer used after workspace roots are surfaced."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|check_issue3_workspace_context_route_surface.sh|The workspace-context note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_workspace_context_route.sh|The workspace-context note keeps the compact route printer visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|scripts/check_issue3_workspace_context.py|The workspace-context note keeps the Python helper visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|python scripts/check_issue3_workspace_context.py --repo-root .|The workspace-context note keeps the exact helper command visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_progress_tracker_route.sh|The workspace-context note keeps the issue #11 handoff visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The workspace-context note keeps the saved-browser-snapshot route visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The workspace-context note keeps the Linux build-readiness route visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The workspace-context note keeps the Zig recovery route visible."
    "scripts/linux/show_issue3_workspace_context_route.sh|workspace-context route|The route printer still introduces the workspace-context handoff clearly."
    "scripts/linux/show_issue3_workspace_context_route.sh|fallback_zig_archive|The route printer JSON output exposes the fallback Zig archive explicitly."
    "scripts/linux/show_issue3_workspace_context_route.sh|check_issue3_workspace_context.py|The route printer still points at the Python helper."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_progress_tracker_route.sh|The route printer still exposes the issue #11 follow-up."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer still exposes the saved-browser-snapshot follow-up."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still exposes the Linux build-readiness follow-up."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The route printer still exposes the Zig recovery follow-up."
    "scripts/linux/show_issue3_workspace_context_route.sh|show_issue3_saved_zig_archive_candidates_route.sh|The route printer still exposes the saved-Zig follow-up."
    "scripts/linux/show_issue3_workspace_context_route.sh|toolchains_root|The route printer JSON output still exposes the resolved toolchains root."
    "scripts/linux/show_issue3_workspace_context_route.sh|saved_archives_root|The route printer JSON output still exposes the resolved saved-archives root."
    "scripts/linux/show_issue3_workspace_context_route.sh|offline_deps_root|The route printer JSON output still exposes the resolved offline-deps root."
    "scripts/linux/show_issue3_workspace_context_route.sh|restored_checkout_root|The route printer JSON output still exposes the resolved restored-checkout root."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-workspace-context-route-surface")"
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

echo "Issue #3 workspace-context route surface check"
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
echo "All workspace-context route surfaces are present."
