#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local Zig archive restore route for the blocked issue #3
Linux or WSL recovery path still has its required docs, helpers, and command
snippets in place before a run stages a Zig archive under ../toolchains.
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
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Read-first route note for staging a real Zig archive under ../toolchains."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first recovery note that should remain paired with the archive-restore route."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness note that should keep the archive-restore route visible before broader Zig validation."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should keep the Linux or WSL toolchain routes visible before the direct runtime patch is reopened."
    "scripts/check_issue3_saved_zig_archive_candidates.py|file|Saved Zig archive discovery helper that should surface matching 0.15.x archive candidates before restore."
    "scripts/linux/check_issue3_zig_toolchain_match.sh|file|Matching-line gate that should stay visible before broader readiness trusts a staged Zig candidate."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|file|Route printer that should keep the archive-restore, recovery, and readiness commands on one compact surface."
    "scripts/linux/restore_zig_toolchain_archive.sh|file|Archive restore helper that stages a Zig archive into ../toolchains."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Recovery route printer that should surface the archive-restore checker and restore commands."
    "scripts/check_linux_build_readiness.py|file|Readiness helper that should consume the restored Zig candidate once it is staged."
    "build.zig.zon|file|Manifest surface that defines the minimum Zig line this route must target."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh|The archive-restore note keeps the surface checker named explicitly."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|The archive-restore note keeps the route printer named explicitly."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/check_issue3_saved_zig_archive_candidates.py|The archive-restore note keeps the saved Zig archive discovery helper visible."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet|The archive-restore note keeps a dedicated saved-archive discovery section visible."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .|The archive-restore note prints the exact saved-archive discovery command."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Print The Route|The archive-restore note keeps a dedicated route-printer section visible."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|The archive-restore note prints the exact route-printer command."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|--saved-archives-root /path/to/memory/repo_archives/browser/dependencies|The archive-restore note keeps the saved-archives override visible on the route printer."
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The archive-restore note still points back to the Zig recovery route after restore."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|check_issue3_zig_toolchain_match.sh|The paired recovery note keeps the dedicated matching-line gate visible."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|check_issue3_zig_toolchain_archive_restore_route_surface.sh|The route printer keeps the route surface check visible."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|check_issue3_saved_zig_archive_candidates.py|The route printer keeps the saved Zig archive discovery helper visible."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|saved_archive_candidates|The route printer keeps a dedicated saved-archive discovery command in structured output."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Saved archive discovery|The route printer keeps the saved-archive discovery section visible in text output."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|restore_zig_toolchain_archive.sh|The route printer keeps the restore helper visible."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The route printer keeps the follow-up recovery route visible."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Archive restore commands|The route printer keeps the archive-restore command section visible in text output."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--saved-archives-root|The route printer keeps the saved-archives override visible."
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--offline-deps-root|The route printer keeps the offline-deps override visible."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_issue3_zig_toolchain_archive_restore_route_surface.sh|The recovery route printer keeps the archive-restore surface checker visible."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|archive_restore_surface_check|The recovery route printer keeps a dedicated archive-restore surface-check command in structured output."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Archive restore surface check|The recovery route printer keeps the archive-restore surface-check section visible in text output."
    "scripts/linux/restore_zig_toolchain_archive.sh|--check-only|The restore helper still supports a surface-only validation pass without extraction."
    "scripts/linux/restore_zig_toolchain_archive.sh|--saved-archives-root|The restore helper keeps the saved-archives override visible for follow-up readiness reruns."
    "scripts/linux/restore_zig_toolchain_archive.sh|--offline-deps-root|The restore helper keeps the offline-deps override visible for follow-up readiness reruns."
    "scripts/linux/restore_zig_toolchain_archive.sh|--fallback-zig-archive|The restore helper keeps the fallback Zig archive override visible for paired recovery reruns."
    "scripts/linux/restore_zig_toolchain_archive.sh|normalize_saved_archives_root()|The restore helper keeps the saved-archives root normalization helper visible."
    "scripts/linux/restore_zig_toolchain_archive.sh|\"saved_archives_root\"|The restore helper JSON output keeps the saved-archives root visible."
    "scripts/linux/restore_zig_toolchain_archive.sh|\"offline_deps_root\"|The restore helper JSON output keeps the offline-deps root visible."
    "scripts/linux/restore_zig_toolchain_archive.sh|\"fallback_zig_archive\"|The restore helper JSON output keeps the fallback Zig archive visible."
    "scripts/linux/restore_zig_toolchain_archive.sh|\"destination_exists\"|The restore helper JSON output keeps the destination-exists flag visible."
    "scripts/linux/restore_zig_toolchain_archive.sh|Saved Zig toolchain restore surface check passed.|The restore helper still reports a clear check-only pass surface."
    "scripts/linux/restore_zig_toolchain_archive.sh|Suggested follow-up commands:|The restore helper still prints the follow-up recovery and readiness commands."
    "scripts/linux/restore_zig_toolchain_archive.sh|--expect-saved-archives|The restore helper keeps the saved-archive readiness expectation visible in its follow-up command."
    "scripts/linux/restore_zig_toolchain_archive.sh|--expect-offline-deps|The restore helper keeps the offline-deps readiness expectation visible in its follow-up command."
    "scripts/linux/restore_zig_toolchain_archive.sh|--require-prebuilt-v8|The restore helper keeps the prebuilt-V8 readiness expectation visible in its follow-up command."
    "scripts/check_linux_build_readiness.py|--toolchains-root|The readiness helper still accepts an explicit staged toolchains root."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|The Linux build-readiness note keeps the archive-restore route in its read-first surface."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|The runtime gate note still routes Linux or WSL reruns through build readiness before direct runtime edits."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-zig-toolchain-archive-restore-route-surface")"
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

echo "Issue #3 Zig archive restore route surface check"
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
echo "All Zig archive restore route surfaces are present."