#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local saved Rust toolchain restore route for the blocked
issue #3 Linux or WSL recovery lane still has its required docs, helpers, and
command snippets in place before a run reuses the saved Rust archive.
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
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Read-first saved Rust restore note for the blocked issue #3 Linux or WSL route."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion that should still point runs at the saved Rust helper route."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the Linux build-readiness lane visible before the direct runtime patch is reopened."
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Fail-fast surface checker for the saved Rust restore route."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Compact saved Rust restore route printer."
    "scripts/check_issue3_saved_rust_archive_candidates.py|file|Saved Rust archive candidate helper that surfaces the preferred restore commands."
    "scripts/check_issue3_staged_rust_toolchain_candidates.py|file|Staged Rust toolchain helper that surfaces a reusable 1.79.0 candidate before restore."
    "scripts/linux/restore_saved_rust_toolchain.sh|file|Saved Rust restore helper that should keep the check-only and restore commands on one branch-local surface."
    "scripts/check_linux_build_readiness.py|file|Readiness helper that reruns the Linux or WSL preflight after the saved Rust toolchain is restored."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|The saved Rust route note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|The saved Rust route note prints the dedicated route surface-check command."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|check_issue3_saved_rust_archive_candidates.py|The saved Rust route note surfaces the saved archive candidate helper."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|check_issue3_staged_rust_toolchain_candidates.py|The saved Rust route note surfaces the staged Rust toolchain helper."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|restore_saved_rust_toolchain.sh|The saved Rust route note still points at the restore helper."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_linux_build_readiness.py|The saved Rust route note still points at the matching readiness preflight."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|The Linux build-readiness note keeps the saved Rust route surface checker visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|The Linux build-readiness note still names the saved Rust route printer explicitly."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|The saved Rust route printer points back to the dedicated route surface checker."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_issue3_saved_rust_archive_candidates.py|The saved Rust route printer exposes the saved archive candidate helper."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_issue3_staged_rust_toolchain_candidates.py|The saved Rust route printer exposes the staged toolchain helper."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|restore_saved_rust_toolchain.sh|The saved Rust route printer still points at the restore helper."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_linux_build_readiness.py|The saved Rust route printer still points at the readiness helper."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Saved archive candidate discovery:|The saved Rust route printer still prints the saved archive candidate step."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Staged toolchain candidate discovery:|The saved Rust route printer still prints the staged toolchain discovery step."
    "scripts/linux/restore_saved_rust_toolchain.sh|--check-only|The saved Rust restore helper still supports surface-only validation without extraction."
    "scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|The saved Rust restore helper still prints the PATH/CARGO/RUSTC handoff surface."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-rust-toolchain-route-surface")"
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

echo "Issue #3 saved Rust toolchain route surface check"
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
echo "All saved Rust toolchain route surfaces are present."