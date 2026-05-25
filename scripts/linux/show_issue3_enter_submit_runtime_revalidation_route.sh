#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--browser-exe /path/to/lightpanda.exe] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact Linux or WSL helper surface for the direct issue #3
Enter-submit runtime re-entry route. This route keeps the gate note, saved
snapshot restore path, restored-checkout readiness check, saved archive
integrity path, source contract check, saved-memory preflight, Linux
build-readiness helpers, focused Zig commands, and the Windows follow-up replay
ladder on one branch-local surface.
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

read_minimum_zig_version() {
    python3 - "$1" <<'PY'
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r'\.minimum_zig_version\s*=\s*"([^"]+)"', text)
if match:
    print(match.group(1))
PY
}

infer_archive_version() {
    if [[ -z "${1:-}" ]]; then
        return 0
    fi
    python3 - "$1" <<'PY'
import pathlib
import re
import sys

match = re.search(r'(\d+\.\d+\.\d+)', pathlib.Path(sys.argv[1]).name)
if match:
    print(match.group(1))
PY
}

expected_zig_line() {
    if [[ -z "${1:-}" ]]; then
        return 0
    fi
    python3 - "$1" <<'PY'
import re
import sys

match = re.match(r'^(\d+)\.(\d+)\.', sys.argv[1])
if match:
    print(f"{match.group(1)}.{match.group(2)}.x")
PY
}

describe_fallback_zig_status() {
    local minimum_zig="$1"
    local fallback_archive="$2"
    local fallback_version="$3"
    local expected_line="$4"

    if [[ -z "${fallback_archive}" ]]; then
        printf '%s' "not found beside the repo workspace"
        return 0
    fi
    if [[ ! -f "${fallback_archive}" ]]; then
        printf '%s' "configured path does not exist"
        return 0
    fi
    if [[ -z "${fallback_version}" || -z "${expected_line}" ]]; then
        printf '%s' "could not infer archive or branch Zig line"
        return 0
    fi

    local minimum_line="${minimum_zig%.*}"
    local fallback_line="${fallback_version%.*}"
    if [[ "${minimum_line}" == "${fallback_line}" ]]; then
        printf '%s' "matches expected ${expected_line} line"
        return 0
    fi

    printf '%s' "mismatched: branch expects ${expected_line}, fallback archive carries ${fallback_version}"
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
BROWSER_EXE="${LIGHTPANDA_BROWSER_EXE:-}"
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --browser-exe)
            BROWSER_EXE="$2"
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
if [[ -z "${BROWSER_EXE}" ]]; then
    BROWSER_EXE="${REPO_ROOT}/zig-out/bin/lightpanda.exe"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

BUILD_ZON_PATH="${REPO_ROOT}/build.zig.zon"
MINIMUM_ZIG_VERSION="$(read_minimum_zig_version "${BUILD_ZON_PATH}")"
EXPECTED_ZIG_LINE="$(expected_zig_line "${MINIMUM_ZIG_VERSION}")"
FALLBACK_ZIG_VERSION="$(infer_archive_version "${FALLBACK_ZIG_ARCHIVE}")"
FALLBACK_ZIG_STATUS="$(describe_fallback_zig_status "${MINIMUM_ZIG_VERSION}" "${FALLBACK_ZIG_ARCHIVE}" "${FALLBACK_ZIG_VERSION}" "${EXPECTED_ZIG_LINE}")"

RESTORED_CHECKOUT_DESTINATION="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
PAGE_SOURCE_PATH="${REPO_ROOT}/src/browser/Page.zig"
WIN32_SOURCE_PATH="${REPO_ROOT}/src/display/win32_backend.zig"
RUNTIME_CONTRACT_CHECKER="${REPO_ROOT}/tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
RUNTIME_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
SAVED_BROWSER_SNAPSHOT_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
SAVED_BROWSER_SNAPSHOT_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
RESTORED_CHECKOUT_HELPER="${REPO_ROOT}/scripts/check_issue3_restored_checkout.py"
SAVED_ARCHIVE_INTEGRITY_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"
SAVED_ARCHIVE_INTEGRITY_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh"
SAVED_ARCHIVE_INTEGRITY_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py"
SAVED_MEMORY_INPUTS_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
LINUX_BUILD_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
LINUX_BUILD_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
LINUX_BUILD_READINESS_SCRIPT="${REPO_ROOT}/scripts/check_linux_build_readiness.py"

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${RUNTIME_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_BROWSER_SNAPSHOT_SURFACE_COMMAND="bash $(format_shell_arg "${SAVED_BROWSER_SNAPSHOT_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_BROWSER_SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_BROWSER_SNAPSHOT_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_HELPER}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_DESTINATION}")"
SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_DESTINATION}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_DESTINATION}") --helper-root $(format_shell_arg "${REPO_ROOT}") --expect-helper-surface"
SAVED_ARCHIVE_INTEGRITY_SURFACE_COMMAND="bash $(format_shell_arg "${SAVED_ARCHIVE_INTEGRITY_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_ARCHIVE_INTEGRITY_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${SAVED_ARCHIVE_INTEGRITY_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
CONTRACT_CHECK_COMMAND="python $(format_shell_arg "${RUNTIME_CONTRACT_CHECKER}") --page $(format_shell_arg "${PAGE_SOURCE_PATH}") --win32 $(format_shell_arg "${WIN32_SOURCE_PATH}")"
CONTRACT_SELF_TEST_COMMAND="python $(format_shell_arg "${RUNTIME_CONTRACT_CHECKER}") --self-test"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${SAVED_MEMORY_INPUTS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LINUX_BUILD_SURFACE_COMMAND="bash $(format_shell_arg "${LINUX_BUILD_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${LINUX_BUILD_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python $(format_shell_arg "${LINUX_BUILD_READINESS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check"
LINUX_BUILD_READINESS_COMMAND="python $(format_shell_arg "${LINUX_BUILD_READINESS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"
FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
WINDOWS_BUILD_COMMAND="zig build -Dtarget=x86_64-windows-msvc --summary all"
REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
REDUCED_GOOGLE_FIXTURE_COMMAND="$(format_shell_arg "${BROWSER_EXE}") browse --headed --window_width 1366 --window_height 900 $(format_shell_arg "http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1")"
LIVE_GOOGLE_COMMAND="$(format_shell_arg "${BROWSER_EXE}") browse --headed --window_width 1366 --window_height 900 $(format_shell_arg "https://www.google.com/")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_BROWSER_SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 Enter-submit runtime revalidation")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "browser_exe": %s,\n' "$(json_escape "${BROWSER_EXE}")"
    printf '  "minimum_zig_version": %s,\n' "$(json_escape "${MINIMUM_ZIG_VERSION}")"
    printf '  "expected_zig_line": %s,\n' "$(json_escape "${EXPECTED_ZIG_LINE}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "fallback_zig_version": %s,\n' "$(json_escape "${FALLBACK_ZIG_VERSION}")"
    printf '  "fallback_zig_status": %s,\n' "$(json_escape "${FALLBACK_ZIG_STATUS}")"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md")"
    printf '    %s\n' "$(json_escape "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")"
    printf '  ],\n'
    printf '  "target_files": [\n'
    printf '    %s,\n' "$(json_escape "src/browser/Page.zig")"
    printf '    %s\n' "$(json_escape "src/display/win32_backend.zig")"
    printf '  ],\n'
    printf '  "commands": {\n'
    printf '    "surface_check": %s,\n' "$(json_escape "${SURFACE_CHECK_COMMAND}")"
    printf '    "saved_browser_snapshot_surface": %s,\n' "$(json_escape "${SAVED_BROWSER_SNAPSHOT_SURFACE_COMMAND}")"
    printf '    "saved_browser_snapshot_route": %s,\n' "$(json_escape "${SAVED_BROWSER_SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "restored_checkout_check": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_CHECK_COMMAND}")"
    printf '    "synced_restored_checkout_check": %s,\n' "$(json_escape "${SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND}")"
    printf '    "saved_archive_integrity_surface": %s,\n' "$(json_escape "${SAVED_ARCHIVE_INTEGRITY_SURFACE_COMMAND}")"
    printf '    "saved_archive_integrity_route": %s,\n' "$(json_escape "${SAVED_ARCHIVE_INTEGRITY_ROUTE_COMMAND}")"
    printf '    "saved_archive_integrity": %s,\n' "$(json_escape "${SAVED_ARCHIVE_INTEGRITY_COMMAND}")"
    printf '    "contract_check": %s,\n' "$(json_escape "${CONTRACT_CHECK_COMMAND}")"
    printf '    "contract_self_test": %s,\n' "$(json_escape "${CONTRACT_SELF_TEST_COMMAND}")"
    printf '    "saved_memory_preflight": %s,\n' "$(json_escape "${SAVED_MEMORY_PREFLIGHT_COMMAND}")"
    printf '    "linux_build_surface": %s,\n' "$(json_escape "${LINUX_BUILD_SURFACE_COMMAND}")"
    printf '    "linux_build_route": %s,\n' "$(json_escape "${LINUX_BUILD_ROUTE_COMMAND}")"
    printf '    "linux_build_readiness_skip_zig": %s,\n' "$(json_escape "${LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND}")"
    printf '    "linux_build_readiness": %s,\n' "$(json_escape "${LINUX_BUILD_READINESS_COMMAND}")"
    printf '    "focused_page_tests": %s,\n' "$(json_escape "${FOCUSED_PAGE_TESTS_COMMAND}")"
    printf '    "focused_win32_tests": %s,\n' "$(json_escape "${FOCUSED_WIN32_TESTS_COMMAND}")"
    printf '    "windows_build": %s,\n' "$(json_escape "${WINDOWS_BUILD_COMMAND}")"
    printf '    "reduced_google_probe": %s,\n' "$(json_escape "${REDUCED_GOOGLE_PROBE_COMMAND}")"
    printf '    "reduced_google_fixture": %s,\n' "$(json_escape "${REDUCED_GOOGLE_FIXTURE_COMMAND}")"
    printf '    "live_google": %s\n' "$(json_escape "${LIVE_GOOGLE_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run surface_check first when the branch may have moved and you want the direct issue #3 docs and helper surfaces checked before replay.")"
    printf '    %s,\n' "$(json_escape "This branch declares minimum Zig ${MINIMUM_ZIG_VERSION:-unknown}; keep looking for a ${EXPECTED_ZIG_LINE:-branch-compatible} toolchain before trusting focused file-level validation.")"
    printf '    %s,\n' "$(json_escape "Current fallback Zig status: ${FALLBACK_ZIG_STATUS}.")"
    printf '    %s,\n' "$(json_escape "If no reusable checkout exists yet, run saved_browser_snapshot_surface and then saved_browser_snapshot_route before trusting follow-up Linux or WSL helper output.")"
    printf '    %s,\n' "$(json_escape "If that saved snapshot route is creating or reusing ../browser-memory-snapshot, run restored_checkout_check before the saved-memory preflight so checkout drift is caught before the route widens again.")"
    printf '    %s,\n' "$(json_escape "Use synced_restored_checkout_check after a helper-surface sync restore when the restored checkout should become its own follow-up root.")"
    printf '    %s,\n' "$(json_escape "If the route still depends on the saved repo snapshot or dependency bundles, run saved_archive_integrity_surface and then saved_archive_integrity_route before trusting Linux or WSL build-readiness output.")"
    printf '    %s,\n' "$(json_escape "Run saved_archive_integrity when you need the exact SHA-256 verification step without reopening the broader archive helper first.")"
    printf '    %s,\n' "$(json_escape "Run contract_check before build or replay when you need a thin source-based yes-or-no answer about whether the Page.zig and win32_backend.zig bridge markers are present on the current branch.")"
    printf '    %s,\n' "$(json_escape "Run contract_self_test when you want to prove the checker still distinguishes vulnerable and guarded samples before pointing it at a real checkout.")"
    printf '    %s,\n' "$(json_escape "Run saved_memory_preflight before Linux or WSL build-readiness commands when the route depends on the saved Memory repo snapshot, dependency archives, and optional fallback Zig bundle.")"
    printf '    %s,\n' "$(json_escape "Use --fallback-zig-archive when the restored checkout or helper workspace is not sitting beside the default agent_files location.")"
    printf '    %s,\n' "$(json_escape "If the toolchain gate is still closed, run linux_build_surface and then linux_build_route before treating focused Zig output as issue-specific evidence.")"
    printf '    %s,\n' "$(json_escape "Use linux_build_readiness_skip_zig when the saved archives or sibling dependencies may still be missing and you want a fast environment check before staging a branch-compatible Zig line.")"
    printf '    %s,\n' "$(json_escape "Use linux_build_readiness only after a matching Zig line is actually staged.")"
    printf '    %s,\n' "$(json_escape "Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain; the attached Zig 0.17 dev fallback can fail in untouched branch files before the focused assertions run.")"
    printf '    %s\n' "$(json_escape "After the Linux or WSL gates turn green, move back to the Windows build and reduced Google probe before widening to live Google.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 Enter-submit runtime revalidation

Repo root:            ${REPO_ROOT}
Browser exe:          ${BROWSER_EXE}
Branch minimum Zig:   ${MINIMUM_ZIG_VERSION:-unknown}
Expected Zig line:    ${EXPECTED_ZIG_LINE:-unknown}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Fallback Zig version: ${FALLBACK_ZIG_VERSION:-unknown}
Fallback Zig status:  ${FALLBACK_ZIG_STATUS}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Target files
============
  src/browser/Page.zig
  src/display/win32_backend.zig

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  If no reusable checkout exists yet, reopen the saved snapshot route first:
    ${SAVED_BROWSER_SNAPSHOT_SURFACE_COMMAND}
    ${SAVED_BROWSER_SNAPSHOT_ROUTE_COMMAND}

  Restored-checkout readiness after saved snapshot restore:
    ${RESTORED_CHECKOUT_CHECK_COMMAND}

  Synced restored-checkout readiness after saved snapshot restore:
    ${SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND}

  If the route still depends on the saved repo snapshot or dependency bundles, reopen the saved archive integrity path:
    ${SAVED_ARCHIVE_INTEGRITY_SURFACE_COMMAND}
    ${SAVED_ARCHIVE_INTEGRITY_ROUTE_COMMAND}
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Source contract check:
    ${CONTRACT_CHECK_COMMAND}

  Checker self-test:
    ${CONTRACT_SELF_TEST_COMMAND}

  Saved-memory preflight:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  If the toolchain gate is still closed, reopen Linux or WSL build readiness:
    ${LINUX_BUILD_SURFACE_COMMAND}
    ${LINUX_BUILD_ROUTE_COMMAND}
    ${LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND}
    ${LINUX_BUILD_READINESS_COMMAND}

  Focused commands after a branch-compatible Zig line is staged:
    ${FOCUSED_PAGE_TESTS_COMMAND}
    ${FOCUSED_WIN32_TESTS_COMMAND}

  Windows follow-up after the Linux or WSL gate turns green:
    ${WINDOWS_BUILD_COMMAND}
    ${REDUCED_GOOGLE_PROBE_COMMAND}
    ${REDUCED_GOOGLE_FIXTURE_COMMAND}
    ${LIVE_GOOGLE_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails fast before replay widens back out.
  - This branch declares minimum Zig ${MINIMUM_ZIG_VERSION:-unknown}; do not trust focused runtime validation until a ${EXPECTED_ZIG_LINE:-branch-compatible} toolchain is actually staged.
  - Treat the surfaced fallback archive status as the quick yes-or-no answer before burning time on untouched-file failures: ${FALLBACK_ZIG_STATUS}.
  - If no reusable checkout exists yet, reopen the saved-browser-snapshot route before trusting follow-up Linux or WSL helper output.
  - If that saved snapshot route is creating or reusing ../browser-memory-snapshot, run the restored-checkout readiness step before saved-memory or archive-focused preflights.
  - Use the synced restored-checkout step after a helper-surface sync restore when the restored checkout should become its own follow-up root.
  - If the route still depends on the saved repo snapshot or dependency bundles, reopen the saved-archive-integrity path before trusting Linux or WSL build-readiness output.
  - Run the source contract check before blaming the runtime patch or reopening the direct Page.zig and win32_backend.zig edit path.
  - Run the saved-memory preflight before broader Linux or WSL build-readiness commands when the route depends on the saved repo snapshot and dependency archives.
  - Use --fallback-zig-archive when the restored checkout or helper workspace is not sitting beside the default agent_files location.
  - If the toolchain gate is still closed, use the Linux or WSL build-readiness route before trusting focused Zig output.
  - Do not treat fallback Zig 0.17 dev failures in untouched branch files as issue #3 patch evidence.
  - Use the Windows build and reduced Google probe only after the Linux or WSL gate agrees that the environment is no longer the blocker.
EOF