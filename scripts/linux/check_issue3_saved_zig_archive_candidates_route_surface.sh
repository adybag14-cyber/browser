#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the saved-Zig-archive discovery route for the blocked issue #3
Linux or WSL re-entry lane still has its required note and helper surfaces.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|file|Route note for saved Zig archive discovery work on issue #11."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Companion Zig recovery note that consumes the saved archive discovery result."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Archive restore note used after a matching saved Zig archive is selected."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Build-readiness note that should keep the saved archive discovery route visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 progress-tracker note that should keep the saved archive discovery lane visible."
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh|file|Fail-fast surface checker for this saved archive discovery route."
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|file|Compact route printer for saved Zig archive discovery work."
    "scripts/check_issue3_saved_zig_archive_candidates.py|file|Saved Zig archive candidate helper that surfaces preferred restore commands."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|check_issue3_saved_zig_archive_candidates_route_surface.sh|The route note keeps the surface checker visible."
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|show_issue3_saved_zig_archive_candidates_route.sh|The route note keeps the route printer visible."
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|check_issue3_saved_zig_archive_candidates.py|The route note keeps the Python candidate helper visible."
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|issue `#11`|The route note keeps the lower-volume tracker visible."
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The route note points back to Zig recovery."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The issue #11 tracker note still references Zig recovery."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|check_issue3_saved_zig_archive_candidates.py|The Zig recovery note still references saved archive discovery."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_zig_archive_candidates.py|The Linux build-readiness route still references saved archive discovery."
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|saved Zig archive candidates route|The route printer still introduces the route clearly."
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|check_issue3_saved_zig_archive_candidates.py|The route printer still exposes the Python helper."
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|check_issue3_zig_toolchain_archive_restore_route_surface.sh|The route printer still exposes archive-restore surface checks."
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The route printer still points back to the broader Zig recovery route."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-zig-archive-candidates-route-surface")"
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
    exit
fi

echo "Issue #3 saved Zig archive candidates route surface check"
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
echo "All saved Zig archive candidate route surfaces are present."
