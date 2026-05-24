#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_build_bootstrap_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved build bootstrap route for blocked issue #3
still has its required docs, helpers, and command markers in place before a run
uses the saved snapshot restore and recovery ladder.
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
    "docs/ISSUE3_SAVED_BUILD_BOOTSTRAP_ROUTE.md|file|Read-first bootstrap note for the blocked issue #3 Linux or WSL recovery ladder."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should still fence the direct runtime patch behind environment readiness."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved snapshot restore note that should stay visible inside the bootstrap ladder."
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Offline dependency staging note that should stay visible inside the bootstrap ladder."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Saved Rust staging note that should stay visible inside the bootstrap ladder."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig recovery note that should stay visible inside the bootstrap ladder."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Broader Linux build-readiness note that should remain aligned with the bootstrap ladder."
    "scripts/linux/check_issue3_saved_build_bootstrap_route_surface.sh|file|Fail-fast surface checker for the saved build bootstrap route."
    "scripts/linux/show_issue3_saved_build_bootstrap_route.sh|file|Compact route printer for the saved build bootstrap ladder."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Synced restore helper for the saved browser snapshot."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory preflight helper used after the synced restore."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved archive integrity helper used before the deeper recovery routes."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Offline-inputs route printer used after the integrity gate."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Saved Rust route printer used after the offline-inputs route."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig recovery route printer used before runtime re-entry."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Runtime re-entry route printer used after the environment gates."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_BUILD_BOOTSTRAP_ROUTE.md|scripts/linux/show_issue3_saved_build_bootstrap_route.sh|The bootstrap note still points at the compact route helper."
    "docs/ISSUE3_SAVED_BUILD_BOOTSTRAP_ROUTE.md|check_issue3_saved_archive_integrity.py|The bootstrap note still points at the saved archive integrity gate."
    "docs/ISSUE3_SAVED_BUILD_BOOTSTRAP_ROUTE.md|show_issue3_offline_build_inputs_route.sh|The bootstrap note still points at the offline-inputs route."
    "docs/ISSUE3_SAVED_BUILD_BOOTSTRAP_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|The bootstrap note still points at the saved Rust route."
    "docs/ISSUE3_SAVED_BUILD_BOOTSTRAP_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The bootstrap note still points at the Zig recovery route."
    "docs/ISSUE3_SAVED_BUILD_BOOTSTRAP_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The bootstrap note still points at the runtime re-entry route."
    "scripts/linux/show_issue3_saved_build_bootstrap_route.sh|--sync-helper-surface|The bootstrap route still restores the saved snapshot with helper-surface sync enabled."
    "scripts/linux/show_issue3_saved_build_bootstrap_route.sh|check_issue3_saved_memory_inputs.py|The bootstrap route still prints the restored-checkout saved-Memory preflight step."
    "scripts/linux/show_issue3_saved_build_bootstrap_route.sh|check_issue3_saved_archive_integrity.py|The bootstrap route still prints the restored-checkout archive integrity step."
    "scripts/linux/show_issue3_saved_build_bootstrap_route.sh|show_issue3_offline_build_inputs_route.sh|The bootstrap route still prints the offline-inputs route step."
    "scripts/linux/show_issue3_saved_build_bootstrap_route.sh|show_issue3_saved_rust_toolchain_route.sh|The bootstrap route still prints the saved Rust route step."
    "scripts/linux/show_issue3_saved_build_bootstrap_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The bootstrap route still prints the Zig recovery route step."
    "scripts/linux/show_issue3_saved_build_bootstrap_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The bootstrap route still prints the runtime re-entry step."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-build-bootstrap-route-surface")"
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

echo "Issue #3 saved build bootstrap route surface check"
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
echo "All saved build bootstrap route surfaces are present."
