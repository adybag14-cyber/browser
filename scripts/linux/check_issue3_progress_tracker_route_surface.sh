#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_progress_tracker_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local issue #11 progress-tracker route for the blocked
issue #3 Linux or WSL re-entry lane still has its required note, helper
surfaces, and comment templates in place before a run relies on it.
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
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|Read-first issue #11 handoff note for blocked Linux or WSL issue #3 re-entry work."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that explains when issue #11 should be used instead of reopening the direct runtime patch too early."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Saved-Memory route note that should keep the issue #11 handoff visible during environment-gated reruns."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Saved-Rust route note that should stay visible when issue #11 is tracking toolchain reuse or restore work."
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md|file|Saved-Zig route note that should stay visible when issue #11 is tracking archive selection work."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Archive-restore note that should stay visible when issue #11 work advances from archive selection to staging."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness note that should keep the issue #11 tracker visible for progress updates."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig-line recovery note that should stay nearby while issue #11 owns the lower-volume status lane."
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh|file|Fail-fast surface checker for the issue #11 progress-tracker route."
    "scripts/linux/show_issue3_progress_tracker_route.sh|file|Compact route printer for the issue #11 progress-tracker handoff."
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Fail-fast surface checker for the saved-Rust route used by the issue #11 progress tracker."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Saved-Rust route printer used when issue #11 is tracking toolchain reuse or restore work."
    "scripts/check_issue3_saved_rust_archive_candidates.py|file|Saved-Rust archive discovery helper used when issue #11 is tracking restore work."
    "scripts/check_issue3_staged_rust_toolchain_candidates.py|file|Staged Rust helper used when issue #11 is checking whether restore can be skipped."
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh|file|Fail-fast surface checker for the saved-Zig archive route used by the issue #11 progress tracker."
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh|file|Saved-Zig route printer used when issue #11 is tracking archive-selection work."
    "scripts/linux/check_issue3_zig_toolchain_match.sh|file|Matching-line gate used after a saved Zig restore before broader readiness is trusted again."
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh|file|Archive-restore surface checker used before a chosen saved Zig archive is staged."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper used by the blocked Linux or WSL re-entry lane."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper used by the blocked Linux or WSL re-entry lane."
    "scripts/check_issue3_saved_zig_archive_candidates.py|file|Saved-Zig archive discovery helper used when issue #11 is tracking archive-selection work."
    "scripts/check_linux_build_readiness.py|file|Linux build-readiness helper used before the narrowed runtime lane is reopened."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_progress_tracker_route_surface.sh|The progress-tracker note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_progress_tracker_route.sh|The progress-tracker note keeps the compact route printer visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|issue \`#11\`|The progress-tracker note still points reruns at issue #11."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The progress-tracker note keeps the explicit fallback Zig archive handoff visible when nested routes need the same surfaced archive path."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Goal:|The progress-tracker note keeps the start-update template visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|Achieved:|The progress-tracker note keeps the completion-update template visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|The progress-tracker note keeps the saved-Rust follow-up route visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|The progress-tracker note keeps the saved-Rust surface check visible before toolchain reruns trust that helper chain."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_rust_archive_candidates.py|The progress-tracker note keeps the saved-Rust archive discovery helper visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_staged_rust_toolchain_candidates.py|The progress-tracker note keeps the staged-Rust candidate helper visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The progress-tracker note keeps the Linux or WSL build-readiness route visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The progress-tracker note keeps the Zig recovery route visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_memory_inputs_route.sh|The progress-tracker note keeps the saved-Memory follow-up route visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_zig_archive_candidates_route_surface.sh|The progress-tracker note keeps the saved-Zig route surface check visible before archive-selection reruns trust that helper chain."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|show_issue3_saved_zig_archive_candidates_route.sh|The progress-tracker note keeps the saved-Zig follow-up route visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_saved_zig_archive_candidates.py|The progress-tracker note keeps the saved-Zig archive discovery helper visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_zig_toolchain_match.sh|The progress-tracker note keeps the post-restore matching-line gate visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_issue3_zig_toolchain_archive_restore_route_surface.sh|The progress-tracker note keeps the archive-restore surface visible before broader readiness reruns."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|check_linux_build_readiness.py|The progress-tracker note keeps the Linux build-readiness helper visible."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|The progress-tracker note keeps the saved-Rust note visible when toolchain work is the slice."
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|The progress-tracker note keeps the archive-restore note visible when saved-Zig work advances to staging."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|The saved-Memory route keeps the issue #11 handoff note visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|The Linux build-readiness route keeps the issue #11 handoff note visible."
    "scripts/linux/show_issue3_progress_tracker_route.sh|issue #11 progress-tracker route|The route printer still introduces the issue #11 handoff clearly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The route printer usage still exposes the explicit fallback Zig archive override."
    "scripts/linux/show_issue3_progress_tracker_route.sh|fallback_zig_archive|The route printer JSON output exposes the fallback Zig archive explicitly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|The route printer still exposes the saved-Rust route surface check."
    "scripts/linux/show_issue3_progress_tracker_route.sh|saved_rust_toolchain_route_surface|The route printer JSON output exposes the saved-Rust route surface check explicitly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_saved_rust_toolchain_route.sh|The route printer still exposes the saved-Rust follow-up."
    "scripts/linux/show_issue3_progress_tracker_route.sh|saved_rust_toolchain_route|The route printer JSON output exposes the saved-Rust follow-up explicitly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|check_issue3_saved_zig_archive_candidates_route_surface.sh|The route printer still exposes the saved-Zig route surface check."
    "scripts/linux/show_issue3_progress_tracker_route.sh|saved_zig_archive_route_surface|The route printer JSON output exposes the saved-Zig route surface check explicitly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_saved_zig_archive_candidates_route.sh|The route printer still exposes the saved-Zig follow-up."
    "scripts/linux/show_issue3_progress_tracker_route.sh|check_issue3_zig_toolchain_match.sh|The route printer still exposes the matching-line gate."
    "scripts/linux/show_issue3_progress_tracker_route.sh|zig_toolchain_matching_line_gate|The route printer JSON output exposes the matching-line gate explicitly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|check_issue3_zig_toolchain_archive_restore_route_surface.sh|The route printer still exposes the archive-restore surface check."
    "scripts/linux/show_issue3_progress_tracker_route.sh|zig_archive_restore_surface|The route printer JSON output exposes the archive-restore surface check explicitly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_saved_memory_inputs_route.sh|The route printer still exposes the saved-Memory follow-up."
    "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still exposes the Linux or WSL build-readiness follow-up."
    "scripts/linux/show_issue3_progress_tracker_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The route printer still exposes the Zig recovery follow-up."
    "scripts/linux/show_issue3_progress_tracker_route.sh|Goal:|The route printer still prints the start-update template."
    "scripts/linux/show_issue3_progress_tracker_route.sh|Achieved:|The route printer still prints the completion-update template."
    "scripts/linux/show_issue3_progress_tracker_route.sh|issue_url|The route printer JSON output exposes the issue URL explicitly."
    "scripts/linux/show_issue3_progress_tracker_route.sh|start_comment_template|The route printer JSON output exposes the start comment template."
    "scripts/linux/show_issue3_progress_tracker_route.sh|completion_comment_template|The route printer JSON output exposes the completion comment template."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-progress-tracker-route-surface")"
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

echo "Issue #3 progress-tracker route surface check"
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

echo "All progress-tracker route surfaces are present."