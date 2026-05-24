#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_attached_html_preflight_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Fail fast when the Linux attached-html preflight route is missing the current
branch-local docs or helper files it depends on.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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
GUIDE_DOC="${REPO_ROOT}/docs/ISSUE3_ATTACHED_HTML_PREFLIGHT_ROUTE.md"
FLOW_DOC="${REPO_ROOT}/docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
RUNBOOK_DOC="${REPO_ROOT}/docs/WINDOWS_FULL_USE.md"
PREFLIGHT_SCRIPT="${REPO_ROOT}/tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py"
CATALOG_SCRIPT="${REPO_ROOT}/tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
README_PATH="${REPO_ROOT}/tmp-browser-smoke/attached-pages/README.md"
ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_attached_html_preflight_route.sh"

required_paths=(
    "${GUIDE_DOC}"
    "${FLOW_DOC}"
    "${RUNBOOK_DOC}"
    "${PREFLIGHT_SCRIPT}"
    "${CATALOG_SCRIPT}"
    "${README_PATH}"
    "${ROUTE_SCRIPT}"
)

missing_paths=()
for path in "${required_paths[@]}"; do
    if [[ ! -f "${path}" ]]; then
        missing_paths+=("${path}")
    fi
done

if [[ "${JSON}" -eq 1 ]]; then
    python3 - "${REPO_ROOT}" "${required_paths[@]}" -- "${missing_paths[@]}" <<'PY'
import json
import sys

args = sys.argv[1:]
separator = args.index("--")
repo_root = args[0]
required_paths = args[1:separator]
missing_paths = args[separator + 1 :]
print(json.dumps({
    "ok": not missing_paths,
    "repo_root": repo_root,
    "required_paths": required_paths,
    "missing_paths": missing_paths,
}, indent=2))
PY
    exit $([[ ${#missing_paths[@]} -eq 0 ]] && echo 0 || echo 1)
fi

if [[ ${#missing_paths[@]} -eq 0 ]]; then
    cat <<EOF
Issue #3 attached-html preflight route surface check passed.

Repo root: ${REPO_ROOT}
Guide doc: ${GUIDE_DOC}
Google flow doc: ${FLOW_DOC}
Windows runbook: ${RUNBOOK_DOC}
Preflight helper: ${PREFLIGHT_SCRIPT}
Catalog helper: ${CATALOG_SCRIPT}
Harness README: ${README_PATH}
Route helper: ${ROUTE_SCRIPT}
EOF
    exit 0
fi

{
    echo "Issue #3 attached-html preflight route surface check failed."
    echo
    echo "Repo root: ${REPO_ROOT}"
    echo "Missing required paths:"
    for path in "${missing_paths[@]}"; do
        echo "- ${path}"
    done
    echo
    echo "Suggested next step: restore the current attached-pages helper surface before trusting the Linux attached-html preflight route."
} >&2
exit 1
