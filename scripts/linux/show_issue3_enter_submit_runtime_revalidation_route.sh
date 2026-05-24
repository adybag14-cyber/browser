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
snapshot restore path, saved archive integrity path, source contract check,
saved-memory preflight, Linux build-readiness helpers, focused Zig commands,
and the Windows follow-up replay ladder on one branch-local surface.
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

PAGE_SOURCE_PATH="${REPO_ROOT}/src/browser/Page.zig"
WIN32_SOURCE_PATH="${REPO_ROOT}/src/display/win32_backend.zig"
RUNTIME_CONTRACT_CHECKER="${REPO_ROOT}/tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
RUNTIME_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
SAVED_BROWSER_SNAPSHOT_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
SAVED_BROWSER_SNAPSHOT_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
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
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")"
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
    printf '    %s,\n' "$(json_escape "If no reusable checkout exists yet, run saved_browser_snapshot_surface and then saved_browser_snapshot_route before trusting follow-up Linux or WSL helper output.")"
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
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
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
  - If no reusable checkout exists yet, reopen the saved-browser-snapshot route before trusting follow-up Linux or WSL helper output.
  - If the route still depends on the saved repo snapshot or dependency bundles, reopen the saved-archive-integrity path before trusting Linux or WSL build-readiness output.
  - Run the source contract check before blaming the runtime patch or reopening the direct Page.zig and win32_backend.zig edit path.
  - Run the saved-memory preflight before broader Linux or WSL build-readiness commands when the route depends on the saved repo snapshot and dependency archives.
  - Use --fallback-zig-archive when the restored checkout or helper workspace is not sitting beside the default agent_files location.
  - If the toolchain gate is still closed, use the Linux or WSL build-readiness route before trusting focused Zig output.
  - Do not treat fallback Zig 0.17 dev failures in untouched branch files as issue #3 patch evidence.
  - Use the Windows build and reduced Google probe only after the Linux or WSL gate agrees that the environment is no longer the blocker.
EOF