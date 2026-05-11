#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/linux/show_offline_build_validation_flow.sh \
    [--repo-root /path/to/browser-repo] \
    [--dependencies-root /path/to/dependencies] \
    [--zig-binary /path/to/zig] \
    [--cargo-binary /path/to/cargo] \
    [--rustc-binary /path/to/rustc] \
    [--prebuilt-v8-path /path/to/libc_v8_*.a] \
    [--json]

Print the recommended Linux offline-build restore and validation order for the
headed browser fork.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
DEPENDENCIES_ROOT="/workspace/memory/repo_archives/browser/dependencies"
ZIG_BINARY=""
CARGO_BINARY=""
RUSTC_BINARY=""
PREBUILT_V8_PATH=""
JSON=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --dependencies-root)
            DEPENDENCIES_ROOT="$2"
            shift 2
            ;;
        --zig-binary)
            ZIG_BINARY="$2"
            shift 2
            ;;
        --cargo-binary)
            CARGO_BINARY="$2"
            shift 2
            ;;
        --rustc-binary)
            RUSTC_BINARY="$2"
            shift 2
            ;;
        --prebuilt-v8-path)
            PREBUILT_V8_PATH="$2"
            shift 2
            ;;
        --json)
            JSON=true
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

MINIMUM_ZIG_VERSION=""
if [[ -f "${REPO_ROOT}/build.zig.zon" ]]; then
    MINIMUM_ZIG_VERSION="$(python3 - "${REPO_ROOT}/build.zig.zon" <<'PY'
from pathlib import Path
import re
import sys
text = Path(sys.argv[1]).read_text()
match = re.search(r'\.minimum_zig_version\s*=\s*"([^"]+)"', text)
print(match.group(1) if match else "")
PY
)"
fi

if [[ -z "${PREBUILT_V8_PATH}" ]]; then
    PREBUILT_V8_PATH="${REPO_ROOT}/../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a"
fi

build_command="zig build --summary all -Dprebuilt_v8_path=$(printf '%q' "${PREBUILT_V8_PATH}")"
if [[ -n "${ZIG_BINARY}" ]]; then
    build_command="$(printf '%q' "${ZIG_BINARY}") build --summary all -Dprebuilt_v8_path=$(printf '%q' "${PREBUILT_V8_PATH}")"
fi

preflight_command="scripts/linux/check_offline_build_prereqs.sh --browser-root $(printf '%q' "${REPO_ROOT}")"
if [[ -n "${ZIG_BINARY}" ]]; then
    preflight_command+=" --zig-binary $(printf '%q' "${ZIG_BINARY}")"
fi
if [[ -n "${CARGO_BINARY}" ]]; then
    preflight_command+=" --cargo-binary $(printf '%q' "${CARGO_BINARY}")"
fi
if [[ -n "${RUSTC_BINARY}" ]]; then
    preflight_command+=" --rustc-binary $(printf '%q' "${RUSTC_BINARY}")"
fi
if [[ -n "${PREBUILT_V8_PATH}" ]]; then
    preflight_command+=" --prebuilt-v8-path $(printf '%q' "${PREBUILT_V8_PATH}")"
fi

if [[ "${JSON}" == "true" ]]; then
    export FLOW_REPO_ROOT="${REPO_ROOT}"
    export FLOW_DEPENDENCIES_ROOT="${DEPENDENCIES_ROOT}"
    export FLOW_MINIMUM_ZIG_VERSION="${MINIMUM_ZIG_VERSION}"
    export FLOW_PREBUILT_V8_PATH="${PREBUILT_V8_PATH}"
    export FLOW_ZIG_BINARY="${ZIG_BINARY}"
    export FLOW_CARGO_BINARY="${CARGO_BINARY}"
    export FLOW_RUSTC_BINARY="${RUSTC_BINARY}"
    export FLOW_PREFLIGHT_COMMAND="${preflight_command}"
    export FLOW_BUILD_COMMAND="${build_command}"
    python3 - <<'PY'
import json
import os

result = {
    "repo_root": os.environ["FLOW_REPO_ROOT"],
    "dependencies_root": os.environ["FLOW_DEPENDENCIES_ROOT"],
    "minimum_zig_version": os.environ["FLOW_MINIMUM_ZIG_VERSION"],
    "steps": [
        {
            "name": "restore-default-memory-archives",
            "goal": "Restore the saved browser dependency archives into the sibling offline layout when the standard Memory path is available.",
            "command": "scripts/linux/restore_offline_build_inputs.sh "
            + json.dumps(os.environ["FLOW_REPO_ROOT"])
            + " "
            + json.dumps(os.environ["FLOW_DEPENDENCIES_ROOT"]),
        },
        {
            "name": "restore-custom-archives",
            "goal": "Use the explicit-archive helper instead when the offline bundles are stored outside the standard Memory path.",
            "command": "scripts/linux/prepare_offline_build_inputs.sh"
            + " --browser-root " + json.dumps(os.environ["FLOW_REPO_ROOT"])
            + " --browser-deps-archive " + json.dumps(os.environ["FLOW_DEPENDENCIES_ROOT"] + "/04-zig-browser-depo.tar.zip")
            + " --boringssl-archive " + json.dumps(os.environ["FLOW_DEPENDENCIES_ROOT"] + "/03-boringssl-zig-main.zip")
            + " --html5ever-archive " + json.dumps(os.environ["FLOW_DEPENDENCIES_ROOT"] + "/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"),
        },
        {
            "name": "preflight",
            "goal": "Check the restored manifest, sibling dependency layout, Rust toolchain, and exact Zig version before running zig build.",
            "command": os.environ["FLOW_PREFLIGHT_COMMAND"],
        },
        {
            "name": "build",
            "goal": "Run the real offline Linux build with the same prebuilt V8 archive that passed preflight.",
            "command": os.environ["FLOW_BUILD_COMMAND"],
        },
    ],
    "notes": [
        "Treat a failing preflight as a setup or toolchain problem before treating it as a browser code regression.",
        "The offline restore rewrites build.zig.zon to local .path dependencies and keeps a manifest backup so future runs can verify the checkout state quickly.",
        "The current branch expects the active Zig version to match build.zig.zon exactly before Linux compile results are considered trustworthy.",
    ],
}
print(json.dumps(result, indent=2))
PY
    exit 0
fi

echo "Linux offline build validation flow"
echo
echo "Repo root: ${REPO_ROOT}"
echo "Dependencies root: ${DEPENDENCIES_ROOT}"
if [[ -n "${MINIMUM_ZIG_VERSION}" ]]; then
    echo "Expected Zig version: ${MINIMUM_ZIG_VERSION}"
fi
echo
echo "[1] Restore the saved standard dependency bundle into the offline layout"
printf '  scripts/linux/restore_offline_build_inputs.sh %q %q\n' "${REPO_ROOT}" "${DEPENDENCIES_ROOT}"
echo
echo "[2] Use the explicit-archive helper instead when the bundles are stored elsewhere"
printf '  scripts/linux/prepare_offline_build_inputs.sh --browser-root %q --browser-deps-archive %q --boringssl-archive %q --html5ever-archive %q\n' \
    "${REPO_ROOT}" \
    "${DEPENDENCIES_ROOT}/04-zig-browser-depo.tar.zip" \
    "${DEPENDENCIES_ROOT}/03-boringssl-zig-main.zip" \
    "${DEPENDENCIES_ROOT}/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
echo
echo "[3] Run the offline preflight before zig build"
printf '  scripts/linux/check_offline_build_prereqs.sh --browser-root %q' "${REPO_ROOT}"
if [[ -n "${ZIG_BINARY}" ]]; then
    printf ' --zig-binary %q' "${ZIG_BINARY}"
fi
if [[ -n "${CARGO_BINARY}" ]]; then
    printf ' --cargo-binary %q' "${CARGO_BINARY}"
fi
if [[ -n "${RUSTC_BINARY}" ]]; then
    printf ' --rustc-binary %q' "${RUSTC_BINARY}"
fi
if [[ -n "${PREBUILT_V8_PATH}" ]]; then
    printf ' --prebuilt-v8-path %q' "${PREBUILT_V8_PATH}"
fi
printf '\n'
echo
echo "[4] Run the real offline build with the same prebuilt V8 archive"
if [[ -n "${ZIG_BINARY}" ]]; then
    printf '  %q build --summary all -Dprebuilt_v8_path=%q\n' "${ZIG_BINARY}" "${PREBUILT_V8_PATH}"
else
    printf '  zig build --summary all -Dprebuilt_v8_path=%q\n' "${PREBUILT_V8_PATH}"
fi
echo
echo "Notes:"
echo "- Treat a failing preflight as a setup or toolchain problem before treating it as a browser code regression."
echo "- The offline restore rewrites build.zig.zon to local .path dependencies and keeps a manifest backup for quick re-checks."
if [[ -n "${MINIMUM_ZIG_VERSION}" ]]; then
    echo "- The current branch expects the active Zig version to match ${MINIMUM_ZIG_VERSION} before Linux compile results are considered trustworthy."
fi
