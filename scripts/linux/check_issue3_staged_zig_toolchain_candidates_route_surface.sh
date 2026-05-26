#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--json]

Fail fast when the staged Zig toolchain candidates route is missing its branch-
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

doc_path = repo_root / "docs" / "ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md"
helper_path = repo_root / "scripts" / "check_issue3_staged_zig_toolchain_candidates.py"
rerun_helper_path = repo_root / "scripts" / "check_issue3_build_readiness_rerun.py"
matching_gate_path = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"
recovery_route_path = repo_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"

failures: list[str] = []
for label, path in (
    ("staged Zig candidate route note", doc_path),
    ("staged Zig candidate helper", helper_path),
    ("build-readiness rerun helper", rerun_helper_path),
    ("matching-line gate", matching_gate_path),
    ("Zig recovery route", recovery_route_path),
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
        failures.append(
            "staged Zig candidate helper produced no JSON output" + detail
        )
    else:
        try:
            helper_report = json.loads(completed.stdout)
        except json.JSONDecodeError as exc:
            failures.append(f"staged Zig candidate helper returned invalid JSON: {exc}")

    if helper_report is not None:
        required_keys = (
            "status",
            "repo_root",
            "toolchains_root",
            "minimum_zig",
            "candidate_count",
            "preferred_candidate",
            "candidates",
        )
        for key in required_keys:
            if key not in helper_report:
                failures.append(f"staged Zig candidate helper JSON is missing `{key}`")
        preferred_candidate = helper_report.get("preferred_candidate")
        if preferred_candidate:
            for key in ("path_export", "zig_export", "version"):
                if key not in preferred_candidate:
                    failures.append(
                        f"staged Zig candidate helper preferred candidate is missing `{key}`"
                    )

result = {
    "status": "passed" if not failures else "failed",
    "repo_root": str(repo_root),
    "toolchains_root": str(toolchains_root),
    "doc_path": str(doc_path),
    "helper_path": str(helper_path),
    "rerun_helper_path": str(rerun_helper_path),
    "matching_gate_path": str(matching_gate_path),
    "recovery_route_path": str(recovery_route_path),
    "helper_status": helper_report.get("status") if isinstance(helper_report, dict) else "",
    "minimum_zig": helper_report.get("minimum_zig") if isinstance(helper_report, dict) else "",
    "failures": failures,
}

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if failures else 0)

print("Issue #3 staged Zig toolchain candidates route surface")
print()
print(f"Repo root:           {repo_root}")
print(f"Toolchains root:     {toolchains_root}")
print(f"Route note:          {doc_path}")
print(f"Candidate helper:    {helper_path}")
print(f"Rerun helper:        {rerun_helper_path}")
print(f"Matching-line gate:  {matching_gate_path}")
print(f"Recovery route:      {recovery_route_path}")
if result["minimum_zig"]:
    print(f"Minimum Zig:         {result['minimum_zig']}")
if result["helper_status"]:
    print(f"Helper status:       {result['helper_status']}")

if failures:
    print("\nStaged Zig candidates route surface check failed:", file=sys.stderr)
    for failure in failures:
        print(f"  - {failure}", file=sys.stderr)
    raise SystemExit(1)

print("\nStaged Zig candidates route surface check passed.")
PY
