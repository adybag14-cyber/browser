#!/usr/bin/env python3

"""Check whether a candidate repo has the full issue #11 live-helper surface."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import unittest


REQUIRED_HELPER_PATHS: tuple[tuple[str, str], ...] = (
    ("build.zig.zon", "browser repo root marker"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    (
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
        "saved-memory route printer",
    ),
    (
        "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
        "issue #11 nested-workspace rerun helper",
    ),
    (
        "scripts/check_issue11_saved_memory_helper_contract.py",
        "issue #11 helper-contract checker",
    ),
    (
        "scripts/check_issue11_reentry_inventory_consistency.py",
        "issue #11 re-entry inventory checker",
    ),
    (
        "scripts/check_issue11_nested_workspace_saved_memory_preflight_contract.py",
        "issue #11 nested-workspace fallback contract checker",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a candidate repo carries the issue #11 live-helper "
            "surface needed by the saved-memory route helpers."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the candidate browser repo root",
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


def collect_surface(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    missing: list[str] = []

    for relative_path, label in REQUIRED_HELPER_PATHS:
        target = repo_root / relative_path
        exists = target.is_file()
        checks.append(
            {
                "path": relative_path,
                "label": label,
                "exists": exists,
            }
        )
        if not exists:
            missing.append(relative_path)

    return {
        "ok": not missing,
        "repo_root": str(repo_root),
        "checks": checks,
        "missing": missing,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    for check in result["checks"]:
        status = "PASS" if check["exists"] else "FAIL"
        print(f"[{status}] {check['path']}")
        print(f"  {check['label']}")
    if result["ok"]:
        print("\nIssue #11 live-helper surface check passed.")
    else:
        print("\nIssue #11 live-helper surface check failed.")
        for missing in result["missing"]:
            print(f"  missing: {missing}")


def write_fixture_repo(root: Path, missing: set[str] | None = None) -> Path:
    missing = missing or set()
    for relative_path, _label in REQUIRED_HELPER_PATHS:
        if relative_path in missing:
            continue
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("fixture\n", encoding="utf-8")
    return root


class Issue11LiveHelperSurfaceTests(unittest.TestCase):
    def test_passes_when_all_required_helper_paths_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = write_fixture_repo(Path(tmpdir))
            result = collect_surface(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(result["missing"], [])

    def test_flags_missing_nested_workspace_runner(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = write_fixture_repo(
                Path(tmpdir),
                {"scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"},
            )
            result = collect_surface(repo_root)
            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
                result["missing"],
            )

    def test_flags_missing_issue11_contract_helpers(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = write_fixture_repo(
                Path(tmpdir),
                {
                    "scripts/check_issue11_saved_memory_helper_contract.py",
                    "scripts/check_issue11_reentry_inventory_consistency.py",
                },
            )
            result = collect_surface(repo_root)
            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue11_saved_memory_helper_contract.py",
                result["missing"],
            )
            self.assertIn(
                "scripts/check_issue11_reentry_inventory_consistency.py",
                result["missing"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11LiveHelperSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_surface(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
