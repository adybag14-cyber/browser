#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

required_paths=(
  "scripts/check_issue3_runtime_reentry_status.py"
  "scripts/check_issue3_saved_memory_inputs.py"
  "scripts/check_issue3_saved_archive_integrity.py"
  "scripts/check_issue3_restored_checkout.py"
  "scripts/check_linux_build_readiness.py"
  "scripts/linux/show_issue3_runtime_reentry_status_route.sh"
)

missing=0
for relative_path in "${required_paths[@]}"; do
  absolute_path="${REPO_ROOT}/${relative_path}"
  if [[ -f "${absolute_path}" ]]; then
    echo "[PASS] ${relative_path}"
  else
    echo "[FAIL] ${relative_path}"
    missing=1
  fi
done

if [[ ${missing} -ne 0 ]]; then
  echo
  echo "Issue #3 runtime re-entry status route surface is incomplete." >&2
  exit 1
fi

echo
echo "Issue #3 runtime re-entry status route surface is ready."
