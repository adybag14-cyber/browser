#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check_lightpanda_wsl_build_readiness.sh [options]

Verify the local WSL/Linux checkout layout that this fork expects before
running Zig build commands for headed-mode work.

Options:
  --repo-root PATH           Browser repo root. Defaults to the repo that owns this script.
  --zig PATH                 Zig executable to inspect. Defaults to zig on PATH.
  --download-cache-dir PATH  Directory that should already contain the remote tarballs
                             referenced by build.zig.zon.
  --v8-root PATH             Override the default ../zig-v8-fork sibling path.
  --boringssl-root PATH      Override the default ../boringssl-zig sibling path.
  --allow-other-zig          Warn instead of failing when Zig is not the exact version
                             pinned in build.zig.zon.
  --print-build-command      Print the recommended recovery build commands.
  --help                     Show this help text.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_repo_root="$(cd "${script_dir}/../.." && pwd)"
repo_root="${default_repo_root}"
zig_bin="zig"
download_cache_dir=""
allow_other_zig=0
print_build_command=0
custom_v8_root=""
custom_boringssl_root=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --zig)
      zig_bin="$2"
      shift 2
      ;;
    --download-cache-dir)
      download_cache_dir="$2"
      shift 2
      ;;
    --v8-root)
      custom_v8_root="$2"
      shift 2
      ;;
    --boringssl-root)
      custom_boringssl_root="$2"
      shift 2
      ;;
    --allow-other-zig)
      allow_other_zig=1
      shift
      ;;
    --print-build-command)
      print_build_command=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

build_zon="${repo_root}/build.zig.zon"
if [[ ! -f "${build_zon}" ]]; then
  echo "FAIL repo-root missing build.zig.zon: ${build_zon}" >&2
  exit 1
fi

required_zig_version="$(
  grep -Eo '\.minimum_zig_version = "[^"]+"' "${build_zon}" | sed -E 's/.*"([^"]+)"/\1/' | head -n 1
)"

if [[ -z "${required_zig_version}" ]]; then
  echo "FAIL could not read .minimum_zig_version from ${build_zon}" >&2
  exit 1
fi

declare -a remote_urls=(
  "https://github.com/google/brotli/archive/028fb5a23661f123017c060daa546b55cf4bde29.tar.gz"
  "https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz"
  "https://github.com/nghttp2/nghttp2/releases/download/v1.68.0/nghttp2-1.68.0.tar.gz"
  "https://github.com/curl/curl/releases/download/curl-8_18_0/curl-8.18.0.tar.gz"
)

v8_root="${custom_v8_root:-$(cd "${repo_root}/.." && pwd)/zig-v8-fork}"
boringssl_root="${custom_boringssl_root:-$(cd "${repo_root}/.." && pwd)/boringssl-zig}"

failures=0
warnings=0

pass() {
  printf 'PASS %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1"
}

pass "repo-root ${repo_root}"
pass "required-zig-version ${required_zig_version}"

resolved_zig_bin=""
if [[ "${zig_bin}" == */* ]]; then
  if [[ -x "${zig_bin}" ]]; then
    resolved_zig_bin="${zig_bin}"
  fi
else
  resolved_zig_bin="$(command -v "${zig_bin}" 2>/dev/null || true)"
fi

if [[ -z "${resolved_zig_bin}" ]]; then
  fail "zig binary not found: ${zig_bin}"
else
  zig_version="$("${resolved_zig_bin}" version 2>/dev/null || true)"
  if [[ -z "${zig_version}" ]]; then
    fail "could not read zig version from ${resolved_zig_bin}"
  elif [[ "${zig_version}" == "${required_zig_version}" ]]; then
    pass "zig-version ${zig_version}"
  elif [[ ${allow_other_zig} -eq 1 ]]; then
    warn "zig-version ${zig_version} does not match required ${required_zig_version}"
  else
    fail "zig-version ${zig_version} does not match required ${required_zig_version}"
  fi
fi

if [[ -d "${v8_root}" ]]; then
  pass "v8-sibling ${v8_root}"
else
  fail "missing v8 sibling ${v8_root}"
fi

if [[ -d "${boringssl_root}" ]]; then
  pass "boringssl-sibling ${boringssl_root}"
else
  fail "missing boringssl sibling ${boringssl_root}"
fi

if [[ -n "${download_cache_dir}" ]]; then
  if [[ ! -d "${download_cache_dir}" ]]; then
    fail "download cache dir does not exist: ${download_cache_dir}"
  else
    pass "download-cache-dir ${download_cache_dir}"
    for remote_url in "${remote_urls[@]}"; do
      archive_name="$(basename "${remote_url}")"
      if [[ -f "${download_cache_dir}/${archive_name}" ]]; then
        pass "cached-archive ${archive_name}"
      else
        fail "missing cached archive ${download_cache_dir}/${archive_name}"
      fi
    done
  fi
else
  warn "download cache dir not supplied; remote dependency tarballs were not checked"
fi

if [[ ${print_build_command} -eq 1 ]]; then
  printf '\nRecommended recovery commands:\n'
  printf '  cd %q\n' "${repo_root}"
  printf '  %q build --help\n' "${zig_bin}"
  printf '  %q build test --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover\n' "${zig_bin}"
fi

printf '\nSummary: %d failure(s), %d warning(s)\n' "${failures}" "${warnings}"

if [[ ${failures} -ne 0 ]]; then
  exit 1
fi
