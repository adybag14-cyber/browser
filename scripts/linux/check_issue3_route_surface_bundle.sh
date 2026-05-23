#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_route_surface_bundle.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Run the branch-local issue #3 Linux or WSL recovery route surface checks
together so a rerun can fail fast before it reopens the saved browser snapshot
restore, Zig toolchain recovery, Linux build-readiness, or direct runtime
revalidation paths.
EOF
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

SNAPSHOT_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_RECOVERY_SURFACE_COMMAND="bash scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_READINESS_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
RUNTIME_REVALIDATION_SURFACE_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"

declare -a CHECKS=(
    "saved-browser-snapshot|Saved-browser-snapshot restore route surface.|${SNAPSHOT_SURFACE_COMMAND}"
    "zig-toolchain-recovery|Zig toolchain recovery route surface.|${ZIG_RECOVERY_SURFACE_COMMAND}"
    "linux-build-readiness|Linux build-readiness route surface.|${BUILD_READINESS_SURFACE_COMMAND}"
    "runtime-revalidation|Direct runtime revalidation route surface.|${RUNTIME_REVALIDATION_SURFACE_COMMAND}"
)

results=()
failure_count=0

for entry in "${CHECKS[@]}"; do
    IFS='|' read -r name purpose command <<<"${entry}"
    if eval "${command}" >/dev/null 2>&1; then
        ok=1
    else
        ok=0
        failure_count=$((failure_count + 1))
    fi
    results+=("${name}|${purpose}|${command}|${ok}")
done

if [[ "${JSON}" -eq 1 ]]; then
    python3 - "${REPO_ROOT}" "${failure_count}" "${results[@]}" <<'PY'
from __future__ import annotations

import json
import sys

repo_root = sys.argv[1]
failure_count = int(sys.argv[2])
checks = []
for raw in sys.argv[3:]:
    name, purpose, command, ok = raw.split("|", 3)
    checks.append(
        {
            "name": name,
            "purpose": purpose,
            "command": command,
            "ok": ok == "1",
        }
    )

print(
    json.dumps(
        {
            "profile": "issue3-route-surface-bundle",
            "repo_root": repo_root,
            "failure_count": failure_count,
            "checks": checks,
        },
        indent=2,
    )
)
PY
    if [[ "${failure_count}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Issue #3 Linux or WSL recovery route bundle surface check"
echo
echo "Repo root: ${REPO_ROOT}"
echo

for row in "${results[@]}"; do
    IFS='|' read -r name purpose command ok <<<"${row}"
    status="FAIL"
    [[ "${ok}" == "1" ]] && status="PASS"
    echo "[${status}] ${name}"
    echo "  ${purpose}"
    echo "  ${command}"
done

if [[ "${failure_count}" -gt 0 ]]; then
    echo
    echo "Failing surfaces: ${failure_count}"
    echo "Rerun the failing surface check directly for detailed output."
    exit 1
fi

echo
echo "All issue #3 Linux or WSL recovery route surfaces are present."
