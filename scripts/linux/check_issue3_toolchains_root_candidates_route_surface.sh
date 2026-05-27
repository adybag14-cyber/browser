#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_toolchains_root_candidates_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Fail fast when the toolchains-root candidates route is missing its branch-local
note or helper scripts, and confirm that the issue #11 toolchains-root helper
and route printer expose the core fields needed by Linux/WSL re-entry work.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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

python3 - "${REPO_ROOT}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
emit_json = sys.argv[2] == "1"

doc_path = repo_root / "docs" / "ISSUE3_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md"
helper_path = repo_root / "scripts" / "check_issue11_toolchains_root_candidates.py"
route_printer_path = repo_root / "scripts" / "linux" / "show_issue3_toolchains_root_candidates_route.sh"
nested_preflight_path = repo_root / "scripts" / "linux" / "run_issue11_nested_workspace_saved_memory_preflight.sh"
staged_rust_route_path = repo_root / "scripts" / "linux" / "show_issue3_staged_rust_toolchain_candidates_route.sh"
staged_zig_route_path = repo_root / "scripts" / "linux" / "show_issue3_staged_zig_toolchain_candidates_route.sh"
saved_rust_bridge_path = repo_root / "scripts" / "linux" / "show_issue3_saved_rust_build_readiness_route.sh"
linux_build_route_path = repo_root / "scripts" / "linux" / "show_issue3_linux_build_readiness_route.sh"
zig_recovery_route_path = repo_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"
progress_tracker_route_path = repo_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh"

failures: list[str] = []
for label, path in (
    ("toolchains-root route note", doc_path),
    ("issue #11 toolchains-root helper", helper_path),
    ("toolchains-root route printer", route_printer_path),
    ("nested-workspace preflight helper", nested_preflight_path),
    ("staged Rust route printer", staged_rust_route_path),
    ("staged Zig route printer", staged_zig_route_path),
    ("saved Rust build-readiness bridge", saved_rust_bridge_path),
    ("Linux build-readiness route", linux_build_route_path),
    ("Zig recovery route", zig_recovery_route_path),
    ("issue #11 progress tracker route", progress_tracker_route_path),
):
    if not path.is_file():
        failures.append(f"missing {label}: expected {path}")

helper_report: dict[str, object] | None = None
route_report: dict[str, object] | None = None
if not failures:
    helper_command = [
        sys.executable,
        str(helper_path),
        "--repo-root",
        str(repo_root),
        "--json",
    ]
    helper_completed = subprocess.run(
        helper_command,
        check=False,
        capture_output=True,
        text=True,
    )
    if not helper_completed.stdout.strip():
        detail = helper_completed.stderr.strip()
        if detail:
            detail = f"; stderr: {detail}"
        failures.append("issue #11 toolchains-root helper produced no JSON output" + detail)
    else:
        try:
            helper_report = json.loads(helper_completed.stdout)
        except json.JSONDecodeError as exc:
            failures.append(f"issue #11 toolchains-root helper returned invalid JSON: {exc}")

    route_command = [
        "bash",
        str(route_printer_path),
        "--repo-root",
        str(repo_root),
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
        failures.append("toolchains-root route printer produced no JSON output" + detail)
    else:
        try:
            route_report = json.loads(route_completed.stdout)
        except json.JSONDecodeError as exc:
            failures.append(f"toolchains-root route printer returned invalid JSON: {exc}")

    if helper_report is not None:
        required_keys = (
            "status",
            "repo_root",
            "helper_root",
            "preferred_toolchains_root",
            "suggested_readiness_command",
            "suggested_nested_preflight_command",
            "suggested_zig_recovery_command",
        )
        for key in required_keys:
            if key not in helper_report:
                failures.append(f"issue #11 toolchains-root helper JSON is missing `{key}`")

    if route_report is not None:
        commands = route_report.get("commands")
        if not isinstance(commands, dict):
            failures.append("toolchains-root route printer JSON is missing `commands`")
        else:
            for key in (
                "toolchains_root_candidates",
                "nested_preflight",
                "staged_rust_route",
                "staged_zig_route",
                "saved_rust_build_bridge",
                "linux_build_readiness_helper",
                "linux_build_readiness_route",
                "zig_recovery_route",
                "progress_tracker_route",
            ):
                if not isinstance(commands.get(key), str):
                    failures.append(f"toolchains-root route printer JSON is missing `commands.{key}`")
            preferred_root = route_report.get("preferred_toolchains_root")
            if isinstance(preferred_root, str) and preferred_root:
                for key in (
                    "staged_rust_route",
                    "staged_zig_route",
                    "saved_rust_build_bridge",
                    "linux_build_readiness_helper",
                    "zig_recovery_route",
                ):
                    command = commands.get(key, "")
                    if "--toolchains-root" not in command or preferred_root not in command:
                        failures.append(
                            f"toolchains-root route handoff `{key}` is missing the surfaced --toolchains-root override"
                        )

result = {
    "status": "passed" if not failures else "failed",
    "repo_root": str(repo_root),
    "doc_path": str(doc_path),
    "helper_path": str(helper_path),
    "route_printer_path": str(route_printer_path),
    "preferred_toolchains_root": route_report.get("preferred_toolchains_root") if isinstance(route_report, dict) else "",
    "helper_status": helper_report.get("status") if isinstance(helper_report, dict) else "",
    "failures": failures,
}

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if failures else 0)

print("Issue #3 toolchains-root candidates route surface")
print()
print(f"Repo root:               {repo_root}")
print(f"Route note:              {doc_path}")
print(f"Toolchains-root helper:  {helper_path}")
print(f"Route printer:           {route_printer_path}")
if result["preferred_toolchains_root"]:
    print(f"Preferred toolchains:    {result['preferred_toolchains_root']}")
if result["helper_status"]:
    print(f"Helper status:           {result['helper_status']}")

if failures:
    print("\nToolchains-root candidates route surface check failed:", file=sys.stderr)
    for failure in failures:
        print(f"  - {failure}", file=sys.stderr)
    raise SystemExit(1)

print("\nToolchains-root candidates route surface check passed.")
PY
