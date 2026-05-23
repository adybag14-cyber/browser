#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_attached_html_bundle_linux_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--input-root /path/to/agent_files-or-bundle-dir] \
    [--browser-exe /path/to/lightpanda] \
    [--bind 127.0.0.1] \
    [--port 8235] \
    [--json]

Print the Linux attached-html replay route for the pinned issue #3 compatibility
bundle. The default input root is ../agent_files beside the repo workspace.
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
INPUT_ROOT=""
BROWSER_EXE=""
BIND="127.0.0.1"
PORT="8235"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --input-root)
            INPUT_ROOT="$2"
            shift 2
            ;;
        --browser-exe)
            BROWSER_EXE="$2"
            shift 2
            ;;
        --bind)
            BIND="$2"
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
if [[ -z "${INPUT_ROOT}" ]]; then
    INPUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/agent_files"
fi

PREFERRED_INITIAL_PAGE="Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html"
BUNDLE_FILES=(
    "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html"
    "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html"
    "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html"
)

REQUIRED_INPUT_FLAGS=()
PRESENT_FILES=()
MISSING_FILES=()
for relative_name in "${BUNDLE_FILES[@]}"; do
    full_path="${INPUT_ROOT}/${relative_name}"
    if [[ -f "${full_path}" ]]; then
        PRESENT_FILES+=("${full_path}")
        REQUIRED_INPUT_FLAGS+=(--input "${full_path}")
    else
        MISSING_FILES+=("${relative_name}")
    fi
done

COMMON_COMMAND_PREFIX=(
    python
    tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py
    --repo-root "${REPO_ROOT}"
    --google-style
    --preferred-initial-page "${PREFERRED_INITIAL_PAGE}"
    --bind "${BIND}"
    --port "${PORT}"
)
if [[ ${#REQUIRED_INPUT_FLAGS[@]} -gt 0 ]]; then
    COMMON_COMMAND_PREFIX+=("${REQUIRED_INPUT_FLAGS[@]}")
fi

PREFLIGHT_COMMAND=(
    python
    tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py
    --repo-root "${REPO_ROOT}"
    --google-style
    --preferred-initial-page "${PREFERRED_INITIAL_PAGE}"
    --bind "${BIND}"
    --port "${PORT}"
)
if [[ ${#REQUIRED_INPUT_FLAGS[@]} -gt 0 ]]; then
    PREFLIGHT_COMMAND+=("${REQUIRED_INPUT_FLAGS[@]}")
fi

format_command() {
    local out=()
    local arg
    for arg in "$@"; do
        out+=("$(format_shell_arg "${arg}")")
    done
    printf '%s' "${out[*]}"
}

PREFLIGHT_COMMAND_TEXT="$(format_command "${PREFLIGHT_COMMAND[@]}")"
SIDECAR_AUDIT_COMMAND_TEXT="$(format_command "${COMMON_COMMAND_PREFIX[@]}" --audit-sidecars)"
ASSET_AUDIT_COMMAND_TEXT="$(format_command "${COMMON_COMMAND_PREFIX[@]}" --audit-assets)"
MANIFEST_COMMAND_TEXT="$(format_command "${COMMON_COMMAND_PREFIX[@]}" --require-complete-sidecars --require-complete-assets --print-manifest)"
LAUNCH_COMMAND_TEXT="$(format_command "${COMMON_COMMAND_PREFIX[@]}" --require-complete-sidecars --require-complete-assets)"
CATALOG_URL="http://${BIND}:${PORT}/"
PREFERRED_URL="http://${BIND}:${PORT}/named/control-your-online-safety-and-privacy-google-safety-centre/"

BROWSER_COMMAND_TEXT=""
if [[ -n "${BROWSER_EXE}" ]]; then
    BROWSER_COMMAND_TEXT="$(format_command "${BROWSER_EXE}" browse --headed --window_width 1366 --window_height 900 "${CATALOG_URL}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    JSON_REPO_ROOT="${REPO_ROOT}" \
    JSON_INPUT_ROOT="${INPUT_ROOT}" \
    JSON_PREFERRED_INITIAL_PAGE="${PREFERRED_INITIAL_PAGE}" \
    JSON_CATALOG_URL="${CATALOG_URL}" \
    JSON_PREFERRED_URL="${PREFERRED_URL}" \
    JSON_PREFLIGHT_COMMAND="${PREFLIGHT_COMMAND_TEXT}" \
    JSON_SIDECAR_AUDIT_COMMAND="${SIDECAR_AUDIT_COMMAND_TEXT}" \
    JSON_ASSET_AUDIT_COMMAND="${ASSET_AUDIT_COMMAND_TEXT}" \
    JSON_MANIFEST_COMMAND="${MANIFEST_COMMAND_TEXT}" \
    JSON_LAUNCH_COMMAND="${LAUNCH_COMMAND_TEXT}" \
    JSON_BROWSER_COMMAND="${BROWSER_COMMAND_TEXT}" \
    JSON_PRESENT_COUNT="${#PRESENT_FILES[@]}" \
    JSON_MISSING_COUNT="${#MISSING_FILES[@]}" \
    python3 - <<'PY'
import json
import os

print(json.dumps({
    "issue": "Issue #3 attached-html compatibility bundle route",
    "repo_root": os.environ["JSON_REPO_ROOT"],
    "input_root": os.environ["JSON_INPUT_ROOT"],
    "preferred_initial_page": os.environ["JSON_PREFERRED_INITIAL_PAGE"],
    "catalog_url": os.environ["JSON_CATALOG_URL"],
    "preferred_url": os.environ["JSON_PREFERRED_URL"],
    "present_count": int(os.environ["JSON_PRESENT_COUNT"]),
    "missing_count": int(os.environ["JSON_MISSING_COUNT"]),
    "all_bundle_files_present": int(os.environ["JSON_MISSING_COUNT"]) == 0,
    "commands": {
        "preflight_report": os.environ["JSON_PREFLIGHT_COMMAND"],
        "sidecar_audit": os.environ["JSON_SIDECAR_AUDIT_COMMAND"],
        "asset_audit": os.environ["JSON_ASSET_AUDIT_COMMAND"],
        "strict_manifest": os.environ["JSON_MANIFEST_COMMAND"],
        "strict_launch": os.environ["JSON_LAUNCH_COMMAND"],
        "headed_browser": os.environ["JSON_BROWSER_COMMAND"],
    },
    "notes": [
        "Run the preflight report first so the selected bundle, recommended next step, and localhost routes stay on one compact surface.",
        "Run the sidecar audit before the broader asset audit so missing sibling _files directories are separated from deeper asset drift.",
        "Keep the Google Safety Centre export first so the same Google-shaped page stays at the front of the replay bundle.",
        "Use the strict manifest before launch when the replay should stop on missing sidecars or missing local assets.",
        "Start the headed browser only after the strict launch route stays green and the pinned bundle is intact."
    ]
}, indent=2, ensure_ascii=False))
PY
    exit 0
fi

cat <<EOF
Issue #3 attached-html compatibility bundle route

Repo root:              ${REPO_ROOT}
Input root:             ${INPUT_ROOT}
Preferred first page:   ${PREFERRED_INITIAL_PAGE}
Catalog URL:            ${CATALOG_URL}
Preferred first route:  ${PREFERRED_URL}

Pinned bundle
=============
EOF

for relative_name in "${BUNDLE_FILES[@]}"; do
    if [[ -f "${INPUT_ROOT}/${relative_name}" ]]; then
        printf '  [present] %s\n' "${relative_name}"
    else
        printf '  [missing] %s\n' "${relative_name}"
    fi
done

cat <<EOF

Suggested route
===============
  1. Preflight report:
    ${PREFLIGHT_COMMAND_TEXT}

  2. Sidecar audit:
    ${SIDECAR_AUDIT_COMMAND_TEXT}

  3. Asset audit:
    ${ASSET_AUDIT_COMMAND_TEXT}

  4. Strict manifest:
    ${MANIFEST_COMMAND_TEXT}

  5. Strict localhost launch:
    ${LAUNCH_COMMAND_TEXT}
EOF

if [[ -n "${BROWSER_COMMAND_TEXT}" ]]; then
    cat <<EOF

  6. Headed browser launch:
    ${BROWSER_COMMAND_TEXT}
EOF
fi

cat <<EOF

Working rules
=============
  - Run the preflight report first so the selected bundle, recommended next step, and localhost routes stay on one compact surface.
  - Run the sidecar audit before the broader asset audit so missing sibling _files directories are separated from deeper asset drift.
  - Keep the Google Safety Centre export first so the same Google-shaped page stays at the front of the replay bundle.
  - Use the strict manifest before launch when the replay should stop on missing sidecars or missing local assets.
  - Start the headed browser only after the strict launch route stays green and the pinned bundle is intact.
  - Walk the bundle in this order once the server is up: Google Safety Centre, Anthropic application, then the U.S. Department of War page.
EOF

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    cat <<EOF

Current blocker
===============
  One or more pinned bundle files are missing under ${INPUT_ROOT}.
  Restore the missing files before treating bundle replay drift as a browser regression.
EOF
fi
