#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/check_hosted_build_prereqs.sh [--offline-dir DIR] [--strict-offline]

Checks the hosted Lightpanda build prerequisites that commonly fail before the
headed fork reaches real compiler diagnostics.

Options:
  --offline-dir DIR   Check DIR for cached brotli/zlib/nghttp2/curl tarballs.
  --strict-offline    Treat missing offline tarballs as failures instead of warnings.
  -h, --help          Show this help text.
EOF
}

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
offline_dir=""
strict_offline=0
failures=0
warnings=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline-dir)
      [[ $# -ge 2 ]] || {
        echo "error: --offline-dir requires a value" >&2
        exit 2
      }
      offline_dir="$2"
      shift 2
      ;;
    --strict-offline)
      strict_offline=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ok() {
  printf 'OK    %s\n' "$1"
}

warn() {
  printf 'WARN  %s\n' "$1"
  warnings=$((warnings + 1))
}

fail() {
  printf 'FAIL  %s\n' "$1"
  failures=$((failures + 1))
}

version_ge() {
  local minimum="$1"
  local current="$2"
  [[ "$(printf '%s\n%s\n' "$minimum" "$current" | sort -V | head -n 1)" == "$minimum" ]]
}

check_command() {
  local command_name="$1"
  local human_name="$2"
  if command -v "$command_name" >/dev/null 2>&1; then
    ok "$human_name is available at $(command -v "$command_name")"
    return 0
  fi
  fail "$human_name is missing from PATH"
  return 1
}

check_path_dependency() {
  local rel_path="$1"
  local label="$2"
  local abs_path
  abs_path=$(cd "$repo_root" && python3 - <<'PY' "$rel_path"
import os
import sys
print(os.path.abspath(sys.argv[1]))
PY
)

  if [[ -d "$abs_path" && -f "$abs_path/build.zig" ]]; then
    ok "$label is staged at $abs_path"
    return
  fi

  fail "$label is missing at $abs_path (expected sibling path from build.zig.zon)"
}

check_offline_archive() {
  local pattern="$1"
  local label="$2"

  if compgen -G "$offline_dir/$pattern" >/dev/null; then
    ok "$label archive found in $offline_dir"
    return
  fi

  if [[ "$strict_offline" -eq 1 ]]; then
    fail "$label archive matching $pattern is missing from $offline_dir"
  else
    warn "$label archive matching $pattern is missing from $offline_dir"
  fi
}

printf 'Lightpanda hosted build preflight\n'
printf 'Repo root: %s\n' "$repo_root"

if [[ ! -f "$repo_root/build.zig.zon" ]]; then
  fail "build.zig.zon is missing; run this script from a browser checkout"
fi

minimum_zig_version=$(sed -n 's/.*minimum_zig_version = "\(.*\)".*/\1/p' "$repo_root/build.zig.zon" | head -n 1)
if [[ -z "$minimum_zig_version" ]]; then
  warn "Could not read minimum_zig_version from build.zig.zon"
fi

if check_command zig "Zig"; then
  current_zig_version=$(zig version)
  if [[ -n "$minimum_zig_version" ]]; then
    if version_ge "$minimum_zig_version" "$current_zig_version"; then
      ok "Zig version $current_zig_version satisfies minimum $minimum_zig_version"
    else
      fail "Zig version $current_zig_version is older than minimum $minimum_zig_version"
    fi
  else
    ok "Zig version $current_zig_version detected"
  fi
fi

check_command cargo "Cargo" || true
check_path_dependency "../zig-v8-fork" "zig-v8-fork"
check_path_dependency "../boringssl-zig" "boringssl-zig"

if [[ -n "$offline_dir" ]]; then
  if [[ ! -d "$offline_dir" ]]; then
    fail "Offline directory does not exist: $offline_dir"
  else
    check_offline_archive 'brotli-*.tar.gz' 'brotli'
    check_offline_archive 'zlib-*.tar.gz' 'zlib'
    check_offline_archive 'nghttp2-*.tar.gz' 'nghttp2'
    check_offline_archive 'curl-*.tar.gz' 'curl'
  fi
else
  warn "No --offline-dir supplied; Zig will fetch brotli/zlib/nghttp2/curl unless they are already cached"
fi

printf '\nSuggested recovery commands:\n'
printf '  zig build --help\n'
printf '  zig build test --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover\n'
printf '  zig build -Dprebuilt_v8_path=<path-to-libc_v8.a> test\n'

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi
