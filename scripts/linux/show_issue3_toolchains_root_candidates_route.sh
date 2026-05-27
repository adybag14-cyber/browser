#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_toolchains_root_candidates_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--json]

Print the compact issue #11 route for surfacing the practical toolchains root
before staged Rust, staged Zig, Zig recovery, or broader Linux build-readiness
helpers trust a guessed default.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"

python3 - "${REPO_ROOT}" "${HELPER_ROOT}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
helper_root = pathlib.Path(sys.argv[2]).resolve()
emit_json = sys.argv[3] == "1"

helper_script = helper_root / "scripts" / "check_issue11_toolchains_root_candidates.py"
helper_command = [
    sys.executable,
    str(helper_script),
    "--repo-root",
    str(repo_root),
    "--helper-root",
    str(helper_root),
    "--json",
]
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
    raise SystemExit("toolchains-root helper produced no JSON output" + detail)

report = json.loads(completed.stdout)
preferred_root = report["preferred_toolchains_root"]
surface_check_command = (
    f"bash {helper_root / 'scripts/linux/check_issue3_toolchains_root_candidates_route_surface.sh'} "
    f"--repo-root {repo_root}"
)
toolchains_root_candidates_command = (
    f"python {helper_root / 'scripts/check_issue11_toolchains_root_candidates.py'} "
    f"--repo-root {repo_root} --helper-root {helper_root}"
)
nested_preflight_command = " ".join(report["suggested_nested_preflight_command"])
staged_rust_route_command = (
    f"bash {helper_root / 'scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh'} "
    f"--repo-root {repo_root} --toolchains-root {preferred_root}"
)
staged_zig_route_command = (
    f"bash {helper_root / 'scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh'} "
    f"--repo-root {repo_root} --toolchains-root {preferred_root}"
)
saved_rust_build_bridge_command = (
    f"bash {helper_root / 'scripts/linux/show_issue3_saved_rust_build_readiness_route.sh'} "
    f"--repo-root {repo_root} --toolchains-root {preferred_root}"
)
linux_build_readiness_route_command = (
    f"bash {helper_root / 'scripts/linux/show_issue3_linux_build_readiness_route.sh'} "
    f"--repo-root {repo_root}"
)
linux_build_readiness_helper_command = " ".join(report["suggested_readiness_command"])
zig_recovery_route_command = " ".join(report["suggested_zig_recovery_command"])
progress_tracker_route_command = (
    f"bash {helper_root / 'scripts/linux/show_issue3_progress_tracker_route.sh'} "
    f"--repo-root {repo_root} --toolchains-root {preferred_root}"
)

result = {
    "issue": "Issue #11 toolchains-root candidates route for issue #3 re-entry",
    "repo_root": str(repo_root),
    "helper_root": str(helper_root),
    "preferred_toolchains_root": preferred_root,
    "helper_status": report["status"],
    "commands": {
        "surface_check": surface_check_command,
        "toolchains_root_candidates": toolchains_root_candidates_command,
        "nested_preflight": nested_preflight_command,
        "staged_rust_route": staged_rust_route_command,
        "staged_zig_route": staged_zig_route_command,
        "saved_rust_build_bridge": saved_rust_build_bridge_command,
        "linux_build_readiness_helper": linux_build_readiness_helper_command,
        "linux_build_readiness_route": linux_build_readiness_route_command,
        "zig_recovery_route": zig_recovery_route_command,
        "progress_tracker_route": progress_tracker_route_command,
    },
    "read_first": [
        "docs/ISSUE3_TOOLCHAINS_ROOT_CANDIDATES_ROUTE.md",
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
        "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
    ],
}

if emit_json:
    print(json.dumps(result, indent=2))
    raise SystemExit(0)

print("Issue #11 toolchains-root candidates route for issue #3 re-entry")
print()
print(f"Repo root:               {repo_root}")
print(f"Helper root:             {helper_root}")
print(f"Preferred toolchains:    {preferred_root}")
print(f"Helper status:           {report['status']}")
print()
print("Read first")
print("==========")
for path in result["read_first"]:
    print(f"  {path}")
print()
print("Suggested route")
print("===============")
print(f"  Surface check:\n    {surface_check_command}")
print(f"  Toolchains-root candidates:\n    {toolchains_root_candidates_command}")
print(f"  Nested-workspace preflight:\n    {nested_preflight_command}")
print(f"  Staged Rust route:\n    {staged_rust_route_command}")
print(f"  Staged Zig route:\n    {staged_zig_route_command}")
print(f"  Saved Rust build-readiness bridge:\n    {saved_rust_build_bridge_command}")
print(f"  Linux build-readiness helper:\n    {linux_build_readiness_helper_command}")
print(f"  Linux build-readiness route:\n    {linux_build_readiness_route_command}")
print(f"  Zig recovery route:\n    {zig_recovery_route_command}")
print(f"  Issue #11 progress-tracker route:\n    {progress_tracker_route_command}")
print()
print("Working rules")
print("=============")
print("  - Run the surface check first so missing route files fail before later reruns trust a guessed toolchains root.")
print("  - Run the toolchains-root helper before staged Rust, staged Zig, Zig recovery, or broader Linux build-readiness helpers so later commands can pass --toolchains-root explicitly.")
print("  - Keep the nested-workspace preflight visible when the run still needs the practical helper, Memory, and restored-checkout roots surfaced before toolchain-specific reruns widen again.")
print("  - Keep the issue #11 progress-tracker route visible when this slice is still about environment readiness rather than reopening the direct runtime patch.")
PY
