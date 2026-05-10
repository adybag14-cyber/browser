#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/linux/prepare_offline_build_inputs.sh \
    --browser-deps-archive /path/to/zig-browser-depo.tar.zip \
    --boringssl-archive /path/to/boringssl-zig-main.zip \
    [--html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip] \
    [--browser-root /path/to/browser-repo]

This helper restores the sibling dependency layout that build.zig.zon expects
for offline Linux validation:
  ../zig-v8-fork
  ../boringssl-zig
  ../offline-deps/{brotli,zlib,nghttp2,curl}

It also rewrites build.zig.zon from remote URL dependencies to local path
dependencies and optionally restores .cargo/config.toml plus vendor/ from the
saved html5ever dependency bundle.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
BROWSER_DEPS_ARCHIVE=""
BORINGSSL_ARCHIVE=""
HTML5EVER_ARCHIVE=""

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

WORKSPACE_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${OFFLINE_DEPS_ROOT}"

extract_nested_tarball() {
    local archive_path="$1"
    local match_pattern="$2"
    local destination_dir="$3"
    local strip_components="${4:-1}"

    local nested_path
    nested_path="$(zipinfo -1 "${archive_path}" | grep -E "${match_pattern}" | head -n 1 || true)"
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
    nested_path="$(zipinfo -1 "${archive_path}" | grep -E "${match_pattern}" | head -n 1 || true)"
    if [[ -z "${nested_path}" ]]; then
        echo "Could not find ${match_pattern} inside ${archive_path}" >&2
        exit 1
    fi

    unzip -p "${archive_path}" "${nested_path}" > "${output_path}"
}

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

PREBUILT_V8_ARCHIVE="$(zipinfo -1 "${BROWSER_DEPS_ARCHIVE}" | grep -E 'libc_v8_.*\.a$' | head -n 1 || true)"
if [[ -n "${PREBUILT_V8_ARCHIVE}" ]]; then
    PREBUILT_V8_PATH="${OFFLINE_DEPS_ROOT}/$(basename "${PREBUILT_V8_ARCHIVE}")"
    echo "Restoring prebuilt V8 archive under ${PREBUILT_V8_PATH}"
    extract_nested_file "${BROWSER_DEPS_ARCHIVE}" 'libc_v8_.*\.a$' "${PREBUILT_V8_PATH}"
else
    PREBUILT_V8_PATH=""
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
BUILD_ZON_BACKUP="${BROWSER_ROOT}/build.zig.zon.before-offline"
if [[ ! -f "${BUILD_ZON_BACKUP}" ]]; then
    cp "${BUILD_ZON_PATH}" "${BUILD_ZON_BACKUP}"
fi

python3 - "${BUILD_ZON_PATH}" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
replacements = {
    '.brotli = .{\n            // v1.2.0\n            .url = "https://github.com/google/brotli/archive/028fb5a23661f123017c060daa546b55cf4bde29.tar.gz",\n            .hash = "N-V-__8AAJudKgCQCuIiH6MJjAiIJHfg_tT_Ew-0vZwVkCo_",\n        },': '.brotli = .{\n            .path = "../offline-deps/brotli",\n        },',
    '.zlib = .{\n            .url = "https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz",\n            .hash = "N-V-__8AAJ2cNgAgfBtAw33Bxfu1IWISDeKKSr3DAqoAysIJ",\n        },': '.zlib = .{\n            .path = "../offline-deps/zlib",\n        },',
    '.nghttp2 = .{\n            .url = "https://github.com/nghttp2/nghttp2/releases/download/v1.68.0/nghttp2-1.68.0.tar.gz",\n            .hash = "N-V-__8AAL15vQCI63ZL6Zaz5hJg6JTEgYXGbLnMFSnf7FT3",\n        },': '.nghttp2 = .{\n            .path = "../offline-deps/nghttp2",\n        },',
    '.curl = .{\n            .url = "https://github.com/curl/curl/releases/download/curl-8_18_0/curl-8.18.0.tar.gz",\n            .hash = "N-V-__8AALp9QAGn6CCHZ6fK_FfMyGtG824LSHYHHasM3w-y",\n        },': '.curl = .{\n            .path = "../offline-deps/curl",\n        },',
}

updated = text
for old, new in replacements.items():
    if old not in updated:
        raise SystemExit(f"Expected dependency stanza was not found in {path}")
    updated = updated.replace(old, new)

path.write_text(updated)
PY

echo
echo "Offline dependency layout is ready."
echo "Sibling workspace root: ${WORKSPACE_ROOT}"
echo "Updated build manifest: ${BUILD_ZON_PATH}"
if [[ -n "${PREBUILT_V8_PATH}" ]]; then
    echo "Suggested validation command:"
    printf "  zig build --summary all -Dprebuilt_v8_path='%s'\n" "${PREBUILT_V8_PATH}"
fi
