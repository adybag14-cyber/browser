#!/usr/bin/env python3

"""Check that the saved-snapshot helper surface stays in sync.

This helper compares the helper-surface path inventory used by the saved
Memory-input checker and the Linux restore helper. Those two files must stay
aligned so `--sync-helper-surface` restores the exact same branch-local helper
paths that later preflights expect to exist inside the restored checkout.
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import re
import sys
import tempfile
import textwrap
import unittest


PYTHON_CONTRACT_NAME = "REQUIRED_RESTORED_HELPER_FILES"
SHELL_CONTRACT_NAME = "HELPER_SURFACE_PATHS"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the saved-browser-snapshot restore helper and the "
            "saved-memory preflight agree on the issue #3 helper surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--memory-checker",
        default=None,
        help=(
            "Optional explicit path to scripts/check_issue3_saved_memory_inputs.py "
            "(default: <repo-root>/scripts/check_issue3_saved_memory_inputs.py)"
        ),
    )
    parser.add_argument(
        "--restore-helper",
        default=None,
        help=(
            "Optional explicit path to scripts/linux/restore_saved_browser_snapshot.sh "
            "(default: <repo-root>/scripts/linux/restore_saved_browser_snapshot.sh)"
        ),
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


def resolve_paths(
    repo_root: Path,
    memory_checker: Path | None,
    restore_helper: Path | None,
) -> tuple[Path, Path]:
    if memory_checker is None:
        memory_checker = repo_root / "scripts/check_issue3_saved_memory_inputs.py"
    if restore_helper is None:
        restore_helper = repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
    return memory_checker.resolve(), restore_helper.resolve()


def extract_python_contract(path: Path) -> list[str]:
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == PYTHON_CONTRACT_NAME:
                value = ast.literal_eval(node.value)
                return [entry[0] for entry in value]
    raise ValueError(
        f"Could not find {PYTHON_CONTRACT_NAME} in {path}"
    )


def extract_shell_contract(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(
        rf"declare -a {re.escape(SHELL_CONTRACT_NAME)}=\((?P<body>.*?)\n\)",
        re.DOTALL,
    )
    match = pattern.search(text)
    if match is None:
        raise ValueError(f"Could not find {SHELL_CONTRACT_NAME} in {path}")
    body = match.group("body")
    entries = re.findall(r'"([^"\n]+)"', body)
    return entries


def compare_contracts(
    python_paths: list[str],
    shell_paths: list[str],
) -> dict[str, object]:
    python_set = set(python_paths)
    shell_set = set(shell_paths)
    python_only = sorted(python_set - shell_set)
    shell_only = sorted(shell_set - python_set)
    shared = [path for path in python_paths if path in shell_set]
    order_matches = [path for path in shell_paths if path in python_set] == shared
    ok = not python_only and not shell_only and order_matches
    return {
        "ok": ok,
        "python_count": len(python_paths),
        "shell_count": len(shell_paths),
        "python_only": python_only,
        "shell_only": shell_only,
        "order_matches": order_matches,
        "python_paths": python_paths,
        "shell_paths": shell_paths,
    }


def collect_results(memory_checker: Path, restore_helper: Path) -> dict[str, object]:
    python_paths = extract_python_contract(memory_checker)
    shell_paths = extract_shell_contract(restore_helper)
    comparison = compare_contracts(python_paths, shell_paths)
    comparison.update(
        {
            "memory_checker": str(memory_checker),
            "restore_helper": str(restore_helper),
        }
    )
    return comparison


def emit_text(result: dict[str, object]) -> None:
    status = "PASS" if result["ok"] else "FAIL"
    print(f"Restore helper surface sync: {status}")
    print(f"Saved-memory checker: {result['memory_checker']}")
    print(f"Restore helper: {result['restore_helper']}")
    print(
        f"Shared contract counts: python={result['python_count']} shell={result['shell_count']}"
    )
    if result["python_only"]:
        print("Paths missing from restore helper:")
        for path in result["python_only"]:
            print(f"  - {path}")
    if result["shell_only"]:
        print("Paths missing from saved-memory checker:")
        for path in result["shell_only"]:
            print(f"  - {path}")
    if not result["order_matches"]:
        print("Order mismatch: shared paths appear in a different order.")
    if result["ok"]:
        print(
            "The restore helper and saved-memory checker agree on the synced helper surface."
        )
    else:
        print(
            "Suggested next step: update the drifting helper-surface list before trusting "
            "--sync-helper-surface or restored-checkout preflights.",
            file=sys.stderr,
        )


class RestoreHelperSurfaceSyncTests(unittest.TestCase):
    def test_extract_python_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "check_issue3_saved_memory_inputs.py"
            path.write_text(
                textwrap.dedent(
                    """
                    REQUIRED_RESTORED_HELPER_FILES = (
                        ("docs/A.md", "A"),
                        ("scripts/B.py", "B"),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            self.assertEqual(
                extract_python_contract(path),
                ["docs/A.md", "scripts/B.py"],
            )

    def test_extract_shell_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "restore_saved_browser_snapshot.sh"
            path.write_text(
                textwrap.dedent(
                    """
                    declare -a HELPER_SURFACE_PATHS=(
                        "docs/A.md"
                        "scripts/B.py"
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            self.assertEqual(
                extract_shell_contract(path),
                ["docs/A.md", "scripts/B.py"],
            )

    def test_compare_contracts_passes_when_lists_match(self) -> None:
        result = compare_contracts(
            ["docs/A.md", "scripts/B.py"],
            ["docs/A.md", "scripts/B.py"],
        )
        self.assertTrue(result["ok"])
        self.assertTrue(result["order_matches"])
        self.assertEqual(result["python_only"], [])
        self.assertEqual(result["shell_only"], [])

    def test_compare_contracts_fails_when_paths_drift(self) -> None:
        result = compare_contracts(
            ["docs/A.md", "scripts/B.py"],
            ["docs/A.md", "scripts/C.py"],
        )
        self.assertFalse(result["ok"])
        self.assertEqual(result["python_only"], ["scripts/B.py"])
        self.assertEqual(result["shell_only"], ["scripts/C.py"])

    def test_compare_contracts_fails_when_order_drifts(self) -> None:
        result = compare_contracts(
            ["docs/A.md", "scripts/B.py"],
            ["scripts/B.py", "docs/A.md"],
        )
        self.assertFalse(result["ok"])
        self.assertFalse(result["order_matches"])


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoreHelperSurfaceSyncTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        print(
            f"RESTORE_HELPER_SURFACE_SYNC_SELF_TEST={'pass' if result.wasSuccessful() else 'fail'}"
        )
        print(
            f"RESTORE_HELPER_SURFACE_SYNC_SELF_TEST_CASE_COUNT={result.testsRun}"
        )
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_checker, restore_helper = resolve_paths(
        repo_root,
        Path(args.memory_checker).resolve() if args.memory_checker else None,
        Path(args.restore_helper).resolve() if args.restore_helper else None,
    )

    try:
        result = collect_results(memory_checker, restore_helper)
    except (OSError, ValueError, SyntaxError) as exc:
        error = {
            "ok": False,
            "error": str(exc),
            "memory_checker": str(memory_checker),
            "restore_helper": str(restore_helper),
        }
        if args.json:
            print(json.dumps(error, indent=2, sort_keys=True))
        else:
            print(f"Restore helper surface sync: FAIL", file=sys.stderr)
            print(str(exc), file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
