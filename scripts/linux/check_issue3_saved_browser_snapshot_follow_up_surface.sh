#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_browser_snapshot_follow_up_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--expect-synced-helper-surface] \
    [--json]

Verify that a restored browser snapshot checkout is ready for the next Linux or
WSL follow-up commands before issue #3 build-readiness or runtime re-entry work
reopens.
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
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
RESTORED_CHECKOUT_ROOT=""
EXPECT_SYNCED_HELPER_SURFACE=0
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --helper-root)
            HELPER_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --expect-synced-helper-surface)
            EXPECT_SYNCED_HELPER_SURFACE=1
            shift
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
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    if [[ -f "${REPO_ROOT}/build.zig.zon" ]]; then
        RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
    else
        RESTORED_CHECKOUT_ROOT="${REPO_ROOT}/${DEFAULT_RESTORED_CHECKOUT_NAME}"
    fi
fi

declare -a REQUIRED_RESTORED_PATHS=(
    "build.zig.zon|file|Restored checkout manifest that proves the saved snapshot extracted into a browser tree."
)

declare -a LIVE_HELPER_PATHS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Read-first note for reopening the saved-browser-snapshot route."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper for restored checkout follow-up."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Compact restore route printer that should stay available on the live helper root."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux or WSL build-readiness route printer for the restored checkout."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime re-entry route printer for the restored checkout."
)

declare -a SYNCED_RESTORED_HELPER_PATHS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|Synced restore note expected inside the restored checkout when helper-surface sync is enabled."
    "scripts/check_issue3_saved_memory_inputs.py|file|Synced saved-Memory preflight expected inside the restored checkout when helper-surface sync is enabled."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Synced Linux or WSL build-readiness route expected inside the restored checkout when helper-surface sync is enabled."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Synced runtime re-entry route expected inside the restored checkout when helper-surface sync is enabled."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/check_issue3_saved_memory_inputs.py|REQUIRED_RESTORED_HELPER_FILES|The saved-Memory preflight still knows which follow-up helper files belong on a reusable restored checkout."
    "scripts/check_issue3_saved_memory_inputs.py|browser-memory-snapshot|The saved-Memory preflight still defaults to the reusable restored checkout name."
    "scripts/check_issue3_saved_memory_inputs.py|has_helper_surface|The saved-Memory preflight still reports whether the restored checkout carries the helper surface."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--sync-helper-surface|The restore route printer still surfaces helper sync mode."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-Memory preflight against the restored checkout:|The restore route printer still surfaces the restored-checkout preflight step."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Linux or WSL build-readiness route from the restored checkout:|The restore route printer still surfaces the restored-checkout Linux follow-up."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Direct runtime re-entry route from the restored checkout:|The restore route printer still surfaces the restored-checkout runtime follow-up."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Recommended Self-Contained Restore|The saved-browser-snapshot note still keeps the synced restore path visible."
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Do not switch into the restored checkout|The saved-browser-snapshot note still warns about stale helper surfaces in unsynced restores."
)

reference_rows=()
content_rows=()
missing_count=0

check_path_rows() {
    local root="$1"
    local scope="$2"
    shift 2
    local entries=("$@")
    local entry relative_path kind purpose full_path exists
    for entry in "${entries[@]}"; do
        IFS="|" read -r relative_path kind purpose <<<"${entry}"
        full_path="${root}/${relative_path}"
        exists=0
        if [[ "${kind}" == "directory" ]]; then
            [[ -d "${full_path}" ]] && exists=1
        else
            [[ -f "${full_path}" ]] && exists=1
        fi
        if [[ "${exists}" -eq 0 ]]; then
            missing_count=$((missing_count + 1))
        fi
        reference_rows+=("${scope}|${relative_path}|${kind}|${purpose}|${exists}")
    done
}

check_content_rows() {
    local root="$1"
    local scope="$2"
    shift 2
    local entries=("$@")
    local entry relative_path snippet purpose full_path exists
    for entry in "${entries[@]}"; do
        IFS="|" read -r relative_path snippet purpose <<<"${entry}"
        full_path="${root}/${relative_path}"
        exists=0
        if [[ -f "${full_path}" ]] && grep -Fq -- "${snippet}" "${full_path}"; then
            exists=1
        fi
        if [[ "${exists}" -eq 0 ]]; then
            missing_count=$((missing_count + 1))
        fi
        content_rows+=("${scope}|${relative_path}|${snippet}|${purpose}|${exists}")
    done
}

check_path_rows "${RESTORED_CHECKOUT_ROOT}" "restored-checkout" "${REQUIRED_RESTORED_PATHS[@]}"
check_path_rows "${HELPER_ROOT}" "live-helper-root" "${LIVE_HELPER_PATHS[@]}"
check_content_rows "${HELPER_ROOT}" "live-helper-root" "${CONTENT_EXPECTATIONS[@]}"
if [[ "${EXPECT_SYNCED_HELPER_SURFACE}" -eq 1 ]]; then
    check_path_rows "${RESTORED_CHECKOUT_ROOT}" "synced-restored-helper-surface" "${SYNCED_RESTORED_HELPER_PATHS[@]}"
fi

DEFAULT_PREFLIGHT_COMMAND="python ${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${RESTORED_CHECKOUT_ROOT}"
DEFAULT_LINUX_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${RESTORED_CHECKOUT_ROOT}"
DEFAULT_RUNTIME_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${RESTORED_CHECKOUT_ROOT}"
SYNCED_PREFLIGHT_COMMAND="python ${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${RESTORED_CHECKOUT_ROOT}"
SYNCED_LINUX_ROUTE_COMMAND="bash ${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${RESTORED_CHECKOUT_ROOT}"
SYNCED_RUNTIME_ROUTE_COMMAND="bash ${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ${RESTORED_CHECKOUT_ROOT}"

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-browser-snapshot-follow-up-surface")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "expect_synced_helper_surface": %s,\n' "$([[ "${EXPECT_SYNCED_HELPER_SURFACE}" -eq 1 ]] && echo true || echo false)"
    printf '  "reference_count": %d,\n' "${#reference_rows[@]}"
    printf '  "content_check_count": %d,\n' "${#content_rows[@]}"
    printf '  "missing_count": %d,\n' "${missing_count}"
    printf '  "references": [\n'
    for index in "${!reference_rows[@]}"; do
        IFS="|" read -r scope relative_path kind purpose exists <<<"${reference_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"scope": %s, "path": %s, "kind": %s, "purpose": %s, "exists": %s}' \
            "$(json_escape "${scope}")" \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${kind}")" \
            "$(json_escape "${purpose}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ],\n'
    printf '  "content_checks": [\n'
    for index in "${!content_rows[@]}"; do
        IFS="|" read -r scope relative_path snippet purpose exists <<<"${content_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"scope": %s, "path": %s, "snippet": %s, "purpose": %s, "exists": %s}' \
            "$(json_escape "${scope}")" \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${snippet}")" \
            "$(json_escape "${purpose}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ],\n'
    printf '  "commands": {\n'
    printf '    "preflight": %s,\n' "$(json_escape "${DEFAULT_PREFLIGHT_COMMAND}")"
    printf '    "linux_build_route": %s,\n' "$(json_escape "${DEFAULT_LINUX_ROUTE_COMMAND}")"
    printf '    "runtime_route": %s,\n' "$(json_escape "${DEFAULT_RUNTIME_ROUTE_COMMAND}")"
    printf '    "synced_preflight": %s,\n' "$(json_escape "${SYNCED_PREFLIGHT_COMMAND}")"
    printf '    "synced_linux_build_route": %s,\n' "$(json_escape "${SYNCED_LINUX_ROUTE_COMMAND}")"
    printf '    "synced_runtime_route": %s\n' "$(json_escape "${SYNCED_RUNTIME_ROUTE_COMMAND}")"
    printf '  }\n'
    printf '}\n'
    if [[ "${missing_count}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Issue #3 saved browser snapshot follow-up surface check"
echo
echo "Repo root:                ${REPO_ROOT}"
echo "Live helper root:         ${HELPER_ROOT}"
echo "Restored checkout root:   ${RESTORED_CHECKOUT_ROOT}"
echo "Expect synced helpers:    $([[ "${EXPECT_SYNCED_HELPER_SURFACE}" -eq 1 ]] && echo yes || echo no)"
echo

for row in "${reference_rows[@]}"; do
    IFS="|" read -r scope relative_path kind purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${scope}: ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Helper source expectations:"
for row in "${content_rows[@]}"; do
    IFS="|" read -r scope relative_path snippet purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${scope}: ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Suggested follow-up:"
echo "  Live helper-root preflight: ${DEFAULT_PREFLIGHT_COMMAND}"
echo "  Live helper-root Linux route: ${DEFAULT_LINUX_ROUTE_COMMAND}"
echo "  Live helper-root runtime route: ${DEFAULT_RUNTIME_ROUTE_COMMAND}"
echo "  Synced restored-checkout preflight: ${SYNCED_PREFLIGHT_COMMAND}"
echo "  Synced restored-checkout Linux route: ${SYNCED_LINUX_ROUTE_COMMAND}"
echo "  Synced restored-checkout runtime route: ${SYNCED_RUNTIME_ROUTE_COMMAND}"

if [[ "${missing_count}" -gt 0 ]]; then
    echo
    echo "Missing checks: ${missing_count}"
    exit 1
fi

echo
echo "Restored checkout follow-up surface is ready."
