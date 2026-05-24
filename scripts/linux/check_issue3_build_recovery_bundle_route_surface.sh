#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_build_recovery_bundle_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the issue #3 build recovery bundle route still has its required
docs, helpers, and command snippets in place before a run depends on it.
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
    "docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md|file|Bundle route note that keeps the saved-input, offline-input, Rust, and Zig recovery helpers on one compact surface."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Broader Linux or WSL route that this bundle complements."
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Offline build-inputs route that should stay visible from the bundle."
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Saved Rust route that should stay visible from the bundle."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Zig recovery route that should stay visible from the bundle."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory preflight helper used before restore routes."
    "scripts/check_issue3_saved_archive_integrity.py|file|Saved-archive integrity helper used before restore routes trust the saved artifacts."
    "scripts/check_linux_build_readiness.py|file|Readiness helper used for the light and full reruns."
    "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Offline build-inputs route printer used by the bundle."
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Saved Rust route printer used by the bundle."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig recovery route printer used by the bundle."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|file|Bundle route printer itself."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|The bundle note keeps the saved Memory preflight visible."
    "docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py|The bundle note keeps the saved-archive integrity preflight visible."
    "docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md|scripts/linux/show_issue3_offline_build_inputs_route.sh|The bundle note keeps the offline build-inputs route visible."
    "docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md|scripts/linux/show_issue3_saved_rust_toolchain_route.sh|The bundle note keeps the saved Rust route visible."
    "docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|The bundle note keeps the Zig recovery route visible."
    "docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The bundle note keeps the fallback Zig archive called out as a surfaced input."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md|The bundle route printer keeps its note in the read-first list."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|Saved Memory input preflight:|The bundle route printer exposes the saved Memory preflight step."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|Saved archive integrity preflight:|The bundle route printer exposes the saved-archive integrity step."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|Offline build-inputs route:|The bundle route printer exposes the offline build-inputs route."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|Saved Rust route:|The bundle route printer exposes the saved Rust route."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|Zig toolchain recovery route:|The bundle route printer exposes the Zig recovery route."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|Full readiness rerun after staging:|The bundle route printer exposes the full readiness rerun."
    "scripts/linux/show_issue3_build_recovery_bundle_route.sh|show_google_issue3_enter_submit_runtime_revalidation.ps1|The bundle route printer exposes the handoff back to the Windows runtime route."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-build-recovery-bundle-route-surface")"
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

echo "Issue #3 build recovery bundle route surface check"
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
echo "All build recovery bundle surfaces are present."
