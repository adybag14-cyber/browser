#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_attached_pages_preflight_report_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the Linux attached-pages preflight helper surface still has its
required scripts, docs, and command flags in place before a localhost replay is
reopened from Linux or WSL.
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

declare -a REFERENCE_PATHS=(
    "tmp-browser-smoke/attached-pages/README.md|file|Attached-pages localhost harness note that describes the preferred catalog and preflight entrypoints."
    "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py|file|Attached-pages localhost launcher used by the preflight report."
    "tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py|file|Python preflight report that ranks the next localhost replay step."
    "scripts/windows/show_attached_pages_preflight_report.ps1|file|Windows wrapper that the Linux helper should stay aligned with at a flag level."
    "scripts/linux/show_attached_pages_preflight_report.sh|file|Linux wrapper that should keep the preflight report on one compact shell surface."
    "scripts/linux/check_attached_pages_preflight_report_surface.sh|file|Fail-fast surface checker for the Linux attached-pages preflight route."
)

declare -a CONTENT_EXPECTATIONS=(
    "tmp-browser-smoke/attached-pages/README.md|attached_pages_preflight_report.py|The attached-pages README still points at the shared Python preflight report."
    "tmp-browser-smoke/attached-pages/README.md|show_attached_pages_preflight_report.ps1|The attached-pages README still points at the Windows wrapper surface that the Linux helper mirrors."
    "scripts/linux/show_attached_pages_preflight_report.sh|--use-workspace-agent-files|The Linux wrapper still supports pinning the workspace agent_files bundle directly."
    "scripts/linux/show_attached_pages_preflight_report.sh|--agent-files-root|The Linux wrapper still supports an explicit agent_files root override."
    "scripts/linux/show_attached_pages_preflight_report.sh|--allow-missing-sidecars|The Linux wrapper still exposes the missing-sidecar tolerance flag."
    "scripts/linux/show_attached_pages_preflight_report.sh|--allow-missing-assets|The Linux wrapper still exposes the missing-asset tolerance flag."
    "scripts/linux/show_attached_pages_preflight_report.sh|--google-style|The Linux wrapper still exposes Google-style ranking."
    "scripts/linux/show_attached_pages_preflight_report.sh|attached_pages_preflight_report.py|The Linux wrapper still delegates to the shared Python preflight report."
    "scripts/linux/check_attached_pages_preflight_report_surface.sh|show_attached_pages_preflight_report.sh|The surface checker still verifies the Linux wrapper itself."
)

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

reference_rows=()
content_rows=()
missing_count=0

for entry in "${REFERENCE_PATHS[@]}"; do
    IFS="|" read -r relative_path kind purpose <<<"${entry}"
    full_path="${REPO_ROOT}/${relative_path}"
    exists=0
    if [[ "${kind}" == "directory" ]]; then
        [[ -d "${full_path}" ]] && exists=1
    else
        [[ -f "${full_path}" ]] && exists=1
    fi
    if [[ "${exists}" -eq 0 ]]; then
        missing_count=$((missing_count + 1))
    fi
    reference_rows+=("${relative_path}|${kind}|${purpose}|${exists}")
done

for entry in "${CONTENT_EXPECTATIONS[@]}"; do
    IFS="|" read -r relative_path snippet purpose <<<"${entry}"
    full_path="${REPO_ROOT}/${relative_path}"
    exists=0
    if [[ -f "${full_path}" ]] && grep -Fq -- "${snippet}" "${full_path}"; then
        exists=1
    fi
    if [[ "${exists}" -eq 0 ]]; then
        missing_count=$((missing_count + 1))
    fi
    content_rows+=("${relative_path}|${snippet}|${purpose}|${exists}")
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(python3 - <<'PY'
import json
print(json.dumps('attached-pages-preflight-report-surface'))
PY
)"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "reference_count": %d,\n' "${#reference_rows[@]}"
    printf '  "content_check_count": %d,\n' "${#content_rows[@]}"
    printf '  "missing_count": %d,\n' "${missing_count}"
    printf '  "references": [\n'
    for index in "${!reference_rows[@]}"; do
        IFS="|" read -r relative_path kind purpose exists <<<"${reference_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"path": %s, "kind": %s, "purpose": %s, "exists": %s}' \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${kind}")" \
            "$(json_escape "${purpose}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ],\n'
    printf '  "content_checks": [\n'
    for index in "${!content_rows[@]}"; do
        IFS="|" read -r relative_path snippet purpose exists <<<"${content_rows[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"path": %s, "snippet": %s, "purpose": %s, "exists": %s}' \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${snippet}")" \
            "$(json_escape "${purpose}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ]\n'
    printf '}\n'
    if [[ "${missing_count}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Attached-pages preflight helper surface check"
echo
echo "Repo root: ${REPO_ROOT}"
echo

for row in "${reference_rows[@]}"; do
    IFS="|" read -r relative_path kind purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
done

echo
echo "Helper source expectations:"
for row in "${content_rows[@]}"; do
    IFS="|" read -r relative_path snippet purpose exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  ${purpose}"
done

if [[ "${missing_count}" -gt 0 ]]; then
    echo
    echo "Missing checks: ${missing_count}"
    exit 1
fi

echo
echo "All attached-pages Linux preflight surfaces are present."
