#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_workspace_context_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #3 workspace-context route for nested or restored Linux or WSL
re-entry work.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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

python3 - "${REPO_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import shlex
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
fallback_zig_archive = sys.argv[2]
emit_json = sys.argv[3] == "1"


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


helper_script = repo_root / "scripts" / "check_issue3_workspace_context.py"
route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_workspace_context_route_surface.sh"
progress_tracker_route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_progress_tracker_route_surface.sh"
progress_tracker_route_script = repo_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh"
saved_snapshot_route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_saved_browser_snapshot_route_surface.sh"
saved_snapshot_route_script = repo_root / "scripts" / "linux" / "show_issue3_saved_browser_snapshot_route.sh"
linux_build_route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_linux_build_readiness_route_surface.sh"
linux_build_route_script = repo_root / "scripts" / "linux" / "show_issue3_linux_build_readiness_route.sh"
zig_recovery_route_script = repo_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"
saved_zig_route_surface_script = repo_root / "scripts" / "linux" / "check_issue3_saved_zig_archive_candidates_route_surface.sh"
saved_zig_route_script = repo_root / "scripts" / "linux" / "show_issue3_saved_zig_archive_candidates_route.sh"

helper_command = [
    sys.executable,
    str(helper_script),
    "--repo-root",
    str(repo_root),
    "--json",
]
if fallback_zig_archive:
    helper_command.extend(("--fallback-zig-archive", fallback_zig_archive))

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
    raise SystemExit(f"workspace-context helper produced no JSON output{detail}")

try:
    helper_report = json.loads(completed.stdout)
except json.JSONDecodeError as exc:
    raise SystemExit(f"workspace-context helper returned invalid JSON: {exc}") from exc

surface_command = format_command(
    ["bash", str(route_surface_script), "--repo-root", str(repo_root)]
)
progress_tracker_surface_command = format_command(
    ["bash", str(progress_tracker_route_surface_script), "--repo-root", str(repo_root)]
)
progress_tracker_command = format_command(
    ["bash", str(progress_tracker_route_script), "--repo-root", str(repo_root)]
    + (["--fallback-zig-archive", fallback_zig_archive] if fallback_zig_archive else [])
)
saved_snapshot_surface_command = format_command(
    ["bash", str(saved_snapshot_route_surface_script), "--repo-root", str(repo_root)]
)
saved_snapshot_command = format_command(
    ["bash", str(saved_snapshot_route_script), "--repo-root", str(repo_root)]
    + (["--fallback-zig-archive", fallback_zig_archive] if fallback_zig_archive else [])
)
linux_build_surface_command = format_command(
    ["bash", str(linux_build_route_surface_script), "--repo-root", str(repo_root)]
)
linux_build_command = format_command(
    ["bash", str(linux_build_route_script), "--repo-root", str(repo_root)]
    + (["--fallback-zig-archive", fallback_zig_archive] if fallback_zig_archive else [])
)
zig_recovery_command = format_command(
    ["bash", str(zig_recovery_route_script), "--repo-root", str(repo_root)]
    + (["--fallback-zig-archive", fallback_zig_archive] if fallback_zig_archive else [])
)
saved_zig_surface_command = format_command(
    ["bash", str(saved_zig_route_surface_script), "--repo-root", str(repo_root)]
)
saved_zig_command = format_command(
    ["bash", str(saved_zig_route_script), "--repo-root", str(repo_root)]
    + (["--fallback-zig-archive", fallback_zig_archive] if fallback_zig_archive else [])
)
readiness_command = format_command(helper_report.get("suggested_readiness_command", []))

result = {
    "issue": "Google issue #3 workspace-context route",
    "repo_root": str(repo_root),
    "route_note_path": str(repo_root / "docs" / "ISSUE3_WORKSPACE_CONTEXT_ROUTE.md"),
    "memory_root": helper_report.get("memory_root"),
    "agent_files_root": helper_report.get("agent_files_root"),
    "fallback_zig_archive": helper_report.get("fallback_zig_archive"),
    "toolchains_root": helper_report.get("toolchains_root"),
    "saved_archives_root": helper_report.get("saved_archives_root"),
    "offline_deps_root": helper_report.get("offline_deps_root"),
    "restored_checkout_root": helper_report.get("restored_checkout_root"),
    "commands": {
        "route_surface": surface_command,
        "workspace_context_helper": format_command(helper_command[:-1]),
        "issue11_progress_tracker_route_surface": progress_tracker_surface_command,
        "issue11_progress_tracker_route": progress_tracker_command,
        "saved_browser_snapshot_route_surface": saved_snapshot_surface_command,
        "saved_browser_snapshot_route": saved_snapshot_command,
        "linux_build_readiness_route_surface": linux_build_surface_command,
        "linux_build_readiness_route": linux_build_command,
        "zig_toolchain_recovery_route": zig_recovery_command,
        "saved_zig_archive_candidates_route_surface": saved_zig_surface_command,
        "saved_zig_archive_candidates_route": saved_zig_command,
        "readiness_command": readiness_command,
    },
    "helper_report": helper_report,
    "notes": [
        "Run route_surface first so note drift or helper drift fails fast before a scheduled run trusts the wrapper route.",
        "Use the helper command first when a restored checkout sits deeper than the default sibling layout and the next route would otherwise guess the wrong shared roots.",
        "Run the printed issue #11 surface check before the tracker route when the next rerun is still environment-gated after the shared roots are surfaced.",
        "Run the printed saved-browser-snapshot surface check before the saved-browser-snapshot route when no reusable checkout exists yet after workspace discovery.",
        "Run the printed Linux build-readiness surface check before the Linux build-readiness route when the shared roots are known and the next rerun can move straight into those gates.",
        "Use the printed Zig toolchain recovery route when the next rerun already has the practical roots but still lacks a branch-compatible 0.15.x toolchain.",
        "Run the printed saved Zig archive candidates surface check before the saved Zig archive candidates route when the next rerun needs to pick or restage a branch-compatible 0.15.x archive before broader recovery is trusted.",
        "Use the printed readiness command as the shortest direct handoff once the practical roots are already surfaced and the next step does not need a broader route wrapper.",
        "Thread --fallback-zig-archive through this route when the attached archive is outside the nearest discovered agent_files root so every follow-up route inspects the same surfaced path.",
    ],
}

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(0)

print("Google issue #3 workspace-context route")
print()
print(f"Repo root:              {repo_root}")
print(f"Route note:             {result['route_note_path']}")
print(f"Toolchains root:        {result['toolchains_root']}")
print(f"Memory root:            {result['memory_root']}")
print(f"Saved archives root:    {result['saved_archives_root']}")
print(f"Agent files root:       {result['agent_files_root']}")
print(f"Offline deps root:      {result['offline_deps_root']}")
print(f"Restored checkout root: {result['restored_checkout_root']}")
print(
    "Fallback Zig archive:   "
    f"{result['fallback_zig_archive'] or 'not found beside the repo workspace'}"
)
print()
print("Read first")
print("==========")
print("  docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md")
print("  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md")
print("  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")
print("  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
print("  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")
print("  docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md")
print()
print("Suggested route")
print("===============")
print("  Route surface check:")
print(f"    {surface_command}")
print()
print("  Workspace-context helper:")
print(f"    {format_command(helper_command[:-1])}")
print()
print("  Issue #11 progress-tracker surface check:")
print(f"    {progress_tracker_surface_command}")
print()
print("  Issue #11 progress-tracker route:")
print(f"    {progress_tracker_command}")
print()
print("  Saved-browser-snapshot surface check:")
print(f"    {saved_snapshot_surface_command}")
print()
print("  Saved-browser-snapshot route:")
print(f"    {saved_snapshot_command}")
print()
print("  Linux build-readiness surface check:")
print(f"    {linux_build_surface_command}")
print()
print("  Linux build-readiness route:")
print(f"    {linux_build_command}")
print()
print("  Zig toolchain recovery route:")
print(f"    {zig_recovery_command}")
print()
print("  Saved Zig archive candidates surface check:")
print(f"    {saved_zig_surface_command}")
print()
print("  Saved Zig archive candidates route:")
print(f"    {saved_zig_command}")
print()
print("  Shortest readiness handoff:")
print(f"    {readiness_command}")
print()
print("Working rules")
print("=============")
for note in result["notes"]:
    print(f"  - {note}")
PY
