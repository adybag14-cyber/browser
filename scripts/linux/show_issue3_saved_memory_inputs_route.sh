#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_memory_inputs_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/helper/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--agent-files-root /path/to/agent_files] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--skip-archive-integrity-check] \
    [--json]

Print the saved-Memory-inputs route for the blocked issue #3 Linux or WSL
re-entry path.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

has_live_helper_surface() {
    local candidate="$1"
    [[ -d "${candidate}" ]] || return 1
    [[ -f "${candidate}/build.zig.zon" ]] || return 1
    [[ -f "${candidate}/scripts/check_issue3_saved_memory_inputs.py" ]] || return 1
    [[ -f "${candidate}/scripts/linux/show_issue3_saved_memory_inputs_route.sh" ]] || return 1
}

find_first_existing_ancestor_dir() {
    local start="$1"
    local relative_dir="$2"
    local current candidate

    current="$(cd "${start}" && pwd)"
    while true; do
        candidate="${current}/${relative_dir}"
        if [[ -d "${candidate}" ]]; then
            cd "${candidate}" && pwd
            return 0
        fi
        if [[ "${current}" == "/" ]]; then
            break
        fi
        current="$(dirname "${current}")"
    done
    return 1
}

find_first_live_helper_surface() {
    local start="$1"
    local current

    current="$(cd "${start}" && pwd)"
    while true; do
        if has_live_helper_surface "${current}"; then
            printf '%s\n' "${current}"
            return 0
        fi
        if [[ "${current}" == "/" ]]; then
            break
        fi
        current="$(dirname "${current}")"
    done
    return 1
}

find_live_helper_surface_among_siblings() {
    local start="$1"
    local current parent child

    current="$(cd "${start}" && pwd)"
    while true; do
        parent="$(dirname "${current}")"
        if [[ "${parent}" == "${current}" ]]; then
            break
        fi
        while IFS= read -r child; do
            [[ -d "${child}" ]] || continue
            [[ "${child}" == "${current}" ]] && continue
            if has_live_helper_surface "${child}"; then
                printf '%s\n' "${child}"
                return 0
            fi
        done < <(find "${parent}" -mindepth 1 -maxdepth 1 -type d | sort)
        current="${parent}"
    done
    return 1
}

resolve_default_helper_root() {
    local repo_root="$1"
    local cwd helper_candidate script_repo_root

    repo_root="$(cd "${repo_root}" && pwd)"
    cwd="$(pwd)"
    script_repo_root="$(cd "${DEFAULT_REPO_ROOT}" && pwd)"
    if [[ "$(basename "${repo_root}")" == "${DEFAULT_RESTORED_CHECKOUT_NAME}" ]]; then
        if [[ "${script_repo_root}" != "${repo_root}" ]] && has_live_helper_surface "${script_repo_root}"; then
            printf '%s\n' "${script_repo_root}"
            return 0
        fi
        if [[ "${cwd}" != "${repo_root}" ]]; then
            helper_candidate="$(find_first_live_helper_surface "${cwd}" || true)"
            if [[ -n "${helper_candidate}" && "${helper_candidate}" != "${repo_root}" ]]; then
                printf '%s\n' "${helper_candidate}"
                return 0
            fi
        fi
        helper_candidate="$(find_live_helper_surface_among_siblings "${repo_root}" || true)"
        if [[ -n "${helper_candidate}" ]]; then
            printf '%s\n' "${helper_candidate}"
            return 0
        fi
    fi
    printf '%s\n' "${repo_root}"
}

resolve_discovered_or_default_root() {
    local start="$1"
    local relative_dir="$2"
    local fallback_root="$3"
    local discovered_root

    discovered_root="$(find_first_existing_ancestor_dir "${start}" "${relative_dir}" || true)"
    if [[ -n "${discovered_root}" ]]; then
        printf '%s\n' "${discovered_root}"
        return 0
    fi
    printf '%s\n' "${fallback_root}"
}

resolve_toolchains_root() {
    local start="$1"
    local fallback_root="$2"
    local discovered_root

    discovered_root="$(find_first_existing_ancestor_dir "${start}" ".toolchains" || true)"
    if [[ -n "${discovered_root}" ]]; then
        printf '%s\n' "${discovered_root}"
        return 0
    fi

    discovered_root="$(find_first_existing_ancestor_dir "${start}" "toolchains" || true)"
    if [[ -n "${discovered_root}" ]]; then
        printf '%s\n' "${discovered_root}"
        return 0
    fi

    printf '%s\n' "${fallback_root}"
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
AGENT_FILES_ROOT=""
RESTORED_CHECKOUT_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
SKIP_ARCHIVE_INTEGRITY_CHECK=0
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
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --agent-files-root)
            AGENT_FILES_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --skip-archive-integrity-check)
            SKIP_ARCHIVE_INTEGRITY_CHECK=1
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
    HELPER_ROOT="$(resolve_default_helper_root "${REPO_ROOT}")"
else
    HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
fi
HELPER_WORKSPACE_ROOT="$(cd "${HELPER_ROOT}/.." && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(resolve_discovered_or_default_root "${HELPER_ROOT}" "memory" "${HELPER_WORKSPACE_ROOT}/memory")"
fi
if [[ -z "${AGENT_FILES_ROOT}" ]]; then
    AGENT_FILES_ROOT="$(resolve_discovered_or_default_root "${HELPER_ROOT}" "agent_files" "${HELPER_WORKSPACE_ROOT}/agent_files")"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    if [[ "$(basename "${REPO_ROOT}")" == "${DEFAULT_RESTORED_CHECKOUT_NAME}" ]]; then
        RESTORED_CHECKOUT_ROOT="${REPO_ROOT}"
    else
        RESTORED_CHECKOUT_ROOT="$(resolve_discovered_or_default_root "${REPO_ROOT}" "${DEFAULT_RESTORED_CHECKOUT_NAME}" "$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}")"
    fi
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

REPO_SNAPSHOT_PATH="${MEMORY_ROOT}/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
BLOCKER_INTELLIGENCE_PATH="${MEMORY_ROOT}/repo_archives/browser/blocker_intelligence.yaml"
DEPENDENCIES_ROOT="${MEMORY_ROOT}/repo_archives/browser/dependencies"
SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
TOOLCHAINS_ROOT="$(resolve_toolchains_root "${HELPER_ROOT}" "${HELPER_WORKSPACE_ROOT}/.toolchains")"
RUST_TOOLCHAIN_DIR="${TOOLCHAINS_ROOT}/rust-1.79.0"
OFFLINE_DEPS_ROOT="$(resolve_discovered_or_default_root "${HELPER_ROOT}" "offline-deps" "${HELPER_WORKSPACE_ROOT}/offline-deps")"
PROGRESS_TRACKER_ROUTE_PATH="${HELPER_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
WORKSPACE_CONTEXT_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_workspace_context_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
WORKSPACE_CONTEXT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_workspace_context_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
WORKSPACE_CONTEXT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_workspace_context.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
NESTED_WORKSPACE_RUNNER_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_INPUT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --agent-files-root $(format_shell_arg "${AGENT_FILES_ROOT}")"
QUICK_SAVED_INPUT_COMMAND="${SAVED_INPUT_COMMAND} --skip-archive-integrity-check"
RESTORED_SAVED_INPUT_COMMAND="${SAVED_INPUT_COMMAND} --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
LIVE_HELPER_RESTORED_CHECKOUT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --agent-files-root $(format_shell_arg "${AGENT_FILES_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_HELPER_SURFACE_SYNC_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_restored_helper_surface_sync_route.sh") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}")"
ISSUE11_SAVED_MEMORY_HELPER_SURFACE_INVENTORY_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue11_saved_memory_helper_surface_inventory.py") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
ISSUE11_SAVED_MEMORY_HELPER_CONTRACT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue11_saved_memory_helper_contract.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
ISSUE11_REENTRY_INVENTORY_CONSISTENCY_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue11_reentry_inventory_consistency.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --agent-files-root $(format_shell_arg "${AGENT_FILES_ROOT}")"
SAVED_ZIG_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    WORKSPACE_CONTEXT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    NESTED_WORKSPACE_RUNNER_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_INPUT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    QUICK_SAVED_INPUT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_SAVED_INPUT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LIVE_HELPER_RESTORED_CHECKOUT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ZIG_ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

NESTED_WORKSPACE_RUNNER_QUICK_COMMAND="${NESTED_WORKSPACE_RUNNER_COMMAND} --skip-archive-integrity-check"

if [[ "${SKIP_ARCHIVE_INTEGRITY_CHECK}" -eq 1 ]]; then
    NESTED_WORKSPACE_RUNNER_COMMAND+=" --skip-archive-integrity-check"
    SAVED_INPUT_COMMAND+=" --skip-archive-integrity-check"
    RESTORED_SAVED_INPUT_COMMAND+=" --skip-archive-integrity-check"
    LIVE_HELPER_RESTORED_CHECKOUT_COMMAND+=" --skip-archive-integrity-check"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Memory inputs route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "agent_files_root": ${AGENT_FILES_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "repo_snapshot_path": ${REPO_SNAPSHOT_PATH@Q},
    "blocker_intelligence_path": ${BLOCKER_INTELLIGENCE_PATH@Q},
    "dependencies_root": ${DEPENDENCIES_ROOT@Q},
    "progress_tracker_route_path": ${PROGRESS_TRACKER_ROUTE_PATH@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "skip_archive_integrity_check": ${SKIP_ARCHIVE_INTEGRITY_CHECK},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "workspace_context_route_surface": ${WORKSPACE_CONTEXT_ROUTE_SURFACE_COMMAND@Q},
        "workspace_context_route": ${WORKSPACE_CONTEXT_ROUTE_COMMAND@Q},
        "workspace_context": ${WORKSPACE_CONTEXT_COMMAND@Q},
        "nested_workspace_saved_memory_preflight": ${NESTED_WORKSPACE_RUNNER_COMMAND@Q},
        "quick_nested_workspace_saved_memory_preflight": ${NESTED_WORKSPACE_RUNNER_QUICK_COMMAND@Q},
        "saved_input_preflight": ${SAVED_INPUT_COMMAND@Q},
        "quick_saved_input_preflight": ${QUICK_SAVED_INPUT_COMMAND@Q},
        "restored_checkout_saved_input_preflight": ${RESTORED_SAVED_INPUT_COMMAND@Q},
        "restored_helper_surface_sync_route": ${RESTORED_HELPER_SURFACE_SYNC_ROUTE_COMMAND@Q},
        "issue11_saved_memory_helper_surface_inventory": ${ISSUE11_SAVED_MEMORY_HELPER_SURFACE_INVENTORY_COMMAND@Q},
        "issue11_saved_memory_helper_contract": ${ISSUE11_SAVED_MEMORY_HELPER_CONTRACT_COMMAND@Q},
        "issue11_reentry_inventory_consistency": ${ISSUE11_REENTRY_INVENTORY_CONSISTENCY_COMMAND@Q},
        "live_helper_restored_checkout_preflight": ${LIVE_HELPER_RESTORED_CHECKOUT_COMMAND@Q},
        "saved_archive_integrity_route": ${SAVED_ARCHIVE_INTEGRITY_ROUTE_COMMAND@Q},
        "saved_zig_archive_candidates_route": ${SAVED_ZIG_ARCHIVE_ROUTE_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_ROUTE_COMMAND@Q},
        "runtime_reentry_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so helper drift fails fast before the saved archive inputs are blamed.",
        "When the checkout sits deeper than the default sibling layout, run workspace_context_route_surface, workspace_context_route, and workspace_context before trusting saved_input_preflight defaults.",
        "When the workspace-context output already identifies the right shared roots and the next step is just rerunning the saved-memory preflight with those surfaced paths, prefer nested_workspace_saved_memory_preflight instead of rebuilding overrides by hand.",
        "Use quick_nested_workspace_saved_memory_preflight only for a fast branch decision when archive integrity is not the question but the surfaced roots still need to stay honest.",
        "Use saved_input_preflight for the normal archive readability and presence check.",
        "Use quick_saved_input_preflight only for a fast branch decision when archive integrity is not the question.",
        "Use restored_checkout_saved_input_preflight when a reusable checkout already exists and the route should confirm both saved inputs and the restored helper surface together.",
        "Use restored_helper_surface_sync_route before the issue #11 contract checks and the live-helper restored-checkout preflight when the extracted snapshot may lag the live issue #11 helper surface or is missing the newer helper-sync route files.",
        "Use issue11_saved_memory_helper_surface_inventory when the route itself needs focused proof that the explicit saved-memory helper inventory still matches restore_saved_browser_snapshot.sh before restored-checkout contract checks are trusted.",
        "Run issue11_saved_memory_helper_contract and issue11_reentry_inventory_consistency against the restored checkout before treating live_helper_restored_checkout_preflight as trustworthy from that restored tree.",
        "Use live_helper_restored_checkout_preflight when the restored snapshot itself needs to be checked against the newer live helper surface before running follow-up route commands from that restored tree.",
        "Point helper_root at the live branch-local helper surface when repo_root is a restored checkout that should reuse newer route helpers.",
        "Keep docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md visible when the run is still blocked in the Linux or WSL re-entry lane so issue #11 remains the practical progress-update target.",
        "If the surfaced memory root exists but repo_archives/browser/ is missing or empty, fix Memory sync first; the restore route still depends on the same saved snapshot and dependency bundles.",
        "Use saved_archive_integrity_route when the saved-input preflight passes but the next question is still whether the exact saved bundles and snapshot helper surface are trustworthy enough for restore or staging.",
        "Use saved_zig_archive_candidates_route when the next question is which saved 0.15.x archive should be staged before broader Zig recovery or Linux build-readiness work resumes.",
        "Keep the caller-provided Memory, restored-checkout, Rust toolchain, and offline-deps roots threaded into the nested Linux build-readiness route so restored follow-up runs do not fall back to guessed sibling paths; toolchain discovery now prefers a hidden .toolchains root but still accepts a visible toolchains root.",
        "Use saved_browser_snapshot_route when the saved inputs are green but there is still no restored checkout.",
        "Use linux_build_readiness_route when the next blocker is still Zig-line selection, Rust restore, or offline dependency staging.",
        "Use runtime_reentry_route only after the saved inputs are green and the direct Page.zig plus win32_backend.zig lane is truly ready to reopen."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved Memory inputs route

Repo root:               ${REPO_ROOT}
Live helper root:        ${HELPER_ROOT}
Memory root:             ${MEMORY_ROOT}
Agent files root:        ${AGENT_FILES_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Saved repo snapshot:     ${REPO_SNAPSHOT_PATH}
Blocker intelligence:    ${BLOCKER_INTELLIGENCE_PATH}
Dependencies root:       ${DEPENDENCIES_ROOT}
Progress tracker route:  ${PROGRESS_TRACKER_ROUTE_PATH}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Skip archive integrity:  $([[ "${SKIP_ARCHIVE_INTEGRITY_CHECK}" -eq 1 ]] && echo enabled || echo disabled)

Read first
==========
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Surface check:
    ${ROUTE_SURFACE_COMMAND}

  Workspace-context surface check:
    ${WORKSPACE_CONTEXT_ROUTE_SURFACE_COMMAND}

  Workspace-context route:
    ${WORKSPACE_CONTEXT_ROUTE_COMMAND}

  Workspace-context helper:
    ${WORKSPACE_CONTEXT_COMMAND}

  Issue #11 nested-workspace saved-Memory preflight:
    ${NESTED_WORKSPACE_RUNNER_COMMAND}

  Quick nested-workspace saved-Memory presence check:
    ${NESTED_WORKSPACE_RUNNER_QUICK_COMMAND}

  Saved-Memory preflight:
    ${SAVED_INPUT_COMMAND}

  Quick saved-Memory presence check:
    ${QUICK_SAVED_INPUT_COMMAND}

  Saved-Memory preflight when a restored checkout already exists:
    ${RESTORED_SAVED_INPUT_COMMAND}

  Restored helper-surface sync route:
    ${RESTORED_HELPER_SURFACE_SYNC_ROUTE_COMMAND}

  Issue #11 saved-memory helper-surface inventory check for the live helper root:
    ${ISSUE11_SAVED_MEMORY_HELPER_SURFACE_INVENTORY_COMMAND}

  Issue #11 saved-memory helper-contract check for the restored checkout:
    ${ISSUE11_SAVED_MEMORY_HELPER_CONTRACT_COMMAND}

  Issue #11 re-entry inventory consistency check for the restored checkout:
    ${ISSUE11_REENTRY_INVENTORY_CONSISTENCY_COMMAND}

  Live-helper preflight from the restored checkout itself:
    ${LIVE_HELPER_RESTORED_CHECKOUT_COMMAND}

  Saved-archive integrity route:
    ${SAVED_ARCHIVE_INTEGRITY_ROUTE_COMMAND}

  Saved Zig archive candidates route:
    ${SAVED_ZIG_ARCHIVE_ROUTE_COMMAND}

  Restore route when no reusable checkout exists yet:
    ${SNAPSHOT_ROUTE_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so helper drift fails fast before the run blames missing Memory inputs.
  - Run the workspace-context surface, route, and helper before the saved-Memory preflight when the checkout sits deeper than the default sibling layout or the next helper would otherwise guess the wrong roots.
  - Prefer the issue #11 nested-workspace runner when the workspace-context output already surfaced the right roots and the next question is simply whether the saved-memory preflight passes once those surfaced paths are threaded through honestly.
  - Run the saved-Memory preflight before restore, build-readiness, or runtime helpers when the route depends on the saved repo snapshot and dependency bundles.
  - Use the quick presence-only command for branch selection only; it is not honest archive validation.
  - Use the restored-checkout preflight when a reusable checkout already exists and the route should confirm that surface before broader helper output is trusted.
  - Use the restored-helper-surface sync route when the extracted snapshot may lag behind the live helper surface or the restored tree is missing the newer issue #11 helper-sync files.
  - Use the issue #11 saved-memory helper-surface inventory check when the run needs focused proof that the explicit saved-memory preflight inventory still matches restore_saved_browser_snapshot.sh before restored-checkout contract checks are trusted.
  - Run the issue #11 saved-memory helper-contract and re-entry inventory checks against the restored checkout before treating the live-helper restored-checkout preflight as trustworthy from that restored tree.
  - Use the live-helper restored-checkout preflight when the extracted snapshot may lag behind the live helper surface and the run needs that drift to fail before it starts calling route commands from the restored tree.
  - Point --helper-root at the live branch-local helper surface when repo_root is a restored checkout that should still reuse newer helper notes and scripts.
  - Keep docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md visible when the run is still blocked in the Linux or WSL re-entry lane and needs a safe issue #11 progress-update handoff before wider follow-up work.
  - If the surfaced memory root exists but repo_archives/browser/ is missing or empty, fix Memory sync first; the restore route still depends on the same saved snapshot and dependency bundles.
  - Use the saved-archive integrity route when the saved-Memory preflight passes but the next question is still whether the exact saved bundles and snapshot helper surface are trustworthy enough for restore or staging.
  - Use the saved Zig archive candidates route when the next question is which saved 0.15.x archive should be staged before wider Zig recovery or Linux build-readiness work resumes.
  - Keep the caller-provided Memory, restored-checkout, Rust toolchain, and offline-deps roots aligned when handing off to the Linux or WSL build-readiness route, and prefer a hidden .toolchains root while still accepting a visible toolchains root when discovering staged toolchains.
  - Use the restore route when the saved archive exists but there is still no reusable checkout for Linux or WSL follow-up.
  - Use the Linux or WSL build-readiness route after the saved-Memory preflight passes and the next blocker is still Rust, Zig, offline dependency staging, or prebuilt V8 readiness.
  - Use the direct runtime re-entry route only after the saved checkout exists and the environment gates are no longer the blocker.
  - Treat the attached Zig 0.17 dev bundle as surfaced fallback input only, not as honest issue #3 validation evidence for this branch.
EOF