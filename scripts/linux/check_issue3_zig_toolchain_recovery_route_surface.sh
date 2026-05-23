#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local Zig toolchain recovery route for the blocked issue
#3 Enter-submit runtime lane still has its required docs, helpers, and command
snippets in place before a run blames the attached Zig fallback for branch
behavior.
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

REPO_ROOT="$(cd "${REPO_ROOT}")" && pwd

declare -a REFERENCE_PATHS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig line recovery note for the blocked issue #3 Linux or WSL route."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion that should still point runs at the Zig line recovery helper."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the Linux build-readiness lane visible before the direct runtime patch is reopened."
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Fail-fast surface checker for the Zig toolchain recovery route."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Compact Zig line recovery route printer."
    "scripts/check_linux_build_readiness.py|file|Readiness helper that reads build.zig.zon and classifies staged Zig candidates."
    "build.zig.zon|file|Manifest surface that defines the branch minimum Zig line."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|The Zig recovery note still points at the compact route helper."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The Zig recovery note still names the attached fallback Zig bundle."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|The Zig recovery note still names the expected branch-compatible Zig line."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The Linux build-readiness note still points at the Zig recovery route."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|The Zig recovery route still reads the branch minimum Zig line from build.zig.zon."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|The Zig recovery route still points back to the readiness helper."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|The Zig recovery route still supports an explicit toolchains root override."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The Zig recovery route still surfaces the attached fallback Zig archive."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-zig-toolchain-recovery-route-surface")"
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

echo "Issue #3 Zig toolchain recovery route surface check"
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
echo "All Zig toolchain recovery surfaces are present."
