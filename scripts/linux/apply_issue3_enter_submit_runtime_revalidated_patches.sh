#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/apply_issue3_enter_submit_runtime_revalidated_patches.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--page-patch /path/to/page.patch] \
    [--win32-patch /path/to/win32.patch] \
    [--check-only] \
    [--apply] \
    [--json]

Check or apply the saved issue #3 Enter-submit runtime patches that were
revalidated against the live headed-mode branch but could not be published
directly from a brittle full-file update path.

This helper is for writable local checkouts, including restored snapshots such
as ../browser-memory-snapshot. It answers three questions quickly:

  1. Are the saved patch files present?
  2. Does the current checkout still accept them with git apply -p4?
  3. Has the checkout already picked up the same runtime change markers?

By default the helper only reports state. Pass --apply to apply both patches
after they both pass the applicability check.
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

find_workspace_anchor() {
    local root="$1"
    local current="$1"

    while true; do
        if [[ -d "${current}/memory" || -d "${current}/agent_files" || "$(basename "${current}")" == "workspace" ]]; then
            printf '%s\n' "${current}"
            return
        fi

        local parent
        parent="$(dirname "${current}")"
        if [[ "${parent}" == "${current}" ]]; then
            break
        fi
        current="${parent}"
    done

    printf '%s\n' "$(cd "${root}/.." && pwd)"
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKSPACE_ANCHOR="$(find_workspace_anchor "${DEFAULT_REPO_ROOT}")"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
MEMORY_ROOT="${WORKSPACE_ANCHOR}/memory"
PAGE_PATCH=""
WIN32_PATCH=""
CHECK_ONLY=1
APPLY_PATCHES=0
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --page-patch)
            PAGE_PATCH="$2"
            shift 2
            ;;
        --win32-patch)
            WIN32_PATCH="$2"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=1
            APPLY_PATCHES=0
            shift
            ;;
        --apply)
            APPLY_PATCHES=1
            CHECK_ONLY=0
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
MEMORY_ROOT="$(cd "${MEMORY_ROOT}" && pwd)"

if [[ -z "${PAGE_PATCH}" ]]; then
    PAGE_PATCH="${MEMORY_ROOT}/repo_archives/browser/patches/2026-05-22-issue3-enter-submit-page-revalidated.patch"
fi
if [[ -z "${WIN32_PATCH}" ]]; then
    WIN32_PATCH="${MEMORY_ROOT}/repo_archives/browser/patches/2026-05-22-issue3-enter-submit-win32-revalidated.patch"
fi

PAGE_SOURCE="${REPO_ROOT}/src/browser/Page.zig"
WIN32_SOURCE="${REPO_ROOT}/src/display/win32_backend.zig"

ensure_file() {
    local path="$1"
    local label="$2"
    if [[ ! -f "${path}" ]]; then
        echo "Missing ${label}: ${path}" >&2
        exit 1
    fi
}

ensure_file "${PAGE_PATCH}" "Page.zig patch"
ensure_file "${WIN32_PATCH}" "win32_backend.zig patch"
ensure_file "${PAGE_SOURCE}" "Page.zig source"
ensure_file "${WIN32_SOURCE}" "win32_backend.zig source"

patch_state() {
    local patch_path="$1"

    if git -C "${REPO_ROOT}" apply -p4 --check "${patch_path}" >/dev/null 2>&1; then
        printf '%s\n' "applicable"
        return
    fi

    if git -C "${REPO_ROOT}" apply -p4 -R --check "${patch_path}" >/dev/null 2>&1; then
        printf '%s\n' "already_applied"
        return
    fi

    printf '%s\n' "mismatch"
}

source_has_runtime_markers() {
    local path="$1"
    shift
    local marker=""

    for marker in "$@"; do
        if ! grep -Fq -- "${marker}" "${path}"; then
            return 1
        fi
    done

    return 0
}

PAGE_PATCH_STATE="$(patch_state "${PAGE_PATCH}")"
WIN32_PATCH_STATE="$(patch_state "${WIN32_PATCH}")"

PAGE_MARKERS_PRESENT=0
WIN32_MARKERS_PRESENT=0
if source_has_runtime_markers \
    "${PAGE_SOURCE}" \
    "_defer_native_text_input_enter_submit: bool = false" \
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void" \
    "test \"Page reduced Google fixture defers native Enter submit until keypress\""
then
    PAGE_MARKERS_PRESENT=1
fi
if source_has_runtime_markers \
    "${WIN32_SOURCE}" \
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{}" \
    "fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void" \
    "test \"win32 dispatchInput allows later real text when stale suppression bytes do not match\""
then
    WIN32_MARKERS_PRESENT=1
fi

READY_TO_APPLY=0
if [[ "${PAGE_PATCH_STATE}" == "applicable" && "${WIN32_PATCH_STATE}" == "applicable" ]]; then
    READY_TO_APPLY=1
fi

ALREADY_APPLIED=0
if [[ "${PAGE_PATCH_STATE}" == "already_applied" && "${WIN32_PATCH_STATE}" == "already_applied" ]]; then
    ALREADY_APPLIED=1
fi

APPLY_COMMAND="git -C $(format_shell_arg "${REPO_ROOT}") apply -p4 $(format_shell_arg "${PAGE_PATCH}") && git -C $(format_shell_arg "${REPO_ROOT}") apply -p4 $(format_shell_arg "${WIN32_PATCH}")"

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "page_patch": %s,\n' "$(json_escape "${PAGE_PATCH}")"
    printf '  "win32_patch": %s,\n' "$(json_escape "${WIN32_PATCH}")"
    printf '  "page_patch_state": %s,\n' "$(json_escape "${PAGE_PATCH_STATE}")"
    printf '  "win32_patch_state": %s,\n' "$(json_escape "${WIN32_PATCH_STATE}")"
    printf '  "page_markers_present": %s,\n' "$([[ "${PAGE_MARKERS_PRESENT}" -eq 1 ]] && echo true || echo false)"
    printf '  "win32_markers_present": %s,\n' "$([[ "${WIN32_MARKERS_PRESENT}" -eq 1 ]] && echo true || echo false)"
    printf '  "ready_to_apply": %s,\n' "$([[ "${READY_TO_APPLY}" -eq 1 ]] && echo true || echo false)"
    printf '  "already_applied": %s,\n' "$([[ "${ALREADY_APPLIED}" -eq 1 ]] && echo true || echo false)"
    printf '  "apply_requested": %s,\n' "$([[ "${APPLY_PATCHES}" -eq 1 ]] && echo true || echo false)"
    printf '  "apply_command": %s\n' "$(json_escape "${APPLY_COMMAND}")"
    printf '}\n'
else
    cat <<EOF
Issue #3 Enter-submit runtime patch replay

Repo root:       ${REPO_ROOT}
Memory root:     ${MEMORY_ROOT}
Page patch:      ${PAGE_PATCH}
Win32 patch:     ${WIN32_PATCH}

Patch states
============
  Page.zig patch:       ${PAGE_PATCH_STATE}
  win32_backend patch:  ${WIN32_PATCH_STATE}

Source markers
==============
  Page.zig markers present:      $([[ "${PAGE_MARKERS_PRESENT}" -eq 1 ]] && echo yes || echo no)
  win32_backend markers present: $([[ "${WIN32_MARKERS_PRESENT}" -eq 1 ]] && echo yes || echo no)

Replay command
==============
  ${APPLY_COMMAND}
EOF
fi

if [[ "${APPLY_PATCHES}" -eq 1 ]]; then
    if [[ "${ALREADY_APPLIED}" -eq 1 ]]; then
        if [[ "${JSON}" -eq 0 ]]; then
            echo
            echo "Both issue #3 runtime patches are already present in this checkout."
        fi
        exit 0
    fi

    if [[ "${READY_TO_APPLY}" -ne 1 ]]; then
        echo "Refusing to apply patches because at least one patch is not currently applicable." >&2
        exit 1
    fi

    git -C "${REPO_ROOT}" apply -p4 "${PAGE_PATCH}"
    git -C "${REPO_ROOT}" apply -p4 "${WIN32_PATCH}"

    if [[ "${JSON}" -eq 0 ]]; then
        echo
        echo "Both issue #3 runtime patches were applied."
    fi
fi

if [[ "${CHECK_ONLY}" -eq 1 && "${READY_TO_APPLY}" -eq 0 && "${ALREADY_APPLIED}" -eq 0 ]]; then
    exit 1
fi
