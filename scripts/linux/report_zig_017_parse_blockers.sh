#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(pwd)}"

if [ ! -d "$repo_root/src" ]; then
  echo "expected a browser repo root with a src/ directory: $repo_root" >&2
  exit 1
fi

findings=0

report_pattern() {
  local label="$1"
  local pattern="$2"
  local scope="${3:-$repo_root/src}"
  echo "## $label"
  if rg -n "$pattern" "$scope"; then
    findings=1
  else
    echo "none"
  fi
  echo
}

echo "# Zig 0.17 parse blockers"
echo "repo: $repo_root"
echo

report_pattern "repeat syntax with spaced operator" ' \*\* '
report_pattern "@Type call sites" '@Type\s*\('
report_pattern "@cImport call sites" '@cImport\s*\('
report_pattern "std.fs.cwd call sites" 'std\.fs\.cwd\s*\(' "$repo_root"
report_pattern "legacy addStaticLibrary call sites" 'addStaticLibrary\s*\(' "$repo_root"

if [ "$findings" -eq 0 ]; then
  echo "No known parser blockers found."
fi
