#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue11_toolchains_root_candidates_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the issue #11 toolchains-root route still has its required note,
helper surface, and follow-up route references in place before a Linux or WSL
rerun relies on it.
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
    "docs/ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md|file|Read-first route note for the issue #11 toolchains-root handoff."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|file|Workspace-context note that should keep the toolchains-root route visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness note that should keep the toolchains-root handoff visible."
    "scripts/linux/check_issue11_toolchains_root_candidates_route_surface.sh|file|Fail-fast surface checker for the issue #11 toolchains-root route."
    "scripts/linux/show_issue11_toolchains_root_candidates_route.sh|file|Compact route printer for the issue #11 toolchains-root handoff."
    "scripts/check_issue11_toolchains_root_candidates.py|file|Python helper that surfaces the preferred toolchains root and follow-up commands."
    "scripts/check_issue3_workspace_context.py|file|Workspace-context helper that should stay visible when the checkout sits deeper than the default layout."
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh|file|Nested-workspace saved-memory preflight that should stay visible after the toolchains-root handoff."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig recovery route that should stay visible after the toolchains-root handoff."
    "scripts/check_linux_build_readiness.py|file|Linux build-readiness helper that should receive the preferred --toolchains-root override."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md|check_issue11_toolchains_root_candidates_route_surface.sh|The route note keeps the dedicated surface checker visible."
    "docs/ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md|show_issue11_toolchains_root_candidates_route.sh|The route note keeps the compact route printer visible."
    "docs/ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md|check_issue11_toolchains_root_candidates.py|The route note keeps the Python helper visible."
    "docs/ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md|run_issue11_nested_workspace_saved_memory_preflight.sh|The route note keeps the nested-workspace saved-memory preflight visible."
    "docs/ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The route note keeps the Zig recovery route visible."
    "docs/ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md|check_linux_build_readiness.py|The route note keeps the Linux build-readiness helper visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|show_issue11_toolchains_root_candidates_route.sh|The workspace-context note keeps the dedicated toolchains-root route visible."
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md|check_issue11_toolchains_root_candidates_route_surface.sh|The workspace-context note keeps the dedicated toolchains-root surface check visible."
    "scripts/linux/show_issue11_toolchains_root_candidates_route.sh|toolchains-root route|The route printer still introduces the toolchains-root handoff clearly."
    "scripts/linux/show_issue11_toolchains_root_candidates_route.sh|preferred_toolchains_root|The route printer JSON output still exposes the preferred toolchains root."
    "scripts/linux/show_issue11_toolchains_root_candidates_route.sh|suggested_readiness_command|The route printer still exposes the readiness follow-up."
    "scripts/linux/show_issue11_toolchains_root_candidates_route.sh|suggested_zig_recovery_command|The route printer still exposes the Zig recovery follow-up."
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
    printf '  "profile": %s,\n' "$(json_escape "issue11-toolchains-root-route-surface")"
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

echo "Issue #11 toolchains-root route surface check"
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
echo "All issue #11 toolchains-root route surfaces are present."
