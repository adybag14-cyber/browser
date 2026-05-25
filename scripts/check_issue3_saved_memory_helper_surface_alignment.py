#!/usr/bin/env python3

"""Compare the saved-memory and restored-checkout helper-surface contracts.

This helper exists for the Linux/WSL issue #3 re-entry lane. It makes one
specific mismatch visible: the saved-memory preflight can drift behind the
restored-checkout helper surface, which creates a false "ready" signal before a
run widens into larger restore or build-readiness steps.
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import tempfile
import textwrap
import unittest


DEFAULT_SAVED_MEMORY_VARIABLE = "REQUIRED_RESTORED_HELPER_FILES"
DEFAULT_RESTORED_CHECKOUT_VARIABLE = "HELPER_SURFACE_PATHS"


def load_tuple_path_map(path: Path, variable_name: str) -> dict[str, str]:
    module = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for node in module.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == variable_name:
                value = ast.literal_eval(node.value)
                return {relative_path: label for relative_path, label in value}
    raise ValueError(f"Could not find {variable_name} in {path}")


def build_alignment_report(
    saved_memory_paths: dict[str, str],
    restored_checkout_paths: dict[str, str],
) -> dict[str, object]:
    saved_memory_set = set(saved_memory_paths)
    restored_checkout_set = set(restored_checkout_paths)

    only_in_saved_memory = sorted(saved_memory_set - restored_checkout_set)
    only_in_restored_checkout = sorted(restored_checkout_set - saved_memory_set)
    shared_paths = sorted(saved_memory_set & restored_checkout_set)

    label_mismatches: list[dict[str, str]] = []
    for relative_path in shared_paths:
        saved_label = saved_memory_paths[relative_path]
        restored_label = restored_checkout_paths[relative_path]
        if saved_label == restored_label:
            continue
        label_mismatches.append(
            {
                "path": relative_path,
                "saved_memory_label": saved_label,
                "restored_checkout_label": restored_label,
            }
        )

    ok = not only_in_saved_memory and not only_in_restored_checkout and not label_mismatches
    return {
        "ok": ok,
        "saved_memory_count": len(saved_memory_paths),
        "restored_checkout_count": len(restored_checkout_paths),
        "shared_count": len(shared_paths),
        "only_in_saved_memory": only_in_saved_memory,
        "only_in_restored_checkout": only_in_restored_checkout,
        "label_mismatches": label_mismatches,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Compare the saved-memory and restored-checkout helper-surface contracts."
    )
    parser.add_argument(
        "--saved-memory-helper",
        default="scripts/check_issue3_saved_memory_inputs.py",
        help="Path to the saved-memory preflight helper",
    )
    parser.add_argument(
        "--saved-memory-variable",
        default=DEFAULT_SAVED_MEMORY_VARIABLE,
        help="Tuple variable name to read from the saved-memory helper",
    )
    parser.add_argument(
        "--restored-checkout-helper",
        default="scripts/check_issue3_restored_checkout.py",
        help="Path to the restored-checkout helper",
    )
    parser.add_argument(
        "--restored-checkout-variable",
        default=DEFAULT_RESTORED_CHECKOUT_VARIABLE,
        help="Tuple variable name to read from the restored-checkout helper",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


def emit_text(
    report: dict[str, object],
    *,
    saved_memory_helper: Path,
    saved_memory_variable: str,
    restored_checkout_helper: Path,
    restored_checkout_variable: str,
) -> None:
    print("Issue #3 saved-memory helper-surface alignment")
    print()
    print(f"Saved-memory helper:      {saved_memory_helper}")
    print(f"Saved-memory variable:    {saved_memory_variable}")
    print(f"Restored-checkout helper: {restored_checkout_helper}")
    print(f"Restored variable:        {restored_checkout_variable}")
    print(f"Saved-memory paths:       {report['saved_memory_count']}")
    print(f"Restored-checkout paths:  {report['restored_checkout_count']}")
    print(f"Shared paths:             {report['shared_count']}")

    def print_section(title: str, values: list[str]) -> None:
        print()
        print(title)
        if not values:
            print("  - none")
            return
        for value in values:
            print(f"  - {value}")

    print_section("Only in saved-memory helper:", report["only_in_saved_memory"])
    print_section("Only in restored-checkout helper:", report["only_in_restored_checkout"])

    print()
    print("Label mismatches:")
    if not report["label_mismatches"]:
        print("  - none")
    else:
        for mismatch in report["label_mismatches"]:
            print(f"  - {mismatch['path']}")
            print(f"    saved-memory: {mismatch['saved_memory_label']}")
            print(f"    restored-checkout: {mismatch['restored_checkout_label']}")


class AlignmentHelperTests(unittest.TestCase):
    def test_build_alignment_report_flags_missing_paths(self) -> None:
        report = build_alignment_report(
            {
                "docs/a.md": "A",
                "docs/b.md": "B",
            },
            {
                "docs/b.md": "B",
                "docs/c.md": "C",
            },
        )

        self.assertFalse(report["ok"])
        self.assertEqual(report["only_in_saved_memory"], ["docs/a.md"])
        self.assertEqual(report["only_in_restored_checkout"], ["docs/c.md"])
        self.assertEqual(report["label_mismatches"], [])

    def test_build_alignment_report_flags_label_mismatches(self) -> None:
        report = build_alignment_report(
            {"docs/a.md": "saved label"},
            {"docs/a.md": "restored label"},
        )

        self.assertFalse(report["ok"])
        self.assertEqual(report["only_in_saved_memory"], [])
        self.assertEqual(report["only_in_restored_checkout"], [])
        self.assertEqual(
            report["label_mismatches"],
            [
                {
                    "path": "docs/a.md",
                    "saved_memory_label": "saved label",
                    "restored_checkout_label": "restored label",
                }
            ],
        )

    def test_load_tuple_path_map_reads_literal_tuples(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_path = Path(tmpdir) / "helper.py"
            helper_path.write_text(
                textwrap.dedent(
                    """
                    REQUIRED_PATHS = (
                        ("docs/a.md", "A"),
                        ("docs/b.md", "B"),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )

            result = load_tuple_path_map(helper_path, "REQUIRED_PATHS")
            self.assertEqual(result, {"docs/a.md": "A", "docs/b.md": "B"})

    def test_load_tuple_path_map_raises_for_missing_variable(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_path = Path(tmpdir) / "helper.py"
            helper_path.write_text("OTHER = ()\n", encoding="utf-8")

            with self.assertRaises(ValueError):
                load_tuple_path_map(helper_path, "REQUIRED_PATHS")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(AlignmentHelperTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    saved_memory_helper = Path(args.saved_memory_helper).resolve()
    restored_checkout_helper = Path(args.restored_checkout_helper).resolve()
    saved_memory_paths = load_tuple_path_map(saved_memory_helper, args.saved_memory_variable)
    restored_checkout_paths = load_tuple_path_map(
        restored_checkout_helper,
        args.restored_checkout_variable,
    )
    report = build_alignment_report(saved_memory_paths, restored_checkout_paths)
    if args.json:
        print(
            json.dumps(
                {
                    "profile": "issue3-saved-memory-helper-surface-alignment",
                    "saved_memory_helper": str(saved_memory_helper),
                    "saved_memory_variable": args.saved_memory_variable,
                    "restored_checkout_helper": str(restored_checkout_helper),
                    "restored_checkout_variable": args.restored_checkout_variable,
                    **report,
                },
                indent=2,
            )
        )
    else:
        emit_text(
            report,
            saved_memory_helper=saved_memory_helper,
            saved_memory_variable=args.saved_memory_variable,
            restored_checkout_helper=restored_checkout_helper,
            restored_checkout_variable=args.restored_checkout_variable,
        )
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())