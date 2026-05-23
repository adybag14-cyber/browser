#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/linux/prepare_offline_build_inputs.sh \
    --browser-deps-archive /path/to/zig-browser-depo.tar.zip \
    --boringssl-archive /path/to/boringssl-zig-main.zip \
    [--html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip] \
    [--browser-root /path/to/browser-repo] \
    [--offline-deps-root /path/to/offline-deps] \
    [--check-only]

This helper restores the sibling dependency layout that build.zig.zon expects
for offline Linux validation:
  ../zig-v8-fork
  ../boringssl-zig
  ../offline-deps/{brotli,zlib,nghttp2,curl} by default

It also rewrites build.zig.zon from remote URL dependencies to local path
dependencies, optionally restores .cargo/config.toml plus vendor/ from the
saved html5ever dependency bundle, and when a prebuilt V8 archive is available
it rewrites ../zig-v8-fork/build.zig.zon to skip the unused depot_tools fetch
that would otherwise block offline validation.

Use --check-only to validate the supplied paths and print the derived restore
layout without mutating the repo or extracting any archives.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
BROWSER_DEPS_ARCHIVE=""
BORINGSSL_ARCHIVE=""
HTML5EVER_ARCHIVE=""
OFFLINE_DEPS_ROOT=""
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --browser-deps-archive)
            BROWSER_DEPS_ARCHIVE="$2"
            shift 2
            ;;
        --boringssl-archive)
            BORINGSSL_ARCHIVE="$2"
            shift 2
            ;;
        --html5ever-archive)
            HTML5EVER_ARCHIVE="$2"
            shift 2
            ;;
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=1
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

if [[ -z "${BROWSER_DEPS_ARCHIVE}" || -z "${BORINGSSL_ARCHIVE}" ]]; then
    echo "Both --browser-deps-archive and --boringssl-archive are required." >&2
    usage >&2
    exit 1
fi

for required_path in "${BROWSER_ROOT}" "${BROWSER_DEPS_ARCHIVE}" "${BORINGSSL_ARCHIVE}"; do
    if [[ ! -e "${required_path}" ]]; then
        echo "Required path does not exist: ${required_path}" >&2
        exit 1
    fi
done

if [[ -n "${HTML5EVER_ARCHIVE}" && ! -e "${HTML5EVER_ARCHIVE}" ]]; then
    echo "html5ever archive does not exist: ${HTML5EVER_ARCHIVE}" >&2
    exit 1
fi

if [[ ! -f "${BROWSER_ROOT}/build.zig.zon" ]]; then
    echo "Browser root does not contain build.zig.zon: ${BROWSER_ROOT}" >&2
    exit 1
fi

BROWSER_ROOT="$(cd "${BROWSER_ROOT}" && pwd)"
WORKSPACE_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ "${CHECK_ONLY}" -eq 0 ]]; then
    mkdir -p "${OFFLINE_DEPS_ROOT}"
fi
OFFLINE_DEPS_ROOT="$(python3 - "${OFFLINE_DEPS_ROOT}" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
OFFLINE_DEPS_RELATIVE_ROOT="$(python3 - "${OFFLINE_DEPS_ROOT}" "${BROWSER_ROOT}" <<'PY'
import os
import sys

print(os.path.relpath(sys.argv[1], sys.argv[2]))
PY
)"

find_zip_match() {
    local archive_path="$1"
    local match_pattern="$2"
    zipinfo -1 "${archive_path}" | grep -E "${match_pattern}" | head -n 1 || true
}

extract_nested_tarball() {
    local archive_path="$1"
    local match_pattern="$2"
    local destination_dir="$3"
    local strip_components="${4:-1}"

    local nested_path
    nested_path="$(find_zip_match "${archive_path}" "${match_pattern}")"
    if [[ -z "${nested_path}" ]]; then
        echo "Could not find ${match_pattern} inside ${archive_path}" >&2
        exit 1
    fi

    rm -rf "${destination_dir}"
    mkdir -p "${destination_dir}"
    unzip -p "${archive_path}" "${nested_path}" > "${TMP_DIR}/nested.tar.gz"
    tar -xzf "${TMP_DIR}/nested.tar.gz" -C "${destination_dir}" --strip-components="${strip_components}"
}

extract_nested_file() {
    local archive_path="$1"
    local match_pattern="$2"
    local output_path="$3"

    local nested_path
    nested_path="$(find_zip_match "${archive_path}" "${match_pattern}")"
    if [[ -z "${nested_path}" ]]; then
        echo "Could not find ${match_pattern} inside ${archive_path}" >&2
        exit 1
    fi

    unzip -p "${archive_path}" "${nested_path}" > "${output_path}"
}

ZIG_V8_ARCHIVE_PATH="$(find_zip_match "${BROWSER_DEPS_ARCHIVE}" '^zig-v8-fork-.*\.tar\.gz$')"
BROTLI_ARCHIVE_PATH="$(find_zip_match "${BROWSER_DEPS_ARCHIVE}" '^brotli-.*\.tar\.gz$')"
ZLIB_ARCHIVE_PATH="$(find_zip_match "${BROWSER_DEPS_ARCHIVE}" '^zlib-.*\.tar\.gz$')"
NGHTTP2_ARCHIVE_PATH="$(find_zip_match "${BROWSER_DEPS_ARCHIVE}" '^nghttp2-.*\.tar\.gz$')"
CURL_ARCHIVE_PATH="$(find_zip_match "${BROWSER_DEPS_ARCHIVE}" '^curl-.*\.tar\.gz$')"
PREBUILT_V8_ARCHIVE="$(find_zip_match "${BROWSER_DEPS_ARCHIVE}" 'libc_v8_.*\.a$')"

if [[ -z "${ZIG_V8_ARCHIVE_PATH}" || -z "${BROTLI_ARCHIVE_PATH}" || -z "${ZLIB_ARCHIVE_PATH}" || -z "${NGHTTP2_ARCHIVE_PATH}" || -z "${CURL_ARCHIVE_PATH}" ]]; then
    echo "Browser dependency archive is missing one or more expected offline inputs." >&2
    echo "Expected: zig-v8-fork tarball, brotli tarball, zlib tarball, nghttp2 tarball, and curl tarball." >&2
    exit 1
fi

if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    echo "Offline dependency surface check passed."
    echo "Browser root: ${BROWSER_ROOT}"
    echo "Workspace root: ${WORKSPACE_ROOT}"
    echo "Resolved restore targets:"
    echo "  zig-v8-fork -> ${WORKSPACE_ROOT}/zig-v8-fork"
    echo "  boringssl-zig -> ${WORKSPACE_ROOT}/boringssl-zig"
    echo "  offline deps -> ${OFFLINE_DEPS_ROOT}"
    echo "  build.zig.zon offline root -> ${OFFLINE_DEPS_RELATIVE_ROOT}"
    echo "Archive contents:"
    echo "  zig-v8-fork tarball -> ${ZIG_V8_ARCHIVE_PATH}"
    echo "  brotli tarball -> ${BROTLI_ARCHIVE_PATH}"
    echo "  zlib tarball -> ${ZLIB_ARCHIVE_PATH}"
    echo "  nghttp2 tarball -> ${NGHTTP2_ARCHIVE_PATH}"
    echo "  curl tarball -> ${CURL_ARCHIVE_PATH}"
    if [[ -n "${PREBUILT_V8_ARCHIVE}" ]]; then
        echo "  prebuilt V8 archive -> ${PREBUILT_V8_ARCHIVE}"
        echo "Suggested validation command:"
        printf "  zig build --summary all -Dprebuilt_v8_path='%s/%s'\n" "${OFFLINE_DEPS_ROOT}" "$(basename "${PREBUILT_V8_ARCHIVE}")"
    else
        echo "  prebuilt V8 archive -> not present"
    fi
    if [[ -n "${HTML5EVER_ARCHIVE}" ]]; then
        echo "  html5ever archive -> ${HTML5EVER_ARCHIVE}"
    else
        echo "  html5ever archive -> not supplied"
    fi
    exit 0
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "Restoring zig-v8-fork under ${WORKSPACE_ROOT}/zig-v8-fork"
extract_nested_tarball "${BROWSER_DEPS_ARCHIVE}" '^zig-v8-fork-.*\.tar\.gz$' "${WORKSPACE_ROOT}/zig-v8-fork"

echo "Restoring BoringSSL Zig sources under ${WORKSPACE_ROOT}/boringssl-zig"
rm -rf "${WORKSPACE_ROOT}/boringssl-zig"
mkdir -p "${WORKSPACE_ROOT}/boringssl-zig"
unzip -q "${BORINGSSL_ARCHIVE}" -d "${TMP_DIR}/boringssl"
BORINGSSL_ROOT="$(find "${TMP_DIR}/boringssl" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
cp -R "${BORINGSSL_ROOT}/." "${WORKSPACE_ROOT}/boringssl-zig/"

for dep_name in brotli zlib nghttp2 curl; do
    dep_dir="${OFFLINE_DEPS_ROOT}/${dep_name}"
    echo "Restoring ${dep_name} under ${dep_dir}"
    case "${dep_name}" in
        brotli)
            extract_nested_tarball "${BROWSER_DEPS_ARCHIVE}" '^brotli-.*\.tar\.gz$' "${dep_dir}"
            ;;
        zlib)
            extract_nested_tarball "${BROWSER_DEPS_ARCHIVE}" '^zlib-.*\.tar\.gz$' "${dep_dir}"
            ;;
        nghttp2)
            extract_nested_tarball "${BROWSER_DEPS_ARCHIVE}" '^nghttp2-.*\.tar\.gz$' "${dep_dir}"
            ;;
        curl)
            extract_nested_tarball "${BROWSER_DEPS_ARCHIVE}" '^curl-.*\.tar\.gz$' "${dep_dir}"
            ;;
    esac
done

if [[ -n "${PREBUILT_V8_ARCHIVE}" ]]; then
    PREBUILT_V8_PATH="${OFFLINE_DEPS_ROOT}/$(basename "${PREBUILT_V8_ARCHIVE}")"
    echo "Restoring prebuilt V8 archive under ${PREBUILT_V8_PATH}"
    extract_nested_file "${BROWSER_DEPS_ARCHIVE}" 'libc_v8_.*\.a$' "${PREBUILT_V8_PATH}"
else
    PREBUILT_V8_PATH=""
fi

ZIG_V8_BUILD_ZON_PATH="${WORKSPACE_ROOT}/zig-v8-fork/build.zig.zon"
if [[ -n "${PREBUILT_V8_PATH}" ]]; then
    echo "Disabling zig-v8-fork depot_tools fetch because a prebuilt V8 archive is available"
    ZIG_V8_BUILD_ZON_BACKUP="${ZIG_V8_BUILD_ZON_PATH}.remote-sources.bak"
    LEGACY_ZIG_V8_BUILD_ZON_BACKUP="${ZIG_V8_BUILD_ZON_PATH}.before-offline"
    if [[ ! -f "${ZIG_V8_BUILD_ZON_BACKUP}" && ! -f "${LEGACY_ZIG_V8_BUILD_ZON_BACKUP}" ]]; then
        cp "${ZIG_V8_BUILD_ZON_PATH}" "${ZIG_V8_BUILD_ZON_BACKUP}"
    fi

    python3 - "${ZIG_V8_BUILD_ZON_PATH}" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
old = '''    .dependencies = .{
        .depot_tools = .{
            .url = "git+https://github.com/rust-skia/depot_tools#8efa575d754b8703d99b0f827528e45aeaa167aa",
            .hash = "N-V-__8AANgeXQAuTDjDItrtITfVslPonFWB-h3Az2C0-2AM",
        },
    },'''
new = '''    .dependencies = .{},'''
if old in text:
    path.write_text(text.replace(old, new))
    print("rewrote zig-v8-fork/build.zig.zon for offline prebuilt-V8 use")
elif new in text:
    print("zig-v8-fork/build.zig.zon already points at offline-safe dependencies")
else:
    raise SystemExit(f"Expected depot_tools dependency stanza was not found in {path}")
PY
fi

if [[ -n "${HTML5EVER_ARCHIVE}" ]]; then
    echo "Restoring vendored html5ever cargo inputs into ${BROWSER_ROOT}"
    rm -rf "${BROWSER_ROOT}/vendor" "${BROWSER_ROOT}/.cargo"
    mkdir -p "${BROWSER_ROOT}/.cargo"

    HTML5EVER_CONFIG="$(zipinfo -1 "${HTML5EVER_ARCHIVE}" | grep -E '/\.cargo/config\.toml$' | head -n 1 || true)"
    if [[ -z "${HTML5EVER_CONFIG}" ]]; then
        echo "Could not find .cargo/config.toml inside ${HTML5EVER_ARCHIVE}" >&2
        exit 1
    fi
    unzip -p "${HTML5EVER_ARCHIVE}" "${HTML5EVER_CONFIG}" > "${BROWSER_ROOT}/.cargo/config.toml"

    HTML5EVER_PREFIX="${HTML5EVER_CONFIG%/.cargo/config.toml}/"
    unzip -q "${HTML5EVER_ARCHIVE}" "${HTML5EVER_PREFIX}vendor/*" -d "${TMP_DIR}/html5ever"
    if [[ ! -d "${TMP_DIR}/html5ever/${HTML5EVER_PREFIX}vendor" ]]; then
        echo "Could not extract vendor/ from ${HTML5EVER_ARCHIVE}" >&2
        exit 1
    fi
    cp -R "${TMP_DIR}/html5ever/${HTML5EVER_PREFIX}vendor" "${BROWSER_ROOT}/vendor"
fi

BUILD_ZON_PATH="${BROWSER_ROOT}/build.zig.zon"
BUILD_ZON_BACKUP="${BROWSER_ROOT}/build.zig.zon.remote-sources.bak"
LEGACY_BUILD_ZON_BACKUP="${BROWSER_ROOT}/build.zig.zon.before-offline"
if [[ ! -f "${BUILD_ZON_BACKUP}" && ! -f "${LEGACY_BUILD_ZON_BACKUP}" ]]; then
    cp "${BUILD_ZON_PATH}" "${BUILD_ZON_BACKUP}"
fi

python3 - "${BUILD_ZON_PATH}" "${OFFLINE_DEPS_RELATIVE_ROOT}" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
offline_deps_relative_root = sys.argv[2]
text = path.read_text()
replacement_paths = {
    "brotli": f"{offline_deps_relative_root}/brotli",
    "zlib": f"{offline_deps_relative_root}/zlib",
    "nghttp2": f"{offline_deps_relative_root}/nghttp2",
    "curl": f"{offline_deps_relative_root}/curl",
}

updated = text
for name, local_path in replacement_paths.items():
    pattern = re.compile(
        rf'(?ms)^(?P<indent>\s*)\.{re.escape(name)}\s*=\s*\.\{{\n.*?^\1\}},'
    )
    local_pattern = re.compile(
        rf'(?ms)^\s*\.{re.escape(name)}\s*=\s*\.\{{\n\s*\.path = "{re.escape(local_path)}",\n\s*\}},'
    )

    def replace_block(match: re.Match[str]) -> str:
        indent = match.group("indent")
        return (
            f"{indent}.{name} = .{{\n"
            f'{indent}    .path = "{local_path}",\n'
            f"{indent}}},"
        )

    candidate, count = pattern.subn(replace_block, updated, count=1)
    if count == 0:
        if local_pattern.search(updated):
            continue
        raise SystemExit(f"Expected dependency stanza for {name} was not found in {path}")
    updated = candidate

if updated != text:
    path.write_text(updated)
    print("rewrote build.zig.zon to local offline dependency paths")
else:
    print("build.zig.zon already points at local paths")
PY

echo
echo "Offline dependency layout is ready."
echo "Sibling workspace root: ${WORKSPACE_ROOT}"
echo "Resolved offline deps root: ${OFFLINE_DEPS_ROOT}"
echo "Updated build manifest: ${BUILD_ZON_PATH}"
if [[ -n "${PREBUILT_V8_PATH}" ]]; then
    echo "Suggested validation command:"
    printf "  zig build --summary all -Dprebuilt_v8_path='%s'\n" "${PREBUILT_V8_PATH}"
fi