#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_reentry_helper_chain.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the issue #3 Linux/WSL re-entry helper chain still has the expected
route notes, surface checks, route printers, and core readiness helpers in
place before a run starts saved-snapshot restore or offline build staging.
EOF
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
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
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Top-level gate note that should still anchor Linux/WSL re-entry before runtime edits reopen."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved snapshot route note for rebuilding or refreshing a reusable checkout."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Restored-checkout route note for follow-up work after snapshot restore."
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Saved-Memory route note for checking the persisted repo and dependency inputs."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Saved-archive integrity note for checksum validation before offline staging."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Saved Rust route note for restoring the saved Rust 1.79.0 toolchain."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig recovery route note for finding a matching 0.15.x toolchain line."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Zig archive restore note for staging a real 0.15.x archive under ../toolchains."
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Offline build-inputs route note for restoring sibling deps and prebuilt V8 inputs."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux/WSL build-readiness note that ties the helper chain together before Windows handoff."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Saved snapshot route surface check."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved snapshot route printer."
    "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh|file|Restored-checkout route surface check."
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh|file|Restored-checkout route printer."
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh|file|Saved-Memory route surface check."
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Saved-Memory route printer."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Saved-archive integrity route surface check."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Saved-archive integrity route printer."
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Saved Rust route surface check."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Saved Rust route printer."
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh|file|Zig archive restore route surface check."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig recovery route printer."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Offline build-inputs route printer."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Linux build-readiness route surface check."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer."
    "scripts/check_issue3_workspace_context.py|file|Workspace-context helper for nested restored checkouts."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity preflight helper."
    "scripts/check_linux_build_readiness.py|file|Linux/WSL build-readiness helper."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The gate note should still route Linux or WSL reruns through build readiness before direct runtime edits."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The Linux route note should still name the saved snapshot route."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|The Linux route note should still surface the saved Rust gate."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_zig_toolchain_archive_restore_route_surface.sh|The Linux route note should still surface the Zig archive restore gate."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_offline_build_inputs_route.sh|The Linux route note should still route runs through offline build-input staging."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_browser_snapshot_route.sh|The Linux route printer should still expose the saved snapshot route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_rust_toolchain_route.sh|The Linux route printer should still expose the saved Rust route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The Linux route printer should still expose the Zig recovery route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_offline_build_inputs_route.sh|The Linux route printer should still expose the offline build-inputs route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_workspace_context.py|The Linux route printer should still expose the workspace-context helper."
    "scripts/check_linux_build_readiness.py|--expect-saved-archives|The readiness helper should still support saved-archive preflight checks."
    "scripts/check_linux_build_readiness.py|--toolchains-root|The readiness helper should still support explicit staged Zig toolchain roots."
)

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
    printf '  "profile": %s,\n' "$(json_escape "issue3-reentry-helper-chain")"
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

echo "Issue #3 re-entry helper chain check"
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
echo "Cross-route expectations:"
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
echo "All issue #3 re-entry helper-chain surfaces are present."
