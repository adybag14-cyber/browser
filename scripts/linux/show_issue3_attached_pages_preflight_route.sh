#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_attached_pages_preflight_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--input /path/to/html-or-folder] \
    [--preferred-initial-page "file name"] \
    [--bind 127.0.0.1] \
    [--port 8235] \
    [--google-style] \
    [--allow-missing-sidecars] \
    [--allow-missing-assets] \
    [--json]

Print the compact Linux or scheduled-run route for the issue #3 attached-pages
preflight helper before Windows replay is reopened.
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
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PYTHON_BIN="${PYTHON:-python3}"
BIND="127.0.0.1"
PORT="8235"
PREFERRED_INITIAL_PAGE=""
GOOGLE_STYLE=0
ALLOW_MISSING_SIDECARS=0
ALLOW_MISSING_ASSETS=0
JSON=0
INPUTS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --input)
            INPUTS+=("$2")
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
        --google-style)
            GOOGLE_STYLE=1
            shift
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
GUIDE_PATH="${REPO_ROOT}/docs/ISSUE3_ATTACHED_PAGES_PREFLIGHT_ROUTE.md"
SURFACE_CHECKER="${REPO_ROOT}/scripts/linux/check_issue3_attached_pages_preflight_route_surface.sh"
REPORT_HELPER="${REPO_ROOT}/tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py"
CATALOG_HELPER="${REPO_ROOT}/tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"

common_args=(
    "--repo-root" "${REPO_ROOT}"
    "--bind" "${BIND}"
    "--port" "${PORT}"
)
if [[ "${GOOGLE_STYLE}" -eq 1 ]]; then
    common_args+=("--google-style")
fi
if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    common_args+=("--preferred-initial-page" "${PREFERRED_INITIAL_PAGE}")
fi
if [[ "${ALLOW_MISSING_SIDECARS}" -eq 1 ]]; then
    common_args+=("--allow-missing-sidecars")
fi
if [[ "${ALLOW_MISSING_ASSETS}" -eq 1 ]]; then
    common_args+=("--allow-missing-assets")
fi
for input_path in "${INPUTS[@]}"; do
    common_args+=("--input" "${input_path}")
done

surface_check_command="bash $(format_shell_arg "${SURFACE_CHECKER}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
preflight_command="${PYTHON_BIN} $(format_shell_arg "${REPORT_HELPER}")"
manifest_command="${PYTHON_BIN} $(format_shell_arg "${CATALOG_HELPER}")"
strict_manifest_command="${PYTHON_BIN} $(format_shell_arg "${CATALOG_HELPER}")"
launch_command="${PYTHON_BIN} $(format_shell_arg "${CATALOG_HELPER}")"

for arg in "${common_args[@]}"; do
    quoted_arg="$(format_shell_arg "${arg}")"
    preflight_command+=" ${quoted_arg}"
    manifest_command+=" ${quoted_arg}"
    strict_manifest_command+=" ${quoted_arg}"
    launch_command+=" ${quoted_arg}"
done

manifest_command+=" --print-manifest"
strict_manifest_command+=" --require-complete-sidecars --require-complete-assets --print-manifest"
launch_command+=" --require-complete-sidecars --require-complete-assets"

sidecar_audit_command="${PYTHON_BIN} $(format_shell_arg "${CATALOG_HELPER}")"
asset_audit_command="${PYTHON_BIN} $(format_shell_arg "${CATALOG_HELPER}")"
for arg in "${common_args[@]}"; do
    quoted_arg="$(format_shell_arg "${arg}")"
    sidecar_audit_command+=" ${quoted_arg}"
    asset_audit_command+=" ${quoted_arg}"
done
sidecar_audit_command+=" --audit-sidecars"
asset_audit_command+=" --audit-assets"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 attached-pages preflight route",
    "repo_root": ${REPO_ROOT@Q},
    "guide": ${GUIDE_PATH@Q},
    "commands": {
        "surface_check": ${surface_check_command@Q},
        "preflight_report": ${preflight_command@Q},
        "sidecar_audit": ${sidecar_audit_command@Q},
        "asset_audit": ${asset_audit_command@Q},
        "manifest": ${manifest_command@Q},
        "strict_manifest": ${strict_manifest_command@Q},
        "strict_launch": ${launch_command@Q}
    },
    "notes": [
        "Run the surface check first so missing branch-local docs or helper files fail before the attached-pages replay opens.",
        "Run the preflight report next so missing sidecars or local assets are classified before Windows replay is blamed.",
        "Use the sidecar audit first when the saved export may be missing its sibling _files bundle.",
        "Use the asset audit after the sidecar audit when the bundle exists but referenced local files may still be missing.",
        "Use the strict manifest command before Windows replay when the catalog should refuse to start on an incomplete bundle."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 attached-pages preflight route

Repo root: ${REPO_ROOT}
Guide: ${GUIDE_PATH}

1. Surface check
${surface_check_command}

2. Preflight report
${preflight_command}

3. Sidecar audit
${sidecar_audit_command}

4. Asset audit
${asset_audit_command}

5. Print the current manifest
${manifest_command}

6. Refuse incomplete bundles before Windows replay
${strict_manifest_command}

7. Start the strict localhost catalog after the bundle is clean
${launch_command}

Working rule:
- Run the preflight report before reopening the Windows replay route.
- Run the sidecar audit before the asset audit when the saved export may be missing its sibling _files bundle.
- Keep the strict manifest or strict launch command as the handoff point back into Windows replay.
EOF
