#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_browser_snapshot_archive_surface_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--json]

Print the compact saved-browser-snapshot archive-surface route for the blocked
issue #3 Linux or WSL re-entry lane.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
ARCHIVE_PATH=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
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

ARCHIVE_SURFACE_COMMAND=(
    "python"
    "${REPO_ROOT}/scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
    "--repo-root"
    "${REPO_ROOT}"
)
if [[ -n "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_SURFACE_COMMAND+=("--archive" "${ARCHIVE_PATH}")
fi

SURFACE_JSON="$(python3 - <<'PY' "${ARCHIVE_SURFACE_COMMAND[@]}"
import subprocess
import sys

completed = subprocess.run(sys.argv[1:] + ["--json"], check=True, capture_output=True, text=True)
print(completed.stdout)
PY
)"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<'PY' "${SURFACE_JSON}" "${REPO_ROOT}" "${ARCHIVE_PATH}"
import json
import sys

payload = json.loads(sys.argv[1])
repo_root = sys.argv[2]
archive_path = sys.argv[3]

route = {
    "issue": "issue3-saved-browser-snapshot-archive-surface-route",
    "repo_root": repo_root,
    "route_note_path": f"{repo_root}/docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE_ROUTE.md",
    "surface_check_command": [
        "bash",
        "scripts/linux/check_issue3_saved_browser_snapshot_archive_surface_route_surface.sh",
        "--repo-root",
        repo_root,
    ],
    "archive_surface_command": [
        "python",
        "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
        "--repo-root",
        repo_root,
    ] + (["--archive", archive_path] if archive_path else []),
    "archive_summary": {
        "archive_path": payload["archive_path"],
        "archive_top_level_root": payload["archive_top_level_root"],
        "helper_surface_complete": payload["helper_surface_complete"],
        "recommended_restore_mode": payload["recommended_restore_mode"],
        "missing_paths": payload["missing_paths"],
    },
    "follow_up_commands": {
        "saved_browser_snapshot_route": [
            "bash",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "--repo-root",
            repo_root,
        ] + (["--archive", payload["archive_path"]] if payload["archive_path"] else []),
        "workspace_context_route": [
            "bash",
            "scripts/linux/show_issue3_workspace_context_route.sh",
            "--repo-root",
            repo_root,
        ],
        "issue11_progress_tracker_route": [
            "bash",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "--repo-root",
            repo_root,
        ],
        "runtime_revalidation_route": [
            "bash",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--repo-root",
            repo_root,
        ],
    },
}
print(json.dumps(route, indent=2))
PY
    exit 0
fi

python3 - <<'PY' "${SURFACE_JSON}" "${REPO_ROOT}"
import json
import shlex
import sys

payload = json.loads(sys.argv[1])
repo_root = sys.argv[2]

def join_command(parts):
    return " ".join(shlex.quote(part) for part in parts)

saved_snapshot_route = [
    "bash",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "--repo-root",
    repo_root,
]
if payload["archive_path"]:
    saved_snapshot_route.extend(["--archive", payload["archive_path"]])

workspace_context_route = [
    "bash",
    "scripts/linux/show_issue3_workspace_context_route.sh",
    "--repo-root",
    repo_root,
]
progress_tracker_route = [
    "bash",
    "scripts/linux/show_issue3_progress_tracker_route.sh",
    "--repo-root",
    repo_root,
]
runtime_revalidation_route = [
    "bash",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
    "--repo-root",
    repo_root,
]

print("Issue #3 saved-browser-snapshot archive-surface route")
print()
print(f"Repo root:   {repo_root}")
print(f"Route note:  {repo_root}/docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE_ROUTE.md")
print()
print("Suggested route")
print("===============")
print("  Route surface check:")
print(f"    bash scripts/linux/check_issue3_saved_browser_snapshot_archive_surface_route_surface.sh --repo-root {shlex.quote(repo_root)}")
print()
print("  Archive-surface helper:")
archive_surface_command = [
    "python",
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
    "--repo-root",
    repo_root,
]
print(f"    {join_command(archive_surface_command)}")
print()
print("Archive summary")
print("===============")
print(f"  Snapshot archive:         {payload['archive_path']}")
print(f"  Archive top-level root:   {payload['archive_top_level_root']}")
print(f"  Helper surface complete:  {'yes' if payload['helper_surface_complete'] else 'no'}")
print(f"  Recommended restore:      {payload['recommended_restore_mode']}")
if payload["missing_paths"]:
    print("  Missing helper paths:")
    for missing_path in payload["missing_paths"]:
        print(f"    - {missing_path}")
else:
    print("  Missing helper paths:     none")
print()
print("Follow-up routes")
print("================")
print("  Saved browser-snapshot route:")
print(f"    {join_command(saved_snapshot_route)}")
print()
print("  Workspace-context route:")
print(f"    {join_command(workspace_context_route)}")
print()
print("  Issue #11 progress-tracker route:")
print(f"    {join_command(progress_tracker_route)}")
print()
print("  Direct runtime revalidation route:")
print(f"    {join_command(runtime_revalidation_route)}")
print()
print("Working rules")
print("=============")
print("  - Run the route surface check first so note or helper drift fails before the route is trusted.")
print("  - Run the archive-surface helper next so the restore mode comes from the current helper contract, not guesswork.")
print("  - Prefer a plain restore only when the helper surface is complete inside the saved archive.")
print("  - Prefer --sync-helper-surface when the helper reports missing paths or stale restore helpers.")
print("  - Use the issue #11 progress-tracker route when the next rerun still needs a lower-volume status lane before reopening the direct runtime patch.")
PY
