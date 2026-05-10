#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/linux/check_offline_build_prereqs.sh \
    [--browser-root /path/to/browser-repo] \
    [--zig-binary /path/to/zig] \
    [--prebuilt-v8-path /path/to/libc_v8_*.a]

This helper confirms that an offline Linux browser checkout is ready for a real
build attempt before `zig build` runs. It checks the active Zig version against
`build.zig.zon`, verifies the restored sibling dependency layout, accepts the
current offline manifest backup names, and prints the suggested validation
command. Use `--zig-binary` or `ZIG=/path/to/zig` when the compatible toolchain
is installed outside PATH.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
ZIG_BINARY="${ZIG:-}"
PREBUILT_V8_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --zig-binary)
            ZIG_BINARY="$2"
            shift 2
            ;;
        --prebuilt-v8-path)
            PREBUILT_V8_PATH="$2"
            shift 2
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

all_ok=true

write_status() {
    local name="$1"
    local ok="$2"
    local details="$3"
    local mark="FAIL"
    if [[ "${ok}" == "true" ]]; then
        mark="PASS"
    else
        all_ok=false
    fi
    printf '[%s] %s - %s\n' "${mark}" "${name}" "${details}"
}

if [[ ! -f "${BROWSER_ROOT}/build.zig.zon" ]]; then
    write_status "BrowserRoot" false "build.zig.zon not found under ${BROWSER_ROOT}"
    echo
    echo "Offline build prerequisites are not ready yet."
    exit 1
fi
write_status "BrowserRoot" true "${BROWSER_ROOT}"

BUILD_ZON_PATH="${BROWSER_ROOT}/build.zig.zon"
WORKSPACE_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
BUILD_ZON_BACKUP=""
for candidate in \
    "${BROWSER_ROOT}/build.zig.zon.remote-sources.bak" \
    "${BROWSER_ROOT}/build.zig.zon.before-offline"
do
    if [[ -f "${candidate}" ]]; then
        BUILD_ZON_BACKUP="${candidate}"
        break
    fi
done

MINIMUM_ZIG_VERSION="$(python3 - "${BUILD_ZON_PATH}" <<'PY'
import pathlib
import re
import sys
text = pathlib.Path(sys.argv[1]).read_text()
match = re.search(r'\.minimum_zig_version\s*=\s*"([^"]+)"', text)
if not match:
    raise SystemExit('missing minimum_zig_version')
print(match.group(1))
PY
)"

zig_version=""
zig_cmd=""
if [[ -n "${ZIG_BINARY}" ]]; then
    if [[ -x "${ZIG_BINARY}" ]]; then
        zig_cmd="${ZIG_BINARY}"
    else
        write_status "Zig" false "configured zig binary is not executable: ${ZIG_BINARY}"
    fi
elif command -v zig >/dev/null 2>&1; then
    zig_cmd="$(command -v zig)"
else
    write_status "Zig" false "zig not found in PATH"
fi

if [[ -n "${zig_cmd}" ]]; then
    zig_version="$(${zig_cmd} version | tr -d '\r')"
    write_status "Zig" true "${zig_cmd} (${zig_version})"
fi

if [[ -n "${zig_version}" ]]; then
    if [[ "${zig_version}" == "${MINIMUM_ZIG_VERSION}" ]]; then
        write_status "ZigVersion" true "matches build.zig.zon minimum ${MINIMUM_ZIG_VERSION}"
    else
        write_status "ZigVersion" false "expected ${MINIMUM_ZIG_VERSION}, found ${zig_version}"
    fi
fi

if [[ -n "${BUILD_ZON_BACKUP}" ]]; then
    write_status "ManifestBackup" true "${BUILD_ZON_BACKUP}"
else
    write_status "ManifestBackup" false "missing build.zig.zon.remote-sources.bak or build.zig.zon.before-offline"
fi

DEP_PATH_ROWS="$(python3 - "${BUILD_ZON_PATH}" <<'PY'
import pathlib
import re
import sys
text = pathlib.Path(sys.argv[1]).read_text()
for dep in ("brotli", "zlib", "nghttp2", "curl"):
    match = re.search(rf'\.{re.escape(dep)}\s*=\s*\.\{{.*?\.path\s*=\s*"([^"]+)"', text, re.S)
    print(f"{dep}\t{match.group(1) if match else ''}")
PY
)"

manifest_paths_ok=true
while IFS=$'\t' read -r dep relpath; do
    if [[ -z "${dep}" ]]; then
        continue
    fi

    if [[ -z "${relpath}" ]]; then
        write_status "manifest:${dep}" false "missing .path entry for ${dep} in build.zig.zon"
        manifest_paths_ok=false
        continue
    fi

    if [[ "${relpath}" != ../offline-deps/* ]]; then
        write_status "manifest:${dep}" false "expected ${dep} to resolve under ../offline-deps, found ${relpath}"
        manifest_paths_ok=false
        continue
    fi

    dep_path="$(python3 - "${BROWSER_ROOT}" "${relpath}" <<'PY'
from pathlib import Path
import sys
browser_root = Path(sys.argv[1])
relpath = sys.argv[2]
print((browser_root / relpath).resolve())
PY
)"
    if [[ -d "${dep_path}" ]]; then
        write_status "offline:${dep}" true "${dep_path}"
    else
        write_status "offline:${dep}" false "missing ${dep_path}"
        manifest_paths_ok=false
    fi
done <<< "${DEP_PATH_ROWS}"

if [[ "${manifest_paths_ok}" == "true" ]]; then
    write_status "ManifestPaths" true "build.zig.zon points brotli/zlib/nghttp2/curl at local ../offline-deps paths"
else
    write_status "ManifestPaths" false "build.zig.zon and the extracted offline dependency directories are not aligned yet"
fi

for sibling in zig-v8-fork boringssl-zig; do
    sibling_path="${WORKSPACE_ROOT}/${sibling}"
    if [[ -d "${sibling_path}" ]]; then
        write_status "${sibling}" true "${sibling_path}"
    else
        write_status "${sibling}" false "missing ${sibling_path}"
    fi
done

if [[ -f "${BROWSER_ROOT}/.cargo/config.toml" ]]; then
    write_status "cargo-config" true "${BROWSER_ROOT}/.cargo/config.toml"
else
    write_status "cargo-config" false "missing ${BROWSER_ROOT}/.cargo/config.toml"
fi

if [[ -d "${BROWSER_ROOT}/vendor" ]]; then
    write_status "vendor" true "${BROWSER_ROOT}/vendor"
else
    write_status "vendor" false "missing ${BROWSER_ROOT}/vendor"
fi

if [[ -z "${PREBUILT_V8_PATH}" ]]; then
    PREBUILT_V8_PATH="$(find "${OFFLINE_DEPS_ROOT}" -maxdepth 1 -type f -name 'libc_v8_*.a' | head -n 1 || true)"
fi

if [[ -n "${PREBUILT_V8_PATH}" && -f "${PREBUILT_V8_PATH}" ]]; then
    write_status "prebuilt-v8" true "${PREBUILT_V8_PATH}"
else
    write_status "prebuilt-v8" false "missing libc_v8_*.a archive (pass --prebuilt-v8-path if stored elsewhere)"
fi

if [[ "${all_ok}" == "true" ]]; then
    echo
    echo "Offline build prerequisites look good."
    if [[ -n "${zig_cmd}" ]]; then
        printf "Suggested validation command:\n  %s build --summary all -Dprebuilt_v8_path='%s'\n" "${zig_cmd}" "${PREBUILT_V8_PATH}"
    else
        printf "Suggested validation command:\n  zig build --summary all -Dprebuilt_v8_path='%s'\n" "${PREBUILT_V8_PATH}"
    fi
    exit 0
fi

echo
echo "Offline build prerequisites are not ready yet."
echo "Run scripts/linux/restore_offline_build_inputs.sh (or scripts/linux/prepare_offline_build_inputs.sh for custom archive locations) and switch to Zig ${MINIMUM_ZIG_VERSION} before retrying zig build. Use --zig-binary /path/to/zig or ZIG=/path/to/zig when the compatible toolchain is installed outside PATH."
exit 1
