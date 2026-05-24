#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_runtime_reentry_gates_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Verify that the branch-local issue #3 runtime re-entry gate route still has its
required docs, helpers, and command snippets in place before a run reopens the
direct Page.zig and win32_backend.zig path.
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
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|file|Read-first compact route note for the issue #3 gate checker."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|The underlying gate note that defines the publication and toolchain rules."
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|The narrowed runtime revalidation note that should stay downstream of the gate checker."
    "scripts/check_issue3_runtime_reentry_gates.py|file|The direct gate checker that answers whether the runtime patch is ready to reopen."
    "scripts/linux/check_issue3_runtime_reentry_gates_surface.sh|file|Fail-fast surface checker for the compact gate route."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|file|Compact route printer for the gate checker and its recovery follow-ups."
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Saved-browser restore route printer used when the publication gate is still closed."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Zig recovery route printer used when the toolchain gate is still closed."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer used when staging is still incomplete."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Direct runtime revalidation route printer used only after the gates open."
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight that the gate checker depends on for honest staging status."
    "scripts/check_linux_build_readiness.py|file|Build-readiness helper that still anchors the downstream staging route."
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1|file|Windows runtime route helper that stays downstream of the gate check."
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|Runtime contract checker that stays downstream of the gate check."
    "build.zig.zon|file|Manifest surface the checker needs for minimum-Zig and path-dependency inspection."
)

declare -a CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|check_issue3_runtime_reentry_gates_surface.sh|The route note keeps the dedicated route surface checker visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|show_issue3_runtime_reentry_gates_route.sh|The route note keeps the compact route printer visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|check_issue3_runtime_reentry_gates.py|The route note keeps the direct gate checker visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The route note keeps the saved-browser restore route visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|The route note keeps the Zig recovery route visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The route note keeps the Linux build-readiness route visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The route note keeps the downstream runtime revalidation route visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md|Reopen the narrowed runtime revalidation route only after the gate checker is green.|The route note keeps the reopen order explicit."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|check_issue3_runtime_reentry_gates_surface.sh|The route printer points back to the dedicated route surface checker."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|check_issue3_runtime_reentry_gates.py|The route printer still prints the direct gate-check command."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer still prints the restore-route follow-up."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|show_issue3_zig_toolchain_recovery_route.sh|The route printer still prints the Zig recovery follow-up."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still prints the Linux build-readiness follow-up."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer still prints the runtime revalidation follow-up."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|Gate check:|The route printer still prints the direct gate-check section."
    "scripts/linux/show_issue3_runtime_reentry_gates_route.sh|Runtime revalidation route after the gates pass:|The route printer still prints the final runtime handoff section."
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
    printf '  "profile": %s,\n' "$(json_escape "issue3-runtime-reentry-gate-route-surface")"
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

echo "Issue #3 runtime re-entry gate route surface check"
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
echo "Content expectations:"
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
echo "All runtime re-entry gate route surfaces are present."
