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

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"

declare -a REFERENCE_PATHS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig line recovery note for the blocked issue #3 Linux or WSL route."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Archive-staging companion note for putting a Zig toolchain under ../toolchains before the route reruns discovery."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion that should still point runs at the Zig line recovery helper."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the Linux build-readiness lane visible before the direct runtime patch is reopened."
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Fail-fast surface checker for the Zig toolchain recovery route."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Compact Zig line recovery route printer."
    "scripts/check_issue3_saved_zig_archive_candidates.py|file|Saved Zig archive discovery helper for choosing the preferred 0.15.x restore candidate."
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh|file|Fallback Zig restore helper for staging the attached archive under ../toolchains."
    "scripts/linux/restore_zig_toolchain_archive.sh|file|Generic Zig archive restore helper for staging a real 0.15.x archive under ../toolchains."
    "scripts/check_linux_build_readiness.py|file|Readiness helper that reads build.zig.zon and classifies staged Zig candidates."
    "build.zig.zon|file|Manifest surface that defines the branch minimum Zig line."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|The Zig recovery note still points at the compact route helper."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/check_issue3_saved_zig_archive_candidates.py|The Zig recovery note keeps the saved archive candidate helper visible."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/restore_issue3_fallback_zig_toolchain.sh|The Zig recovery note keeps the fallback restore helper visible."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|The Zig recovery note keeps the archive-staging companion visible for real 0.15.x archives."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The Zig recovery note still names the attached fallback Zig bundle."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|The Zig recovery note still names the expected branch-compatible Zig line."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The Linux build-readiness note still points at the Zig recovery route."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|restore_zig_toolchain_archive.sh|The archive-staging companion note still points at the generic Zig archive restore helper."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_issue3_zig_toolchain_recovery_route_surface.sh|The Zig recovery route still points back to its dedicated surface checker."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_issue3_saved_zig_archive_candidates.py|The Zig recovery route still points at the saved archive candidate helper."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|The Zig recovery route still points at the archive-staging companion note."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|restore_issue3_fallback_zig_toolchain.sh|The Zig recovery route still points at the fallback restore helper."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|The Zig recovery route still reads the branch minimum Zig line from build.zig.zon."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|The Zig recovery route still points back to the readiness helper."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|The Zig recovery route still supports an explicit toolchains root override."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--saved-archives-root|The Zig recovery route still supports an explicit saved-archives root override."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--offline-deps-root|The Zig recovery route still supports an explicit offline dependency root override."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--fallback-zig-archive|The Zig recovery route still supports an explicit fallback Zig archive override."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|surface_check|The Zig recovery route JSON output still carries the fail-fast surface-check command."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|saved_archive_candidate_discovery|The Zig recovery route JSON output still carries the saved archive candidate discovery command."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|matching_readiness|The Zig recovery route still exposes the full matching-line readiness command when a compatible Zig candidate is staged."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore_check|The Zig recovery route JSON output still carries the fallback restore surface-check command when the attached archive is visible."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore|The Zig recovery route JSON output still carries the fallback restore command when the attached archive is visible."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Saved archive candidate discovery|The Zig recovery route still prints the saved archive candidate discovery section."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Fallback archive staging|The Zig recovery route still prints the fallback archive staging section when the attached archive is visible."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Discovered Zig candidates: none|The Zig recovery route still prints a clear empty-candidate state when no staged Zig toolchains are available."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|No branch-compatible Zig candidate is staged yet.|The Zig recovery route still prints a clear no-match state when only older or mismatched Zig candidates are present."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The Zig recovery route still surfaces the attached fallback Zig archive."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Saved archives root:|The Zig recovery route still prints the saved archives root used for discovery and readiness reruns."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Offline deps root:|The Zig recovery route still prints the offline dependency root used for full readiness reruns."
    "scripts/check_issue3_saved_zig_archive_candidates.py|--saved-archives-root|The saved archive candidate helper still supports an explicit saved-archives root override."
    "scripts/check_issue3_saved_zig_archive_candidates.py|--toolchains-root|The saved archive candidate helper still supports an explicit toolchains root override."
    "scripts/check_issue3_saved_zig_archive_candidates.py|Preferred restore commands:|The saved archive candidate helper still prints preferred restore commands when a matching archive is found."
    "scripts/check_issue3_saved_zig_archive_candidates.py|use the fallback archive only as a surfaced stopgap|The saved archive candidate helper still warns when only the fallback archive is available."
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh|--check-only|The fallback restore helper still supports surface-only validation without extraction."
    "scripts/linux/restore_zig_toolchain_archive.sh|--check-only|The generic Zig archive restore helper still supports surface-only validation without extraction."
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