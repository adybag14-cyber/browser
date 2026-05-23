#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restored_checkout_surface.sh \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-root /path/to/restored/browser-checkout] \
    [--json]

Check whether a restored saved-browser-snapshot checkout is ready for the next
issue #3 Linux or WSL follow-up steps, and whether those follow-up helpers
should run from the restored checkout itself or from a separate live helper
root.
EOF
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_HELPER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_RESTORED_ROOT="$(cd "${DEFAULT_HELPER_ROOT}/.." && pwd)/browser-memory-snapshot"
HELPER_ROOT="${DEFAULT_HELPER_ROOT}"
RESTORED_ROOT="${DEFAULT_RESTORED_ROOT}"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --helper-root)
            HELPER_ROOT="$2"
            shift 2
            ;;
        --restored-root)
            RESTORED_ROOT="$2"
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

HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
RESTORED_ROOT="$(cd "$(dirname "${RESTORED_ROOT}")" && pwd)/$(basename "${RESTORED_ROOT}")"

declare -a REQUIRED_RESTORED_FILES=(
    "build.zig.zon|build manifest"
    "src/browser/Page.zig|Page runtime source"
    "src/display/win32_backend.zig|Win32 runtime source"
)

declare -a REQUIRED_HELPER_FILES=(
    "scripts/check_issue3_saved_memory_inputs.py|saved-memory preflight helper"
    "scripts/linux/restore_saved_browser_snapshot.sh|saved-browser-snapshot restore helper"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Linux build-readiness route helper"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|runtime re-entry route helper"
)

restored_rows=()
restored_missing=()
for entry in "${REQUIRED_RESTORED_FILES[@]}"; do
    IFS="|" read -r relative_path purpose <<<"${entry}"
    full_path="${RESTORED_ROOT}/${relative_path}"
    exists=0
    [[ -f "${full_path}" ]] && exists=1
    restored_rows+=("${relative_path}|${purpose}|${exists}")
    if [[ "${exists}" -eq 0 ]]; then
        restored_missing+=("${relative_path}")
    fi
done

restored_helper_rows=()
restored_helper_missing=()
for entry in "${REQUIRED_HELPER_FILES[@]}"; do
    IFS="|" read -r relative_path purpose <<<"${entry}"
    full_path="${RESTORED_ROOT}/${relative_path}"
    exists=0
    [[ -f "${full_path}" ]] && exists=1
    restored_helper_rows+=("${relative_path}|${purpose}|${exists}")
    if [[ "${exists}" -eq 0 ]]; then
        restored_helper_missing+=("${relative_path}")
    fi
done

live_helper_rows=()
live_helper_missing=()
for entry in "${REQUIRED_HELPER_FILES[@]}"; do
    IFS="|" read -r relative_path purpose <<<"${entry}"
    full_path="${HELPER_ROOT}/${relative_path}"
    exists=0
    [[ -f "${full_path}" ]] && exists=1
    live_helper_rows+=("${relative_path}|${purpose}|${exists}")
    if [[ "${exists}" -eq 0 ]]; then
        live_helper_missing+=("${relative_path}")
    fi
done

restored_exists=0
[[ -d "${RESTORED_ROOT}" ]] && restored_exists=1

follow_up_helper_root=""
follow_up_mode="blocked"
status="blocked"

if [[ "${#restored_missing[@]}" -eq 0 ]]; then
    if [[ "${#restored_helper_missing[@]}" -eq 0 ]]; then
        follow_up_helper_root="${RESTORED_ROOT}"
        follow_up_mode="self-contained"
        status="ready"
    elif [[ "${#live_helper_missing[@]}" -eq 0 ]]; then
        follow_up_helper_root="${HELPER_ROOT}"
        follow_up_mode="live-helper-root"
        status="ready-with-live-helper-root"
    fi
fi

saved_memory_preflight_command=""
linux_build_route_command=""
runtime_route_command=""
sync_restore_command=""

if [[ -n "${follow_up_helper_root}" ]]; then
    saved_memory_preflight_command="python $(format_shell_arg "${follow_up_helper_root}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
    linux_build_route_command="bash $(format_shell_arg "${follow_up_helper_root}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
    runtime_route_command="bash $(format_shell_arg "${follow_up_helper_root}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
fi

if [[ "${#restored_helper_missing[@]}" -gt 0 && "${#live_helper_missing[@]}" -eq 0 ]]; then
    sync_restore_command="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${HELPER_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_ROOT}") --sync-helper-surface --force"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-restored-checkout-surface")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "restored_root": %s,\n' "$(json_escape "${RESTORED_ROOT}")"
    printf '  "restored_checkout_exists": %s,\n' "$([[ "${restored_exists}" -eq 1 ]] && echo true || echo false)"
    printf '  "status": %s,\n' "$(json_escape "${status}")"
    printf '  "follow_up_mode": %s,\n' "$(json_escape "${follow_up_mode}")"
    printf '  "follow_up_helper_root": %s,\n' "$(json_escape "${follow_up_helper_root}")"
    printf '  "restored_missing_count": %d,\n' "${#restored_missing[@]}"
    printf '  "restored_helper_missing_count": %d,\n' "${#restored_helper_missing[@]}"
    printf '  "live_helper_missing_count": %d,\n' "${#live_helper_missing[@]}"
    printf '  "saved_memory_preflight_command": %s,\n' "$(json_escape "${saved_memory_preflight_command}")"
    printf '  "linux_build_route_command": %s,\n' "$(json_escape "${linux_build_route_command}")"
    printf '  "runtime_route_command": %s,\n' "$(json_escape "${runtime_route_command}")"
    printf '  "sync_restore_command": %s\n' "$(json_escape "${sync_restore_command}")"
    printf '}\n'
    [[ "${status}" == "blocked" ]] && exit 1
    exit 0
fi

echo "Issue #3 restored checkout surface"
echo
echo "Live helper root:      ${HELPER_ROOT}"
echo "Restored checkout:     ${RESTORED_ROOT}"
echo

for row in "${restored_rows[@]}"; do
    IFS="|" read -r relative_path purpose exists <<<"${row}"
    state="FAIL"
    [[ "${exists}" -eq 1 ]] && state="PASS"
    echo "[${state}] ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Restored helper surface:"
for row in "${restored_helper_rows[@]}"; do
    IFS="|" read -r relative_path purpose exists <<<"${row}"
    state="WARN"
    [[ "${exists}" -eq 1 ]] && state="PASS"
    echo "[${state}] ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Live helper fallback surface:"
for row in "${live_helper_rows[@]}"; do
    IFS="|" read -r relative_path purpose exists <<<"${row}"
    state="FAIL"
    [[ "${exists}" -eq 1 ]] && state="PASS"
    echo "[${state}] ${relative_path}"
    echo "  ${purpose}"
done

echo
case "${status}" in
    ready)
        echo "Status: PASS"
        echo "Mode:   self-contained restored checkout"
        ;;
    ready-with-live-helper-root)
        echo "Status: WARN"
        echo "Mode:   restored checkout is usable, but follow-up helpers still need the live helper root"
        ;;
    *)
        echo "Status: FAIL"
        echo "Mode:   blocked"
        ;;
esac

if [[ -n "${saved_memory_preflight_command}" ]]; then
    echo
    echo "Next commands:"
    echo "  ${saved_memory_preflight_command}"
    echo "  ${linux_build_route_command}"
    echo "  ${runtime_route_command}"
fi

if [[ -n "${sync_restore_command}" ]]; then
    echo
    echo "Optional self-contained restore refresh:"
    echo "  ${sync_restore_command}"
fi

if [[ "${status}" == "blocked" ]]; then
    echo
    echo "The restored checkout is missing required runtime files or no usable helper root is available." >&2
    exit 1
fi
