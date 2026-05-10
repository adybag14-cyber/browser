#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/linux/restore_offline_build_inputs.sh [repo_root] [dependencies_root]

Restore the saved offline Linux build inputs into the layout expected by the
headed-mode browser fork.

Arguments:
  repo_root           Browser repo root. Defaults to the parent of this script.
  dependencies_root   Directory containing the saved dependency archives.
                      Defaults to /workspace/memory/repo_archives/browser/dependencies.

This script:
  - extracts ../zig-v8-fork from 04-zig-browser-depo.tar.zip
  - extracts ../boringssl-zig from 03-boringssl-zig-main.zip
  - extracts brotli/zlib/nghttp2/curl and the saved prebuilt V8 archive into ../offline-deps
  - copies .cargo/config.toml and vendor/ from the saved html5ever archive
  - rewrites build.zig.zon to use local .path dependencies with a backup
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${1:-$(cd "${script_dir}/../.." && pwd)}"
dependencies_root="${2:-/workspace/memory/repo_archives/browser/dependencies}"

depo_zip="${dependencies_root}/04-zig-browser-depo.tar.zip"
boringssl_zip="${dependencies_root}/03-boringssl-zig-main.zip"
html5ever_zip="${dependencies_root}/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"

for required in "${depo_zip}" "${boringssl_zip}" "${html5ever_zip}" "${repo_root}/build.zig.zon"; do
    if [[ ! -e "${required}" ]]; then
        echo "missing required input: ${required}" >&2
        exit 1
    fi
done

parent_dir="$(cd "${repo_root}/.." && pwd)"
offline_deps_dir="${parent_dir}/offline-deps"
zig_v8_dir="${parent_dir}/zig-v8-fork"
boringssl_dir="${parent_dir}/boringssl-zig"
vendor_extract_root="${offline_deps_dir}/html5ever-vendor"
build_zon_path="${repo_root}/build.zig.zon"
build_zon_backup="${repo_root}/build.zig.zon.remote-sources.bak"
zig_v8_build_zon_path="${zig_v8_dir}/build.zig.zon"
zig_v8_build_zon_backup="${zig_v8_dir}/build.zig.zon.remote-sources.bak"
prebuilt_v8_output="${offline_deps_dir}/libc_v8_14.0.365.4_linux_x86_64 (1).a"

mkdir -p "${offline_deps_dir}" "${vendor_extract_root}" "${repo_root}/.cargo"

extract_tree_from_tarball_member() {
    local archive_path="$1"
    local member_path="$2"
    local destination_dir="$3"
    local marker_path="$4"
    if [[ -e "${marker_path}" ]]; then
        return
    fi

    local temp_dir temp_tarball extracted_root
    temp_dir="$(mktemp -d)"
    temp_tarball="$(mktemp)"
    unzip -p "${archive_path}" "${member_path}" > "${temp_tarball}"
    tar -xzf "${temp_tarball}" -C "${temp_dir}"
    extracted_root="$(find "${temp_dir}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    if [[ -z "${extracted_root}" ]]; then
        echo "failed to locate extracted directory for ${member_path}" >&2
        rm -f "${temp_tarball}"
        rm -rf "${temp_dir}"
        exit 1
    fi
    rm -rf "${destination_dir}"
    mv "${extracted_root}" "${destination_dir}"
    rm -f "${temp_tarball}"
    rm -rf "${temp_dir}"
}

extract_tree_from_zip() {
    local archive_path="$1"
    local destination_dir="$2"
    local marker_path="$3"
    if [[ -e "${marker_path}" ]]; then
        return
    fi

    local temp_dir extracted_root
    temp_dir="$(mktemp -d)"
    unzip -q "${archive_path}" -d "${temp_dir}"
    extracted_root="$(find "${temp_dir}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    if [[ -z "${extracted_root}" ]]; then
        echo "failed to locate extracted directory for ${archive_path}" >&2
        rm -rf "${temp_dir}"
        exit 1
    fi
    rm -rf "${destination_dir}"
    mv "${extracted_root}" "${destination_dir}"
    rm -rf "${temp_dir}"
}

extract_tarball_member_into_dir() {
    local archive_path="$1"
    local member_path="$2"
    local output_dir="$3"
    local marker_path="$4"
    if [[ -e "${marker_path}" ]]; then
        return
    fi

    local temp_tarball
    temp_tarball="$(mktemp)"
    unzip -p "${archive_path}" "${member_path}" > "${temp_tarball}"
    tar -xzf "${temp_tarball}" -C "${output_dir}"
    rm -f "${temp_tarball}"
}

echo "Restoring sibling dependency trees..."
extract_tree_from_tarball_member "${depo_zip}" "zig-v8-fork-0.3.1.tar.gz" "${zig_v8_dir}" "${zig_v8_dir}/build.zig"
extract_tree_from_zip "${boringssl_zip}" "${boringssl_dir}" "${boringssl_dir}/build.zig"

echo "Restoring offline tarball dependencies..."
extract_tarball_member_into_dir "${depo_zip}" "brotli-028fb5a23661f123017c060daa546b55cf4bde29.tar.gz" "${offline_deps_dir}" "${offline_deps_dir}/brotli-028fb5a23661f123017c060daa546b55cf4bde29"
extract_tarball_member_into_dir "${depo_zip}" "zlib-1.3.2.tar.gz" "${offline_deps_dir}" "${offline_deps_dir}/zlib-1.3.2"
extract_tarball_member_into_dir "${depo_zip}" "nghttp2-1.68.0.tar.gz" "${offline_deps_dir}" "${offline_deps_dir}/nghttp2-1.68.0"
extract_tarball_member_into_dir "${depo_zip}" "curl-8.18.0.tar.gz" "${offline_deps_dir}" "${offline_deps_dir}/curl-8.18.0"
if [[ ! -e "${prebuilt_v8_output}" ]]; then
    unzip -p "${depo_zip}" "libc_v8_14.0.365.4_linux_x86_64 (1).a" > "${prebuilt_v8_output}"
fi

echo "Restoring vendored html5ever Cargo inputs..."
rm -rf "${vendor_extract_root}"
mkdir -p "${vendor_extract_root}"
unzip -q "${html5ever_zip}" -d "${vendor_extract_root}"
vendor_root="$(find "${vendor_extract_root}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "${vendor_root}" ]]; then
    echo "failed to locate extracted html5ever vendor root" >&2
    exit 1
fi
rm -rf "${repo_root}/vendor" "${repo_root}/.cargo"
mkdir -p "${repo_root}/.cargo"
cp -R "${vendor_root}/vendor" "${repo_root}/vendor"
cp "${vendor_root}/.cargo/config.toml" "${repo_root}/.cargo/config.toml"

if [[ ! -e "${build_zon_backup}" ]]; then
    cp "${build_zon_path}" "${build_zon_backup}"
fi

python3 - "${build_zon_path}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
replacements = {
    '.url = "https://github.com/google/brotli/archive/028fb5a23661f123017c060daa546b55cf4bde29.tar.gz",\n            .hash = "N-V-__8AAJudKgCQCuIiH6MJjAiIJHfg_tT_Ew-0vZwVkCo_",':
    '.path = "../offline-deps/brotli-028fb5a23661f123017c060daa546b55cf4bde29",',
    '.url = "https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz",\n            .hash = "N-V-__8AAJ2cNgAgfBtAw33Bxfu1IWISDeKKSr3DAqoAysIJ",':
    '.path = "../offline-deps/zlib-1.3.2",',
    '.url = "https://github.com/nghttp2/nghttp2/releases/download/v1.68.0/nghttp2-1.68.0.tar.gz",\n            .hash = "N-V-__8AAL15vQCI63ZL6Zaz5hJg6JTEgYXGbLnMFSnf7FT3",':
    '.path = "../offline-deps/nghttp2-1.68.0",',
    '.url = "https://github.com/curl/curl/releases/download/curl-8_18_0/curl-8.18.0.tar.gz",\n            .hash = "N-V-__8AALp9QAGn6CCHZ6fK_FfMyGtG824LSHYHHasM3w-y",':
    '.path = "../offline-deps/curl-8.18.0",',
}

updated = text
for old, new in replacements.items():
    updated = updated.replace(old, new)

if updated != text:
    path.write_text(updated)
    print("rewrote build.zig.zon to local offline dependency paths")
else:
    print("build.zig.zon already points at local paths or did not match expected remote layout")
PY

if [[ -f "${zig_v8_build_zon_path}" && ! -e "${zig_v8_build_zon_backup}" ]]; then
    cp "${zig_v8_build_zon_path}" "${zig_v8_build_zon_backup}"
fi

python3 - "${zig_v8_build_zon_path}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = '''    .dependencies = .{
        .depot_tools = .{
            .url = "git+https://github.com/rust-skia/depot_tools#8efa575d754b8703d99b0f827528e45aeaa167aa",
            .hash = "N-V-__8AANgeXQAuTDjDItrtITfVslPonFWB-h3Az2C0-2AM",
        },
    },
'''
new = '''    .dependencies = .{},
'''

updated = text.replace(old, new)
if updated != text:
    path.write_text(updated)
    print("rewrote zig-v8-fork/build.zig.zon for offline prebuilt-V8 use")
else:
    print("zig-v8-fork/build.zig.zon already points at offline-safe dependencies")
PY

echo
echo "Offline restore complete."
echo "Repo root: ${repo_root}"
echo "Sibling V8 path: ${zig_v8_dir}"
echo "Sibling BoringSSL path: ${boringssl_dir}"
echo "Offline deps path: ${offline_deps_dir}"
echo "Prebuilt V8 archive: ${prebuilt_v8_output}"
echo "Next step:"
echo "  zig build -Dprebuilt_v8_path='../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a' --summary all"