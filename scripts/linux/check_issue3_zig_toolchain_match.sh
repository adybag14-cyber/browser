#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_zig_toolchain_match.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Fail fast when no branch-compatible Zig 0.15.x toolchain is staged for the
issue #3 Linux/WSL recovery route.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
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
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

python3 - "${REPO_ROOT}" "${TOOLCHAINS_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
toolchains_root = pathlib.Path(sys.argv[2]).resolve()
fallback_zig_archive = pathlib.Path(sys.argv[3]).resolve() if sys.argv[3] else None
emit_json = sys.argv[4] == "1"

build_zon = repo_root / "build.zig.zon"
if not build_zon.is_file():
    raise SystemExit(f"build.zig.zon not found under {repo_root}")

minimum_match = re.search(
    r'\.minimum_zig_version\s*=\s*"([^"]+)"',
    build_zon.read_text(encoding="utf-8"),
)
if minimum_match is None:
    raise SystemExit("Could not find minimum_zig_version in build.zig.zon")
minimum_zig = minimum_match.group(1)

semver_re = re.compile(r"(\d+)\.(\d+)\.(\d+)")
fallback_version_re = re.compile(r"(\d+\.\d+\.\d+)")
patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")


def parse_semver(text: str) -> tuple[int, int, int]:
    match = semver_re.search(text)
    if match is None:
        raise ValueError(text)
    return tuple(int(part) for part in match.groups())


def classify(version_text: str) -> str:
    minimum_parts = parse_semver(minimum_zig)
    actual_parts = parse_semver(version_text)
    if actual_parts < minimum_parts:
        return "older-than-minimum"
    if actual_parts[:2] == minimum_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


candidates: list[dict[str, str]] = []
matching_candidates: list[dict[str, str]] = []
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
            record = {"path": str(resolved), "version": version, "status": status}
            candidates.append(record)
            if status == "matches-expected-line":
                matching_candidates.append(record)

fallback_record: dict[str, str] | None = None
if fallback_zig_archive is not None and fallback_zig_archive.is_file():
    version_match = fallback_version_re.search(fallback_zig_archive.name)
    if version_match is not None:
        fallback_version = version_match.group(1)
        fallback_record = {
            "path": str(fallback_zig_archive),
            "version": fallback_version,
            "status": classify(fallback_version),
        }
    else:
        fallback_record = {
            "path": str(fallback_zig_archive),
            "version": "unknown",
            "status": "unknown-version",
        }

failures: list[str] = []
if not matching_candidates:
    minimum_parts = parse_semver(minimum_zig)
    failures.append(
        f"no staged Zig candidate under {toolchains_root} matches the branch's expected "
        f"{minimum_parts[0]}.{minimum_parts[1]}.x line"
    )
    if fallback_record is None:
        failures.append("no surfaced fallback Zig archive is available beside the repo workspace")
    elif fallback_record["status"] == "mismatched-line":
        failures.append(
            f"fallback Zig archive {pathlib.Path(fallback_record['path']).name} surfaces Zig "
            f"{fallback_record['version']}, which is not honest validation for this branch"
        )
    elif fallback_record["status"] == "older-than-minimum":
        failures.append(
            f"fallback Zig archive {pathlib.Path(fallback_record['path']).name} is older than the branch minimum {minimum_zig}"
        )

report = {
    "status": "failed" if failures else "passed",
    "repo_root": str(repo_root),
    "minimum_zig": minimum_zig,
    "toolchains_root": str(toolchains_root),
    "zig_candidates": candidates,
    "matching_zig_candidates": matching_candidates,
    "fallback_zig_archive": fallback_record,
    "failures": failures,
    "suggested_next_step": (
        f"Run bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root {repo_root}"
        if failures
        else None
    ),
}

if emit_json:
    print(json.dumps(report, indent=2))
    raise SystemExit(1 if failures else 0)

print(f"Repo root: {repo_root}")
print(f"Minimum Zig from build.zig.zon: {minimum_zig}")
print(f"Toolchains root: {toolchains_root}")
if candidates:
    print("Discovered Zig candidates:")
    for candidate in candidates:
        print(f"  - {candidate['path']} [{candidate['version']}; {candidate['status']}]")
else:
    print("Discovered Zig candidates: none")

if fallback_record is not None:
    print(
        "Fallback Zig archive: "
        f"{fallback_record['path']} [{fallback_record['version']}; {fallback_record['status']}]"
    )

if failures:
    print("\nMatching Zig toolchain check failed:", file=sys.stderr)
    for failure in failures:
        print(f"  - {failure}", file=sys.stderr)
    print(
        "\nSuggested next step: "
        f"bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root {repo_root}",
        file=sys.stderr,
    )
    raise SystemExit(1)

print("\nMatching Zig toolchain check passed.")
PY
