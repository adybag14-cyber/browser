#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ $# -gt 0 ]]; then
    REPO_ROOT="$1"
fi

if [[ ! -d "${REPO_ROOT}" ]]; then
    echo "Repository root does not exist: ${REPO_ROOT}" >&2
    exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
    echo "ripgrep (rg) is required" >&2
    exit 2
fi

found=0

report_section() {
    local title="$1"
    local pattern="$2"
    shift 2
    local output
    output="$(rg -n --no-heading --color=never "$pattern" "$@" 2>/dev/null || true)"
    if [[ -n "${output}" ]]; then
        found=1
        printf '\n[%s]\n%s\n' "${title}" "${output}"
    fi
}

printf 'Inspecting Zig 0.17 migration blockers under %s\n' "${REPO_ROOT}"

report_section \
    "Config args iterator migration" \
    'std\.process\.ArgIterator' \
    "${REPO_ROOT}/src/Config.zig"

report_section \
    "Display backends with top-level cImport" \
    '@cImport\(' \
    "${REPO_ROOT}/src/display/baremetal_backend.zig" \
    "${REPO_ROOT}/src/display/win32_backend.zig"

report_section \
    "Legacy stderr writer accessors" \
    'std\.(fs\.File|Io\.File)\.stderr\(\)\.writerStreaming|getStdErr\(' \
    "${REPO_ROOT}/src/crash_handler.zig" \
    "${REPO_ROOT}/src/log.zig"

report_section \
    "ArrayList writer API migration" \
    '\.writer\(' \
    "${REPO_ROOT}/src/browser/js/Local.zig"

report_section \
    "Tuple-based @call migration candidates" \
    '@call\(' \
    "${REPO_ROOT}/src/browser/js/Caller.zig"

report_section \
    "Packed union vector restrictions" \
    'packed union|@Vector' \
    "${REPO_ROOT}/src/string.zig"

if [[ ${found} -eq 0 ]]; then
    echo "No known Zig 0.17 blocker patterns matched."
    exit 0
fi

echo
cat <<'EOF'
Known blocker patterns are still present.
Next step: patch the matches above or rerun the helper after landing a focused compatibility fix.
EOF
exit 1
