#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Fail fast when the saved Zig archive candidate route is missing its branch-local
note or helper scripts, and confirm that the candidate helper returns the core
JSON fields needed by the Linux or WSL issue #3 toolchain recovery lane.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

python3 - "${REPO_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${TOOLCHAINS_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
saved_archives_root = pathlib.Path(sys.argv[2]).resolve()
toolchains_root = pathlib.Path(sys.argv[3]).resolve()
fallback_zig_archive = pathlib.Path(sys.argv[4]).resolve() if sys.argv[4] else None
emit_json = sys.argv[5] == "1"

doc_path = repo_root / "docs" / "ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
helper_path = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
restore_helper_path = repo_root / "scripts" / "linux" / "restore_zig_toolchain_archive.sh"
build_zon_path = repo_root / "build.zig.zon"

failures: list[str] = []
for label, path in (
    ("saved Zig archive candidate route note", doc_path),
    ("saved Zig archive candidate helper", helper_path),
    ("Zig toolchain archive restore helper", restore_helper_path),
    ("build metadata", build_zon_path),
):
    if not path.is_file():
        failures.append(f"missing {label}: expected {path}")

helper_report: dict[str, object] | None = None
if not failures:
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

    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    if not completed.stdout.strip():
        detail = completed.stderr.strip()
        if detail:
            detail = f"; stderr: {detail}"
        failures.append(
            "saved Zig archive candidate helper produced no JSON output" + detail
        )
    else:
        try:
            helper_report = json.loads(completed.stdout)
        except json.JSONDecodeError as exc:
            failures.append(f"saved Zig archive candidate helper returned invalid JSON: {exc}")

    if helper_report is not None:
        required_keys = (
            "status",
            "repo_root",
            "saved_archives_root",
            "toolchains_root",
            "minimum_zig",
            "zig_archives",
            "commands",
            "failures",
        )
        for key in required_keys:
            if key not in helper_report:
                failures.append(f"saved Zig archive candidate helper JSON is missing `{key}`")
        commands = helper_report.get("commands")
        if not isinstance(commands, dict):
            failures.append("saved Zig archive candidate helper JSON has a non-object `commands` field")
        else:
            for key in ("restore_check", "restore"):
                preferred_archive = helper_report.get("preferred_archive")
                if preferred_archive and key not in commands:
                    failures.append(
                        f"saved Zig archive candidate helper JSON is missing `{key}` for the preferred archive route"
                    )

result = {
    "status": "passed" if not failures else "failed",
    "repo_root": str(repo_root),
    "saved_archives_root": str(saved_archives_root),
    "toolchains_root": str(toolchains_root),
    "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else "",
    "doc_path": str(doc_path),
    "helper_path": str(helper_path),
    "restore_helper_path": str(restore_helper_path),
    "helper_status": helper_report.get("status") if isinstance(helper_report, dict) else "",
    "minimum_zig": helper_report.get("minimum_zig") if isinstance(helper_report, dict) else "",
    "failures": failures,
}

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if failures else 0)

print("Issue #3 saved Zig archive candidates route surface")
print()
print(f"Repo root:           {repo_root}")
print(f"Saved archives root: {saved_archives_root}")
print(f"Toolchains root:     {toolchains_root}")
print(
    "Fallback archive:    "
    f"{fallback_zig_archive if fallback_zig_archive is not None else 'not found beside the repo workspace'}"
)
print(f"Route note:          {doc_path}")
print(f"Candidate helper:    {helper_path}")
print(f"Restore helper:      {restore_helper_path}")
if result["minimum_zig"]:
    print(f"Minimum Zig line:    {result['minimum_zig']}")
if result["helper_status"]:
    print(f"Helper status:       {result['helper_status']}")

if failures:
    print("\nSaved Zig archive candidate surface check failed:", file=sys.stderr)
    for failure in failures:
        print(f"  - {failure}", file=sys.stderr)
    raise SystemExit(1)

print("\nSaved Zig archive candidate surface check passed.")
PY
