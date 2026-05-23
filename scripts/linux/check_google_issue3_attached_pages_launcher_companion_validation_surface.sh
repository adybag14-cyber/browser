#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_google_issue3_attached_pages_launcher_companion_validation_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the Linux attached-pages launcher companion for issue #3 still
points at the live note, Python launcher, preflight report, and Windows handoff
surfaces it depends on.
EOF
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
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
    "docs/ISSUE3_LINUX_ATTACHED_HTML_VALIDATION_FLOW.md|file|Linux attached-pages note for issue #3 launcher preflight."
    "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md|file|Broader Google attached HTML note kept beside the Linux companion."
    "scripts/linux/check_google_issue3_attached_pages_launcher_companion_validation_surface.sh|file|Fail-fast checker for the Linux attached-pages launcher companion."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|file|Linux attached-pages launcher companion helper."
    "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1|file|Windows replay helper that receives the Linux-side handoff."
    "scripts/windows/show_google_attached_html_validation_flow.ps1|file|Dedicated Windows Google attached HTML flow that receives the Linux-side handoff."
    "tmp-browser-smoke/attached-pages/README.md|file|Attached-pages README surfaced by the Linux companion."
    "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py|file|Cross-platform launcher surfaced by the Linux companion."
    "tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py|file|Preflight report surfaced by the Linux companion."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|check_google_issue3_attached_pages_launcher_companion_validation_surface.sh|Linux companion keeps its own fail-fast checker visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|attached_pages_preflight_report.py|Linux companion keeps the attached-pages preflight report visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|start_attached_pages_catalog.py|Linux companion keeps the cross-platform launcher visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|--audit-sidecars|Linux companion keeps the sidecar-first audit route visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|--audit-assets|Linux companion keeps the broader asset audit route visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|--require-complete-sidecars|Linux companion keeps the strict sidecar gate visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|--require-complete-assets|Linux companion keeps the strict asset gate visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|--google-style|Linux companion keeps the Google-style replay ordering visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|show_google_issue3_windows_replay_attached_html_quickstart.ps1|Linux companion keeps the Windows replay quickstart handoff visible."
    "scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh|show_google_attached_html_validation_flow.ps1|Linux companion keeps the dedicated Windows Google-flow handoff visible."
    "docs/ISSUE3_LINUX_ATTACHED_HTML_VALIDATION_FLOW.md|show_google_issue3_attached_pages_launcher_companion.sh|Linux attached-pages note keeps the companion helper visible."
    "docs/ISSUE3_LINUX_ATTACHED_HTML_VALIDATION_FLOW.md|check_google_issue3_attached_pages_launcher_companion_validation_surface.sh|Linux attached-pages note keeps the fail-fast checker visible."
    "docs/ISSUE3_LINUX_ATTACHED_HTML_VALIDATION_FLOW.md|Control your online safety and privacy|Linux attached-pages note preserves the pinned Google-like first page guidance."
    "docs/ISSUE3_LINUX_ATTACHED_HTML_VALIDATION_FLOW.md|show_google_issue3_windows_replay_attached_html_quickstart.ps1|Linux attached-pages note keeps the Windows replay quickstart handoff visible."
    "docs/ISSUE3_LINUX_ATTACHED_HTML_VALIDATION_FLOW.md|show_google_attached_html_validation_flow.ps1|Linux attached-pages note keeps the dedicated Windows Google-flow handoff visible."
)

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
    printf '  "profile": %s,\n' "$(json_escape "google-issue3-linux-attached-pages-launcher-companion")"
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

echo "Google issue #3 Linux attached-pages launcher companion surface check"
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
echo "Linux attached-pages launcher companion surface is intact."
