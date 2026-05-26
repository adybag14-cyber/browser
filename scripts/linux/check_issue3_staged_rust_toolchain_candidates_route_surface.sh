#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--json]

Fail fast when the staged Rust toolchain candidates route is missing its branch-
local note or helper scripts, and confirm that the staged-toolchain helper
returns the core JSON fields needed by the issue #11 Linux or WSL re-entry
lane.
EOF
}

resolve_path() {
    python3 - "$1" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
}

locate_first_existing() {
    python3 - "$1" "$2" <<'PY'
import pathlib
import sys

start = pathlib.Path(sys.argv[1]).resolve()
relative = pathlib.Path(sys.argv[2])
for ancestor in (start, *start.parents):
    candidate = ancestor / relative
    if candidate.exists():
        print(candidate.resolve())
        break
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
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
    DISCOVERED_TOOLCHAINS_ROOT="$(locate_first_existing "${REPO_ROOT}" "toolchains" || true)"
    if [[ -n "${DISCOVERED_TOOLCHAINS_ROOT}" ]]; then
        TOOLCHAINS_ROOT="${DISCOVERED_TOOLCHAINS_ROOT}"
    else
        TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
    fi
fi
TOOLCHAINS_ROOT="$(resolve_path "${TOOLCHAINS_ROOT}")"

python3 - "${REPO_ROOT}" "${TOOLCHAINS_ROOT}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
toolchains_root = pathlib.Path(sys.argv[2]).resolve()
emit_json = sys.argv[3] == "1"

doc_path = repo_root / "docs" / "ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md"
helper_path = repo_root / "scripts" / "check_issue3_staged_rust_toolchain_candidates.py"
route_printer_path = repo_root / "scripts" / "linux" / "show_issue3_staged_rust_toolchain_candidates_route.sh"
saved_archive_route_path = repo_root / "scripts" / "linux" / "show_issue3_saved_rust_archive_candidates_route.sh"
saved_toolchain_route_path = repo_root / "scripts" / "linux" / "show_issue3_saved_rust_toolchain_route.sh"
build_bridge_route_path = repo_root / "scripts" / "linux" / "show_issue3_saved_rust_build_readiness_route.sh"
progress_tracker_route_path = repo_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh"

failures: list[str] = []
for label, path in (
    ("staged Rust candidate route note", doc_path),
    ("staged Rust candidate helper", helper_path),
    ("staged Rust candidate route printer", route_printer_path),
    ("saved Rust archive route", saved_archive_route_path),
    ("saved Rust toolchain route", saved_toolchain_route_path),
    ("saved Rust build-readiness bridge", build_bridge_route_path),
    ("issue #11 progress tracker route", progress_tracker_route_path),
):
    if not path.is_file():
        failures.append(f"missing {label}: expected {path}")

helper_report: dict[str, object] | None = None
route_report: dict[str, object] | None = None
if not failures:
    command = [
        sys.executable,
        str(helper_path),
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--json",
    ]
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
        failures.append("staged Rust candidate helper produced no JSON output" + detail)
    else:
        try:
            helper_report = json.loads(completed.stdout)
        except json.JSONDecodeError as exc:
            failures.append(f"staged Rust candidate helper returned invalid JSON: {exc}")

    route_command = [
        "bash",
        str(route_printer_path),
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--json",
    ]
    route_completed = subprocess.run(
        route_command,
        check=False,
        capture_output=True,
        text=True,
    )
    if not route_completed.stdout.strip():
        detail = route_completed.stderr.strip()
        if detail:
            detail = f"; stderr: {detail}"
        failures.append("staged Rust candidate route printer produced no JSON output" + detail)
    else:
        try:
            route_report = json.loads(route_completed.stdout)
        except json.JSONDecodeError as exc:
            failures.append(f"staged Rust candidate route printer returned invalid JSON: {exc}")

    if helper_report is not None:
        required_keys = (
            "status",
            "repo_root",
            "toolchains_root",
            "expected_rust_version",
            "expected_rust_line",
            "candidate_count",
            "preferred_candidate",
            "candidates",
        )
        for key in required_keys:
            if key not in helper_report:
                failures.append(f"staged Rust candidate helper JSON is missing `{key}`")
        preferred_candidate = helper_report.get("preferred_candidate")
        if preferred_candidate:
            for key in ("path_export", "cargo_export", "rustc_export", "cargo_version", "rustc_version"):
                if key not in preferred_candidate:
                    failures.append(
                        f"staged Rust candidate helper preferred candidate is missing `{key}`"
                    )

    if route_report is not None:
        commands = route_report.get("commands")
        if not isinstance(commands, dict):
            failures.append("staged Rust candidate route printer JSON is missing `commands`")
        else:
            progress_tracker_command = commands.get("progress_tracker_route")
            if not isinstance(progress_tracker_command, str):
                failures.append(
                    "staged Rust candidate route printer JSON is missing `commands.progress_tracker_route`"
                )
            else:
                for fragment in (
                    "--saved-archives-root",
                    str(route_report.get("saved_archives_root")),
                    "--toolchains-root",
                    str(route_report.get("toolchains_root")),
                ):
                    if fragment not in progress_tracker_command:
                        failures.append(
                            "staged Rust candidate progress-tracker handoff is missing "
                            f"`{fragment}`"
                        )

result = {
    "status": "passed" if not failures else "failed",
    "repo_root": str(repo_root),
    "toolchains_root": str(toolchains_root),
    "doc_path": str(doc_path),
    "helper_path": str(helper_path),
    "route_printer_path": str(route_printer_path),
    "saved_archive_route_path": str(saved_archive_route_path),
    "saved_toolchain_route_path": str(saved_toolchain_route_path),
    "build_bridge_route_path": str(build_bridge_route_path),
    "progress_tracker_route_path": str(progress_tracker_route_path),
    "helper_status": helper_report.get("status") if isinstance(helper_report, dict) else "",
    "expected_rust_version": helper_report.get("expected_rust_version") if isinstance(helper_report, dict) else "",
    "expected_rust_line": helper_report.get("expected_rust_line") if isinstance(helper_report, dict) else "",
    "route_saved_archives_root": route_report.get("saved_archives_root") if isinstance(route_report, dict) else "",
    "route_toolchains_root": route_report.get("toolchains_root") if isinstance(route_report, dict) else "",
    "failures": failures,
}

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if failures else 0)

print("Issue #3 staged Rust toolchain candidates route surface")
print()
print(f"Repo root:               {repo_root}")
print(f"Toolchains root:         {toolchains_root}")
print(f"Route note:              {doc_path}")
print(f"Candidate helper:        {helper_path}")
print(f"Route printer:           {route_printer_path}")
print(f"Saved archive route:     {saved_archive_route_path}")
print(f"Saved Rust route:        {saved_toolchain_route_path}")
print(f"Build-readiness bridge:  {build_bridge_route_path}")
print(f"Issue #11 route:         {progress_tracker_route_path}")
if result["expected_rust_version"]:
    print(f"Expected Rust version:   {result['expected_rust_version']}")
if result["expected_rust_line"]:
    print(f"Expected Rust line:      {result['expected_rust_line']}")
if result["helper_status"]:
    print(f"Helper status:           {result['helper_status']}")
if result["route_saved_archives_root"]:
    print(f"Route saved archives:    {result['route_saved_archives_root']}")
if result["route_toolchains_root"]:
    print(f"Route toolchains root:   {result['route_toolchains_root']}")

if failures:
    print("\nStaged Rust candidates route surface check failed:", file=sys.stderr)
    for failure in failures:
        print(f"  - {failure}", file=sys.stderr)
    raise SystemExit(1)

print("\nStaged Rust candidates route surface check passed.")
PY