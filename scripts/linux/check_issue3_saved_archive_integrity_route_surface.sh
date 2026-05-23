#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved-archive-integrity route for the blocked
issue #3 restore and build-readiness path still has its required docs, helpers,
and command snippets in place.
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
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Read-first saved-archive-integrity note for the blocked issue #3 restore and build-readiness path."
    "scripts/check_issue3_saved_archive_integrity.py|file|Checksum helper that verifies the saved repo snapshot and dependency bundles by SHA-256."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Fail-fast surface checker for the saved-archive-integrity route."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Compact route printer for the saved-archive-integrity helper flow."
    "scripts/check_issue3_saved_memory_inputs.py|file|Presence-only saved-Memory preflight that should stay paired with the integrity helper."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Companion saved-browser-snapshot route printer for the next restore step."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Companion Linux build-readiness route printer for the next offline staging step."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The route note keeps the checksum helper visible."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|--require-fallback-zig|The route note keeps the strict fallback Zig option visible."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The route note keeps the saved-browser-snapshot follow-up visible."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The route note keeps the Linux build-readiness follow-up visible."
    "scripts/check_issue3_saved_archive_integrity.py|DEFAULT_FALLBACK_ZIG_SHA256|The checksum helper keeps the fallback Zig fingerprint surfaced."
    "scripts/check_issue3_saved_archive_integrity.py|Saved archive integrity check passed.|The checksum helper reports a clear pass surface."
    "scripts/check_issue3_saved_archive_integrity.py|--require-fallback-zig|The checksum helper still supports strict fallback Zig enforcement."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|check_issue3_saved_archive_integrity_route_surface.sh|The route printer points back to the fail-fast surface checker."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|check_issue3_saved_archive_integrity.py|The route printer still prints the checksum helper invocation."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer keeps the saved-browser-snapshot follow-up visible."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer keeps the Linux build-readiness follow-up visible."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|Fallback Zig archive:|The route printer still prints the fallback Zig surface."
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
echo "All saved-archive-integrity route surfaces are present."
