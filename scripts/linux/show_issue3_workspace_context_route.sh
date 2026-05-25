#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_workspace_context_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact workspace-context route for the blocked issue #3 Linux or WSL
re-entry lane.
EOF
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

WORKSPACE_CONTEXT_COMMAND=(
    "python"
    "${REPO_ROOT}/scripts/check_issue3_workspace_context.py"
    "--repo-root"
    "${REPO_ROOT}"
)
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    WORKSPACE_CONTEXT_COMMAND+=("--fallback-zig-archive" "${FALLBACK_ZIG_ARCHIVE}")
fi

CONTEXT_JSON="$(python3 - <<'PY' "${WORKSPACE_CONTEXT_COMMAND[@]}"
import subprocess
import sys

completed = subprocess.run(sys.argv[1:] + ["--json"], check=True, capture_output=True, text=True)
print(completed.stdout)
PY
)"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<'PY' "${CONTEXT_JSON}"
import json
import sys

context = json.loads(sys.argv[1])
repo_root = context["repo_root"]
route = {
    "issue": "issue3-workspace-context-route",
    "repo_root": repo_root,
    "route_note_path": f"{repo_root}/docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
    "surface_check_command": [
        "bash",
        "scripts/linux/check_issue3_workspace_context_route_surface.sh",
        "--repo-root",
        repo_root,
    ],
    "workspace_context_command": [
        "python",
        "scripts/check_issue3_workspace_context.py",
        "--repo-root",
        repo_root,
    ],
    "resolved_roots": {
        "toolchains_root": context["toolchains_root"],
        "memory_root": context["memory_root"],
        "saved_archives_root": context["saved_archives_root"],
        "agent_files_root": context["agent_files_root"],
        "offline_deps_root": context["offline_deps_root"],
        "restored_checkout_root": context["restored_checkout_root"],
        "fallback_zig_archive": context["fallback_zig_archive"],
    },
    "follow_up_commands": {
        "issue11_progress_tracker_route": context["suggested_progress_tracker_route_command"],
        "saved_browser_snapshot_route": context["suggested_saved_snapshot_route_command"],
        "linux_build_readiness_route": context["suggested_build_readiness_route_command"],
        "zig_toolchain_recovery_route": context["suggested_zig_recovery_route_command"],
        "zig_toolchain_match_gate": context["suggested_zig_match_command"],
        "saved_zig_archive_candidates_route": [
            "bash",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            "--repo-root",
            repo_root,
        ],
    },
}
print(json.dumps(route, indent=2))
PY
    exit 0
fi

python3 - <<'PY' "${CONTEXT_JSON}"
import json
import shlex
import sys

context = json.loads(sys.argv[1])

def join_command(parts):
    return " ".join(shlex.quote(part) for part in parts)

print("Issue #3 workspace-context route")
print()
print(f"Repo root:   {context['repo_root']}")
print(f"Route note:  {context['repo_root']}/docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md")
print()
print("Suggested route")
print("===============")
print("  Route surface check:")
print(f"    bash scripts/linux/check_issue3_workspace_context_route_surface.sh --repo-root {shlex.quote(context['repo_root'])}")
print()
print("  Workspace-context helper:")
print(f"    python scripts/check_issue3_workspace_context.py --repo-root {shlex.quote(context['repo_root'])}")
print()
print("Resolved roots")
print("==============")
print(f"  Toolchains root:         {context['toolchains_root']}")
print(f"  Memory root:             {context['memory_root']}")
print(f"  Saved archives root:     {context['saved_archives_root']}")
print(f"  Agent files root:        {context['agent_files_root']}")
print(f"  Offline deps root:       {context['offline_deps_root']}")
print(f"  Restored checkout root:  {context['restored_checkout_root']}")
print(f"  Fallback Zig archive:    {context['fallback_zig_archive']}")
print()
print("Follow-up routes")
print("================")
print("  Issue #11 progress-tracker route:")
print(f"    {join_command(context['suggested_progress_tracker_route_command'])}")
print()
print("  Saved browser-snapshot route:")
print(f"    {join_command(context['suggested_saved_snapshot_route_command'])}")
print()
print("  Linux or WSL build-readiness route:")
print(f"    {join_command(context['suggested_build_readiness_route_command'])}")
print()
print("  Zig recovery route:")
print(f"    {join_command(context['suggested_zig_recovery_route_command'])}")
print()
print("  Zig matching-line gate:")
print(f"    {join_command(context['suggested_zig_match_command'])}")
print()
print("  Saved Zig archive-candidates route:")
print(f"    bash scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh --repo-root {shlex.quote(context['repo_root'])}")
print()
print("Working rules")
print("=============")
print("  - Run the route surface check first so note or helper drift fails before the route is trusted.")
print("  - Run the workspace-context helper next so nested or restored checkouts surface the practical shared roots.")
print("  - Use the printed issue #11 route when the run still needs a lower-volume progress tracker before reopening the direct runtime patch.")
print("  - Use the saved browser-snapshot or Zig recovery follow-up routes when the surfaced roots show that restore or matching-line staging is still the blocker.")
print("  - Use the saved Zig archive-candidates route before hand-picking a Zig archive from Memory dependencies.")
PY
