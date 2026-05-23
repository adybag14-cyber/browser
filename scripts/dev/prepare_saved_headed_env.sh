#!/usr/bin/env bash

set -euo pipefail

memory_root="${MEMORY_ROOT:-/workspace/memory/repo_archives/browser}"
output_root="${OUTPUT_ROOT:-$PWD/.headed-env}"
zig_archive="${ZIG_ARCHIVE:-}"
force=0

repo_archive_name="01-browser-fork-headed-mode-foundation.zip"
rust_archive_name="01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"
litefetch_archive_name="02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
boringssl_archive_name="03-boringssl-zig-main.zip"
depo_archive_name="04-zig-browser-depo.tar.zip"

usage() {
    cat <<'EOF'
Restore the saved headed-mode repo snapshot and dependency archives into a reusable
local workspace.

Usage:
  prepare_saved_headed_env.sh [options]

Options:
  --memory-root PATH   Memory repo_archives/browser root
  --output-root PATH   Destination root for extracted files
  --zig-archive PATH   Optional Zig archive to unpack alongside the saved deps
  --force              Replace already-extracted outputs
  --help               Show this help

Environment overrides:
  MEMORY_ROOT, OUTPUT_ROOT, ZIG_ARCHIVE
EOF
}

die() {
    echo "error: $*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

abs_path() {
    local path="$1"
    if [ -d "$path" ]; then
        (cd "$path" && pwd)
    else
        local dir
        dir="$(dirname "$path")"
        local base
        base="$(basename "$path")"
        (cd "$dir" && printf '%s/%s\n' "$(pwd)" "$base")
    fi
}

ensure_file() {
    [ -f "$1" ] || die "missing required file: $1"
}

reset_target() {
    local target="$1"
    if [ -e "$target" ] && [ "$force" -eq 1 ]; then
        rm -rf "$target"
    fi
}

extract_zip_dir() {
    local archive="$1"
    local target="$2"
    local temp_dir

    reset_target "$target"
    if [ -e "$target" ]; then
        echo "skip: $target already exists"
        return
    fi

    temp_dir="$(mktemp -d)"
    unzip -q "$archive" -d "$temp_dir"

    local first_entry
    first_entry="$(find "$temp_dir" -mindepth 1 -maxdepth 1 | head -n 1)"
    [ -n "$first_entry" ] || die "archive extracted no content: $archive"

    mkdir -p "$(dirname "$target")"
    if [ -d "$first_entry" ] && [ "$(find "$temp_dir" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
        mv "$first_entry" "$target"
    else
        mkdir -p "$target"
        find "$temp_dir" -mindepth 1 -maxdepth 1 -exec mv {} "$target"/ \;
    fi

    rm -rf "$temp_dir"
    echo "restored: $target"
}

extract_tar_dir() {
    local archive="$1"
    local target="$2"
    local temp_dir

    reset_target "$target"
    if [ -e "$target" ]; then
        echo "skip: $target already exists"
        return
    fi

    temp_dir="$(mktemp -d)"
    tar -xf "$archive" -C "$temp_dir"

    local first_entry
    first_entry="$(find "$temp_dir" -mindepth 1 -maxdepth 1 | head -n 1)"
    [ -n "$first_entry" ] || die "archive extracted no content: $archive"

    mkdir -p "$(dirname "$target")"
    if [ -d "$first_entry" ] && [ "$(find "$temp_dir" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
        mv "$first_entry" "$target"
    else
        mkdir -p "$target"
        find "$temp_dir" -mindepth 1 -maxdepth 1 -exec mv {} "$target"/ \;
    fi

    rm -rf "$temp_dir"
    echo "restored: $target"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --memory-root)
            [ "$#" -ge 2 ] || die "--memory-root requires a value"
            memory_root="$2"
            shift 2
            ;;
        --output-root)
            [ "$#" -ge 2 ] || die "--output-root requires a value"
            output_root="$2"
            shift 2
            ;;
        --zig-archive)
            [ "$#" -ge 2 ] || die "--zig-archive requires a value"
            zig_archive="$2"
            shift 2
            ;;
        --force)
            force=1
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

require_cmd unzip
require_cmd tar

memory_root="$(abs_path "$memory_root")"
output_root="$(abs_path "$output_root")"
mkdir -p "$output_root"

repo_archive="$memory_root/$repo_archive_name"
deps_root="$memory_root/dependencies"
rust_archive="$deps_root/$rust_archive_name"
litefetch_archive="$deps_root/$litefetch_archive_name"
boringssl_archive="$deps_root/$boringssl_archive_name"
depo_archive="$deps_root/$depo_archive_name"

ensure_file "$repo_archive"
ensure_file "$rust_archive"
ensure_file "$litefetch_archive"
ensure_file "$boringssl_archive"
ensure_file "$depo_archive"
if [ -n "$zig_archive" ]; then
    ensure_file "$zig_archive"
fi

repo_target="$output_root/repo"
toolchains_root="$output_root/toolchains"
deps_target_root="$output_root/dependencies"

extract_zip_dir "$repo_archive" "$repo_target"
extract_tar_dir "$rust_archive" "$toolchains_root/rust-1.79.0-x86_64-unknown-linux-gnu"
extract_zip_dir "$litefetch_archive" "$deps_target_root/litefetch-html5ever-linux-x86_64-deps"
extract_zip_dir "$boringssl_archive" "$deps_target_root/boringssl-zig-main"
extract_zip_dir "$depo_archive" "$deps_target_root/zig-browser-depo"

zig_target=""
if [ -n "$zig_archive" ]; then
    zig_target="$toolchains_root/$(basename "$zig_archive" .tar.xz)"
    extract_tar_dir "$zig_archive" "$zig_target"
fi

rust_bin="$toolchains_root/rust-1.79.0-x86_64-unknown-linux-gnu/bin"

echo
echo "Prepared headed-mode workspace:"
echo "  repo:        $repo_target"
echo "  rust:        $rust_bin"
echo "  dependencies:$deps_target_root"
if [ -n "$zig_target" ]; then
    echo "  zig:         $zig_target"
fi

echo
echo "Suggested shell setup:"
if [ -n "$zig_target" ]; then
    echo "  export PATH=\"$rust_bin:$zig_target:\$PATH\""
else
    echo "  export PATH=\"$rust_bin:\$PATH\""
fi
echo "  export LIGHTPANDA_REPO_ROOT=\"$repo_target\""
