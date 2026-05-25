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
    [--json]

Print the compact issue #3 Zig toolchain archive-restore route for Linux or
WSL headed-mode recovery work.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
ARCHIVE_PATH=""
OFFLINE_DEPS_ROOT=""
SAVED_ARCHIVES_ROOT=""
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

SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
RESTORE_SCRIPT="${REPO_ROOT}/scripts/linux/restore_zig_toolchain_archive.sh"
RECOVERY_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
READINESS_SCRIPT="${REPO_ROOT}/scripts/check_linux_build_readiness.py"

python3 - "${REPO_ROOT}" "${TOOLCHAINS_ROOT}" "${ARCHIVE_PATH}" "${OFFLINE_DEPS_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${SURFACE_SCRIPT}" "${RESTORE_SCRIPT}" "${RECOVERY_SCRIPT}" "${READINESS_SCRIPT}" "${JSON}" <<'PY'
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
surface_script = pathlib.Path(sys.argv[6]).resolve()
restore_script = pathlib.Path(sys.argv[7]).resolve()
recovery_script = pathlib.Path(sys.argv[8]).resolve()
readiness_script = pathlib.Path(sys.argv[9]).resolve()
emit_json = sys.argv[10] == "1"


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
restore_check = None
restore_run = None
readiness = None
if archive_path is not None:
    restore_check = quote(
        [
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
    )
    restore_run = quote(
        [
            "bash",
            str(restore_script),
            "--browser-root",
            str(repo_root),
            "--toolchains-root",
            str(toolchains_root),
            "--archive",
            str(archive_path),
        ]
    )
    readiness = quote(
        [
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
    )

recovery = quote(
    [
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
)

result = {
    "issue": "Google issue #3 Zig toolchain archive restore route",
    "repo_root": str(repo_root),
    "toolchains_root": str(toolchains_root),
    "saved_archives_root": str(saved_archives_root),
    "offline_deps_root": str(offline_deps_root),
    "archive_path": str(archive_path) if archive_path else "",
    "destination": str(destination) if destination else "",
    "zig_path_candidates": zig_path_candidates,
    "commands": {
        "surface_check": surface_check,
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
if restore_check is None:
    print("Archive restore commands")
    print("========================")
    print("  Re-run with --archive /path/to/zig-0.15.2.tar.xz to print the exact check-only, restore, and readiness commands.")
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
print("  - Prefer a Zig 0.15.x archive for honest branch validation on this headed-mode branch.")
print("  - Use the restore_check_only command before extraction when a run only needs the derived destination and follow-up commands.")
print("  - After restore, rerun the recovery route so the current workspace can rediscover the staged Zig candidate.")
print("  - Reopen the direct Page.zig plus win32_backend.zig runtime patch only after the matching-line readiness helper stops reporting the environment as the blocker.")
PY
