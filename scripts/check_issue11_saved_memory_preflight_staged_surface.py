#!/usr/bin/env python3

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import tempfile
import unittest


TARGET_FILE = "scripts/check_issue3_saved_memory_inputs.py"
REQUIRED_PATHS: tuple[str, ...] = (
    "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh",
    "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
)

FIXTURE_SOURCE = """
from __future__ import annotations

BASE_REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md", "fixture"),
    ("docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md", "fixture"),
    ("scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh", "fixture"),
    ("scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh", "fixture"),
    ("scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh", "fixture"),
    ("scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh", "fixture"),
    ("scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh", "fixture"),
)
"""


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #11 staged Zig/Rust route follow-ups stay "
            "explicit in scripts/check_issue3_saved_memory_inputs.py."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def extract_base_required_helper_paths(source_text: str) -> set[str]:
    module = ast.parse(source_text)

    for node in module.body:
        value = None
        if isinstance(node, ast.Assign):
            if any(
                isinstance(target, ast.Name)
                and target.id == "BASE_REQUIRED_RESTORED_HELPER_FILES"
                for target in node.targets
            ):
                value = node.value
        elif isinstance(node, ast.AnnAssign):
            if (
                isinstance(node.target, ast.Name)
                and node.target.id == "BASE_REQUIRED_RESTORED_HELPER_FILES"
            ):
                value = node.value

        if value is None or not isinstance(value, (ast.Tuple, ast.List)):
            continue

        paths: set[str] = set()
        for element in value.elts:
            if not isinstance(element, (ast.Tuple, ast.List)) or not element.elts:
                continue
            first = element.elts[0]
            if isinstance(first, ast.Constant) and isinstance(first.value, str):
                paths.add(first.value)
        return paths

    raise ValueError("BASE_REQUIRED_RESTORED_HELPER_FILES is missing")


def collect_result(repo_root: Path) -> dict[str, object]:
    target_path = repo_root / TARGET_FILE
    exists = target_path.is_file()
    result: dict[str, object] = {
        "ok": False,
        "repo_root": str(repo_root),
        "target_file": str(target_path),
        "target_exists": exists,
        "required_paths": list(REQUIRED_PATHS),
        "present_paths": [],
        "missing_paths": list(REQUIRED_PATHS),
        "error": None,
    }
    if not exists:
        result["error"] = f"Missing target file: {target_path}"
        return result

    try:
        source = target_path.read_text(encoding="utf-8")
        present_paths = extract_base_required_helper_paths(source)
    except (OSError, SyntaxError, ValueError) as exc:
        result["error"] = str(exc)
        return result

    missing_paths = [path for path in REQUIRED_PATHS if path not in present_paths]
    result["present_paths"] = sorted(present_paths)
    result["missing_paths"] = missing_paths
    result["ok"] = not missing_paths
    return result


def emit_text(result: dict[str, object]) -> None:
    status = "PASS" if result["ok"] else "FAIL"
    print(f"Issue #11 staged saved-memory preflight surface: [{status}]")
    print(f"Repo root:    {result['repo_root']}")
    print(f"Target file:  {result['target_file']}")
    if result["error"]:
        print(f"Error:        {result['error']}")
        return
    if result["missing_paths"]:
        print("Missing paths:")
        for path in result["missing_paths"]:
            print(f"  - {path}")
    else:
        print("All staged follow-up paths remain explicit in BASE_REQUIRED_RESTORED_HELPER_FILES.")


def build_fixture_repo() -> Path:
    root = Path(tempfile.mkdtemp(prefix="lightpanda-issue11-saved-memory-preflight-"))
    target = root / TARGET_FILE
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(FIXTURE_SOURCE.lstrip("\n"), encoding="utf-8")
    return root


class Issue11SavedMemoryPreflightStagedSurfaceTests(unittest.TestCase):
    def test_extract_base_required_helper_paths(self) -> None:
        extracted = extract_base_required_helper_paths(FIXTURE_SOURCE)
        for path in REQUIRED_PATHS:
            self.assertIn(path, extracted)

    def test_collect_result_passes_when_all_required_paths_are_present(self) -> None:
        repo_root = build_fixture_repo()
        result = collect_result(repo_root)
        self.assertTrue(result["ok"])
        self.assertEqual(result["missing_paths"], [])

    def test_collect_result_reports_missing_paths(self) -> None:
        repo_root = Path(tempfile.mkdtemp(prefix="lightpanda-issue11-saved-memory-preflight-missing-"))
        target = repo_root / TARGET_FILE
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            'BASE_REQUIRED_RESTORED_HELPER_FILES = (("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "fixture"),)\n',
            encoding="utf-8",
        )
        result = collect_result(repo_root)
        self.assertFalse(result["ok"])
        self.assertEqual(result["missing_paths"], list(REQUIRED_PATHS))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11SavedMemoryPreflightStagedSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_result(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
