#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_build_reentry_stack_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved-archive build-and-reentry helper stack for
issue #3 still has its required docs, route printers, surface checkers, and
handoff commands before a run reopens restore, offline staging, or runtime
validation work.
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
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep publication and toolchain blockers visible before direct runtime edits."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved snapshot restore note for rebuilding a reusable checkout from Memory."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Checksum and archive-integrity route that should stay available before offline staging."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Saved Rust toolchain route for Linux or WSL follow-up work."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig-line recovery route for choosing a branch-compatible toolchain."
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Offline dependency staging route for the saved browser-deps and BoringSSL bundles."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Top-level Linux or WSL readiness route before runtime replay."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight for repo snapshot, dependencies, blocker intelligence, and fallback Zig visibility."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved archive integrity checker for the repo snapshot and dependency bundles."
    "scripts/check_linux_build_readiness.py|file|Focused Linux or WSL readiness helper for Zig, Rust, sibling deps, and offline input staging."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Saved-browser-snapshot surface checker."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot route printer."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Saved-archive integrity route surface checker."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Saved-archive integrity route printer."
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Saved Rust route surface checker."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Saved Rust route printer."
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Zig toolchain recovery surface checker."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig toolchain recovery route printer."
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|file|Offline build-inputs surface checker."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Offline build-inputs route printer."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Top-level Linux or WSL build-readiness surface checker."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Top-level Linux or WSL build-readiness route printer."
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1|file|Windows runtime handoff surface checker that closes the Linux readiness loop."
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1|file|Windows runtime handoff route printer for the narrowed Page.zig plus win32_backend.zig lane."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The gate note keeps the saved-browser-snapshot route in the read-first path."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|The gate note keeps the saved-memory preflight visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_linux_build_readiness.py|The gate note keeps the Linux build-readiness helper visible."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-memory preflight still checks blocker intelligence."
    "scripts/check_issue3_saved_memory_inputs.py|suggested next step: re-run the saved-browser restore with --sync-helper-surface before Linux or WSL follow-up work|The saved-memory preflight still points to synced restore when helper drift is the blocker."
    "scripts/check_linux_build_readiness.py|discovered a staged Zig candidate at|The Linux readiness helper still suggests a matching staged Zig candidate when one exists."
    "scripts/check_linux_build_readiness.py|fallback Zig archive|The Linux readiness helper still surfaces the fallback Zig archive state."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--sync-helper-surface|The saved-browser-snapshot route still supports the synced helper-surface restore mode."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-archive integrity preflight against the restored checkout:|The saved-browser-snapshot route still keeps the saved-archive integrity follow-up visible."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|scripts/check_issue3_saved_archive_integrity.py|The saved-archive route still anchors the direct integrity checker."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|export PATH=|The saved Rust route still prints the PATH export needed for follow-up checks."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Candidate discovery|The Zig recovery route still prints the staged-toolchain discovery step."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Treat the attached Zig 0.17 dev bundle as a surfaced fallback only|The Zig recovery route still warns against treating the fallback Zig line as honest validation evidence."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|saved Memory input preflight|The offline build-inputs route still keeps the saved-memory preflight ahead of archive restore."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|saved Rust toolchain route|The offline build-inputs route still hands off into the saved Rust route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved-browser-snapshot route when no reusable checkout exists yet:|The Linux build-readiness route still keeps the reusable-checkout rebuild path visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved archive integrity route surface check:|The Linux build-readiness route still keeps the archive-integrity surface check visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Zig toolchain recovery route:|The Linux build-readiness route still keeps the Zig-line route visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Rust route surface check:|The Linux build-readiness route still keeps the saved Rust surface check visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Offline build-inputs route:|The Linux build-readiness route still keeps the offline staging route visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Windows runtime surface handoff:|The Linux build-readiness route still prints the Windows runtime surface handoff."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Windows runtime route handoff:|The Linux build-readiness route still prints the Windows runtime route handoff."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Prefer a Zig 0.15.2 toolchain for honest branch validation|The Linux build-readiness route still calls out the branch-compatible Zig line explicitly."
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1|saved_memory_preflight|The Windows runtime handoff still keeps the saved-memory preflight command in its route output."
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1|linux_build_readiness_skip_zig|The Windows runtime handoff still keeps the Linux readiness preflight visible."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-build-reentry-stack-surface")"
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

echo "Issue #3 build-and-reentry stack surface check"
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
echo "All build-and-reentry stack surfaces are present."
