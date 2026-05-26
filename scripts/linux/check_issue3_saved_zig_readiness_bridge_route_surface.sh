#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_zig_readiness_bridge_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--expect-offline-deps] \
    [--require-prebuilt-v8] \
    [--json]

Fail fast when the saved Zig readiness bridge route is missing its branch-local
note or helper scripts, and confirm that the bridge helper returns the core JSON
fields needed by the Linux or WSL issue #3 re-entry lane.
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

resolve_first_existing_path() {
    local start="$1"
    local relative_path="$2"
    local current="$start"
    while true; do
        if [[ -e "${current}/${relative_path}" ]]; then
            printf '%s\n' "${current}/${relative_path}"
            return 0
        fi
        if [[ "${current}" == "/" ]]; then
            return 1
        fi
        current="$(dirname "${current}")"
    done
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
EXPECT_OFFLINE_DEPS=0
REQUIRE_PREBUILT_V8=0
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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --expect-offline-deps)
            EXPECT_OFFLINE_DEPS=1
            shift
            ;;
        --require-prebuilt-v8)
            REQUIRE_PREBUILT_V8=1
            shift
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
    SAVED_ARCHIVES_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "memory/repo_archives/browser" || true)"
    if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
        SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
    fi
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "toolchains" || true)"
    if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
        TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
    fi
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "offline-deps" || true)"
    if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
        OFFLINE_DEPS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/offline-deps"
    fi
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(resolve_first_existing_path "${REPO_ROOT}" "agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz" || true)"
    if [[ -z "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    fi
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

python3 - "${REPO_ROOT}" "${SAVED_ARCHIVES_ROOT}" "${TOOLCHAINS_ROOT}" "${OFFLINE_DEPS_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" "${EXPECT_OFFLINE_DEPS}" "${REQUIRE_PREBUILT_V8}" "${JSON}" <<'PY'
from __future__ import annotations

import json
import pathlib
import subprocess
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
saved_archives_root = pathlib.Path(sys.argv[2]).resolve()
toolchains_root = pathlib.Path(sys.argv[3]).resolve()
offline_deps_root = pathlib.Path(sys.argv[4]).resolve()
fallback_zig_archive = pathlib.Path(sys.argv[5]).resolve() if sys.argv[5] else None
expect_offline_deps = sys.argv[6] == "1"
require_prebuilt_v8 = sys.argv[7] == "1"
emit_json = sys.argv[8] == "1"

doc_path = repo_root / "docs" / "ISSUE3_SAVED_ZIG_READINESS_BRIDGE_ROUTE.md"
helper_path = repo_root / "scripts" / "check_issue3_saved_zig_readiness_bridge.py"
saved_zig_helper_path = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
build_helper_path = repo_root / "scripts" / "check_linux_build_readiness.py"
progress_route_path = repo_root / "docs" / "ISSUE3_PROGRESS_TRACKER_ROUTE.md"

failures: list[str] = []
for label, path in (
    ("saved Zig readiness bridge route note", doc_path),
    ("saved Zig readiness bridge helper", helper_path),
    ("saved Zig archive candidate helper", saved_zig_helper_path),
    ("Linux build-readiness helper", build_helper_path),
    ("issue #11 progress-tracker note", progress_route_path),
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
        "--offline-deps-root",
        str(offline_deps_root),
        "--json",
    ]
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
    if expect_offline_deps:
        command.append("--expect-offline-deps")
    if require_prebuilt_v8:
        command.append("--require-prebuilt-v8")

    completed = subprocess.run(command, check=False, capture_output=True, text=True)
    if not completed.stdout.strip():
        detail = completed.stderr.strip()
        if detail:
            detail = f"; stderr: {detail}"
        failures.append("saved Zig readiness bridge helper produced no JSON output" + detail)
    else:
        try:
            helper_report = json.loads(completed.stdout)
        except json.JSONDecodeError as exc:
            failures.append(f"saved Zig readiness bridge helper returned invalid JSON: {exc}")

    if helper_report is not None:
        required_keys = (
            "status",
            "repo_root",
            "saved_archives_root",
            "toolchains_root",
            "offline_deps_root",
            "fallback_zig_archive",
            "readiness_report",
            "saved_zig_report",
            "next_action",
        )
        for key in required_keys:
            if key not in helper_report:
                failures.append(f"saved Zig readiness bridge helper JSON is missing `{key}`")
        next_action = helper_report.get("next_action")
        if not isinstance(next_action, dict):
            failures.append("saved Zig readiness bridge helper JSON has a non-object `next_action` field")
        else:
            for key in ("kind", "summary", "commands"):
                if key not in next_action:
                    failures.append(f"saved Zig readiness bridge helper next_action is missing `{key}`")

result = {
    "status": "passed" if not failures else "failed",
    "repo_root": str(repo_root),
    "saved_archives_root": str(saved_archives_root),
    "toolchains_root": str(toolchains_root),
    "offline_deps_root": str(offline_deps_root),
    "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else "",
    "doc_path": str(doc_path),
    "helper_path": str(helper_path),
    "saved_zig_helper_path": str(saved_zig_helper_path),
    "build_helper_path": str(build_helper_path),
    "progress_route_path": str(progress_route_path),
    "helper_status": helper_report.get("status") if isinstance(helper_report, dict) else "",
    "next_action_kind": helper_report.get("next_action", {}).get("kind") if isinstance(helper_report, dict) and isinstance(helper_report.get("next_action"), dict) else "",
    "failures": failures,
}

if emit_json:
    print(json.dumps(result, indent=2))
else:
    print("Issue #3 saved Zig readiness bridge route surface check")
    print(f"Repo root:            {repo_root}")
    print(f"Saved archives root:  {saved_archives_root}")
    print(f"Toolchains root:      {toolchains_root}")
    print(f"Offline deps root:    {offline_deps_root}")
    print(f"Fallback Zig archive: {fallback_zig_archive or 'not found'}")
    print(f"Route note:           {doc_path}")
    print(f"Bridge helper:        {helper_path}")
    print(f"Progress tracker:     {progress_route_path}")
    if failures:
        print()
        print("Failures:")
        for failure in failures:
            print(f"  - {failure}")
    else:
        print()
        print("Surface check passed.")
        print(f"Bridge helper status: {result['helper_status']}")
        print(f"Next action kind:     {result['next_action_kind']}")

sys.exit(0 if not failures else 1)
PY
