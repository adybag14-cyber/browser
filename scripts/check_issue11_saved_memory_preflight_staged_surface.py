#!/usr/bin/env python3

"""Check the issue #11 saved-memory preflight staged-surface contract.

This helper is intentionally narrow. It verifies that the saved-memory
preflight helper, its route note, and its route printer keep the staged Zig and
Rust toolchain follow-ups plus the nested-workspace rerun helper visible on one
explicit surface.
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import tempfile
import unittest


FILES = {
    "saved_memory_helper": "scripts/check_issue3_saved_memory_inputs.py",
    "route_note": "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
    "route_printer": "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
}

REQUIRED_BASE_PATHS = (
    "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
    "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh",
    "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
    "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
)

REQUIRED_ROUTE_NOTE_SNIPPETS = REQUIRED_BASE_PATHS

REQUIRED_ROUTE_PRINTER_SNIPPETS = (
    "nested_workspace_saved_memory_preflight",
    "quick_nested_workspace_saved_memory_preflight",
    "Issue #11 nested-workspace saved-Memory preflight:",
    "Quick nested-workspace saved-Memory presence check:",
    "check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
    "show_issue3_staged_zig_toolchain_candidates_route.sh",
    "check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
    "show_issue3_staged_rust_toolchain_candidates_route.sh",
)

FIXTURE_SAVED_MEMORY_HELPER = """
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

FIXTURE_ROUTE_NOTE = """
# Fixture saved-memory route

- docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md
- docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md
- scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh
- scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh
- scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh
- scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh
- scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh
"""

FIXTURE_ROUTE_PRINTER = """
nested_workspace_saved_memory_preflight
quick_nested_workspace_saved_memory_preflight
Issue #11 nested-workspace saved-Memory preflight:
Quick nested-workspace saved-Memory presence check:
check_issue3_staged_zig_toolchain_candidates_route_surface.sh
show_issue3_staged_zig_toolchain_candidates_route.sh
check_issue3_staged_rust_toolchain_candidates_route_surface.sh
show_issue3_staged_rust_toolchain_candidates_route.sh
"""


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #11 saved-memory preflight keeps the "
            "staged toolchain and nested-workspace follow-ups visible."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of a line-oriented summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused self-tests and exit",
    )
    return parser


def extract_base_required_helper_paths(source_text: str) -> set[str]:
    try:
        module = ast.parse(source_text)
    except SyntaxError:
        return set()

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

    return set()


def load_repo_texts(repo_root: Path) -> dict[str, str]:
    return {
        key: (repo_root / relative_path).read_text(encoding="utf-8")
        for key, relative_path in FILES.items()
    }


def collect_report(repo_root: Path) -> dict[str, object]:
    texts = load_repo_texts(repo_root)
    helper_paths = extract_base_required_helper_paths(texts["saved_memory_helper"])

    checks: list[dict[str, object]] = []
    missing: list[str] = []

    for relative_path in REQUIRED_BASE_PATHS:
        ok = relative_path in helper_paths
        if not ok:
            missing.append(relative_path)
        checks.append(
            {
                "surface": "saved_memory_helper",
                "requirement": relative_path,
                "ok": ok,
            }
        )

    for snippet in REQUIRED_ROUTE_NOTE_SNIPPETS:
        ok = snippet in texts["route_note"]
        if not ok:
            missing.append(f"route_note:{snippet}")
        checks.append(
            {
                "surface": "route_note",
                "requirement": snippet,
                "ok": ok,
            }
        )

    for snippet in REQUIRED_ROUTE_PRINTER_SNIPPETS:
        ok = snippet in texts["route_printer"]
        if not ok:
            missing.append(f"route_printer:{snippet}")
        checks.append(
            {
                "surface": "route_printer",
                "requirement": snippet,
                "ok": ok,
            }
        )

    return {
        "ok": not missing,
        "repo_root": str(repo_root),
        "checks": checks,
        "missing": missing,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    for check in report["checks"]:
        status = "PASS" if check["ok"] else "FAIL"
        print(f"[{status}] {check['surface']}: {check['requirement']}")
    if report["ok"]:
        print("Issue #11 saved-memory staged-surface check passed.")
        return
    print("Issue #11 saved-memory staged-surface check failed.")


def build_fixture_repo() -> Path:
    root = Path(
        tempfile.mkdtemp(prefix="lightpanda-issue11-saved-memory-preflight-")
    )
    for key, relative_path in FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        if key == "saved_memory_helper":
            target.write_text(FIXTURE_SAVED_MEMORY_HELPER.lstrip("\n"), encoding="utf-8")
        elif key == "route_note":
            target.write_text(FIXTURE_ROUTE_NOTE.lstrip("\n"), encoding="utf-8")
        else:
            target.write_text(FIXTURE_ROUTE_PRINTER.lstrip("\n"), encoding="utf-8")
    return root


class Issue11SavedMemoryPreflightStagedSurfaceTests(unittest.TestCase):
    def test_fixture_passes(self) -> None:
        fixture_root = build_fixture_repo()
        report = collect_report(fixture_root)
        self.assertTrue(report["ok"])
        self.assertEqual(report["missing"], [])

    def test_missing_saved_memory_helper_entry_fails(self) -> None:
        fixture_root = build_fixture_repo()
        helper = fixture_root / FILES["saved_memory_helper"]
        helper.write_text(
            FIXTURE_SAVED_MEMORY_HELPER.replace(
                '    ("scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh", "fixture"),\n',
                "",
            ).lstrip("\n"),
            encoding="utf-8",
        )
        report = collect_report(fixture_root)
        self.assertFalse(report["ok"])
        self.assertIn(
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            report["missing"],
        )

    def test_missing_route_printer_snippet_fails(self) -> None:
        fixture_root = build_fixture_repo()
        route_printer = fixture_root / FILES["route_printer"]
        route_printer.write_text(
            FIXTURE_ROUTE_PRINTER.replace(
                "Quick nested-workspace saved-Memory presence check:\n",
                "",
            ).lstrip("\n"),
            encoding="utf-8",
        )
        report = collect_report(fixture_root)
        self.assertFalse(report["ok"])
        self.assertIn(
            "route_printer:Quick nested-workspace saved-Memory presence check:",
            report["missing"],
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11SavedMemoryPreflightStagedSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    report = collect_report(Path(args.repo_root).resolve())
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
