#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/stage_linux_offline_dependencies.sh [options]

Stages the browser fork's Linux/WSL offline Zig dependencies from the saved
local archives described in docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md.

Options:
  --repo-root PATH           Browser checkout root. Defaults to the parent of this script's directory.
  --parent-dir PATH          Parent directory that should receive sibling checkouts such as ../zig-v8-fork and ../boringssl-zig.
  --boringssl-archive PATH   Path to 03-boringssl-zig-main.zip.
  --bundle-archive PATH      Path to 04-zig-browser-depo.tar.zip.
  --source-cache-dir PATH    Directory that should receive the saved brotli/zlib/nghttp2/curl tarballs.
  --extract-dir PATH         Directory that should receive extracted brotli/zlib/nghttp2/curl source trees.
  --force                    Replace existing staged directories and files.
  --help                     Show this help text.

What this script does:
  - stages ../boringssl-zig from the saved boringssl zip
  - stages ../zig-v8-fork from the saved V8 tarball bundle
  - copies the saved brotli/zlib/nghttp2/curl tarballs into a local cache dir
  - extracts those tarballs into a local source dir for later path rewrites

What this script does not do:
  - it does not edit build.zig.zon
  - it does not populate Zig's global download cache automatically
  - it does not run zig build for you
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '==> %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

maybe_remove() {
  local path="$1"
  if [[ -e "$path" ]]; then
    if [[ "$force" != "true" ]]; then
      die "path already exists: $path (rerun with --force to replace it)"
    fi
    rm -rf "$path"
  fi
}

extract_zip_root_dir() {
  local archive="$1"
  local target_dir="$2"
  local temp_dir
  temp_dir="$(mktemp -d)"
  unzip -q "$archive" -d "$temp_dir"
  local root_dir
  root_dir="$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [[ -n "$root_dir" ]] || die "could not find extracted directory in $archive"
  maybe_remove "$target_dir"
  mkdir -p "$(dirname "$target_dir")"
  mv "$root_dir" "$target_dir"
  rm -rf "$temp_dir"
}

extract_bundle_member() {
  local archive="$1"
  local member="$2"
  local output_path="$3"
  maybe_remove "$output_path"
  mkdir -p "$(dirname "$output_path")"
  unzip -p "$archive" "$member" >"$output_path"
}

extract_tarball_root_dir() {
  local tarball="$1"
  local target_dir="$2"
  local temp_dir
  temp_dir="$(mktemp -d)"
  tar -xzf "$tarball" -C "$temp_dir"
  local root_dir
  root_dir="$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [[ -n "$root_dir" ]] || die "could not find extracted directory in $tarball"
  maybe_remove "$target_dir"
  mkdir -p "$(dirname "$target_dir")"
  mv "$root_dir" "$target_dir"
  rm -rf "$temp_dir"
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
parent_dir="$(dirname "$repo_root")"
boringssl_archive=""
bundle_archive=""
source_cache_dir=""
extract_dir=""
force="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --parent-dir)
      parent_dir="$2"
      shift 2
      ;;
    --boringssl-archive)
      boringssl_archive="$2"
      shift 2
      ;;
    --bundle-archive)
      bundle_archive="$2"
      shift 2
      ;;
    --source-cache-dir)
      source_cache_dir="$2"
      shift 2
      ;;
    --extract-dir)
      extract_dir="$2"
      shift 2
      ;;
    --force)
      force="true"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

repo_root="$(cd "$repo_root" && pwd)"
parent_dir="$(mkdir -p "$parent_dir" && cd "$parent_dir" && pwd)"
source_cache_dir="${source_cache_dir:-$repo_root/.offline-deps/distfiles}"
extract_dir="${extract_dir:-$repo_root/.offline-deps/src}"

[[ -f "$repo_root/build.zig.zon" ]] || die "repo root does not look like the browser checkout: $repo_root"
[[ -n "$boringssl_archive" ]] || die "--boringssl-archive is required"
[[ -n "$bundle_archive" ]] || die "--bundle-archive is required"
[[ -f "$boringssl_archive" ]] || die "boringssl archive not found: $boringssl_archive"
[[ -f "$bundle_archive" ]] || die "bundle archive not found: $bundle_archive"

require_cmd unzip
require_cmd tar
require_cmd mktemp
require_cmd find

mkdir -p "$source_cache_dir" "$extract_dir"

boringssl_target="$parent_dir/boringssl-zig"
v8_target="$parent_dir/zig-v8-fork"

info "staging boringssl-zig into $boringssl_target"
extract_zip_root_dir "$boringssl_archive" "$boringssl_target"

tmp_v8_tarball="$(mktemp)"
trap 'rm -f "$tmp_v8_tarball"' EXIT

info "extracting zig-v8-fork tarball from $bundle_archive"
extract_bundle_member "$bundle_archive" "zig-v8-fork-0.3.1.tar.gz" "$tmp_v8_tarball"
extract_tarball_root_dir "$tmp_v8_tarball" "$v8_target"

declare -a bundle_members=(
  "brotli-028fb5a23661f123017c060daa546b55cf4bde29.tar.gz:brotli"
  "zlib-1.3.2.tar.gz:zlib"
  "nghttp2-1.68.0.tar.gz:nghttp2"
  "curl-8.18.0.tar.gz:curl"
)

for entry in "${bundle_members[@]}"; do
  member="${entry%%:*}"
  name="${entry##*:}"
  tarball_path="$source_cache_dir/$member"
  source_dir="$extract_dir/$name"

  info "caching $member"
  extract_bundle_member "$bundle_archive" "$member" "$tarball_path"

  info "extracting $name sources into $source_dir"
  extract_tarball_root_dir "$tarball_path" "$source_dir"
done

cat <<EOF

Offline dependency staging complete.

Repo root:
  $repo_root

Sibling dependencies:
  $v8_target
  $boringssl_target

Cached source tarballs:
  $source_cache_dir

Extracted source trees:
  $extract_dir/brotli
  $extract_dir/zlib
  $extract_dir/nghttp2
  $extract_dir/curl

Suggested next steps:
  1. Keep this checkout under the same parent directory as ../zig-v8-fork and ../boringssl-zig.
  2. Use the cached tarballs or extracted source trees for an offline cache fill or a throwaway build.zig.zon path rewrite.
  3. Retry the build with explicit cache dirs, for example:
       zig build --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover

This helper does not rewrite build.zig.zon automatically.
EOF
