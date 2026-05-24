#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved-archive-integrity route for the blocked
issue #3 recovery work still has its required note, helper, and follow-up
surfaces in place before a run trusts the saved Memory bundles.
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
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Read-first saved-archive-integrity note for the blocked issue #3 recovery path."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md|file|Saved snapshot archive-surface note that should stay nearby before restore trusts the older snapshot zip."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot restore note that should keep the archive-integrity preflight visible before restore or follow-up work."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness note that should keep the archive-integrity preflight visible before offline staging."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the archive-integrity preflight visible before runtime re-entry."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Fail-fast surface checker for the saved-archive-integrity route."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Compact route printer for the saved-archive-integrity path."
    "scripts/check_issue3_saved_archive_integrity.py|file|SHA-256 helper that verifies the saved repo and dependency bundle fingerprints."
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py|file|Helper that proves whether the saved snapshot zip already carries the current issue #3 restore and runtime helper surface."
    "scripts/check_issue3_saved_memory_inputs.py|file|Presence preflight that should follow the checksum and snapshot-surface route checks before restore or build work."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot restore route that should stay reachable after archive verification."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux or WSL build-readiness route that should stay reachable after archive verification."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime re-entry route that should stay reachable after archive verification."
    "build.zig.zon|file|Manifest surface that should still exist before deeper validation begins."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|The route note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|The route note keeps the compact route printer visible."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The route note keeps the SHA-256 helper visible."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_browser_snapshot_archive_surface.py|The route note keeps the saved snapshot archive-surface helper visible after checksum verification."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|The route note keeps the strict fallback Zig mode visible."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The route note keeps the saved-Memory presence preflight visible after the checksum and snapshot-surface checks."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The route note keeps the restore route visible after checksum verification."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The route note keeps the build-readiness route visible after checksum verification."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The route note keeps the runtime re-entry route visible after checksum verification."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The saved-browser-snapshot note keeps the archive-integrity helper visible before restore follow-up work."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Saved-archive integrity preflight against the restored checkout:|The saved-browser-snapshot note keeps the integrity preflight step visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The Linux build-readiness note keeps the archive-integrity helper visible before offline staging."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|The Linux build-readiness note keeps the exact integrity command visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|The runtime re-entry gates keep the saved-archive route note visible before focused Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|The runtime re-entry gates keep the archive-integrity surface checker visible before focused Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_saved_archive_integrity_route.sh|The runtime re-entry gates keep the compact archive-integrity route visible before focused Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|python scripts/check_issue3_saved_archive_integrity.py --repo-root .|The runtime re-entry gates keep the exact archive-integrity command visible before focused Zig validation."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|check_issue3_saved_archive_integrity.py|The route printer still prints the SHA-256 verification command."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|check_issue3_saved_browser_snapshot_archive_surface.py|The route printer still prints the saved snapshot archive-surface command."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|--require-fallback-zig|The route printer still supports strict fallback Zig verification."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer still prints the saved-browser-snapshot follow-up route."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still prints the Linux or WSL build-readiness follow-up route."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer still prints the runtime re-entry follow-up route."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved snapshot archive surface:|The route printer still prints the saved snapshot archive-surface step."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|Saved-Memory presence preflight:|The route printer still prints the post-checksum presence preflight."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-archive integrity preflight against the restored checkout:|The saved-browser-snapshot route printer keeps the integrity preflight step visible."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|scripts/check_issue3_saved_archive_integrity.py|The saved-browser-snapshot route printer keeps the integrity helper visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved archive integrity preflight:|The Linux build-readiness route printer keeps the integrity preflight step visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_archive_integrity.py|The Linux build-readiness route printer keeps the integrity helper visible."
    "scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|The SHA-256 helper still exposes the expected fallback Zig fingerprint."
    "scripts/check_issue3_saved_archive_integrity.py|Suggested next step: refresh the mismatched archive|The SHA-256 helper still reports the mismatch recovery guidance."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-archive-integrity-route-surface")"
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

echo "Issue #3 saved archive integrity route surface check"
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

echo "All saved archive integrity route surfaces are present."