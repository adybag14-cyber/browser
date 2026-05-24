#!/usr/bin/env python3

"""Check that the issue #3 helper-surface file lists stay aligned.

This helper compares the helper-surface path lists used by the restored-checkout
checker, the saved-Memory preflight, and the saved-browser-snapshot restore
helper. It lets future runs fail fast when one surface gains or loses a file
without the other recovery helpers being updated to match.
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


PYTHON_SOURCES: tuple[tuple[str, str, str], ...] = (
    (
        "scripts/check_issue3_restored_checkout.py",
        "HELPER_SURFACE_PATHS",
        "restored checkout helper surface",
    ),
    (
        "scripts/check_issue3_saved_memory_inputs.py",
        "REQUIRED_RESTORED_HELPER_FILES",
        "saved-Memory restored helper surface",
    ),
)

SHELL_SOURCE: tuple[str, str, str] = (
    "scripts/linux/restore_saved_browser_snapshot.sh",
    "HELPER_SURFACE_PATHS",
    "saved-browser restore helper surface",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #3 restored-checkout, saved-Memory, and "
            "restore-helper surfaces list the same helper files."
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
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def parse_python_path_list(path: Path, variable_name: str) -> list[str]:
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for node in tree.body:
        if isinstance(node, ast.Assign):
            targets = node.targets
        elif isinstance(node, ast.AnnAssign):
            targets = [node.target]
        else:
            continue
        if not any(isinstance(target, ast.Name) and target.id == variable_name for target in targets):
            continue
        literal = ast.literal_eval(node.value)
        paths: list[str] = []
        for entry in literal:
            if not isinstance(entry, tuple) or not entry:
                raise ValueError(f"{path}: {variable_name} contains an unexpected entry: {entry!r}")
            relative_path = entry[0]
            if not isinstance(relative_path, str):
                raise ValueError(f"{path}: {variable_name} entry is missing a string path: {entry!r}")
            paths.append(relative_path)
        return paths
    raise ValueError(f"{path}: could not find {variable_name}")


def parse_shell_path_list(path: Path, variable_name: str) -> list[str]:
    content = path.read_text(encoding="utf-8")
    pattern = re.compile(
        rf"declare -a {re.escape(variable_name)}=\(\n(?P<body>.*?)\n\)",
        re.DOTALL,
    )
    match = pattern.search(content)
    if match is None:
        raise ValueError(f"{path}: could not find {variable_name}")
    body = match.group("body")
    paths: list[str] = []
    for raw_line in body.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if not (line.startswith('"') and line.endswith('"')):
            raise ValueError(f"{path}: unexpected array entry format: {raw_line!r}")
        paths.append(line[1:-1])
    return paths


def unique_paths(paths: list[str]) -> list[str]:
    return sorted(dict.fromkeys(paths))


def collect_results(repo_root: Path) -> dict[str, object]:
    sources: dict[str, list[str]] = {}
    source_labels: dict[str, str] = {}

    for relative_path, variable_name, label in PYTHON_SOURCES:
        paths = parse_python_path_list(repo_root / relative_path, variable_name)
        sources[relative_path] = unique_paths(paths)
        source_labels[relative_path] = label

    shell_relative_path, shell_variable_name, shell_label = SHELL_SOURCE
    shell_paths = parse_shell_path_list(repo_root / shell_relative_path, shell_variable_name)
    sources[shell_relative_path] = unique_paths(shell_paths)
    source_labels[shell_relative_path] = shell_label

    expected_union = sorted({path for paths in sources.values() for path in paths})
    comparisons: list[dict[str, object]] = []
    ok = True

    for relative_path, paths in sources.items():
        missing = sorted(set(expected_union) - set(paths))
        extra = sorted(set(paths) - set(expected_union))
        source_ok = not missing and not extra
        ok = ok and source_ok
        comparisons.append(
            {
                "source": relative_path,
                "label": source_labels[relative_path],
                "count": len(paths),
                "missing_paths": missing,
                "extra_paths": extra,
                "ok": source_ok,
            }
        )

    pairwise_mismatches: list[dict[str, object]] = []
    source_items = list(sources.items())
    for index, (left_path, left_paths) in enumerate(source_items):
        for right_path, right_paths in source_items[index + 1 :]:
            left_only = sorted(set(left_paths) - set(right_paths))
            right_only = sorted(set(right_paths) - set(left_paths))
            pair_ok = not left_only and not right_only
            ok = ok and pair_ok
            pairwise_mismatches.append(
                {
                    "left_source": left_path,
                    "right_source": right_path,
                    "left_only": left_only,
                    "right_only": right_only,
                    "ok": pair_ok,
                }
            )

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "expected_union": expected_union,
        "comparisons": comparisons,
        "pairwise_mismatches": pairwise_mismatches,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Expected helper-surface paths: {len(result['expected_union'])}")
    print("Source parity:")
    for entry in result["comparisons"]:
        status = "PASS" if entry["ok"] else "FAIL"
        print(f"  [{status}] {entry['source']} ({entry['label']})")
        print(f"         path count: {entry['count']}")
        if entry["missing_paths"]:
            print("         missing: " + ", ".join(entry["missing_paths"]))
        if entry["extra_paths"]:
            print("         extra: " + ", ".join(entry["extra_paths"]))
    if result["ok"]:
        print("\nIssue #3 helper-surface alignment check passed.")
        return
    print("\nIssue #3 helper-surface alignment check failed.", file=sys.stderr)
    print(
        "Suggested next step: update the drifted helper surface so the restored-checkout, "
        "saved-Memory, and restore-helper routes stay in sync.",
        file=sys.stderr,
    )


class HelperSurfaceAlignmentTests(unittest.TestCase):
    def write_repo(self, root: Path, *, saved_memory_paths: list[str]) -> Path:
        repo_root = root / "browser"
        (repo_root / "scripts/linux").mkdir(parents=True)
        (repo_root / "scripts").mkdir(exist_ok=True)

        restored_content = textwrap.dedent(
            """
            HELPER_SURFACE_PATHS = (
                ("docs/A.md", "A"),
                ("docs/B.md", "B"),
            )
            """
        ).strip() + "\n"
        saved_memory_lines = "\n".join(
            f'        ("{path}", "label"),' for path in saved_memory_paths
        )
        saved_memory_content = textwrap.dedent(
            f"""
            REQUIRED_RESTORED_HELPER_FILES = (
            {saved_memory_lines}
            )
            """
        ).strip() + "\n"
        restore_content = textwrap.dedent(
            """
            declare -a HELPER_SURFACE_PATHS=(
                "docs/A.md"
                "docs/B.md"
            )
            """
        ).strip() + "\n"

        (repo_root / "scripts/check_issue3_restored_checkout.py").write_text(
            restored_content,
            encoding="utf-8",
        )
        (repo_root / "scripts/check_issue3_saved_memory_inputs.py").write_text(
            saved_memory_content,
            encoding="utf-8",
        )
        (repo_root / "scripts/linux/restore_saved_browser_snapshot.sh").write_text(
            restore_content,
            encoding="utf-8",
        )
        return repo_root

    def test_collect_results_passes_when_surfaces_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.write_repo(Path(tmpdir), saved_memory_paths=["docs/A.md", "docs/B.md"])
            result = collect_results(repo_root)
            self.assertTrue(result["ok"])

    def test_collect_results_fails_when_saved_memory_lags(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.write_repo(Path(tmpdir), saved_memory_paths=["docs/A.md"])
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            comparisons = {entry["source"]: entry for entry in result["comparisons"]}
            self.assertEqual(
                comparisons["scripts/check_issue3_saved_memory_inputs.py"]["missing_paths"],
                ["docs/B.md"],
            )


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(HelperSurfaceAlignmentTests)
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
    sys.exit(main())
