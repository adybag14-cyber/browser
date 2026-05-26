#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOUSAGE'
Usage:
  bash scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh \
    [--repo-root /path/to/browser-repo] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--skip-archive-integrity-check] \
    [--json]

Use the branch-local workspace-context helper to resolve the nearest practical
helper, Memory, agent-files, and restored-checkout roots, then rerun the saved
Memory preflight with those surfaced paths threaded through explicitly.
EOUSAGE
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
SKIP_ARCHIVE_INTEGRITY_CHECK=0
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
        --skip-archive-integrity-check)
            SKIP_ARCHIVE_INTEGRITY_CHECK=1
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
WORKSPACE_CONTEXT_SCRIPT="${DEFAULT_REPO_ROOT}/scripts/check_issue3_workspace_context.py"
WORKSPACE_CONTEXT_CMD=(
    python3
    "${WORKSPACE_CONTEXT_SCRIPT}"
    --repo-root "${REPO_ROOT}"
    --json
)
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    WORKSPACE_CONTEXT_CMD+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi

CONTEXT_JSON="$(${WORKSPACE_CONTEXT_CMD[@]})"

mapfile -t SURFACED_VALUES < <(
    CONTEXT_JSON="${CONTEXT_JSON}" python3 - <<'PY'
import json
import os

context = json.loads(os.environ["CONTEXT_JSON"])
print(context["helper_root"])
print(context["memory_root"])
print(context["agent_files_root"])
print(context["restored_checkout_root"])
fallback = context.get("fallback_zig_archive")
print("" if fallback is None else fallback)
PY
)

HELPER_ROOT="${SURFACED_VALUES[0]}"
MEMORY_ROOT="${SURFACED_VALUES[1]}"
AGENT_FILES_ROOT="${SURFACED_VALUES[2]}"
RESTORED_CHECKOUT_ROOT="${SURFACED_VALUES[3]}"
SURFACED_FALLBACK_ZIG="${SURFACED_VALUES[4]}"

ROUTE_SURFACE_SCRIPT="${HELPER_ROOT}/scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh"
ROUTE_SURFACE_CMD=(
    bash
    "${ROUTE_SURFACE_SCRIPT}"
    --repo-root "${REPO_ROOT}"
)

PREFLIGHT_CMD=(
    python3
    "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
    --repo-root "${REPO_ROOT}"
    --helper-root "${HELPER_ROOT}"
    --memory-root "${MEMORY_ROOT}"
    --agent-files-root "${AGENT_FILES_ROOT}"
    --restored-checkout-root "${RESTORED_CHECKOUT_ROOT}"
)

if [[ -n "${SURFACED_FALLBACK_ZIG}" ]]; then
    PREFLIGHT_CMD+=(--fallback-zig-archive "${SURFACED_FALLBACK_ZIG}")
fi
if [[ "${SKIP_ARCHIVE_INTEGRITY_CHECK}" -eq 1 ]]; then
    PREFLIGHT_CMD+=(--skip-archive-integrity-check)
fi

if [[ "${JSON}" -eq 1 ]]; then
    CONTEXT_JSON="${CONTEXT_JSON}" PREFLIGHT_JSON="$(
        "${PREFLIGHT_CMD[@]}" --json
    )" python3 - "$SKIP_ARCHIVE_INTEGRITY_CHECK" <<'PY'
import json
import os
import shlex
import sys

context = json.loads(os.environ["CONTEXT_JSON"])
preflight = json.loads(os.environ["PREFLIGHT_JSON"])

command = [
    "python3",
    f"{context['helper_root']}/scripts/check_issue3_saved_memory_inputs.py",
    "--repo-root", context["repo_root"],
    "--helper-root", context["helper_root"],
    "--memory-root", context["memory_root"],
    "--agent-files-root", context["agent_files_root"],
    "--restored-checkout-root", context["restored_checkout_root"],
]
fallback = context.get("fallback_zig_archive")
if fallback:
    command.extend(["--fallback-zig-archive", fallback])
if sys.argv[1] == "1":
    command.append("--skip-archive-integrity-check")

print(json.dumps({
    "profile": "issue11-nested-workspace-saved-memory-preflight",
    "route_surface_command": [
        "bash",
        f"{context['helper_root']}/scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
        "--repo-root",
        context["repo_root"],
    ],
    "route_surface_command_shell": " ".join(
        shlex.quote(part) for part in [
            "bash",
            f"{context['helper_root']}/scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "--repo-root",
            context["repo_root"],
        ]
    ),
    "workspace_context": context,
    "preflight": preflight,
    "command": command,
    "command_shell": " ".join(shlex.quote(part) for part in command),
}, indent=2))
PY
    exit 0
fi

"${ROUTE_SURFACE_CMD[@]}"

cat <<EOF
Issue #11 nested-workspace saved-Memory preflight

Repo root:              ${REPO_ROOT}
Live helper root:       ${HELPER_ROOT}
Memory root:            ${MEMORY_ROOT}
Agent files root:       ${AGENT_FILES_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Fallback Zig archive:   ${SURFACED_FALLBACK_ZIG:-not surfaced}

Saved-Memory route surface command:
  $(printf '%q ' "${ROUTE_SURFACE_CMD[@]}")

Workspace-context command:
  $(printf '%q ' "${WORKSPACE_CONTEXT_CMD[@]}")

Saved-Memory preflight command:
  $(printf '%q ' "${PREFLIGHT_CMD[@]}")
EOF

"${PREFLIGHT_CMD[@]}"