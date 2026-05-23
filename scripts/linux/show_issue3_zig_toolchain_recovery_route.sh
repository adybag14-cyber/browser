#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #3 Linux or WSL Zig toolchain recovery route for the blocked
Enter-submit runtime lane.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
SAVED_ARCHIVES_ROOT=""
OFFLINE_DEPS_ROOT=""
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
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
            shift 2
            ;;
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/offline-deps"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

python3 - "${REPO_ROOT}" "${TOOLCHAINS_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${OFFLINE_DEPS_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import re
import shlex
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
toolchains_root = pathlib.Path(sys.argv[2]).resolve()
saved_archives_root = pathlib.Path(sys.argv[3]).resolve()
offline_deps_root = pathlib.Path(sys.argv[4]).resolve()
fallback_zig_archive = sys.argv[5]
emit_json = sys.argv[6] == "1"

build_zon = repo_root / "build.zig.zon"
if not build_zon.is_file():
    raise SystemExit(f"build.zig.zon not found under {repo_root}")

match = re.search(
    r'\.minimum_zig_version\s*=\s*"([^"]+)"',
    build_zon.read_text(encoding="utf-8"),
)
if match is None:
    raise SystemExit("Could not find minimum_zig_version in build.zig.zon")
minimum_zig = match.group(1)

semver_re = re.compile(r"^(\d+)\.(\d+)\.(\d+)")


def parse_semver(text: str) -> tuple[int, int, int]:
    match = semver_re.match(text)
    if match is None:
        raise ValueError(text)
    return tuple(int(part) for part in match.groups())


def classify(actual: str) -> str:
    minimum_parts = parse_semver(minimum_zig)
    actual_parts = parse_semver(actual)
    if actual_parts < minimum_parts:
        return "older-than-minimum"
    if actual_parts[:2] == minimum_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
candidates: list[dict[str, str]] = []
seen: set[pathlib.Path] = set()

if toolchains_root.is_dir():
    for pattern in patterns:
        for path in sorted(toolchains_root.glob(pattern)):
            resolved = path.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            try:
                completed = subprocess.run(
                    [str(resolved), "version"],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                version = completed.stdout.strip() or completed.stderr.strip()
                status = classify(version)
            except Exception:
                version = "unusable"
                status = "version-probe-failed"
            candidates.append(
                {
                    "path": str(resolved),
                    "version": version,
                    "status": status,
                }
            )

matching_candidate = next(
    (candidate for candidate in candidates if candidate["status"] == "matches-expected-line"),
    None,
)

surface_check_command = format_command(
    [
        "bash",
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
        "--repo-root",
        str(repo_root),
    ]
)
discovery_parts = [
    "python",
    "scripts/check_linux_build_readiness.py",
    "--repo-root",
    str(repo_root),
    "--skip-zig-check",
    "--skip-rust-check",
    "--expect-saved-archives",
    "--saved-archives-root",
    str(saved_archives_root),
    "--toolchains-root",
    str(toolchains_root),
]
if fallback_zig_archive:
    discovery_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
discovery_command = format_command(discovery_parts)
matching_readiness_command = None
if matching_candidate is not None:
    matching_parts = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--zig",
        matching_candidate["path"],
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-offline-deps",
        "--offline-deps-root",
        str(offline_deps_root),
        "--require-prebuilt-v8",
        "--toolchains-root",
        str(toolchains_root),
    ]
    if fallback_zig_archive:
        matching_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
    matching_readiness_command = format_command(matching_parts)

fallback_restore_check_command = None
fallback_restore_command = None
if fallback_zig_archive:
    fallback_restore_check_command = format_command(
        [
            "bash",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "--browser-root",
            str(repo_root),
            "--toolchains-root",
            str(toolchains_root),
            "--archive",
            fallback_zig_archive,
            "--check-only",
        ]
    )
    fallback_restore_command = format_command(
        [
            "bash",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "--browser-root",
            str(repo_root),
            "--toolchains-root",
            str(toolchains_root),
            "--archive",
            fallback_zig_archive,
        ]
    )

result = {
    "issue": "Google issue #3 Zig toolchain recovery route",
    "repo_root": str(repo_root),
    "toolchains_root": str(toolchains_root),
    "saved_archives_root": str(saved_archives_root),
    "offline_deps_root": str(offline_deps_root),
    "minimum_zig": minimum_zig,
    "fallback_zig_archive": fallback_zig_archive,
    "matching_candidate": matching_candidate["path"] if matching_candidate else "",
    "matching_candidate_version": matching_candidate["version"] if matching_candidate else "",
    "commands": {
        "surface_check": surface_check_command,
        "discovery": discovery_command,
    },
    "candidates": candidates,
}
if matching_readiness_command is not None:
    result["commands"]["matching_readiness"] = matching_readiness_command
if fallback_restore_check_command is not None:
    result["commands"]["fallback_restore_check"] = fallback_restore_check_command
if fallback_restore_command is not None:
    result["commands"]["fallback_restore"] = fallback_restore_command

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(0)

print("Google issue #3 Zig toolchain recovery route")
print()
print(f"Repo root:            {repo_root}")
print(f"Toolchains root:      {toolchains_root}")
print(f"Saved archives root:  {saved_archives_root}")
print(f"Offline deps root:    {offline_deps_root}")
print(f"Minimum Zig line:     {minimum_zig}")
print(
    "Fallback Zig archive: "
    f"{fallback_zig_archive or 'not found beside the repo workspace'}"
)
print()
print("Read first")
print("==========")
print("  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")
print("  docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md")
print("  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
print("  docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
print()
print("Surface check")
print("=============")
print(f"  {surface_check_command}")
print()
print("Candidate discovery")
print("===================")
print(f"  {discovery_command}")

if fallback_restore_check_command is not None and fallback_restore_command is not None:
    print()
    print("Fallback archive staging")
    print("========================")
    print(f"  {fallback_restore_check_command}")
    print(f"  {fallback_restore_command}")

if not candidates:
    print()
    print("Discovered Zig candidates: none")
    print()
    print("Working rules")
    print("=============")
    print(
        "  - Run the surface check first so missing docs or helper drift fails "
        "before the route blames the fallback Zig bundle."
    )
    print(
        f"  - Stage a Zig {minimum_zig.rsplit('.', 1)[0]}.x toolchain under "
        f"{toolchains_root} before reopening focused Linux or WSL validation."
    )
    if fallback_restore_command is not None:
        print(
            "  - If the only available archive is the attached Zig 0.17 fallback, "
            "use the fallback restore helper above so later reruns can probe it "
            "consistently from the shared toolchains area."
        )
    print(
        "  - Treat the attached Zig 0.17 dev bundle as a surfaced fallback "
        "only; it is not branch-compatible validation evidence for this checkout."
    )
    print(
        "  - After staging a matching Zig line, rerun the discovery command and "
        "then rerun the full readiness helper with that toolchain."
    )
    raise SystemExit(0)

print()
print("Discovered Zig candidates")
print("=========================")
for candidate in candidates:
    print(
        f"  - {candidate['path']} "
        f"[{candidate['version']}; {candidate['status']}]"
    )

print()
if matching_readiness_command is not None:
    print("Suggested matching readiness command")
    print("====================================")
    print(f"  {matching_readiness_command}")
    print()
    print("Working rules")
    print("=============")
    print(
        "  - Run the surface check first so missing docs or helper drift fails "
        "before the route blames the fallback Zig bundle."
    )
    print(
        f"  - Prefer {matching_candidate['path']} because it matches the branch's "
        f"{minimum_zig.rsplit('.', 1)[0]}.x Zig line."
    )
    if fallback_restore_command is not None:
        print(
            "  - Keep the fallback restore helper above as the branch-local way "
            "to restage the attached Zig archive when toolchains/ is empty on a "
            "future rerun."
        )
    print(
        "  - Keep the saved-archive, offline-dependency, and fallback-Zig path "
        "surfaces aligned with the current workspace when rerunning readiness."
    )
    print(
        "  - Only reopen the direct Page.zig plus win32_backend.zig runtime "
        "patch after this matching-line readiness pass stops reporting the "
        "environment as the blocker."
    )
else:
    print("No branch-compatible Zig candidate is staged yet.")
    print()
    print("Working rules")
    print("=============")
    print(
        "  - Run the surface check first so missing docs or helper drift fails "
        "before the route blames the fallback Zig bundle."
    )
    print(
        f"  - Ignore candidates above that are older than {minimum_zig} or that "
        "live on a different major/minor Zig line."
    )
    print(
        f"  - Stage a Zig {minimum_zig.rsplit('.', 1)[0]}.x toolchain under "
        f"{toolchains_root}, then rerun the discovery command."
    )
    if fallback_restore_command is not None:
        print(
            "  - If the only available archive is the attached Zig 0.17 fallback, "
            "use the fallback restore helper above to keep that staging step on a "
            "branch-local route instead of rebuilding the extraction command by hand."
        )
    print(
        "  - Treat the attached Zig 0.17 dev bundle as a surfaced fallback "
        "only; it is not honest issue #3 validation evidence for this branch."
    )
PY
