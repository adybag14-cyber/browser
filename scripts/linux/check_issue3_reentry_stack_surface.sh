#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_reentry_stack_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local issue #3 re-entry stack route still has the docs,
surface checks, and route printers it depends on before a run trusts the compact
saved-snapshot-to-runtime ladder.
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
    "docs/ISSUE3_REENTRY_STACK_ROUTE.md|file|Top-level compact stack note for the saved-snapshot-to-runtime ladder."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Snapshot restore route for creating a reusable checkout."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Restored-checkout route for proving the extracted checkout is safe to trust."
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file|Saved-archive checksum route for the Memory bundles."
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Offline dependency restore route for Linux or WSL staging."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Saved Rust toolchain route for branch-compatible shell setup."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig-line recovery route for the 0.15.x vs fallback decision."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness route after restore and staging."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that blocks direct runtime edits until publication and toolchain checks are green."
    "scripts/linux/check_issue3_reentry_stack_surface.sh|file|Fail-fast surface checker for the compact re-entry stack."
    "scripts/linux/show_issue3_reentry_stack.sh|file|Compact route printer for the full issue #3 recovery ladder."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Saved-browser-snapshot surface checker."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser-snapshot route printer."
    "scripts/linux/check_issue3_restored_checkout_route_surface.sh|file|Restored-checkout surface checker."
    "scripts/linux/show_issue3_restored_checkout_route.sh|file|Restored-checkout route printer."
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file|Saved-archive integrity surface checker."
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file|Saved-archive integrity route printer."
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|file|Offline build-inputs surface checker."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Offline build-inputs route printer."
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Saved Rust surface checker."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Saved Rust route printer."
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Zig-line recovery surface checker."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig-line recovery route printer."
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Linux build-readiness surface checker."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer."
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|Direct runtime revalidation surface checker."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime revalidation route printer."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/linux/show_issue3_reentry_stack.sh|check_issue3_saved_browser_snapshot_route_surface.sh|The stack route still starts by checking the saved-browser-snapshot surface."
    "scripts/linux/show_issue3_reentry_stack.sh|show_issue3_saved_browser_snapshot_route.sh|The stack route still prints the saved-browser-snapshot helper."
    "scripts/linux/show_issue3_reentry_stack.sh|check_issue3_restored_checkout_route_surface.sh|The stack route still checks the restored-checkout surface."
    "scripts/linux/show_issue3_reentry_stack.sh|show_issue3_restored_checkout_route.sh|The stack route still prints the restored-checkout helper."
    "scripts/linux/show_issue3_reentry_stack.sh|show_issue3_saved_archive_integrity_route.sh|The stack route still prints the saved-archive integrity helper."
    "scripts/linux/show_issue3_reentry_stack.sh|show_issue3_offline_build_inputs_route.sh|The stack route still prints the offline build-inputs helper."
    "scripts/linux/show_issue3_reentry_stack.sh|show_issue3_saved_rust_toolchain_route.sh|The stack route still prints the saved Rust helper."
    "scripts/linux/show_issue3_reentry_stack.sh|show_issue3_zig_toolchain_recovery_route.sh|The stack route still prints the Zig-line recovery helper."
    "scripts/linux/show_issue3_reentry_stack.sh|show_issue3_linux_build_readiness_route.sh|The stack route still prints the Linux build-readiness helper."
    "scripts/linux/show_issue3_reentry_stack.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The stack route still prints the direct runtime re-entry helper."
    "scripts/linux/show_issue3_reentry_stack.sh|synced helper surface|The stack route still explains when the restored checkout should become its own helper root."
    "scripts/linux/show_issue3_reentry_stack.sh|Fallback Zig archive:|The stack route still surfaces the fallback Zig archive before follow-up commands."
    "scripts/linux/show_issue3_reentry_stack.sh|Working rules|The stack route still prints compact replay rules."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-reentry-stack-surface")"
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

echo "Issue #3 re-entry stack surface check"
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
echo "Helper source expectations:"
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
echo "All issue #3 re-entry stack surfaces are present."
