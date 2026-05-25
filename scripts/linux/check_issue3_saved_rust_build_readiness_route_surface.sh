#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved-Rust bridge route still exposes the issue #11
progress tracker, the saved Rust candidate helpers, the saved Rust restore
route, and the broader Linux build-readiness route.
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
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|file|Read-first bridge note for the saved Rust handoff back into Linux build readiness."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Issue #11 status-lane note that should stay visible while the route is still environment-gated."
    "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md|file|Saved Rust archive-selection note that should stay visible before restore commands are trusted."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Saved Rust restore note that should stay visible before the broader Linux route is replayed."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Broader Linux build-readiness note that should stay visible as the next handoff after the Rust toolchain stops being the blocker."
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh|file|Fail-fast issue #11 surface checker."
    "scripts/linux/show_issue3_progress_tracker_route.sh|file|Issue #11 route printer."
    "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh|file|Fail-fast saved Rust archive-candidate route checker."
    "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh|file|Saved Rust archive-candidate route printer."
    "scripts/check_issue3_saved_rust_archive_candidates.py|file|Saved Rust archive-candidate helper."
    "scripts/check_issue3_staged_rust_toolchain_candidates.py|file|Staged Rust toolchain-candidate helper."
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Fail-fast saved Rust restore route checker."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Saved Rust restore route printer."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Fail-fast Linux build-readiness route checker."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer."
    "scripts/check_linux_build_readiness.py|file|Broader Linux build-readiness helper."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|issue \`#11\`|The bridge note keeps the lower-volume issue #11 lane visible."
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md|The bridge note keeps the saved Rust archive-candidate note visible."
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_rust_archive_candidates.py|The bridge note keeps the saved Rust archive-candidate helper visible."
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|scripts/check_issue3_staged_rust_toolchain_candidates.py|The bridge note keeps the staged Rust toolchain-candidate helper visible."
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|scripts/linux/show_issue3_saved_rust_toolchain_route.sh|The bridge note keeps the saved Rust route printer visible."
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|The bridge note keeps the Linux build-readiness route printer visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_progress_tracker_route_surface.sh|The bridge route printer keeps the issue #11 surface check visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|show_issue3_progress_tracker_route.sh|The bridge route printer keeps the issue #11 route visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_saved_rust_archive_candidates_route_surface.sh|The bridge route printer keeps the saved Rust archive-candidate surface check visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|show_issue3_saved_rust_archive_candidates_route.sh|The bridge route printer keeps the saved Rust archive-candidate route visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_saved_rust_archive_candidates.py|The bridge route printer keeps the raw saved Rust archive-candidate helper visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_staged_rust_toolchain_candidates.py|The bridge route printer keeps the staged Rust toolchain-candidate helper visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|The bridge route printer keeps the saved Rust route surface check visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|show_issue3_saved_rust_toolchain_route.sh|The bridge route printer keeps the saved Rust route visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The bridge route printer keeps the Linux build-readiness surface check visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|show_issue3_linux_build_readiness_route.sh|The bridge route printer keeps the Linux build-readiness route visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|check_linux_build_readiness.py|The bridge route printer keeps the Linux build-readiness helper visible."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|Progress-tracker route surface check:|The bridge route printer still prints the issue #11 surface-check step."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|Saved Rust archive-candidate route:|The bridge route printer still prints the saved Rust archive-candidate route step."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|Staged Rust toolchain candidates:|The bridge route printer still prints the staged Rust candidate step."
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh|Linux build-readiness route:|The bridge route printer still prints the Linux build-readiness handoff."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-rust-build-readiness-route-surface")"
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

echo "Issue #3 saved Rust build-readiness bridge route surface check"
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
echo "All saved-Rust build-readiness bridge surfaces are present."
