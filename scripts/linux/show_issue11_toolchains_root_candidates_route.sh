#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue11_toolchains_root_candidates_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live-helper-checkout] \
    [--json]

Print the issue #11 toolchains-root route for Linux or WSL re-entry work.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --helper-root)
            HELPER_ROOT="$2"
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

python3 - "${REPO_ROOT}" "${HELPER_ROOT}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import shlex
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
helper_root = sys.argv[2]
emit_json = sys.argv[3] == "1"


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


helper_script = repo_root / "scripts" / "check_issue11_toolchains_root_candidates.py"
surface_script = repo_root / "scripts" / "linux" / "check_issue11_toolchains_root_candidates_route_surface.sh"
workspace_context_script = repo_root / "scripts" / "check_issue3_workspace_context.py"
nested_preflight_script = repo_root / "scripts" / "linux" / "run_issue11_nested_workspace_saved_memory_preflight.sh"
zig_recovery_script = repo_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"

helper_command = [
    sys.executable,
    str(helper_script),
    "--repo-root",
    str(repo_root),
    "--json",
]
if helper_root:
    helper_command.extend(("--helper-root", helper_root))

completed = subprocess.run(
    helper_command,
    check=False,
    capture_output=True,
    text=True,
)
if not completed.stdout.strip():
    detail = completed.stderr.strip()
    if detail:
        detail = f"; stderr: {detail}"
    raise SystemExit(f"toolchains-root helper produced no JSON output{detail}")

try:
    helper_report = json.loads(completed.stdout)
except json.JSONDecodeError as exc:
    raise SystemExit(f"toolchains-root helper returned invalid JSON: {exc}") from exc

surface_command = format_command(["bash", str(surface_script), "--repo-root", str(repo_root)])
workspace_context_command = format_command(
    helper_report.get("suggested_workspace_context_command")
    or [sys.executable, str(workspace_context_script), "--repo-root", str(repo_root)]
)
nested_preflight_command = format_command(
    helper_report.get("suggested_nested_preflight_command")
    or ["bash", str(nested_preflight_script), "--repo-root", str(repo_root)]
)
readiness_command = format_command(helper_report.get("suggested_readiness_command", []))
zig_recovery_command = format_command(helper_report.get("suggested_zig_recovery_command", []))

result = {
    "issue": "Issue #11 toolchains-root route",
    "repo_root": str(repo_root),
    "route_note_path": str(repo_root / "docs" / "ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md"),
    "preferred_toolchains_root": helper_report.get("preferred_toolchains_root"),
    "hidden_toolchains_root": helper_report.get("hidden_toolchains_root"),
    "visible_toolchains_root": helper_report.get("visible_toolchains_root"),
    "helper_report": helper_report,
    "commands": {
        "route_surface": surface_command,
        "toolchains_root_helper": format_command(helper_command[:-1]),
        "workspace_context_helper": workspace_context_command,
        "nested_saved_memory_preflight": nested_preflight_command,
        "linux_build_readiness": readiness_command,
        "zig_toolchain_recovery_route": zig_recovery_command,
    },
    "notes": [
        "Run route_surface first so note drift or helper drift fails fast before a rerun trusts the toolchains-root handoff.",
        "Use the helper when both .toolchains and toolchains/ may be visible above the checkout and the next rerun should stop guessing.",
        "Treat preferred_toolchains_root as the shared override for the next saved-memory preflight, readiness rerun, and Zig recovery command from the same workspace layout.",
        "Run the printed workspace-context helper first when the checkout sits deeper than the default sibling layout and the practical shared roots still need to be surfaced.",
        "Run the printed nested saved-memory preflight when the toolchains root is known but the rerun still needs the helper, Memory, agent-files, and restored-checkout roots threaded through one wrapper.",
        "Run the printed Zig recovery route when the toolchains-root question is settled but the branch-compatible Zig 0.15.x line is still missing."
    ],
}

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(0)

print("Issue #11 toolchains-root route")
print()
print(f"Repo root:                 {repo_root}")
print(f"Route note:                {result['route_note_path']}")
print(f"Hidden .toolchains root:   {result['hidden_toolchains_root'] or 'not found'}")
print(f"Visible toolchains root:   {result['visible_toolchains_root'] or 'not found'}")
print(f"Preferred toolchains root: {result['preferred_toolchains_root']}")
print()
print("Read first")
print("==========")
print("  docs/ISSUE11_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md")
print("  docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md")
print("  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
print("  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")
print()
print("Suggested route")
print("===============")
print("  Route surface check:")
print(f"    {surface_command}")
print()
print("  Toolchains-root helper:")
print(f"    {format_command(helper_command[:-1])}")
print()
print("  Workspace-context helper:")
print(f"    {workspace_context_command}")
print()
print("  Issue #11 nested saved-memory preflight:")
print(f"    {nested_preflight_command}")
print()
print("  Linux build-readiness handoff:")
print(f"    {readiness_command}")
print()
print("  Zig toolchain recovery route:")
print(f"    {zig_recovery_command}")
print()
print("Working rules")
print("=============")
for note in result["notes"]:
    print(f"  - {note}")
PY
