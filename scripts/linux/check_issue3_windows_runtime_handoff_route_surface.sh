#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local Linux-or-WSL-to-Windows handoff surface for the
blocked issue #3 runtime lane still has its required docs, helpers, probes, and
command snippets in place before a run reopens the narrower Windows-only replay
ladder.
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
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should stay visible before the narrower Windows-only replay ladder reopens from Linux or WSL staging."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that still defines the Page.zig plus win32_backend.zig target boundary behind this handoff."
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md|file|Reduced Google click-focus trace note that should stay nearby before the handoff widens back to live Google."
    "docs/WINDOWS_FULL_USE.md|file|Windows-first runbook that should stay nearby when the handoff widens back out beyond the reduced probe."
    "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh|file|Fail-fast surface checker for the Linux-or-WSL-to-Windows issue #3 runtime handoff."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|file|Compact route printer for reopening the Windows-only replay ladder after Linux or WSL gating is already green."
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1|file|Fail-fast Windows runtime surface checker that should still lead the narrower replay ladder."
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1|file|Broader Windows runtime route printer that should still follow the reduced handoff surface."
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1|file|Reduced Google title probe that should remain the quickest trace-ready Windows yes-or-no check after the handoff."
    "src/browser/tests/page/google_home_title_probe.html|file|Reduced Google fixture that should remain the next narrower replay target before live Google."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|docs/ISSUE3_RUNTIME_REENTRY_GATES.md|The handoff route printer keeps the runtime gate note in its read-first set."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|check_issue3_windows_runtime_handoff_route_surface.sh|The handoff route printer points back to the dedicated handoff surface checker."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"handoff_surface\"|The handoff route printer exposes the fail-fast checker in JSON output."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|Linux or WSL handoff surface check:|The handoff route printer prints the fail-fast checker before the narrower Windows-only replay ladder."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|Run handoff_surface first|The handoff route printer explains that the checker runs before the broader Windows replay helpers."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"windows_runtime_surface\"|The handoff route printer keeps the Windows runtime surface checker visible after the Linux or WSL handoff checker."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"windows_runtime_route\"|The handoff route printer keeps the broader Windows runtime route visible after the Linux or WSL handoff checker."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"reduced_google_probe\"|The handoff route printer keeps the reduced Google probe visible before the reduced fixture or live Google."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|Treat live Google as the last step|The handoff route printer keeps the live-Google-last rule visible."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-windows-runtime-handoff-surface")"
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

echo "Issue #3 Windows runtime handoff surface check"
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
echo "All Windows runtime handoff surfaces are present."
