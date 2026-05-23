#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_restored_checkout_route.sh \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-root /path/to/restored/browser-checkout] \
    [--json]

Print the smallest issue #3 Linux or WSL follow-up route for an already
restored browser snapshot checkout.
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
    "build.zig.zon"
    "src/browser/Page.zig"
    "src/display/win32_backend.zig"
)

declare -a REQUIRED_HELPER_FILES=(
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
)

restored_exists=0
[[ -d "${RESTORED_ROOT}" ]] && restored_exists=1

restored_missing=0
for relative_path in "${REQUIRED_RESTORED_FILES[@]}"; do
    [[ -f "${RESTORED_ROOT}/${relative_path}" ]] || restored_missing=$((restored_missing + 1))
done

restored_helper_missing=0
for relative_path in "${REQUIRED_HELPER_FILES[@]}"; do
    [[ -f "${RESTORED_ROOT}/${relative_path}" ]] || restored_helper_missing=$((restored_helper_missing + 1))
done

live_helper_missing=0
for relative_path in "${REQUIRED_HELPER_FILES[@]}"; do
    [[ -f "${HELPER_ROOT}/${relative_path}" ]] || live_helper_missing=$((live_helper_missing + 1))
done

surface_check_command="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_surface.sh") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-root $(format_shell_arg "${RESTORED_ROOT}")"
restore_surface_check_command="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${HELPER_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_ROOT}") --check-only"
restore_command="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${HELPER_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_ROOT}")"
sync_refresh_check_command="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${HELPER_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_ROOT}") --sync-helper-surface --check-only"
sync_refresh_command="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${HELPER_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_ROOT}") --sync-helper-surface --force"

status="blocked"
follow_up_mode="blocked"
follow_up_helper_root=""

if [[ "${restored_exists}" -eq 1 && "${restored_missing}" -eq 0 ]]; then
    if [[ "${restored_helper_missing}" -eq 0 ]]; then
        status="ready"
        follow_up_mode="self-contained"
        follow_up_helper_root="${RESTORED_ROOT}"
    elif [[ "${live_helper_missing}" -eq 0 ]]; then
        status="ready"
        follow_up_mode="live-helper-root"
        follow_up_helper_root="${HELPER_ROOT}"
    fi
fi

saved_memory_preflight_command=""
linux_build_route_command=""
runtime_route_command=""
if [[ -n "${follow_up_helper_root}" ]]; then
    saved_memory_preflight_command="python $(format_shell_arg "${follow_up_helper_root}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
    linux_build_route_command="bash $(format_shell_arg "${follow_up_helper_root}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
    runtime_route_command="bash $(format_shell_arg "${follow_up_helper_root}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-restored-checkout-route")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "restored_root": %s,\n' "$(json_escape "${RESTORED_ROOT}")"
    printf '  "restored_checkout_exists": %s,\n' "$([[ "${restored_exists}" -eq 1 ]] && echo true || echo false)"
    printf '  "restored_missing_count": %d,\n' "${restored_missing}"
    printf '  "restored_helper_missing_count": %d,\n' "${restored_helper_missing}"
    printf '  "live_helper_missing_count": %d,\n' "${live_helper_missing}"
    printf '  "status": %s,\n' "$(json_escape "${status}")"
    printf '  "follow_up_mode": %s,\n' "$(json_escape "${follow_up_mode}")"
    printf '  "follow_up_helper_root": %s,\n' "$(json_escape "${follow_up_helper_root}")"
    printf '  "commands": {\n'
    printf '    "surface_check": %s,\n' "$(json_escape "${surface_check_command}")"
    printf '    "restore_surface_check": %s,\n' "$(json_escape "${restore_surface_check_command}")"
    printf '    "restore": %s,\n' "$(json_escape "${restore_command}")"
    printf '    "sync_refresh_surface_check": %s,\n' "$(json_escape "${sync_refresh_check_command}")"
    printf '    "sync_refresh": %s,\n' "$(json_escape "${sync_refresh_command}")"
    printf '    "saved_memory_preflight": %s,\n' "$(json_escape "${saved_memory_preflight_command}")"
    printf '    "linux_build_route": %s,\n' "$(json_escape "${linux_build_route_command}")"
    printf '    "runtime_route": %s\n' "$(json_escape "${runtime_route_command}")"
    printf '  }\n'
    printf '}\n'
    [[ "${status}" == "ready" ]] && exit 0
    exit 1
fi

cat <<EOF
Issue #3 restored checkout reuse route

Live helper root:  ${HELPER_ROOT}
Restored checkout: ${RESTORED_ROOT}

Recommended first check
=======================
  ${surface_check_command}
EOF

if [[ "${status}" == "ready" ]]; then
    cat <<EOF

Ready state
===========
  Mode: ${follow_up_mode}

Suggested follow-up commands
============================
  ${saved_memory_preflight_command}
  ${linux_build_route_command}
  ${runtime_route_command}
EOF

    if [[ "${follow_up_mode}" == "live-helper-root" ]]; then
        cat <<EOF

Optional self-contained refresh
===============================
  Surface check:
    ${sync_refresh_check_command}
  Refresh the restored checkout with the current helper surface:
    ${sync_refresh_command}
EOF
    fi

    exit 0
fi

cat <<EOF

Restore path
============
  Surface check:
    ${restore_surface_check_command}
  Restore the saved snapshot:
    ${restore_command}

If the restored checkout already exists but still lacks the current helper surface,
refresh it as a self-contained checkout:
  Surface check:
    ${sync_refresh_check_command}
  Refresh command:
    ${sync_refresh_command}
EOF

exit 1
