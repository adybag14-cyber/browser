#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #3 Linux or WSL Zig toolchain recovery route for the blocked
Enter-submit runtime lane. This route helps the next run confirm the branch's
minimum Zig line, discover staged Zig candidates, and print the exact readiness
commands to rerun once a matching toolchain is available.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
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
TOOLCHAINS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
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

REPO_ROOT="$(cd "${REPO_ROOT}")" && pwd)
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

if [[ ! -f "${REPO_ROOT}/build.zig.zon" ]]; then
    echo "build.zig.zon not found under ${REPO_ROOT}" >&2
    exit 1
fi

MINIMUM_ZIG="$(python3 - "${REPO_ROOT}/build.zig.zon" <<'PY'
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r'\.minimum_zig_version\s*=\s*"([^"]+)"', text)
if match is None:
    raise SystemExit("Could not find minimum_zig_version in build.zig.zon")
print(match.group(1))
PY
)"

mapfile -t CANDIDATE_ROWS < <(python3 - "${TOOLCHAINS_ROOT}" "${MINIMUM_ZIG}" <<'PY'
from __future__ import annotations

import pathlib
import re
import subprocess
import sys

toolchains_root = pathlib.Path(sys.argv[1])
minimum_zig = sys.argv[2]
patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
semver_re = re.compile(r"^(\d+)\.(\d+)\.(\d+)")

def parse_semver(text: str) -> tuple[int, int, int]:
    match = semver_re.match(text)
    if match is None:
        raise ValueError(text)
    return tuple(int(part) for part in match.groups())

def classify(minimum: str, actual: str) -> str:
    minimum_parts = parse_semver(minimum)
    actual_parts = parse_semver(actual)
    if actual_parts < minimum_parts:
        return "older-than-minimum"
    if actual_parts[:2] == minimum_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"

seen: set[pathlib.Path] = set()
if toolchains_root.is_dir():
    for pattern in patterns:
        for path in sorted(toolchains_root.glob(pattern)):
            resolved = path.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            try:
                completed = subprocess.run(
                    [str(resolved), "version"],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                version = completed.stdout.strip() or completed.stderr.strip()
                status = classify(minimum_zig, version)
            except Exception:
                version = "unusable"
                status = "version-probe-failed"
            print(f"{resolved}\t{version}\t{status}")
PY
)

MATCHING_CANDIDATE=""
MATCHING_VERSION=""
if [[ "${#CANDIDATE_ROWS[@]}" -gt 0 ]]; then
    for row in "${CANDIDATE_ROWS[@]}"; do
        IFS=$'\t' read -r candidate_path candidate_version candidate_status <<<"${row}"
        if [[ "${candidate_status}" == "matches-expected-line" ]]; then
            MATCHING_CANDIDATE="${candidate_path}"
            MATCHING_VERSION="${candidate_version}"
            break
        fi
    done
fi

DISCOVERY_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --skip-rust-check --expect-saved-archives"
MATCHING_READINESS_COMMAND=""
if [[ -n "${MATCHING_CANDIDATE}" ]]; then
    MATCHING_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --zig $(format_shell_arg "${MATCHING_CANDIDATE}") --expect-saved-archives --expect-offline-deps --require-prebuilt-v8"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 Zig toolchain recovery route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "toolchains_root": %s,\n' "$(json_escape "${TOOLCHAINS_ROOT}")"
    printf '  "minimum_zig": %s,\n' "$(json_escape "${MINIMUM_ZIG}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "matching_candidate": %s,\n' "$(json_escape "${MATCHING_CANDIDATE}")"
    printf '  "matching_candidate_version": %s,\n' "$(json_escape "${MATCHING_VERSION}")"
    printf '  "commands": {\n'
    printf '    "discovery": %s' "$(json_escape "${DISCOVERY_COMMAND}")"
    if [[ -n "${MATCHING_READINESS_COMMAND}" ]]; then
        printf ',\n    "matching_readiness": %s\n' "$(json_escape "${MATCHING_READINESS_COMMAND}")"
    else
        printf '\n'
    fi
    printf '  },\n'
    printf '  "candidates": [\n'
    for index in "${!CANDIDATE_ROWS[@]}"; do
        IFS=$'\t' read -r candidate_path candidate_version candidate_status <<<"${CANDIDATE_ROWS[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"path": %s, "version": %s, "status": %s}' \
            "$(json_escape "${candidate_path}")" \
            "$(json_escape "${candidate_version}")" \
            "$(json_escape "${candidate_status}")"
    done
    printf '\n  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 Zig toolchain recovery route

Repo root:            ${REPO_ROOT}
Toolchains root:      ${TOOLCHAINS_ROOT}
Minimum Zig line:     ${MINIMUM_ZIG}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Candidate discovery
===================
  ${DISCOVERY_COMMAND}
EOF

if [[ "${#CANDIDATE_ROWS[@]}" -eq 0 ]]; then
    cat <<EOF

Discovered Zig candidates: none

Working rules
=============
  - Stage a Zig ${MINIMUM_ZIG%.*}.x toolchain under ${TOOLCHAINS_ROOT} before reopening focused Linux or WSL validation.
  - Treat the attached Zig 0.17 dev bundle as a surfaced fallback only; it is not branch-compatible validation evidence for this checkout.
  - After staging a matching Zig line, rerun the discovery command and then rerun the full readiness helper with that toolchain.
EOF
    exit 0
fi

echo
echo "Discovered Zig candidates"
echo "========================="
for row in "${CANDIDATE_ROWS[@]}"; do
    IFS=$'\t' read -r candidate_path candidate_version candidate_status <<<"${row}"
    echo "  - ${candidate_path} [${candidate_version}; ${candidate_status}]"
done

if [[ -n "${MATCHING_READINESS_COMMAND}" ]]; then
    cat <<EOF

Suggested matching readiness command
====================================
  ${MATCHING_READINESS_COMMAND}

Working rules
=============
  - Prefer ${MATCHING_CANDIDATE} because it matches the branch's ${MINIMUM_ZIG%.*}.x Zig line.
  - Keep the saved-archive and offline-dependency checks in place when rerunning readiness with the matching toolchain.
  - Only reopen the direct Page.zig plus win32_backend.zig runtime patch after this matching-line readiness pass stops reporting the environment as the blocker.
EOF
else
    cat <<EOF

No branch-compatible Zig candidate is staged yet.

Working rules
=============
  - Ignore candidates above that are older than ${MINIMUM_ZIG} or that live on a different major/minor Zig line.
  - Stage a Zig ${MINIMUM_ZIG%.*}.x toolchain under ${TOOLCHAINS_ROOT}, then rerun the discovery command.
  - Treat the attached Zig 0.17 dev bundle as a surfaced fallback only; it is not honest issue #3 validation evidence for this branch.
EOF
fi
