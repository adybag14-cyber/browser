#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh \
    [--repo-root /path/to/browser-repo] \
    [--input-path /path/to/attached-html-or-folder] \
    [--preferred-initial-page "Google Safety Centre.html"] \
    [--host 127.0.0.1] \
    [--port 8235] \
    [--json]

Print the Linux-side attached-pages preflight ladder for issue #3 so the saved
HTML bundle can be checked honestly before the route hands back into the
Windows headed replay helpers.
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
HOST="127.0.0.1"
PORT="8235"
PREFERRED_INITIAL_PAGE=""
JSON=0
declare -a INPUT_PATHS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --input-path)
            INPUT_PATHS+=("$2")
            shift 2
            ;;
        --preferred-initial-page)
            PREFERRED_INITIAL_PAGE="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
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

REPO_ROOT_Q="$(format_shell_arg "${REPO_ROOT}")"
HOST_Q="$(format_shell_arg "${HOST}")"
PORT_Q="$(format_shell_arg "${PORT}")"

declare -a PYTHON_BASE_PARTS=(
    "python"
    "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
    "--repo-root" "${REPO_ROOT}"
    "--host" "${HOST}"
    "--port" "${PORT}"
)

declare -a PREFLIGHT_BASE_PARTS=(
    "python"
    "tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py"
    "--repo-root" "${REPO_ROOT}"
    "--bind" "${HOST}"
    "--port" "${PORT}"
)

declare -a WINDOWS_QUICKSTART_PARTS=(
    "powershell" "-ExecutionPolicy" "Bypass" "-File"
    ".\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1"
    "-RepoRoot" "${REPO_ROOT}"
)

declare -a WINDOWS_GOOGLE_FLOW_PARTS=(
    "powershell" "-ExecutionPolicy" "Bypass" "-File"
    ".\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
    "-RepoRoot" "${REPO_ROOT}"
)

for input_path in "${INPUT_PATHS[@]}"; do
    PYTHON_BASE_PARTS+=("--input" "${input_path}")
    PREFLIGHT_BASE_PARTS+=("--input" "${input_path}")
    WINDOWS_QUICKSTART_PARTS+=("-InputPath" "${input_path}")
    WINDOWS_GOOGLE_FLOW_PARTS+=("-InputPath" "${input_path}")
done

if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    PYTHON_BASE_PARTS+=("--preferred-initial-page" "${PREFERRED_INITIAL_PAGE}")
    PREFLIGHT_BASE_PARTS+=("--preferred-initial-page" "${PREFERRED_INITIAL_PAGE}")
    WINDOWS_QUICKSTART_PARTS+=("-PreferredInitialPage" "${PREFERRED_INITIAL_PAGE}")
    WINDOWS_GOOGLE_FLOW_PARTS+=("-PreferredInitialPage" "${PREFERRED_INITIAL_PAGE}")
fi

join_command() {
    python3 - "$@" <<'PY'
import shlex
import sys

print(" ".join(shlex.quote(part) for part in sys.argv[1:]))
PY
}

SURFACE_CHECK_COMMAND="bash scripts/linux/check_google_issue3_attached_pages_launcher_companion_validation_surface.sh --repo-root ${REPO_ROOT_Q}"
PREFLIGHT_REPORT_COMMAND="$(join_command "${PREFLIGHT_BASE_PARTS[@]}" "--google-style")"
SIDECAR_AUDIT_COMMAND="$(join_command "${PYTHON_BASE_PARTS[@]}" "--google-style" "--audit-sidecars")"
ASSET_AUDIT_COMMAND="$(join_command "${PYTHON_BASE_PARTS[@]}" "--google-style" "--audit-assets")"
PRINT_MANIFEST_COMMAND="$(join_command "${PYTHON_BASE_PARTS[@]}" "--google-style" "--print-manifest")"
STRICT_MANIFEST_COMMAND="$(join_command "${PYTHON_BASE_PARTS[@]}" "--google-style" "--require-complete-sidecars" "--require-complete-assets" "--print-manifest")"
STRICT_LAUNCH_COMMAND="$(join_command "${PYTHON_BASE_PARTS[@]}" "--google-style" "--require-complete-sidecars" "--require-complete-assets")"
WINDOWS_QUICKSTART_COMMAND="$(join_command "${WINDOWS_QUICKSTART_PARTS[@]}")"
WINDOWS_GOOGLE_FLOW_COMMAND="$(join_command "${WINDOWS_GOOGLE_FLOW_PARTS[@]}")"

if [[ "${JSON}" -eq 1 ]]; then
    export LP_ISSUE="Google issue #3 Linux attached-pages launcher companion"
    export LP_REPO_ROOT="${REPO_ROOT}"
    export LP_HOST="${HOST}"
    export LP_PORT="${PORT}"
    export LP_INPUT_COUNT="${#INPUT_PATHS[@]}"
    export LP_PREFERRED_INITIAL_PAGE="${PREFERRED_INITIAL_PAGE}"
    export LP_SURFACE_CHECK_COMMAND="${SURFACE_CHECK_COMMAND}"
    export LP_PREFLIGHT_REPORT_COMMAND="${PREFLIGHT_REPORT_COMMAND}"
    export LP_SIDECAR_AUDIT_COMMAND="${SIDECAR_AUDIT_COMMAND}"
    export LP_ASSET_AUDIT_COMMAND="${ASSET_AUDIT_COMMAND}"
    export LP_PRINT_MANIFEST_COMMAND="${PRINT_MANIFEST_COMMAND}"
    export LP_STRICT_MANIFEST_COMMAND="${STRICT_MANIFEST_COMMAND}"
    export LP_STRICT_LAUNCH_COMMAND="${STRICT_LAUNCH_COMMAND}"
    export LP_WINDOWS_QUICKSTART_COMMAND="${WINDOWS_QUICKSTART_COMMAND}"
    export LP_WINDOWS_GOOGLE_FLOW_COMMAND="${WINDOWS_GOOGLE_FLOW_COMMAND}"
    python3 - <<'PY'
import json
import os

print(json.dumps({
    "issue": os.environ["LP_ISSUE"],
    "repo_root": os.environ["LP_REPO_ROOT"],
    "host": os.environ["LP_HOST"],
    "port": int(os.environ["LP_PORT"]),
    "input_path_count": int(os.environ["LP_INPUT_COUNT"]),
    "preferred_initial_page": os.environ["LP_PREFERRED_INITIAL_PAGE"],
    "read_first": [
        "docs/ISSUE3_LINUX_ATTACHED_HTML_VALIDATION_FLOW.md",
        "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
        "tmp-browser-smoke/attached-pages/README.md"
    ],
    "commands": {
        "surface_check": os.environ["LP_SURFACE_CHECK_COMMAND"],
        "preflight_report": os.environ["LP_PREFLIGHT_REPORT_COMMAND"],
        "sidecar_audit": os.environ["LP_SIDECAR_AUDIT_COMMAND"],
        "asset_audit": os.environ["LP_ASSET_AUDIT_COMMAND"],
        "print_manifest": os.environ["LP_PRINT_MANIFEST_COMMAND"],
        "strict_manifest": os.environ["LP_STRICT_MANIFEST_COMMAND"],
        "strict_launch": os.environ["LP_STRICT_LAUNCH_COMMAND"],
        "windows_replay_quickstart": os.environ["LP_WINDOWS_QUICKSTART_COMMAND"],
        "windows_google_flow": os.environ["LP_WINDOWS_GOOGLE_FLOW_COMMAND"]
    },
    "notes": [
        "Run the surface check first so the Linux companion note and helper paths fail fast before attached-page replay is blamed on headed mode.",
        "Use the preflight report first when you want one compact readiness summary before the sidecar and asset audits.",
        "Run the Google-style sidecar audit before the broader asset audit so missing sibling _files bundles fail earlier than deeper local asset drift.",
        "Use the strict manifest or strict launch commands when the saved export must be a closed bundle before Windows headed replay is trusted.",
        "After the Linux-side bundle preflight is green, hand off to the Windows replay quickstart or the dedicated Google attached HTML flow instead of treating Linux headed fallback as runtime evidence."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 Linux attached-pages launcher companion

Repo root:            ${REPO_ROOT}
Host:                 ${HOST}
Port:                 ${PORT}
Pinned input count:   ${#INPUT_PATHS[@]}
Preferred first page: ${PREFERRED_INITIAL_PAGE:-auto}

Read first
==========
  docs/ISSUE3_LINUX_ATTACHED_HTML_VALIDATION_FLOW.md
  docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md
  tmp-browser-smoke/attached-pages/README.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Preflight report:
    ${PREFLIGHT_REPORT_COMMAND}

  Sidecar audit:
    ${SIDECAR_AUDIT_COMMAND}

  Asset audit:
    ${ASSET_AUDIT_COMMAND}

  Manifest:
    ${PRINT_MANIFEST_COMMAND}

  Strict manifest:
    ${STRICT_MANIFEST_COMMAND}

  Strict launch:
    ${STRICT_LAUNCH_COMMAND}

  Windows replay quickstart handoff:
    ${WINDOWS_QUICKSTART_COMMAND}

  Windows Google-flow handoff:
    ${WINDOWS_GOOGLE_FLOW_COMMAND}

Working rules
=============
  - Run the surface check first so missing note or helper drift fails fast before preflight evidence is trusted.
  - Prefer the preflight report first when the next run needs a single Linux-side readiness summary before narrower route selection.
  - Run the sidecar audit before the broader asset audit so missing sibling _files bundles fail before deeper local asset drift.
  - Use the strict manifest or strict launch commands when the current saved bundle must be fully closed before the Windows replay route is trusted.
  - After Linux-side bundle preflight succeeds, use the Windows replay quickstart or the dedicated Google attached HTML flow for real headed follow-up.
  - Treat this helper as bundle-preflight guidance, not as evidence that non-Windows headed fallback is good enough for issue #3 runtime validation.
EOF
