#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_linux_reentry_stack_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Run the issue #3 Linux/WSL re-entry surface checks as one fail-fast stack so a
rerun can confirm the saved-browser-snapshot, Zig line, saved Rust, offline
inputs, Linux readiness, and direct runtime helper surfaces stay aligned before
it reopens focused validation.
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

declare -a SURFACE_SCRIPTS=(
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|saved-browser-snapshot"
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|zig-toolchain-recovery"
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|saved-rust-toolchain"
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|offline-build-inputs"
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|linux-build-readiness"
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|enter-submit-runtime"
)

surface_rows=()
failure_count=0

for entry in "${SURFACE_SCRIPTS[@]}"; do
    IFS="|" read -r relative_path label <<<"${entry}"
    script_path="${REPO_ROOT}/${relative_path}"
    exists=0
    exit_code=1
    missing_count=""
    profile=""
    if [[ -f "${script_path}" ]]; then
        exists=1
        if output="$(bash "${script_path}" --repo-root "${REPO_ROOT}" --json 2>&1)"; then
            exit_code=0
        else
            exit_code=$?
        fi
        if [[ -n "${output}" ]]; then
            missing_count="$(python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("missing_count",""))' <<<"${output}" 2>/dev/null || true)"
            profile="$(python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("profile",""))' <<<"${output}" 2>/dev/null || true)"
        fi
    fi

    if [[ "${exists}" -eq 0 || "${exit_code}" -ne 0 ]]; then
        failure_count=$((failure_count + 1))
    fi
    surface_rows+=("${relative_path}|${label}|${exists}|${exit_code}|${missing_count}|${profile}")
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-linux-reentry-stack-surface")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "surface_count": %d,\n' "${#surface_rows[@]}"
    printf '  "failure_count": %d,\n' "${failure_count}"
    printf '  "surfaces": [\n'
    for index in "${!surface_rows[@]}"; do
        IFS="|" read -r relative_path label exists exit_code missing_count profile <<<"${surface_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"path": %s, "label": %s, "exists": %s, "exit_code": %s, "missing_count": %s, "profile": %s}' \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${label}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)" \
            "${exit_code}" \
            "${missing_count:-null}" \
            "$(json_escape "${profile}")"
    done
    printf '\n  ]\n'
    printf '}\n'
    if [[ "${failure_count}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Issue #3 Linux re-entry stack surface check"
echo
echo "Repo root: ${REPO_ROOT}"
echo

for row in "${surface_rows[@]}"; do
    IFS="|" read -r relative_path label exists exit_code missing_count profile <<<"${row}"
    status="FAIL"
    if [[ "${exists}" -eq 1 && "${exit_code}" -eq 0 ]]; then
        status="PASS"
    elif [[ "${exists}" -eq 1 && "${exit_code}" -eq 1 ]]; then
        status="DRIFT"
    fi
    echo "[${status}] ${label}"
    echo "  ${relative_path}"
    if [[ "${exists}" -eq 0 ]]; then
        echo "  Missing surface script."
    else
        echo "  Exit code: ${exit_code}"
        if [[ -n "${missing_count}" ]]; then
            echo "  Missing checks: ${missing_count}"
        fi
        if [[ -n "${profile}" ]]; then
            echo "  Profile: ${profile}"
        fi
    fi
done

if [[ "${failure_count}" -gt 0 ]]; then
    echo
    echo "Surface stack failures: ${failure_count}"
    exit 1
fi

echo
echo "All issue #3 Linux re-entry surfaces are aligned."
