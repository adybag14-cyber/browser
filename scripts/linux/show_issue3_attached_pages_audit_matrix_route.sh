#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_attached_pages_audit_matrix_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--surface branch-inventory] \
    [--surface windows-full-use-route] \
    [--json]

Print the issue #3 attached-pages audit-matrix route so Linux or WSL reruns can
reopen the current attached-pages validation surface without rebuilding the
commands by hand.
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
JSON=0
SURFACES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --surface)
            SURFACES+=("$2")
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
MATRIX_SCRIPT="${REPO_ROOT}/tmp-browser-smoke/attached-pages/google_issue3_attached_pages_audit_matrix.py"
MATRIX_TEST="${REPO_ROOT}/tmp-browser-smoke/attached-pages/test_google_issue3_attached_pages_audit_matrix.py"

SELECTED_SURFACES_TEXT="all"
if [[ "${#SURFACES[@]}" -gt 0 ]]; then
    SELECTED_SURFACES_TEXT="$(printf '%s, ' "${SURFACES[@]}")"
    SELECTED_SURFACES_TEXT="${SELECTED_SURFACES_TEXT%, }"
fi

SURFACE_COMMAND="python $(format_shell_arg "${MATRIX_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
for surface in "${SURFACES[@]}"; do
    SURFACE_COMMAND+=" --surface $(format_shell_arg "${surface}")"
done
JSON_COMMAND="${SURFACE_COMMAND} --json"
TEST_COMMAND="python -m unittest $(format_shell_arg "${MATRIX_TEST}")"
FOLLOW_UP_COMMAND="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 attached-pages audit matrix route",
    "repo_root": ${REPO_ROOT@Q},
    "selected_surfaces": ${SELECTED_SURFACES_TEXT@Q},
    "commands": {
        "matrix_text": ${SURFACE_COMMAND@Q},
        "matrix_json": ${JSON_COMMAND@Q},
        "matrix_tests": ${TEST_COMMAND@Q},
        "headed_follow_up": ${FOLLOW_UP_COMMAND@Q}
    },
    "notes": [
        "Use this route when the direct Page.zig and win32_backend.zig runtime lane is still blocked and the next useful step is to tighten attached-pages validation instead.",
        "Run the matrix in text mode first when a human needs the recommended focus and first missing path quickly.",
        "Run the matrix in JSON mode when another helper or notebook needs the same recommendation as structured data.",
        "Use --surface to pin the route to one or more attached-pages audits when the next rerun already knows which surface family it needs.",
        "Run the focused unittest when the helper itself changes or when the selected surface output looks suspicious.",
        "After choosing the recommended focus, reopen the Windows headed attached-html bundle route so the bounded localhost replay ladder stays aligned with the audit result."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 attached-pages audit matrix route

Repo root:          ${REPO_ROOT}
Selected surfaces:  ${SELECTED_SURFACES_TEXT}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  scripts/windows/show_headed_validation_suites.ps1

Suggested route
===============
  Attached-pages audit matrix (text):
    ${SURFACE_COMMAND}

  Attached-pages audit matrix (JSON):
    ${JSON_COMMAND}

  Audit helper unittest:
    ${TEST_COMMAND}

  Headed attached-html bundle follow-up:
    ${FOLLOW_UP_COMMAND}

Working rules
=============
  - Use this route when the direct Page.zig plus win32_backend.zig runtime lane is still blocked and the best next move is attached-pages validation narrowing.
  - Run the text matrix first when you want the recommended focus and first missing path in a readable summary.
  - Run the JSON matrix when another helper needs the same recommendation as structured data.
  - Use --surface to pin the route to one or more audits when the next rerun already knows which attached-pages surface family it needs.
  - Run the unittest when the helper changes or when the selected-surface output looks suspicious.
  - After choosing the recommended focus, reopen the Windows headed attached-html bundle route so the bounded localhost replay ladder stays aligned with the audit result.
EOF
