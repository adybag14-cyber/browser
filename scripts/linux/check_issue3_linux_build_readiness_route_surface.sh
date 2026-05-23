#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local Linux build-readiness route for the blocked issue
#3 Enter-submit runtime lane still has its required docs, helpers, and command
snippets in place before a run reopens offline staging or focused Zig checks.
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
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should point Linux or WSL reruns at the build-readiness route before focused Zig checks."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should stay paired with the Linux readiness route."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Saved-browser-snapshot restore note that should stay visible when no reusable checkout exists yet."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux or WSL build-readiness note for the blocked issue #3 runtime lane."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig toolchain recovery note for the blocked issue #3 Linux or WSL route."
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Read-first offline build-inputs note for the blocked issue #3 Linux or WSL route."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight that checks the repo snapshot, notes, dependency archives, and fallback Zig surface before offline staging starts."
    "scripts/check_linux_build_readiness.py|file|Python helper that checks saved archives, sibling deps, offline deps, and toolchain readiness."
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file|Fail-fast saved-browser-snapshot checker used when no reusable checkout exists yet."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact saved-browser-snapshot route printer for restoring a disposable checkout before Linux or WSL staging continues."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that keeps the saved repo snapshot extraction path on one branch-local surface."
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Fail-fast Zig toolchain recovery checker used before the route blames the fallback Zig bundle."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Compact Zig toolchain recovery route printer for selecting a branch-compatible Zig line."
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Fail-fast saved Rust route checker used before the route reuses the saved Rust archive."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Compact saved Rust route printer for reusing the saved Rust archive."
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|file|Fail-fast offline build-inputs checker used before the route stages saved archives into sibling dependencies."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Compact offline build-inputs route printer for staging sibling dependencies from the saved archives."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Compact Linux route printer for the saved-archive-first recovery path."
    "scripts/linux/restore_saved_rust_toolchain.sh|file|Saved Rust restore helper that should keep the check-only and restore commands on one branch-local surface."
    "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper that stages zig-v8-fork, boringssl-zig, and offline-deps."
    "build.zig.zon|file|Manifest surface that defines the branch minimum Zig line and sibling path dependencies."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The gate note keeps the Linux build-readiness note in the direct issue #3 read-first surface."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|The gate note keeps the Linux route printer visible before focused Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|The gate note keeps the saved-Memory input preflight visible before offline staging or focused Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_linux_build_readiness.py|The gate note keeps the Linux readiness helper visible before focused Zig validation."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The Linux build-readiness note keeps the saved-browser-snapshot restore note visible when no reusable checkout exists yet."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The Linux build-readiness note keeps the Zig recovery note visible before fallback Zig is blamed."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|The Linux build-readiness note keeps the dedicated offline-inputs route visible before raw archive staging."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_browser_snapshot_route_surface.sh|The Linux build-readiness note keeps the saved-browser-snapshot surface checker visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The Linux build-readiness note keeps the saved-browser-snapshot route printer visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|restore_saved_browser_snapshot.sh|The Linux build-readiness note keeps the saved-browser-snapshot restore helper visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_linux_build_readiness_route_surface.sh|The Linux build-readiness note keeps its own fail-fast surface checker visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The Linux build-readiness note keeps the saved-Memory input preflight named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The Linux build-readiness note keeps the Zig recovery route named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|The Linux build-readiness note keeps the saved Rust route surface checker named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|The Linux build-readiness note keeps the saved Rust route named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_offline_build_inputs_route.sh|The Linux build-readiness note keeps the offline build-inputs route named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_linux_build_readiness.py|The Linux build-readiness note keeps the readiness helper named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/linux/show_issue3_linux_build_readiness_route.sh|The Linux build-readiness note keeps the route printer named explicitly."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|saved Rust 1.79.0 restore command|The Linux build-readiness note keeps the saved Rust restore step visible before trusting Linux or WSL Zig output."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The Linux build-readiness note keeps the attached fallback Zig archive visible as a surfaced input."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|The Linux route printer keeps the saved-browser-snapshot note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|The Linux route printer keeps the saved Rust note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|The Linux route printer keeps the Zig recovery note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|The Linux route printer keeps the offline build-inputs note in its read-first companion list."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_browser_snapshot_route.sh|The Linux route printer keeps a saved-browser-snapshot restore route visible before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The Linux route printer keeps the Zig toolchain recovery helper visible before trusting fallback Zig."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|The Linux route printer keeps the saved Rust route surface checker visible before the saved Rust route itself."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_saved_rust_toolchain_route.sh|The Linux route printer keeps the saved Rust route printer visible before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|show_issue3_offline_build_inputs_route.sh|The Linux route printer keeps the offline build-inputs helper visible before the raw prepare command."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved-browser-snapshot route when no reusable checkout exists yet:|The Linux route printer still prints the saved-browser-snapshot recovery step before the saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_MEMORY_INPUTS_COMMAND|The Linux route printer keeps a dedicated saved-Memory preflight command before the broader saved-archive preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|TOOLCHAIN_ROUTE_COMMAND|The Linux route printer keeps a dedicated Zig recovery command before the broader saved-archive preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|SAVED_RUST_SURFACE_COMMAND|The Linux route printer keeps a dedicated saved Rust surface-check command before the saved Rust route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|OFFLINE_ROUTE_COMMAND|The Linux route printer keeps a dedicated offline build-inputs command before the broader saved-archive preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_memory_inputs.py|The Linux route printer still points at the saved-Memory input preflight helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory input preflight:|The Linux route printer still prints the saved-Memory preflight step before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Zig toolchain recovery route:|The Linux route printer still prints the Zig toolchain recovery step before the broader readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Rust route surface check:|The Linux route printer still prints the saved Rust route surface-check step before the saved Rust route."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Offline build-inputs route:|The Linux route printer still prints the offline build-inputs step before the raw prepare command."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux route printer points back to the fail-fast surface checker."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_linux_build_readiness.py|The Linux route printer still points at the readiness helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|restore_saved_rust_toolchain.sh|The Linux route printer still points at the saved Rust restore helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|fallback-zig-archive|The Linux route printer still supports an explicit attached fallback Zig archive override."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Fallback Zig archive:|The Linux route printer still prints the attached fallback Zig archive surface."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|The saved-Memory input preflight still checks for the saved repo snapshot before route replay."
    "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-Memory input preflight still checks for blocker intelligence before route replay."
    "scripts/check_issue3_saved_memory_inputs.py|--fallback-zig-archive|The saved-Memory input preflight still supports an explicit fallback Zig archive override."
    "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|The saved-Memory input preflight still reports a clear pass surface."
    "scripts/check_linux_build_readiness.py|saved Rust toolchain archive|The readiness helper still knows the saved Rust archive contract."
    "scripts/check_linux_build_readiness.py|saved browser dependency archive|The readiness helper still knows the saved browser dependency archive contract."
    "scripts/linux/restore_saved_rust_toolchain.sh|--check-only|The saved Rust restore helper still supports surface-only validation without extraction."
    "scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|The saved Rust restore helper still prints the PATH/CARGO/RUSTC handoff surface."
    "scripts/linux/prepare_offline_build_inputs.sh|--check-only|The offline prep helper still supports surface-only validation without mutation."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-linux-build-readiness-route-surface")"
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

echo "Issue #3 Linux build-readiness route surface check"
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
echo "All Linux build-readiness surfaces are present."
