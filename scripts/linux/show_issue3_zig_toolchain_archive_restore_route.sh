#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--archive /path/to/zig-0.15.2.tar.xz] \
    [--offline-deps-root /path/to/offline-deps] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact issue #3 Zig toolchain archive-restore route for Linux or
WSL headed-mode recovery work.
EOF
}

resolve_first_existing_path() {
    local start="$1"
    local relative_path="$2"
    local current="$start"
    while true; do
        if [[ -e "${current}/${relative_path}" ]]; then
            printf '%s\n' "${current}/${relative_path}"
            return 0
        fi
        if [[ "${current}" == "/" ]]; then
            return 1
        fi
        current="$(dirname "${current}")"
    done
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
ARCHIVE_PATH=""
OFFLINE_DEPS_ROOT=""
SAVED_ARCHIVES_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

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
        --archive)
            ARCHIVE_PATH="$2"
            shift 2
            ;;
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
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
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/offline-deps"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(resolve_first_existing_path "${REPO_ROOT}" "agent_files/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}" || true)"
    if [[ -z "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    fi
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
SAVED_ARCHIVE_CANDIDATES_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py"
RESTORE_SCRIPT="${REPO_ROOT}/scripts/linux/restore_zig_toolchain_archive.sh"
RECOVERY_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
READINESS_SCRIPT="${REPO_ROOT}/scripts/check_linux_build_readiness.py"

python3 - "${REPO_ROOT}" "${TOOLCHAINS_ROOT}" "${ARCHIVE_PATH}" "${OFFLINE_DEPS_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" "${SURFACE_SCRIPT}" "${SAVED_ARCHIVE_CANDIDATES_SCRIPT}" "${RESTORE_SCRIPT}" "${RECOVERY_SCRIPT}" "${READINESS_SCRIPT}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import shlex
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
toolchains_root = pathlib.Path(sys.argv[2]).resolve()
archive_arg = sys.argv[3]
offline_deps_root = pathlib.Path(sys.argv[4]).resolve()
saved_archives_root = pathlib.Path(sys.argv[5]).resolve()
fallback_zig_archive = sys.argv[6]
surface_script = pathlib.Path(sys.argv[7]).resolve()
saved_archive_candidates_script = pathlib.Path(sys.argv[8]).resolve()
restore_script = pathlib.Path(sys.argv[9]).resolve()
recovery_script = pathlib.Path(sys.argv[10]).resolve()
readiness_script = pathlib.Path(sys.argv[11]).resolve()
emit_json = sys.argv[12] == "1"


def quote(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def archive_top_level_name(path: pathlib.Path) -> str:
    name = path.name
    for suffix in (".tar.gz", ".tar.xz", ".tgz", ".zip", ".tar"):
        if name.endswith(suffix):
            return name[: -len(suffix)]
    return path.stem


archive_path = pathlib.Path(archive_arg).expanduser().resolve() if archive_arg else None
destination = None
zig_path_candidates: list[str] = []
if archive_path is not None:
    destination = toolchains_root / archive_top_level_name(archive_path)
    zig_path_candidates = [
        str(destination / "zig"),
        str(destination / "bin" / "zig"),
    ]

surface_check = quote(["bash", str(surface_script), "--repo-root", str(repo_root)])
saved_archive_candidate_parts = [
    "python",
    str(saved_archive_candidates_script),
    "--repo-root",
    str(repo_root),
    "--saved-archives-root",
    str(saved_archives_root),
    "--toolchains-root",
    str(toolchains_root),
]
if fallback_zig_archive:
    saved_archive_candidate_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
saved_archive_candidates = quote(saved_archive_candidate_parts)

restore_check = None
restore_run = None
readiness = None
if archive_path is not None:
    restore_check_parts = [
        "bash",
        str(restore_script),
        "--browser-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--archive",
        str(archive_path),
        "--check-only",
    ]
    restore_run_parts = [
        "bash",
        str(restore_script),
        "--browser-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--archive",
        str(archive_path),
    ]
    readiness_parts = [
        "python",
        str(readiness_script),
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--offline-deps-root",
        str(offline_deps_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-saved-archives",
        "--expect-offline-deps",
        "--require-prebuilt-v8",
        "--zig",
        "<restored-zig-path>",
    ]
    if fallback_zig_archive:
        restore_check_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
        restore_run_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
        readiness_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
    restore_check = quote(restore_check_parts)
    restore_run = quote(restore_run_parts)
    readiness = quote(readiness_parts)

recovery_parts = [
    "bash",
    str(recovery_script),
    "--repo-root",
    str(repo_root),
    "--toolchains-root",
    str(toolchains_root),
    "--saved-archives-root",
    str(saved_archives_root),
    "--offline-deps-root",
    str(offline_deps_root),
]
if fallback_zig_archive:
    recovery_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
recovery = quote(recovery_parts)

result = {
    "issue": "Google issue #3 Zig toolchain archive restore route",
    "repo_root": str(repo_root),
    "toolchains_root": str(toolchains_root),
    "saved_archives_root": str(saved_archives_root),
    "offline_deps_root": str(offline_deps_root),
    "fallback_zig_archive": fallback_zig_archive,
    "archive_path": str(archive_path) if archive_path else "",
    "destination": str(destination) if destination else "",
    "zig_path_candidates": zig_path_candidates,
    "commands": {
        "surface_check": surface_check,
        "saved_archive_candidates": saved_archive_candidates,
        "recovery_route": recovery,
    },
}
if restore_check is not None:
    result["commands"]["restore_check_only"] = restore_check
if restore_run is not None:
    result["commands"]["restore"] = restore_run
if readiness is not None:
    result["commands"]["full_readiness"] = readiness

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(0)

print("Google issue #3 Zig toolchain archive restore route")
print()
print(f"Repo root:           {repo_root}")
print(f"Toolchains root:     {toolchains_root}")
print(f"Saved archives root: {saved_archives_root}")
print(f"Offline deps root:   {offline_deps_root}")
print(
    "Fallback archive:   "
    + (fallback_zig_archive if fallback_zig_archive else "not found beside the repo workspace")
)
print(
    "Archive:             "
    + (str(archive_path) if archive_path else "provide --archive /path/to/zig-0.15.2.tar.xz")
)
if destination is not None:
    print(f"Destination:         {destination}")
    print("Candidate zig paths:")
    for zig_path in zig_path_candidates:
        print(f"  {zig_path}")
print()
print("Read first")
print("==========")
print("  docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md")
print("  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")
print("  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
print("  docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
print()
print("Surface check")
print("=============")
print(f"  {surface_check}")
print()
print("Saved archive discovery")
print("=======================")
print(f"  {saved_archive_candidates}")
print("  Use this first when the saved archives root is known but the exact matching Zig archive path is not.")
print()
if restore_check is None:
    print("Archive restore commands")
    print("========================")
    print("  Re-run with --archive /path/to/zig-0.15.2.tar.xz after using the saved-archive discovery helper to choose the matching Zig archive.")
else:
    print("Archive restore commands")
    print("========================")
    print(f"  {restore_check}")
    print(f"  {restore_run}")
    print()
    print("Suggested follow-up")
    print("===================")
    print(f"  {recovery}")
    print(f"  {readiness}")
    print("  Replace <restored-zig-path> with the actual zig path printed by restore_zig_toolchain_archive.sh after extraction.")
print()
print("Working rules")
print("=============")
print("  - Run the surface check first so route drift fails fast before toolchain staging starts.")
print("  - Use the saved-archive discovery command before hand-building an archive path when the saved archive bundle is present.")
print("  - Keep the fallback Zig archive override on this route so saved-archive discovery, restore, recovery, and readiness commands stay aligned on one helper surface.")
print("  - Prefer a Zig 0.15.x archive for honest branch validation on this headed-mode branch.")
print("  - Treat the attached Zig 0.17 dev archive as a surfaced stopgap input, not as issue #3 validation evidence.")
print("  - Use the restore_check_only command before extraction when a run only needs the derived destination and follow-up commands.")
print("  - After restore, rerun the recovery route so the current workspace can rediscover the staged Zig candidate.")
print("  - Reopen the direct Page.zig plus win32_backend.zig runtime patch only after the matching-line readiness helper stops reporting the environment as the blocker.")
PY
