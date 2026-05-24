#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/linux/show_issue3_runtime_reentry_gate_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--zig /path/to/zig] \
    [--json]

Print the compact issue #3 runtime re-entry gate route on one Linux or WSL
surface. This helper does not mutate the checkout. It exists to reopen the
existing `scripts/check_issue3_runtime_reentry_gates.py` checker and the
adjacent restore/build-readiness routes without rebuilding the commands by hand.
EOF
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
RESTORED_CHECKOUT_ROOT=""
ZIG_CMD="zig"
JSON=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --zig)
            ZIG_CMD="$2"
            shift 2
            ;;
        --json)
            JSON=true
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
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi

GATE_CHECKER="${REPO_ROOT}/scripts/check_issue3_runtime_reentry_gates.py"
SNAPSHOT_ROUTE="${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
OFFLINE_ROUTE="${REPO_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh"
RUST_ROUTE="${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
ZIG_ROUTE="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
READINESS_HELPER="${REPO_ROOT}/scripts/check_linux_build_readiness.py"

for required_path in \
    "${GATE_CHECKER}" \
    "${SNAPSHOT_ROUTE}" \
    "${OFFLINE_ROUTE}" \
    "${RUST_ROUTE}" \
    "${ZIG_ROUTE}" \
    "${READINESS_HELPER}"
do
    if [[ ! -f "${required_path}" ]]; then
        echo "Required route helper is missing: ${required_path}" >&2
        exit 1
    fi
done

GATE_COMMAND="python scripts/check_issue3_runtime_reentry_gates.py --repo-root '${REPO_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}' --restored-checkout-root '${RESTORED_CHECKOUT_ROOT}' --zig '${ZIG_CMD}'"
SNAPSHOT_COMMAND="bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root '${REPO_ROOT}' --helper-root '${REPO_ROOT}'"
SNAPSHOT_SYNC_COMMAND="bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root '${REPO_ROOT}' --helper-root '${REPO_ROOT}' --sync-helper-surface"
OFFLINE_COMMAND="bash scripts/linux/show_issue3_offline_build_inputs_route.sh --repo-root '${REPO_ROOT}'"
RUST_COMMAND="bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh --browser-root '${REPO_ROOT}'"
ZIG_COMMAND="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root '${REPO_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}'"
READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root '${REPO_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}' --zig '${ZIG_CMD}' --expect-saved-archives --expect-offline-deps"

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "toolchains_root": %s,\n' "$(json_escape "${TOOLCHAINS_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "zig": %s,\n' "$(json_escape "${ZIG_CMD}")"
    printf '  "gate_check_command": %s,\n' "$(json_escape "${GATE_COMMAND}")"
    printf '  "saved_browser_snapshot_route_command": %s,\n' "$(json_escape "${SNAPSHOT_COMMAND}")"
    printf '  "saved_browser_snapshot_sync_route_command": %s,\n' "$(json_escape "${SNAPSHOT_SYNC_COMMAND}")"
    printf '  "offline_build_inputs_route_command": %s,\n' "$(json_escape "${OFFLINE_COMMAND}")"
    printf '  "saved_rust_toolchain_route_command": %s,\n' "$(json_escape "${RUST_COMMAND}")"
    printf '  "zig_toolchain_recovery_route_command": %s,\n' "$(json_escape "${ZIG_COMMAND}")"
    printf '  "linux_build_readiness_command": %s\n' "$(json_escape "${READINESS_COMMAND}")"
    printf '}\n'
    exit 0
fi

echo "Issue #3 runtime re-entry gate route"
echo "Repo root: ${REPO_ROOT}"
echo "Toolchains root: ${TOOLCHAINS_ROOT}"
echo "Restored checkout root: ${RESTORED_CHECKOUT_ROOT}"
echo
echo "Run these in order:"
echo "1. Gate check"
printf '   %s\n' "${GATE_COMMAND}"
echo "2. Saved browser snapshot route"
printf '   %s\n' "${SNAPSHOT_COMMAND}"
echo "3. Saved browser snapshot synced helper-surface route"
printf '   %s\n' "${SNAPSHOT_SYNC_COMMAND}"
echo "4. Offline build inputs route"
printf '   %s\n' "${OFFLINE_COMMAND}"
echo "5. Saved Rust toolchain route"
printf '   %s\n' "${RUST_COMMAND}"
echo "6. Zig toolchain recovery route"
printf '   %s\n' "${ZIG_COMMAND}"
echo "7. Linux build readiness route"
printf '   %s\n' "${READINESS_COMMAND}"
