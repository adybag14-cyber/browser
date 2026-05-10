#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  restore_offline_build_deps.sh \
    --deps-archive /path/to/04-zig-browser-depo.tar.zip \
    --boringssl-archive /path/to/03-boringssl-zig-main.zip \
    [--html5ever-archive /path/to/02-litefetch-html5ever-...zip] \
    [--repo-root /path/to/browser] \
    [--workspace-root /path/to/workspace-parent] \
    [--skip-zon-rewrite]

Restores the headed fork's offline Linux dependency layout next to the browser
repo, then optionally rewrites build.zig.zon so brotli, zlib, nghttp2, and curl
resolve from ../offline-deps instead of GitHub URLs.

Expected sibling layout after a successful run:
  ../zig-v8-fork
  ../boringssl-zig
  ../offline-deps/brotli
  ../offline-deps/zlib
  ../offline-deps/nghttp2
  ../offline-deps/curl

If --html5ever-archive is provided, the script also refreshes:
  .cargo/config.toml
  vendor/

This script prepares the offline dependency tree only. Full browser validation
still expects the repo's supported Zig 0.15.x toolchain.
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workspace_root="$(cd "${repo_root}/.." && pwd)"
deps_archive=""
boringssl_archive=""
html5ever_archive=""
rewrite_zon=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deps-archive)
      deps_archive="$2"
      shift 2
      ;;
    --boringssl-archive)
      boringssl_archive="$2"
      shift 2
      ;;
    --html5ever-archive)
      html5ever_archive="$2"
      shift 2
      ;;
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --workspace-root)
      workspace_root="$2"
      shift 2
      ;;
    --skip-zon-rewrite)
      rewrite_zon=0
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

if [[ -z "${deps_archive}" || -z "${boringssl_archive}" ]]; then
  echo "Both --deps-archive and --boringssl-archive are required." >&2
  usage >&2
  exit 1
fi

for required_tool in unzip tar python3; do
  if ! command -v "${required_tool}" >/dev/null 2>&1; then
    echo "Missing required tool: ${required_tool}" >&2
    exit 1
  fi
done

for required_file in "${deps_archive}" "${boringssl_archive}"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "Archive not found: ${required_file}" >&2
    exit 1
  fi
done

if [[ -n "${html5ever_archive}" && ! -f "${html5ever_archive}" ]]; then
  echo "Archive not found: ${html5ever_archive}" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

extract_zip_member() {
  local archive_path="$1"
  local member_name="$2"
  local output_path="$3"
  unzip -p "${archive_path}" "${member_name}" > "${output_path}"
}

extract_tarball_to_named_dir() {
  local tarball_path="$1"
  local destination_parent="$2"
  local final_dir_name="$3"

  local scratch_dir="${tmpdir}/extract-${final_dir_name}"
  mkdir -p "${scratch_dir}" "${destination_parent}"
  tar -xzf "${tarball_path}" -C "${scratch_dir}"

  local extracted_root
  extracted_root="$(find "${scratch_dir}" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z "${extracted_root}" ]]; then
    echo "Could not determine extracted root for ${tarball_path}" >&2
    exit 1
  fi

  rm -rf "${destination_parent}/${final_dir_name}"
  mv "${extracted_root}" "${destination_parent}/${final_dir_name}"
}

extract_zip_root_to_named_dir() {
  local archive_path="$1"
  local destination_parent="$2"
  local final_dir_name="$3"

  local scratch_dir="${tmpdir}/zip-${final_dir_name}"
  mkdir -p "${scratch_dir}" "${destination_parent}"
  unzip -q "${archive_path}" -d "${scratch_dir}"

  local extracted_root
  extracted_root="$(find "${scratch_dir}" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z "${extracted_root}" ]]; then
    echo "Could not determine extracted root for ${archive_path}" >&2
    exit 1
  fi

  rm -rf "${destination_parent}/${final_dir_name}"
  mv "${extracted_root}" "${destination_parent}/${final_dir_name}"
}

refresh_html5ever_vendor_bundle() {
  local archive_path="$1"
  local scratch_dir="${tmpdir}/html5ever-vendor"
  mkdir -p "${scratch_dir}"
  unzip -q "${archive_path}" -d "${scratch_dir}"

  local extracted_root
  extracted_root="$(find "${scratch_dir}" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z "${extracted_root}" ]]; then
    echo "Could not determine extracted root for ${archive_path}" >&2
    exit 1
  fi

  mkdir -p "${repo_root}/.cargo"
  cp "${extracted_root}/.cargo/config.toml" "${repo_root}/.cargo/config.toml"
  rm -rf "${repo_root}/vendor"
  cp -R "${extracted_root}/vendor" "${repo_root}/vendor"
}

rewrite_build_zon_for_offline_deps() {
  local zon_path="${repo_root}/build.zig.zon"
  local backup_path="${repo_root}/build.zig.zon.before-offline"

  cp "${zon_path}" "${backup_path}"

  python3 - "${zon_path}" <<'PY'
from pathlib import Path
import re
import sys

zon_path = Path(sys.argv[1])
text = zon_path.read_text()

replacements = {
    "brotli": "../offline-deps/brotli",
    "zlib": "../offline-deps/zlib",
    "nghttp2": "../offline-deps/nghttp2",
    "curl": "../offline-deps/curl",
}

for name, path in replacements.items():
    pattern = re.compile(
        rf'(\.{re.escape(name)} = \.\{{\n)(?P<body>.*?)(\n\s+\}},)',
        re.S,
    )
    match = pattern.search(text)
    if not match:
        raise SystemExit(f"Could not find dependency block for {name} in build.zig.zon")
    replacement = f'{match.group(1)}            .path = "{path}",{match.group(3)}'
    text = text[:match.start()] + replacement + text[match.end():]

zon_path.write_text(text)
PY
}

mkdir -p "${workspace_root}/offline-deps"

extract_zip_member "${deps_archive}" "zig-v8-fork-0.3.1.tar.gz" "${tmpdir}/zig-v8-fork.tar.gz"
extract_tarball_to_named_dir "${tmpdir}/zig-v8-fork.tar.gz" "${workspace_root}" "zig-v8-fork"

extract_zip_member "${deps_archive}" "brotli-028fb5a23661f123017c060daa546b55cf4bde29.tar.gz" "${tmpdir}/brotli.tar.gz"
extract_tarball_to_named_dir "${tmpdir}/brotli.tar.gz" "${workspace_root}/offline-deps" "brotli"

extract_zip_member "${deps_archive}" "zlib-1.3.2.tar.gz" "${tmpdir}/zlib.tar.gz"
extract_tarball_to_named_dir "${tmpdir}/zlib.tar.gz" "${workspace_root}/offline-deps" "zlib"

extract_zip_member "${deps_archive}" "nghttp2-1.68.0.tar.gz" "${tmpdir}/nghttp2.tar.gz"
extract_tarball_to_named_dir "${tmpdir}/nghttp2.tar.gz" "${workspace_root}/offline-deps" "nghttp2"

extract_zip_member "${deps_archive}" "curl-8.18.0.tar.gz" "${tmpdir}/curl.tar.gz"
extract_tarball_to_named_dir "${tmpdir}/curl.tar.gz" "${workspace_root}/offline-deps" "curl"

extract_zip_root_to_named_dir "${boringssl_archive}" "${workspace_root}" "boringssl-zig"

if [[ -n "${html5ever_archive}" ]]; then
  refresh_html5ever_vendor_bundle "${html5ever_archive}"
fi

if [[ "${rewrite_zon}" -eq 1 ]]; then
  rewrite_build_zon_for_offline_deps
fi

cat <<EOF
Offline dependency layout restored.
Repo root: ${repo_root}
Workspace root: ${workspace_root}
Next:
  1. Review ${repo_root}/build.zig.zon.before-offline if you need to revert.
  2. Use the repo's supported Zig 0.15.x toolchain for real validation.
  3. Run: zig build --summary all -Dprebuilt_v8_path='../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a'
EOF
