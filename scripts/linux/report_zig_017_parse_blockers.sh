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
  local matches

  echo "## $label"
  matches="$(rg -n "$pattern" "$scope" || true)"
  if [ -n "$matches" ]; then
    findings=1
    printf '%s\n' "$matches"
    echo
    echo "files: $(printf '%s\n' "$matches" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')"
  else
    echo "none"
  fi
  echo
}

report_smallest_candidates() {
  local label="$1"
  local pattern="$2"
  local scope="${3:-$repo_root/src}"
  local limit="${4:-5}"
  local files

  echo "## $label"
  files="$(rg -l "$pattern" "$scope" || true)"
  if [ -z "$files" ]; then
    echo "none"
    echo
    return
  fi

  printf '%s\n' "$files" \
    | xargs -r wc -c \
    | sort -n \
    | head -n "$limit" \
    | awk '{ printf "%7s  %s\n", $1, $2 }'
  echo
}

echo "# Zig 0.17 parse blockers"
echo "repo: $repo_root"
echo

report_pattern "repeat syntax with spaced operator" ' \*\* '
report_smallest_candidates "smallest repeat-syntax candidates" ' \*\* '

report_pattern "@Type call sites" '@Type\s*\('
report_smallest_candidates "smallest @Type candidates" '@Type\s*\('

report_pattern "@cImport call sites" '@cImport\s*\('
report_smallest_candidates "smallest @cImport candidates" '@cImport\s*\('

report_pattern "std.fs.cwd call sites" 'std\.fs\.cwd\s*\(' "$repo_root"
report_smallest_candidates "smallest std.fs.cwd candidates" 'std\.fs\.cwd\s*\(' "$repo_root"

report_pattern "legacy addStaticLibrary call sites" 'addStaticLibrary\s*\(' "$repo_root"
report_smallest_candidates "smallest addStaticLibrary candidates" 'addStaticLibrary\s*\(' "$repo_root"

if [ "$findings" -eq 0 ]; then
  echo "No known parser blockers found."
fi
