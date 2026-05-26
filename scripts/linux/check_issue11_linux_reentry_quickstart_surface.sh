#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue11_linux_reentry_quickstart_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the issue #11 Linux/WSL re-entry quickstart note and compact route
printer still point at the expected progress-tracker, archive-integrity,
restore, build-readiness, and Zig-recovery helper surfaces.
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
    "docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md|file|Issue #11 quickstart note for the Linux or WSL re-entry lane."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|file|Compact quickstart route printer for issue #11 Linux or WSL re-entry work."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 progress-tracker route note that the quickstart reopens first."
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh|file|Progress-tracker route surface checker that the quickstart should surface first."
    "scripts/linux/show_issue3_progress_tracker_route.sh|file|Progress-tracker route printer that the quickstart should reopen first."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Saved-archive integrity note that the quickstart should surface before trusting saved inputs."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Saved-archive integrity surface checker that the quickstart should expose."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Saved-archive integrity route printer that the quickstart should expose."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot route note that the quickstart should use when no reusable checkout exists."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Saved-browser-snapshot route surface checker that the quickstart should expose."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot route printer that the quickstart should expose."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness route note that the quickstart should reopen after saved inputs are trusted."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Linux build-readiness surface checker that the quickstart should expose."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer that the quickstart should expose."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig toolchain recovery note that the quickstart should reopen when the staged line still mismatches build.zig.zon."
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Zig toolchain recovery surface checker that the quickstart should expose."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig toolchain recovery route printer that the quickstart should expose."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md|scripts/linux/show_issue11_linux_reentry_quickstart.sh|The quickstart note points at the compact route printer."
    "docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md|issue \`#11\`|The quickstart note still points reruns at issue #11."
    "docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md|saved-archive integrity|The quickstart note keeps the archive-integrity route visible."
    "docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md|saved-browser-snapshot route|The quickstart note keeps the saved-browser-snapshot route visible."
    "docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md|Linux build-readiness route|The quickstart note keeps the Linux build-readiness route visible."
    "docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md|Zig toolchain recovery route|The quickstart note keeps the Zig recovery route visible."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|Issue #11 Linux re-entry quickstart|The quickstart printer still introduces the issue #11 handoff clearly."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|check_issue3_progress_tracker_route_surface.sh|The quickstart printer exposes the progress-tracker surface checker first."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|show_issue3_progress_tracker_route.sh|The quickstart printer exposes the progress-tracker route printer."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|check_issue3_saved_archive_integrity_route_surface.sh|The quickstart printer exposes the archive-integrity surface checker."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|show_issue3_saved_archive_integrity_route.sh|The quickstart printer exposes the archive-integrity route printer."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|check_issue3_saved_browser_snapshot_route_surface.sh|The quickstart printer exposes the saved-browser-snapshot surface checker."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|show_issue3_saved_browser_snapshot_route.sh|The quickstart printer exposes the saved-browser-snapshot route printer."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|check_issue3_linux_build_readiness_route_surface.sh|The quickstart printer exposes the build-readiness surface checker."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|show_issue3_linux_build_readiness_route.sh|The quickstart printer exposes the build-readiness route printer."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|check_issue3_zig_toolchain_recovery_route_surface.sh|The quickstart printer exposes the Zig recovery surface checker."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|show_issue3_zig_toolchain_recovery_route.sh|The quickstart printer exposes the Zig recovery route printer."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|fallback_zig_archive|The quickstart printer JSON output exposes the fallback Zig archive key."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|progress_surface|The quickstart printer JSON output exposes the progress surface key."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|archive_surface|The quickstart printer JSON output exposes the archive surface key."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|snapshot_surface|The quickstart printer JSON output exposes the snapshot surface key."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|build_surface|The quickstart printer JSON output exposes the build surface key."
    "scripts/linux/show_issue11_linux_reentry_quickstart.sh|zig_surface|The quickstart printer JSON output exposes the Zig surface key."
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
    IFS='|' read -r relative_path kind purpose <<<"${entry}"
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
    IFS='|' read -r relative_path snippet purpose <<<"${entry}"
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
    printf '  "profile": %s,\n' "$(json_escape "issue11-linux-reentry-quickstart-surface")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "reference_count": %d,\n' "${#reference_rows[@]}"
    printf '  "content_check_count": %d,\n' "${#content_rows[@]}"
    printf '  "missing_count": %d,\n' "${missing_count}"
    printf '  "references": [\n'
    for index in "${!reference_rows[@]}"; do
        IFS='|' read -r relative_path kind purpose exists <<<"${reference_rows[$index]}"
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
        IFS='|' read -r relative_path snippet purpose exists <<<"${content_rows[$index]}"
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

echo "Issue #11 Linux re-entry quickstart surface check"
echo
echo "Repo root: ${REPO_ROOT}"
echo

for row in "${reference_rows[@]}"; do
    IFS='|' read -r relative_path kind purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Helper source expectations:"
for row in "${content_rows[@]}"; do
    IFS='|' read -r relative_path snippet purpose exists <<<"${row}"
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

echo "All issue #11 quickstart surfaces are present."
