#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/bootstrap_issue3_saved_build_workspace.sh \
    [--browser-root /path/to/live/browser-repo] \
    [--target-repo-root /path/to/repo-to-stage] \
    [--snapshot-destination /path/to/restored/browser-memory-snapshot] \
    [--dependencies-root /path/to/memory/repo_archives/browser/dependencies] \
    [--toolchain-root /path/to/toolchains/rust-1.79.0] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--zig /path/to/zig] \
    [--restore-snapshot-first] \
    [--force-restore] \
    [--check-only] \
    [--json]

Bootstrap the saved-archive-first Linux or WSL workspace used by the blocked
issue #3 Enter-submit runtime lane. The helper can optionally restore the saved
repo snapshot, reuse the saved Rust 1.79.0 toolchain, stage the offline sibling
dependencies, and rerun the Linux build-readiness helper from one command.

Defaults:
  browser root          parent of this script
  target repo root      browser root
  snapshot destination  <browser-root>/../browser-memory-snapshot
  dependencies root     <browser-root>/../memory/repo_archives/browser/dependencies
  toolchain root        <browser-root>/../toolchains/rust-1.79.0
  fallback Zig archive  <browser-root>/../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz

Use --restore-snapshot-first when the staging target should be a disposable
checkout restored from the saved Memory snapshot before the Rust and offline
dependency helpers run.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

run_and_log() {
    local label="$1"
    shift
    echo
    echo "==> ${label}"
    "$@"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
TARGET_REPO_ROOT=""
SNAPSHOT_DESTINATION=""
DEPENDENCIES_ROOT=""
TOOLCHAIN_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
ZIG_BIN=""
RESTORE_SNAPSHOT_FIRST=false
FORCE_RESTORE=false
CHECK_ONLY=false
JSON=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --target-repo-root)
            TARGET_REPO_ROOT="$2"
            shift 2
            ;;
        --snapshot-destination)
            SNAPSHOT_DESTINATION="$2"
            shift 2
            ;;
        --dependencies-root)
            DEPENDENCIES_ROOT="$2"
            shift 2
            ;;
        --toolchain-root)
            TOOLCHAIN_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --zig)
            ZIG_BIN="$2"
            shift 2
            ;;
        --restore-snapshot-first)
            RESTORE_SNAPSHOT_FIRST=true
            shift
            ;;
        --force-restore)
            FORCE_RESTORE=true
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
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

BROWSER_ROOT="$(cd "${BROWSER_ROOT}" && pwd)"
WORKSPACE_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
if [[ -z "${SNAPSHOT_DESTINATION}" ]]; then
    SNAPSHOT_DESTINATION="${WORKSPACE_ROOT}/browser-memory-snapshot"
fi
if [[ -z "${TARGET_REPO_ROOT}" ]]; then
    if [[ "${RESTORE_SNAPSHOT_FIRST}" == "true" ]]; then
        TARGET_REPO_ROOT="${SNAPSHOT_DESTINATION}"
    else
        TARGET_REPO_ROOT="${BROWSER_ROOT}"
    fi
fi
if [[ -z "${DEPENDENCIES_ROOT}" ]]; then
    DEPENDENCIES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${TOOLCHAIN_ROOT}" ]]; then
    TOOLCHAIN_ROOT="${WORKSPACE_ROOT}/toolchains/rust-1.79.0"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

REQUIRED_HELPERS=(
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/check_linux_build_readiness.py"
    "scripts/linux/restore_saved_browser_snapshot.sh"
    "scripts/linux/restore_saved_rust_toolchain.sh"
    "scripts/linux/prepare_offline_build_inputs.sh"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
)

for helper_path in "${REQUIRED_HELPERS[@]}"; do
    if [[ ! -f "${BROWSER_ROOT}/${helper_path}" ]]; then
        echo "Helper root is missing ${helper_path}: ${BROWSER_ROOT}" >&2
        exit 1
    fi
done

BROWSER_ARCHIVE="${WORKSPACE_ROOT}/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
BROWSER_DEPS_ARCHIVE="${DEPENDENCIES_ROOT}/04-zig-browser-depo.tar.zip"
BORINGSSL_ARCHIVE="${DEPENDENCIES_ROOT}/03-boringssl-zig-main.zip"
HTML5EVER_ARCHIVE="${DEPENDENCIES_ROOT}/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
OFFLINE_DEPS_ROOT="$(cd "$(dirname "${TARGET_REPO_ROOT}")" && pwd)/offline-deps"

RESTORE_SNAPSHOT_COMMAND=(
    bash "${BROWSER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh"
    --browser-root "${BROWSER_ROOT}"
    --helper-root "${BROWSER_ROOT}"
    --destination "${SNAPSHOT_DESTINATION}"
)
if [[ "${FORCE_RESTORE}" == "true" ]]; then
    RESTORE_SNAPSHOT_COMMAND+=(--force)
fi

MEMORY_CHECK_COMMAND=(
    python "${BROWSER_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
    --repo-root "${TARGET_REPO_ROOT}"
)
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    MEMORY_CHECK_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

RUST_RESTORE_COMMAND=(
    bash "${BROWSER_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh"
    --browser-root "${TARGET_REPO_ROOT}"
    --dependencies-root "${DEPENDENCIES_ROOT}"
    --toolchain-root "${TOOLCHAIN_ROOT}"
)

PREPARE_COMMAND=(
    bash "${BROWSER_ROOT}/scripts/linux/prepare_offline_build_inputs.sh"
    --browser-root "${TARGET_REPO_ROOT}"
    --browser-deps-archive "${BROWSER_DEPS_ARCHIVE}"
    --boringssl-archive "${BORINGSSL_ARCHIVE}"
    --html5ever-archive "${HTML5EVER_ARCHIVE}"
)

READINESS_COMMAND=(
    python "${BROWSER_ROOT}/scripts/check_linux_build_readiness.py"
    --repo-root "${TARGET_REPO_ROOT}"
    --expect-saved-archives
    --saved-archives-root "${DEPENDENCIES_ROOT}"
    --expect-offline-deps
    --offline-deps-root "${OFFLINE_DEPS_ROOT}"
    --require-prebuilt-v8
)
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    READINESS_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi
if [[ -n "${ZIG_BIN}" ]]; then
    READINESS_COMMAND+=(--zig "${ZIG_BIN}")
else
    READINESS_COMMAND+=(--skip-zig-check)
fi

ZIG_ROUTE_COMMAND=(
    bash "${BROWSER_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    --repo-root "${TARGET_REPO_ROOT}"
    --saved-archives-root "${DEPENDENCIES_ROOT}"
    --offline-deps-root "${OFFLINE_DEPS_ROOT}"
)
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    ZIG_ROUTE_COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

RUNTIME_ROUTE_COMMAND=(
    bash "${BROWSER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    --repo-root "${TARGET_REPO_ROOT}"
)

restore_snapshot_command_text=""
if [[ "${RESTORE_SNAPSHOT_FIRST}" == "true" ]]; then
    restore_snapshot_command_text="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${BROWSER_ROOT}") --helper-root $(format_shell_arg "${BROWSER_ROOT}") --destination $(format_shell_arg "${SNAPSHOT_DESTINATION}")"
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        restore_snapshot_command_text+=" --force"
    fi
fi
memory_check_command_text="python $(format_shell_arg "${BROWSER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${TARGET_REPO_ROOT}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    memory_check_command_text+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi
rust_restore_command_text="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh") --browser-root $(format_shell_arg "${TARGET_REPO_ROOT}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}")"
prepare_command_text="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/prepare_offline_build_inputs.sh") --browser-root $(format_shell_arg "${TARGET_REPO_ROOT}") --browser-deps-archive $(format_shell_arg "${BROWSER_DEPS_ARCHIVE}") --boringssl-archive $(format_shell_arg "${BORINGSSL_ARCHIVE}") --html5ever-archive $(format_shell_arg "${HTML5EVER_ARCHIVE}")"
readiness_command_text="python $(format_shell_arg "${BROWSER_ROOT}/scripts/check_linux_build_readiness.py") --repo-root $(format_shell_arg "${TARGET_REPO_ROOT}") --expect-saved-archives --saved-archives-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --expect-offline-deps --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}") --require-prebuilt-v8"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    readiness_command_text+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi
if [[ -n "${ZIG_BIN}" ]]; then
    readiness_command_text+=" --zig $(format_shell_arg "${ZIG_BIN}")"
else
    readiness_command_text+=" --skip-zig-check"
fi
zig_route_command_text="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${TARGET_REPO_ROOT}") --saved-archives-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    zig_route_command_text+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi
runtime_route_command_text="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${TARGET_REPO_ROOT}")"

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 saved build workspace bootstrap")"
    printf '  "browser_root": %s,\n' "$(json_escape "${BROWSER_ROOT}")"
    printf '  "target_repo_root": %s,\n' "$(json_escape "${TARGET_REPO_ROOT}")"
    printf '  "snapshot_destination": %s,\n' "$(json_escape "${SNAPSHOT_DESTINATION}")"
    printf '  "dependencies_root": %s,\n' "$(json_escape "${DEPENDENCIES_ROOT}")"
    printf '  "toolchain_root": %s,\n' "$(json_escape "${TOOLCHAIN_ROOT}")"
    printf '  "offline_deps_root": %s,\n' "$(json_escape "${OFFLINE_DEPS_ROOT}")"
    printf '  "browser_archive": %s,\n' "$(json_escape "${BROWSER_ARCHIVE}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "zig_bin": %s,\n' "$(json_escape "${ZIG_BIN}")"
    printf '  "restore_snapshot_first": %s,\n' "$([[ "${RESTORE_SNAPSHOT_FIRST}" == "true" ]] && echo true || echo false)"
    printf '  "force_restore": %s,\n' "$([[ "${FORCE_RESTORE}" == "true" ]] && echo true || echo false)"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '  "commands": {\n'
    printf '    "restore_snapshot": %s,\n' "$(json_escape "${restore_snapshot_command_text}")"
    printf '    "saved_memory_preflight": %s,\n' "$(json_escape "${memory_check_command_text}")"
    printf '    "restore_rust_toolchain": %s,\n' "$(json_escape "${rust_restore_command_text}")"
    printf '    "prepare_offline_inputs": %s,\n' "$(json_escape "${prepare_command_text}")"
    printf '    "readiness_check": %s,\n' "$(json_escape "${readiness_command_text}")"
    printf '    "zig_route": %s,\n' "$(json_escape "${zig_route_command_text}")"
    printf '    "runtime_route": %s\n' "$(json_escape "${runtime_route_command_text}")"
    printf '  }\n'
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Issue #3 saved build workspace bootstrap surface check"
    echo
    echo "Browser root:         ${BROWSER_ROOT}"
    echo "Target repo root:     ${TARGET_REPO_ROOT}"
    echo "Snapshot destination: ${SNAPSHOT_DESTINATION}"
    echo "Dependencies root:    ${DEPENDENCIES_ROOT}"
    echo "Toolchain root:       ${TOOLCHAIN_ROOT}"
    echo "Offline deps root:    ${OFFLINE_DEPS_ROOT}"
    echo "Browser archive:      ${BROWSER_ARCHIVE}"
    echo "Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}"
    echo
    echo "Suggested route:"
    if [[ "${RESTORE_SNAPSHOT_FIRST}" == "true" ]]; then
        echo "  Restore snapshot first:"
        echo "    ${restore_snapshot_command_text}"
        echo
    fi
    echo "  Saved Memory preflight:"
    echo "    ${memory_check_command_text}"
    echo
    echo "  Restore saved Rust toolchain:"
    echo "    ${rust_restore_command_text}"
    echo
    echo "  Stage offline build inputs:"
    echo "    ${prepare_command_text}"
    echo
    echo "  Rerun Linux readiness:"
    echo "    ${readiness_command_text}"
    echo
    echo "  If Zig still needs attention:"
    echo "    ${zig_route_command_text}"
    echo
    echo "  When the environment is ready, hand back to the runtime route:"
    echo "    ${runtime_route_command_text}"
    exit 0
fi

if [[ "${RESTORE_SNAPSHOT_FIRST}" == "true" ]]; then
    run_and_log "Restore saved browser snapshot" "${RESTORE_SNAPSHOT_COMMAND[@]}"
fi
run_and_log "Saved Memory preflight" "${MEMORY_CHECK_COMMAND[@]}"
run_and_log "Restore saved Rust toolchain" "${RUST_RESTORE_COMMAND[@]}"
run_and_log "Prepare offline build inputs" "${PREPARE_COMMAND[@]}"
run_and_log "Linux build-readiness check" "${READINESS_COMMAND[@]}"

echo
echo "Issue #3 saved build workspace bootstrap completed."
echo "Target repo root: ${TARGET_REPO_ROOT}"
echo "Offline deps root: ${OFFLINE_DEPS_ROOT}"
echo
echo "Next routes:"
echo "  Zig toolchain recovery:"
echo "    ${zig_route_command_text}"
echo "  Runtime revalidation:"
echo "    ${runtime_route_command_text}"
