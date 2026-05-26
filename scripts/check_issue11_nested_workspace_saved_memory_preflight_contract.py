#!/usr/bin/env python3

"""Check the issue #11 nested-workspace preflight fallback contract."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import textwrap
import unittest


TARGET_FILE = "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"
REQUIRED_FRAGMENTS: tuple[tuple[str, str], ...] = (
    (
        'if [[ -d "${RESTORED_CHECKOUT_ROOT}" ]]; then',
        "The wrapper should detect whether the restored checkout exists before choosing the contract target root.",
    ),
    (
        'CONTRACT_TARGET_ROOT="${RESTORED_CHECKOUT_ROOT}"',
        "The wrapper should prefer the restored checkout when it already exists.",
    ),
    (
        'CONTRACT_TARGET_ROOT="${HELPER_ROOT}"',
        "The wrapper should fall back to the live helper root when no restored checkout exists yet.",
    ),
    (
        '--repo-root "${CONTRACT_TARGET_ROOT}"',
        "The issue #11 contract and inventory checks should run against the surfaced contract target root.",
    ),
    (
        '"contract_target_root": contract_target_root,',
        "The JSON output should expose which root the wrapper selected for issue #11 contract checks.",
    ),
    (
        'Contract target root:   ${CONTRACT_TARGET_ROOT}',
        "The text output should expose which root the wrapper selected for issue #11 contract checks.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check the issue #11 nested-workspace preflight fallback contract."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root that contains the wrapper script",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


def collect_results(repo_root: Path) -> dict[str, object]:
    target = repo_root / TARGET_FILE
    missing: list[str] = []
    text = ""
    if target.is_file():
        text = target.read_text(encoding="utf-8")
    else:
        missing.append(f"missing target file: {target}")

    checks: list[dict[str, object]] = []
    for fragment, purpose in REQUIRED_FRAGMENTS:
        exists = fragment in text
        checks.append(
            {
                "fragment": fragment,
                "purpose": purpose,
                "exists": exists,
            }
        )
        if not exists:
            missing.append(fragment)

    return {
        "ok": target.is_file() and not missing,
        "repo_root": str(repo_root),
        "target_file": str(target),
        "checks": checks,
        "missing": missing,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Target file: {result['target_file']}")
    for check in result["checks"]:
        status = "PASS" if check["exists"] else "FAIL"
        print(f"[{status}] {check['fragment']}")
        print(f"  {check['purpose']}")
    if result["ok"]:
        print("\nNested-workspace preflight contract check passed.")
    else:
        print("\nNested-workspace preflight contract check failed.")
        for item in result["missing"]:
            print(f"  missing: {item}")


def write_fixture(root: Path, body: str) -> Path:
    target = root / TARGET_FILE
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(body, encoding="utf-8")
    return root


class NestedWorkspacePreflightContractTests(unittest.TestCase):
    def test_passes_when_all_required_fragments_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            body = textwrap.dedent(
                """
                if [[ -d "${RESTORED_CHECKOUT_ROOT}" ]]; then
                    CONTRACT_TARGET_ROOT="${RESTORED_CHECKOUT_ROOT}"
                else
                    CONTRACT_TARGET_ROOT="${HELPER_ROOT}"
                fi
                HELPER_CONTRACT_CMD=(
                    python3
                    "scripts/check_issue11_saved_memory_helper_contract.py"
                    --repo-root "${CONTRACT_TARGET_ROOT}"
                )
                REENTRY_INVENTORY_CMD=(
                    python3
                    "scripts/check_issue11_reentry_inventory_consistency.py"
                    --repo-root "${CONTRACT_TARGET_ROOT}"
                )
                print(json.dumps({
                    "contract_target_root": contract_target_root,
                }, indent=2))
                Contract target root:   ${CONTRACT_TARGET_ROOT}
                """
            ).strip() + "\n"
            result = collect_results(write_fixture(repo_root, body))
            self.assertTrue(result["ok"])

    def test_flags_missing_helper_root_fallback(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            body = textwrap.dedent(
                """
                if [[ -d "${RESTORED_CHECKOUT_ROOT}" ]]; then
                    CONTRACT_TARGET_ROOT="${RESTORED_CHECKOUT_ROOT}"
                fi
                """
            ).strip() + "\n"
            result = collect_results(write_fixture(repo_root, body))
            self.assertFalse(result["ok"])
            self.assertIn('CONTRACT_TARGET_ROOT="${HELPER_ROOT}"', result["missing"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            NestedWorkspacePreflightContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
