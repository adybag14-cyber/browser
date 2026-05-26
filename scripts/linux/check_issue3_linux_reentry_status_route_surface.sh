#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_linux_reentry_status_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--python /path/to/python3] \
    [--json]

Fail fast when the Linux or WSL re-entry status route is missing its branch-
local note or helper scripts, and confirm that the quick-status helper still
returns the core JSON fields needed by the issue #11 lane.
EOF
}

resolve_path() {
    python3 - "$1" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
PYTHON_BIN="python3"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --python)
            PYTHON_BIN="$2"
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
PYTHON_BIN="$(resolve_path "${PYTHON_BIN}")"

"${PYTHON_BIN}" - "${REPO_ROOT}" "${PYTHON_BIN}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
python_bin = pathlib.Path(sys.argv[2]).resolve()
emit_json = sys.argv[3] == "1"

doc_path = repo_root / "docs" / "ISSUE3_LINUX_REENTRY_STATUS_ROUTE.md"
surface_path = repo_root / "scripts" / "linux" / "check_issue3_linux_reentry_status_route_surface.sh"
route_path = repo_root / "scripts" / "linux" / "show_issue3_linux_reentry_status_route.sh"
helper_path = repo_root / "scripts" / "check_issue3_linux_reentry_status.py"
workspace_route_path = repo_root / "scripts" / "linux" / "show_issue3_workspace_context_route.sh"
saved_memory_route_path = repo_root / "scripts" / "linux" / "show_issue3_saved_memory_inputs_route.sh"
zig_match_path = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"
build_readiness_path = repo_root / "scripts" / "check_linux_build_readiness.py"
progress_route_path = repo_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh"
runtime_route_path = repo_root / "scripts" / "linux" / "show_issue3_enter_submit_runtime_revalidation_route.sh"

failures: list[str] = []
for label, path in (
    ("Linux re-entry status route note", doc_path),
    ("Linux re-entry status route surface", surface_path),
    ("Linux re-entry status route printer", route_path),
    ("Linux re-entry status helper", helper_path),
    ("workspace-context route printer", workspace_route_path),
    ("saved-Memory route printer", saved_memory_route_path),
    ("Zig matching-line gate", zig_match_path),
    ("Linux build-readiness helper", build_readiness_path),
    ("issue #11 progress-tracker route printer", progress_route_path),
    ("runtime revalidation route printer", runtime_route_path),
):
    if not path.is_file():
        failures.append(f"missing {label}: expected {path}")

helper_report: dict[str, object] | None = None
if not failures:
    command = [
        str(python_bin),
        str(helper_path),
        "--repo-root",
        str(repo_root),
        "--json",
    ]
    completed = subprocess.run(command, check=False, capture_output=True, text=True)
    if not completed.stdout.strip():
        detail = completed.stderr.strip()
        if detail:
            detail = f"; stderr: {detail}"
        failures.append("Linux re-entry status helper produced no JSON output" + detail)
    else:
        try:
            loaded = json.loads(completed.stdout)
            if isinstance(loaded, dict):
                helper_report = loaded
            else:
                failures.append("Linux re-entry status helper returned non-object JSON")
        except json.JSONDecodeError as exc:
            failures.append(f"Linux re-entry status helper returned invalid JSON: {exc}")

    if helper_report is not None:
        for key in ("status", "repo_root", "components", "suggested_next_step"):
            if key not in helper_report:
                failures.append(f"Linux re-entry status helper JSON is missing `{key}`")
        components = helper_report.get("components")
        if not isinstance(components, dict):
            failures.append("Linux re-entry status helper JSON is missing the component map")
        else:
            for key in ("workspace_context", "saved_memory", "zig_match", "build_readiness"):
                if key not in components:
                    failures.append(f"Linux re-entry status helper components are missing `{key}`")

result = {
    "status": "passed" if not failures else "failed",
    "repo_root": str(repo_root),
    "python": str(python_bin),
    "doc_path": str(doc_path),
    "surface_path": str(surface_path),
    "route_path": str(route_path),
    "helper_path": str(helper_path),
    "helper_status": helper_report.get("status") if isinstance(helper_report, dict) else "",
    "suggested_next_step": helper_report.get("suggested_next_step") if isinstance(helper_report, dict) else "",
    "failures": failures,
}

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if failures else 0)

print("Issue #3 Linux re-entry status route surface")
print()
print(f"Repo root:            {repo_root}")
print(f"Python helper:        {python_bin}")
print(f"Route note:           {doc_path}")
print(f"Route surface:        {surface_path}")
print(f"Route printer:        {route_path}")
print(f"Status helper:        {helper_path}")
if result["helper_status"]:
    print(f"Helper status:        {result['helper_status']}")
if result["suggested_next_step"]:
    print(f"Suggested next step:  {result['suggested_next_step']}")

if failures:
    print("\nLinux re-entry status route surface check failed:", file=sys.stderr)
    for failure in failures:
        print(f"  - {failure}", file=sys.stderr)
    raise SystemExit(1)

print("\nLinux re-entry status route surface check passed.")
PY
