#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/run_issue3_linux_build_readiness_preflight.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Run the branch-local non-destructive Linux/WSL build-readiness preflight for the
blocked issue #3 runtime lane.

The preflight executes the saved-browser-snapshot, Linux route, Zig recovery,
saved Rust, and offline-inputs surface checkers, then runs the saved-Memory,
archive-integrity, and saved-archive readiness helpers in order.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY2'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY2
}

json_escape() {
    python3 - "$1" <<'PY3'
import json
import sys

print(json.dumps(sys.argv[1]))
PY3
}

normalize_dependencies_root() {
    local root="$1"
    if [[ "$(basename "${root}")" == "dependencies" ]]; then
        printf '%s\n' "${root}"
        return 0
    fi
    printf '%s/dependencies\n' "${root}"
}

headline_for_output() {
    local output_file="$1"
    python3 - "$output_file" <<'PY4'
from pathlib import Path
import sys

for raw_line in Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").splitlines():
    line = raw_line.strip()
    if line:
        print(line)
        break
PY4
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
RUST_TOOLCHAIN_DIR=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
            shift 2
            ;;
        --rust-toolchain-dir)
            RUST_TOOLCHAIN_DIR="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
fi
DEPENDENCIES_ROOT="$(normalize_dependencies_root "${SAVED_ARCHIVES_ROOT}")"
if [[ "$(basename "${SAVED_ARCHIVES_ROOT}")" == "dependencies" ]]; then
    SAVED_ARCHIVES_ROOT="$(dirname "${SAVED_ARCHIVES_ROOT}")"
fi
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(cd "${REPO_ROOT}/.." && pwd)/toolchains/rust-1.79.0"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
SNAPSHOT_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
TOOLCHAIN_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
SAVED_RUST_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
OFFLINE_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_offline_build_inputs_route_surface.sh"
SAVED_MEMORY_INPUTS_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
SAVED_ARCHIVE_INTEGRITY_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py"
READINESS_SCRIPT="${REPO_ROOT}/scripts/check_linux_build_readiness.py"
ROUTE_PRINTER_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"

declare -a STEP_NAMES=(
    "saved-browser-snapshot-route-surface"
    "linux-build-readiness-route-surface"
    "zig-toolchain-recovery-route-surface"
    "saved-rust-route-surface"
    "offline-build-inputs-route-surface"
    "saved-memory-inputs"
    "saved-archive-integrity"
    "saved-archive-readiness"
)

declare -a STEP_PURPOSES=(
    "Fail fast when the saved-browser-snapshot restore route drifted."
    "Fail fast when the Linux build-readiness route drifted."
    "Fail fast when the Zig toolchain recovery route drifted."
    "Fail fast when the saved Rust route drifted."
    "Fail fast when the offline build-inputs route drifted."
    "Verify the saved Memory repo snapshot, notes, blocker file, dependency bundles, and fallback Zig surface."
    "Verify the exact SHA-256 fingerprints of the saved repo snapshot and dependency bundles."
    "Verify saved-archive Linux or WSL readiness before raw Zig output is trusted."
)

declare -a STEP_COMMANDS=(
    "bash $(format_shell_arg "${SNAPSHOT_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    "bash $(format_shell_arg "${ROUTE_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    "bash $(format_shell_arg "${TOOLCHAIN_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    "bash $(format_shell_arg "${SAVED_RUST_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    "bash $(format_shell_arg "${OFFLINE_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    "python $(format_shell_arg "${SAVED_MEMORY_INPUTS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    "python $(format_shell_arg "${SAVED_ARCHIVE_INTEGRITY_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
    "python $(format_shell_arg "${READINESS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${DEPENDENCIES_ROOT}")"
)

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    STEP_COMMANDS[5]+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    STEP_COMMANDS[6]+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    STEP_COMMANDS[7]+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

NEXT_ROUTE_COMMAND="bash $(format_shell_arg "${ROUTE_PRINTER_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    NEXT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

declare -a STEP_STATUSES=()
declare -a STEP_EXIT_CODES=()
declare -a STEP_HEADLINES=()
failures=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

for index in "${!STEP_NAMES[@]}"; do
    name="${STEP_NAMES[$index]}"
    command="${STEP_COMMANDS[$index]}"
    output_file="${tmpdir}/${index}-${name}.log"
    status="PASS"
    exit_code=0
    if bash -lc "${command}" >"${output_file}" 2>&1; then
        status="PASS"
        exit_code=0
    else
        status="FAIL"
        exit_code=$?
        failures=$((failures + 1))
    fi
    headline="$(headline_for_output "${output_file}")"
    STEP_STATUSES+=("${status}")
    STEP_EXIT_CODES+=("${exit_code}")
    STEP_HEADLINES+=("${headline}")
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "issue3-linux-build-readiness-preflight")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "saved_archives_root": %s,\n' "$(json_escape "${SAVED_ARCHIVES_ROOT}")"
    printf '  "dependencies_root": %s,\n' "$(json_escape "${DEPENDENCIES_ROOT}")"
    printf '  "rust_toolchain_dir": %s,\n' "$(json_escape "${RUST_TOOLCHAIN_DIR}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "failure_count": %d,\n' "${failures}"
    printf '  "suggested_next_command": %s,\n' "$(json_escape "${NEXT_ROUTE_COMMAND}")"
    printf '  "steps": [\n'
    for index in "${!STEP_NAMES[@]}"; do
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"name": %s, "purpose": %s, "command": %s, "status": %s, "exit_code": %d, "headline": %s}' \
            "$(json_escape "${STEP_NAMES[$index]}")" \
            "$(json_escape "${STEP_PURPOSES[$index]}")" \
            "$(json_escape "${STEP_COMMANDS[$index]}")" \
            "$(json_escape "${STEP_STATUSES[$index]}")" \
            "${STEP_EXIT_CODES[$index]}" \
            "$(json_escape "${STEP_HEADLINES[$index]}")"
    done
    printf '\n  ]\n'
    printf '}\n'
    if [[ "${failures}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Issue #3 Linux build-readiness preflight"
echo
echo "Repo root:            ${REPO_ROOT}"
echo "Saved archives root:  ${SAVED_ARCHIVES_ROOT}"
echo "Dependencies root:    ${DEPENDENCIES_ROOT}"
echo "Rust toolchain dir:   ${RUST_TOOLCHAIN_DIR}"
echo "Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}"
echo

for index in "${!STEP_NAMES[@]}"; do
    echo "[${STEP_STATUSES[$index]}] ${STEP_NAMES[$index]}"
    echo "  ${STEP_PURPOSES[$index]}"
    echo "  Command: ${STEP_COMMANDS[$index]}"
    if [[ -n "${STEP_HEADLINES[$index]}" ]]; then
        echo "  Headline: ${STEP_HEADLINES[$index]}"
    fi
done

if [[ "${failures}" -gt 0 ]]; then
    echo
    echo "Preflight failures: ${failures}" >&2
    echo "Suggested next step: rerun the first failing command directly and follow its route note before reopening issue #3 runtime work." >&2
    exit 1
fi

echo
echo "All non-destructive Linux build-readiness preflight steps passed."
echo "Suggested next command:"
echo "  ${NEXT_ROUTE_COMMAND}"
