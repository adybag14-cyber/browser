#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_branch_compatible_zig_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print a compact issue #3 helper route for finding a branch-compatible Zig
toolchain before rerunning Linux build-readiness or focused Page.zig and
win32_backend.zig validation.
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

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
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
    echo "build.zig.zon was not found under ${REPO_ROOT}" >&2
    exit 1
fi

PYTHON_OUTPUT="$(
python3 - "${REPO_ROOT}" "${TOOLCHAINS_ROOT}" "${FALLBACK_ZIG_ARCHIVE}" <<'PY'
from __future__ import annotations

import json
from pathlib import Path
import re
import subprocess
import sys

repo_root = Path(sys.argv[1]).resolve()
toolchains_root = Path(sys.argv[2]).resolve()
fallback_raw = sys.argv[3]
fallback_path = Path(fallback_raw).resolve() if fallback_raw else None

text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
match = re.search(r'\.minimum_zig_version\s*=\s*"([^"]+)"', text)
if match is None:
    raise SystemExit("Could not find .minimum_zig_version in build.zig.zon")

minimum_zig = match.group(1)
minimum_major_minor = ".".join(minimum_zig.split(".")[:2])
patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")

def probe(path: Path) -> tuple[str | None, str]:
    try:
        completed = subprocess.run(
            [str(path), "version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None, "unusable"

    version = completed.stdout.strip() or completed.stderr.strip()
    if not version:
        return None, "unusable"
    major_minor = ".".join(version.split(".")[:2])
    if major_minor == minimum_major_minor:
        return version, "matches"
    return version, "mismatched"

candidates: list[dict[str, str]] = []
seen: set[Path] = set()
if toolchains_root.is_dir():
    for pattern in patterns:
        for path in sorted(toolchains_root.glob(pattern)):
            if not path.is_file():
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            version, status = probe(resolved)
            candidates.append(
                {
                    "path": str(resolved),
                    "version": version or "unknown",
                    "status": status,
                }
            )

matching_candidates = [entry for entry in candidates if entry["status"] == "matches"]

fallback = None
if fallback_path is not None:
    fallback = {
        "path": str(fallback_path),
        "exists": fallback_path.is_file(),
    }
    if fallback_path.is_file():
        version_match = re.search(r"(\d+\.\d+\.\d+)", fallback_path.name)
        if version_match:
            fallback["version"] = version_match.group(1)
            fallback["status"] = (
                "matches"
                if ".".join(version_match.group(1).split(".")[:2]) == minimum_major_minor
                else "mismatched"
            )
        else:
            fallback["version"] = "unknown"
            fallback["status"] = "unknown"

result = {
    "minimum_zig": minimum_zig,
    "minimum_major_minor": minimum_major_minor,
    "repo_root": str(repo_root),
    "toolchains_root": str(toolchains_root),
    "candidates": candidates,
    "matching_candidates": matching_candidates,
    "fallback_zig_archive": fallback,
}
print(json.dumps(result))
PY
)"

MINIMUM_ZIG="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["minimum_zig"])' "${PYTHON_OUTPUT}")"
MINIMUM_MAJOR_MINOR="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["minimum_major_minor"])' "${PYTHON_OUTPUT}")"
MATCHING_CANDIDATE_PATH="$(python3 -c 'import json,sys; data=json.loads(sys.argv[1]); print(data["matching_candidates"][0]["path"] if data["matching_candidates"] else "")' "${PYTHON_OUTPUT}")"
MATCHING_CANDIDATE_VERSION="$(python3 -c 'import json,sys; data=json.loads(sys.argv[1]); print(data["matching_candidates"][0]["version"] if data["matching_candidates"] else "")' "${PYTHON_OUTPUT}")"
FALLBACK_STATUS="$(python3 -c 'import json,sys; data=json.loads(sys.argv[1]); fb=data.get("fallback_zig_archive"); print("" if not fb else fb.get("status",""))' "${PYTHON_OUTPUT}")"
FALLBACK_PATH="$(python3 -c 'import json,sys; data=json.loads(sys.argv[1]); fb=data.get("fallback_zig_archive"); print("" if not fb else fb.get("path",""))' "${PYTHON_OUTPUT}")"
FALLBACK_VERSION="$(python3 -c 'import json,sys; data=json.loads(sys.argv[1]); fb=data.get("fallback_zig_archive"); print("" if not fb else fb.get("version",""))' "${PYTHON_OUTPUT}")"

SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root $(format_shell_arg "${REPO_ROOT}")"
SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives"
ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_PATH}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_PATH}")"
    SKIP_ZIG_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_PATH}")"
    ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_PATH}")"
fi

MATCHED_READINESS_COMMAND=""
MATCHED_BUILD_COMMAND=""
if [[ -n "${MATCHING_CANDIDATE_PATH}" ]]; then
    MATCHED_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --zig $(format_shell_arg "${MATCHING_CANDIDATE_PATH}") --expect-saved-archives --expect-offline-deps --require-prebuilt-v8"
    if [[ -n "${FALLBACK_PATH}" ]]; then
        MATCHED_READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_PATH}")"
    fi
    MATCHED_BUILD_COMMAND="ZIG=$(format_shell_arg "${MATCHING_CANDIDATE_PATH}") zig build --summary all"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

payload = json.loads(${PYTHON_OUTPUT@Q})
payload["commands"] = {
    "surface_check": ${SURFACE_CHECK_COMMAND@Q},
    "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
    "skip_zig_readiness": ${SKIP_ZIG_COMMAND@Q},
    "linux_build_route": ${ROUTE_COMMAND@Q},
    "matched_readiness": ${MATCHED_READINESS_COMMAND@Q},
    "matched_build": ${MATCHED_BUILD_COMMAND@Q},
}
print(json.dumps(payload, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 branch-compatible Zig route

Repo root:            ${REPO_ROOT}
Minimum Zig line:     ${MINIMUM_ZIG}
Toolchains root:      ${TOOLCHAINS_ROOT}
Fallback Zig archive: ${FALLBACK_PATH:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved-memory preflight:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Build-readiness route before picking a Zig binary:
    ${SKIP_ZIG_COMMAND}
    ${ROUTE_COMMAND}

EOF

echo "Discovered Zig candidates"
echo "========================"
python3 - "${PYTHON_OUTPUT}" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
candidates = data["candidates"]
if not candidates:
    print("  none")
else:
    for entry in candidates:
        print(f'  {entry["path"]} [{entry["version"]}; {entry["status"]}]')
PY

if [[ -n "${MATCHING_CANDIDATE_PATH}" ]]; then
    cat <<EOF

Recommended branch-compatible Zig
================================
  ${MATCHING_CANDIDATE_PATH} [${MATCHING_CANDIDATE_VERSION}]

  Re-run readiness with the matching Zig line:
    ${MATCHED_READINESS_COMMAND}

  Build with the matching Zig line after the readiness check passes:
    ${MATCHED_BUILD_COMMAND}
EOF
else
    cat <<EOF

No matching Zig ${MINIMUM_MAJOR_MINOR}.x candidate is staged under ${TOOLCHAINS_ROOT}.

Working rules
=============
  - Do not treat the attached fallback Zig archive as honest issue #3 validation evidence when it stays on the wrong major.minor line.
  - Stage a Zig ${MINIMUM_MAJOR_MINOR}.x toolchain before reopening focused Page.zig or win32_backend.zig validation.
  - Keep using the saved-memory preflight and Linux build-readiness route so missing archives or offline deps do not get mistaken for source regressions.
EOF
    if [[ -n "${FALLBACK_PATH}" ]]; then
        echo
        echo "Observed fallback archive: ${FALLBACK_PATH} [${FALLBACK_VERSION:-unknown}; ${FALLBACK_STATUS:-unknown}]"
    fi
fi
