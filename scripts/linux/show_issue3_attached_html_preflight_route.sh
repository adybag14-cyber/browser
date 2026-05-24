#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_attached_html_preflight_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--input /path/to/attached-page-or-folder] \
    [--preferred-initial-page page-name-or-path] \
    [--bind 127.0.0.1] \
    [--port 8235] \
    [--allow-missing-sidecars] \
    [--allow-missing-assets] \
    [--json]

Print the Linux attached-html preflight route for the current issue #3
compatibility bundle using the cross-platform attached-pages harness.
EOF
}

format_shell_command() {
    python3 - "$@" <<'PY'
import shlex
import sys
print(" ".join(shlex.quote(arg) for arg in sys.argv[1:]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
BIND="127.0.0.1"
PORT=8235
PREFERRED_INITIAL_PAGE=""
ALLOW_MISSING_SIDECARS=0
ALLOW_MISSING_ASSETS=0
JSON=0
declare -a INPUT_PATHS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --input)
            INPUT_PATHS+=("$2")
            shift 2
            ;;
        --preferred-initial-page)
            PREFERRED_INITIAL_PAGE="$2"
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
        --allow-missing-sidecars)
            ALLOW_MISSING_SIDECARS=1
            shift
            ;;
        --allow-missing-assets)
            ALLOW_MISSING_ASSETS=1
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
SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_attached_html_preflight_route_surface.sh"
GUIDE_DOC="${REPO_ROOT}/docs/ISSUE3_ATTACHED_HTML_PREFLIGHT_ROUTE.md"
FLOW_DOC="${REPO_ROOT}/docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
RUNBOOK_DOC="${REPO_ROOT}/docs/WINDOWS_FULL_USE.md"
PREFLIGHT_SCRIPT="${REPO_ROOT}/tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py"
CATALOG_SCRIPT="${REPO_ROOT}/tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"

common_args=(--repo-root "${REPO_ROOT}" --google-style --bind "${BIND}" --port "${PORT}")
for input_path in "${INPUT_PATHS[@]}"; do
    common_args+=(--input "${input_path}")
done
if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    common_args+=(--preferred-initial-page "${PREFERRED_INITIAL_PAGE}")
fi

surface_check_command="$(format_shell_command bash "${SURFACE_SCRIPT}" --repo-root "${REPO_ROOT}")"
preflight_command_parts=(python "${PREFLIGHT_SCRIPT}" "${common_args[@]}")
sidecar_audit_parts=(python "${CATALOG_SCRIPT}" "${common_args[@]}" --audit-sidecars)
asset_audit_parts=(python "${CATALOG_SCRIPT}" "${common_args[@]}" --audit-assets)
manifest_parts=(python "${CATALOG_SCRIPT}" "${common_args[@]}" --print-manifest)
strict_manifest_parts=(python "${CATALOG_SCRIPT}" "${common_args[@]}" --require-complete-sidecars --require-complete-assets --print-manifest)
launch_parts=(python "${CATALOG_SCRIPT}" "${common_args[@]}")
strict_launch_parts=(python "${CATALOG_SCRIPT}" "${common_args[@]}" --require-complete-sidecars --require-complete-assets)

if [[ "${ALLOW_MISSING_SIDECARS}" -eq 1 ]]; then
    preflight_command_parts+=(--allow-missing-sidecars)
    sidecar_audit_parts+=(--allow-missing-sidecars)
fi
if [[ "${ALLOW_MISSING_ASSETS}" -eq 1 ]]; then
    preflight_command_parts+=(--allow-missing-assets)
    asset_audit_parts+=(--allow-missing-assets)
fi

preflight_command="$(format_shell_command "${preflight_command_parts[@]}")"
sidecar_audit_command="$(format_shell_command "${sidecar_audit_parts[@]}")"
asset_audit_command="$(format_shell_command "${asset_audit_parts[@]}")"
manifest_command="$(format_shell_command "${manifest_parts[@]}")"
strict_manifest_command="$(format_shell_command "${strict_manifest_parts[@]}")"
launch_command="$(format_shell_command "${launch_parts[@]}")"
strict_launch_command="$(format_shell_command "${strict_launch_parts[@]}")"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json
print(json.dumps({
    "issue": "Issue #3 attached-html preflight route",
    "repo_root": ${REPO_ROOT@Q},
    "guide_doc": ${GUIDE_DOC@Q},
    "google_flow_doc": ${FLOW_DOC@Q},
    "windows_runbook_doc": ${RUNBOOK_DOC@Q},
    "bind": ${BIND@Q},
    "port": ${PORT},
    "input_paths": ${INPUT_PATHS[@]+[]},
    "preferred_initial_page": ${PREFERRED_INITIAL_PAGE@Q},
    "allow_missing_sidecars": ${ALLOW_MISSING_SIDECARS} == 1,
    "allow_missing_assets": ${ALLOW_MISSING_ASSETS} == 1,
    "commands": {
        "surface_check": ${surface_check_command@Q},
        "preflight_report": ${preflight_command@Q},
        "sidecar_audit": ${sidecar_audit_command@Q},
        "asset_audit": ${asset_audit_command@Q},
        "manifest": ${manifest_command@Q},
        "strict_manifest": ${strict_manifest_command@Q},
        "launch_catalog": ${launch_command@Q},
        "strict_launch_catalog": ${strict_launch_command@Q}
    },
    "notes": [
        "Run the surface check first so missing branch-local docs or attached-pages helpers fail fast before the bundle is blamed.",
        "Run the preflight report first when the route should truthfully summarize whether the current agent_files or user_files bundle is ready for localhost replay.",
        "Run the sidecar audit before the broader asset audit so missing sibling _files directories are caught before deeper asset drift is diagnosed.",
        "Use the strict manifest or strict launch commands only after the sidecar and asset audits already reflect the exact pinned inputs you want to trust."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #3 attached-html preflight route

Repo root: ${REPO_ROOT}
Guide: ${GUIDE_DOC}
Google flow doc: ${FLOW_DOC}
Windows runbook: ${RUNBOOK_DOC}
Bind: http://${BIND}:${PORT}/
Pinned inputs: ${#INPUT_PATHS[@]}
Preferred initial page: ${PREFERRED_INITIAL_PAGE:-auto}
Allow missing sidecars: $([[ "${ALLOW_MISSING_SIDECARS}" -eq 1 ]] && echo yes || echo no)
Allow missing assets: $([[ "${ALLOW_MISSING_ASSETS}" -eq 1 ]] && echo yes || echo no)

Suggested route
===============
  Surface check:
    ${surface_check_command}

  Preflight report:
    ${preflight_command}

  Sidecar audit:
    ${sidecar_audit_command}

  Asset audit:
    ${asset_audit_command}

  Manifest:
    ${manifest_command}

  Strict manifest:
    ${strict_manifest_command}

  Launch localhost catalog:
    ${launch_command}

  Strict localhost catalog launch:
    ${strict_launch_command}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails fast before the attached export is blamed.
  - Run the preflight report first when the next replay should stay on one compact Linux or WSL summary before the localhost server is started.
  - Run the sidecar audit before the broader asset audit so missing sibling _files bundles are separated from deeper asset-closure drift.
  - Treat strict manifest or strict launch failures as bundle-integrity problems first, not headed-browser regressions.
  - Keep the current Google-shaped attached page first with --preferred-initial-page when the replay should stay pinned to one page inside the three-page compatibility bundle.
EOF
