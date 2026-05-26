#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_zig_toolchain_match.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Fail fast when no branch-compatible Zig 0.15.x toolchain is staged for the
issue #3 Linux/WSL recovery route, and surface any saved restore candidate that
matches the branch line before broader readiness is retried.
EOF
}

normalize_saved_archives_root() {
    local raw_root="$1"
    if [[ -d "${raw_root}/dependencies" ]]; then
        raw_root="${raw_root}/dependencies"
    fi
    if [[ -d "${raw_root}" ]]; then
        (
            cd "${raw_root}"
            pwd
        )
        return 0
    fi
    printf '%s\n' "${raw_root}"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
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
    TOOLCHAINS_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "toolchains" || true)"
    if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
        TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
    fi
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "memory/repo_archives/browser" || true)"
    if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
        SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
    fi
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(resolve_first_existing_path "${REPO_ROOT}" "agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz" || true)"
    if [[ -z "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    fi
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

python3 - "${REPO_ROOT}" "${TOOLCHAINS_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" "${JSON}" <<'PY'
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
fallback_zig_archive = pathlib.Path(sys.argv[4]).resolve() if sys.argv[4] else None
emit_json = sys.argv[5] == "1"

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
toolchain_patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")


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


def load_saved_archive_report() -> tuple[
    list[dict[str, str]],
    dict[str, str] | None,
    str | None,
    str | None,
    str | None,
]:
    helper_path = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
    if not helper_path.is_file():
        return [], None, None, None, f"saved archive candidate helper is missing: {helper_path}"

    command = [
        sys.executable,
        str(helper_path),
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
        "--json",
    ]
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return [], None, None, None, f"saved archive candidate helper could not run: {exc}"

    helper_stdout = completed.stdout.strip()
    if not helper_stdout:
        detail = completed.stderr.strip()
        if detail:
            detail = f"; stderr: {detail}"
        return [], None, None, None, f"saved archive candidate helper produced no JSON output{detail}"

    try:
        helper_report = json.loads(helper_stdout)
    except json.JSONDecodeError as exc:
        return [], None, None, None, f"saved archive candidate helper returned invalid JSON: {exc}"

    commands = helper_report.get("commands") or {}
    return (
        helper_report.get("zig_archives") or [],
        helper_report.get("preferred_archive"),
        commands.get("restore_check"),
        commands.get("restore"),
        None,
    )


candidates: list[dict[str, str]] = []
matching_candidates: list[dict[str, str]] = []
seen: set[pathlib.Path] = set()

if toolchains_root.is_dir():
    for pattern in toolchain_patterns:
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

(
    saved_archives,
    preferred_saved_archive,
    preferred_restore_check,
    preferred_restore,
    saved_archive_helper_warning,
) = load_saved_archive_report()

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

saved_archive_discovery_command = None
if (repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py").is_file():
    saved_archive_discovery_parts = [
        "python",
        str(repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"),
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
    ]
    if fallback_zig_archive is not None:
        saved_archive_discovery_parts.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
    saved_archive_discovery_command = " ".join(shlex.quote(part) for part in saved_archive_discovery_parts)

failures: list[str] = []
if not matching_candidates:
    minimum_parts = parse_semver(minimum_zig)
    failures.append(
        f"no staged Zig candidate under {toolchains_root} matches the branch's expected "
        f"{minimum_parts[0]}.{minimum_parts[1]}.x line"
    )
    if preferred_saved_archive is not None:
        failures.append(
            f"saved Zig archive {pathlib.Path(preferred_saved_archive['path']).name} matches that line but is not staged yet"
        )
    elif saved_archive_helper_warning is not None:
        failures.append(saved_archive_helper_warning)
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

suggested_next_step = None
if failures:
    suggested_next_step = (
        preferred_restore_check
        if preferred_restore_check is not None
        else f"bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root {repo_root}"
    )

report = {
    "status": "failed" if failures else "passed",
    "repo_root": str(repo_root),
    "minimum_zig": minimum_zig,
    "toolchains_root": str(toolchains_root),
    "saved_archives_root": str(saved_archives_root),
    "zig_candidates": candidates,
    "matching_zig_candidates": matching_candidates,
    "saved_zig_archives": saved_archives,
    "preferred_saved_archive": preferred_saved_archive,
    "preferred_saved_archive_restore_check": preferred_restore_check,
    "preferred_saved_archive_restore": preferred_restore,
    "saved_archive_discovery_command": saved_archive_discovery_command,
    "fallback_zig_archive": fallback_record,
    "saved_archive_helper_warning": saved_archive_helper_warning,
    "failures": failures,
    "suggested_next_step": suggested_next_step,
}

if emit_json:
    print(json.dumps(report, indent=2))
    raise SystemExit(1 if failures else 0)

print(f"Repo root: {repo_root}")
print(f"Minimum Zig from build.zig.zon: {minimum_zig}")
print(f"Toolchains root: {toolchains_root}")
print(f"Saved archives root: {saved_archives_root}")
if candidates:
    print("Discovered Zig candidates:")
    for candidate in candidates:
        print(f"  - {candidate['path']} [{candidate['version']}; {candidate['status']}]")
else:
    print("Discovered Zig candidates: none")

if saved_archives:
    print("Saved Zig archives:")
    for archive in saved_archives:
        version = archive.get("version") or "unknown"
        top_level = archive.get("top_level") or ""
        if top_level:
            print(f"  - {archive['path']} [top-level={top_level}; {version}; {archive['status']}]")
        else:
            print(f"  - {archive['path']} [{version}; {archive['status']}]")
else:
    print("Saved Zig archives: none")

if preferred_saved_archive is not None and preferred_restore_check is not None and preferred_restore is not None:
    print("Preferred saved archive restore:")
    print(f"  {preferred_restore_check}")
    print(f"  {preferred_restore}")

if saved_archive_discovery_command is not None:
    print("Saved archive candidate discovery:")
    print(f"  {saved_archive_discovery_command}")

if fallback_record is not None:
    print(
        "Fallback Zig archive: "
        f"{fallback_record['path']} [{fallback_record['version']}; {fallback_record['status']}]"
    )

if saved_archive_helper_warning is not None:
    print(f"Saved archive helper warning: {saved_archive_helper_warning}")

if failures:
    print("\nMatching Zig toolchain check failed:", file=sys.stderr)
    for failure in failures:
        print(f"  - {failure}", file=sys.stderr)
    if saved_archive_discovery_command is not None:
        print(f"  - saved archive discovery: {saved_archive_discovery_command}", file=sys.stderr)
    if preferred_restore_check is not None:
        print(f"  - preferred restore check: {preferred_restore_check}", file=sys.stderr)
    print(f"\nSuggested next step: {suggested_next_step}", file=sys.stderr)
    raise SystemExit(1)

print("\nMatching Zig toolchain check passed.")
PY
