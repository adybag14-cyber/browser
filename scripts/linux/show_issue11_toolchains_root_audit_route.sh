#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue11_toolchains_root_audit_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Print the compact issue #11 toolchains-root audit route used before Linux/WSL
re-entry trusts wider helper surfaces.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
SURFACE_CHECK_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue11_toolchains_root_audit_surface.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PREFERENCE_AUDIT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue11_toolchains_root_preference.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
CONSISTENCY_AUDIT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue11_toolchains_root_consistency.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
CANDIDATE_HELPER_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue11_toolchains_root_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Issue #11 toolchains-root audit route",
    "repo_root": ${REPO_ROOT@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "preference_audit": ${PREFERENCE_AUDIT_COMMAND@Q},
        "consistency_audit": ${CONSISTENCY_AUDIT_COMMAND@Q},
        "candidate_helper": ${CANDIDATE_HELPER_COMMAND@Q},
    },
    "notes": [
        "Run the surface check first so missing audit helpers fail fast before Linux/WSL re-entry trusts wider saved-Memory, Rust, Zig, or build-readiness surfaces.",
        "Run the preference audit next when the question is whether branch-local helpers still prefer toolchains/ before .toolchains/.",
        "Run the consistency audit after the broader preference audit when the narrowed issue #11 checkpoints need a smaller pass-fail summary.",
        "Run the candidate helper last when both roots are visible and the next rerun needs an explicit --toolchains-root override."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #11 toolchains-root audit route

Repo root: ${REPO_ROOT}

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Preference audit:
    ${PREFERENCE_AUDIT_COMMAND}

  Consistency audit:
    ${CONSISTENCY_AUDIT_COMMAND}

  Candidate helper:
    ${CANDIDATE_HELPER_COMMAND}

Working rules
=============
  - Run the surface check first so missing audit helpers fail fast before Linux/WSL re-entry trusts wider saved-Memory, Rust, Zig, or build-readiness surfaces.
  - Run the preference audit next when the question is whether branch-local helpers still prefer toolchains/ before .toolchains/.
  - Run the consistency audit after the broader preference audit when the narrowed issue #11 checkpoints need a smaller pass-fail summary.
  - Run the candidate helper last when both roots are visible and the next rerun needs an explicit --toolchains-root override.
EOF