#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local Linux-to-Windows handoff helper surface for issue
#3 still has its required docs, helpers, and command snippets in place before a
run jumps from saved-snapshot recovery back onto the final headed Win32 replay
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
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should stay read-first before the Windows handoff reopens."
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md|file|Click-focus trace replay note that should stay visible before the reduced Google fixture or live Google reruns."
    "docs/WINDOWS_FULL_USE.md|file|Windows route catalog that should keep the neighboring Google and attached-page replay ladders visible."
    "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh|file|Fail-fast Linux surface checker for the issue #3 Windows runtime handoff route."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|file|Compact Linux-or-WSL-to-Windows handoff route printer for the final headed runtime ladder."
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1|file|Fail-fast Windows runtime surface checker that should run before the broader Windows route helper."
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1|file|Broader Windows runtime route helper that should stay one rung below the handoff helper."
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1|file|Reduced Google headed probe used before the direct fixture or live Google replay."
    "src/browser/tests/page/google_home_title_probe.html|file|Reduced Google fixture used for the lower-risk headed Win32 replay step."
)

declare -a CONTENT_EXPECTATIONS=(
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|The handoff helper keeps the runtime revalidation note in its read-first list."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md|The handoff helper keeps the click-focus trace replay note in its read-first list."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|docs/WINDOWS_FULL_USE.md|The handoff helper keeps the broader Windows route catalog in its read-first list."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|check_google_issue3_enter_submit_runtime_revalidation_surface.ps1|The handoff helper still starts with the fail-fast Windows runtime surface check."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|show_google_issue3_enter_submit_runtime_revalidation.ps1|The handoff helper still points back to the broader Windows runtime route."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|chrome-google-home-title-probe.ps1|The handoff helper still keeps the reduced Google probe visible before the direct fixture and live Google."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|google_home_title_probe.html?google-home-probe=1|The handoff helper still prints the reduced Google fixture replay step."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|https://www.google.com/|The handoff helper still keeps live Google as the final replay rung."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|runtime-input-backend-<pid>.log|The handoff helper still points at the runtime trace log pattern."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|wndproc-input-<pid>.log|The handoff helper still points at the wndproc trace log pattern."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"windows_runtime_surface\"|The handoff helper still exposes the fail-fast Windows surface command in JSON output."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"windows_runtime_route\"|The handoff helper still exposes the broader Windows route command in JSON output."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"windows_build\"|The handoff helper still exposes the Windows build command in JSON output."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"reduced_google_probe\"|The handoff helper still exposes the reduced Google probe command in JSON output."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"reduced_google_fixture\"|The handoff helper still exposes the reduced Google fixture command in JSON output."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|\"live_google\"|The handoff helper still exposes the live Google command in JSON output."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.|The handoff helper keeps the saved-snapshot and toolchain gate note visible."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|Run the Windows runtime surface check first|The handoff helper keeps the fail-fast ordering note visible."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|Use the reduced Google probe before the direct fixture or live Google|The handoff helper keeps the reduced-before-live replay rule visible."
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh|Treat live Google as the last step in this handoff|The handoff helper keeps the final live-Google guardrail visible."
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md|enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus|The click-focus replay note still keeps the click-first shared Enter-order probe visible."
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md|show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle|The click-focus replay note still keeps the attached-pages bundle ladder visible."
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md|runtime-input-backend-<pid>.log|The click-focus replay note still keeps the runtime trace pattern visible."
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md|wndproc-input-<pid>.log|The click-focus replay note still keeps the wndproc trace pattern visible."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|chrome-google-home-title-probe.ps1|The runtime revalidation note still keeps the reduced Google probe visible."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|google_home_title_probe.html?google-home-probe=1|The runtime revalidation note still keeps the reduced Google fixture visible."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|runtime-input-backend-*.log|The runtime revalidation note still keeps the runtime trace glob visible."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|wndproc-input-*.log|The runtime revalidation note still keeps the wndproc trace glob visible."
    "docs/WINDOWS_FULL_USE.md|google-form-controls-enter-order|The Windows route catalog still keeps the Google form-controls replay ladder visible."
    "docs/WINDOWS_FULL_USE.md|google-shared-enter-order|The Windows route catalog still keeps the shared Enter-order replay ladder visible."
    "docs/WINDOWS_FULL_USE.md|attached-html-target-bundle|The Windows route catalog still keeps the attached-pages bundle ladder visible."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-windows-runtime-handoff-route-surface")"
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
