#!/usr/bin/env python3

"""Check that the issue #3 restore helper-surface lists stay aligned."""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


RESTORE_SCRIPT_RELATIVE_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
RESTORED_CHECKOUT_RELATIVE_PATH = "scripts/check_issue3_restored_checkout.py"
SAVED_MEMORY_INPUTS_RELATIVE_PATH = "scripts/check_issue3_saved_memory_inputs.py"

RESTORE_ARRAY_NAME = "HELPER_SURFACE_PATHS"
RESTORED_CHECKOUT_CONSTANT = "HELPER_SURFACE_PATHS"
SAVED_MEMORY_INPUTS_CONSTANT = "REQUIRED_RESTORED_HELPER_FILES"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #3 saved-browser restore helper surface stays "
            "aligned across the restore script and its Python follow-up helpers."
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


def parse_bash_array(script_text: str, array_name: str) -> list[str]:
    pattern = re.compile(
        rf"declare\s+-a\s+{re.escape(array_name)}=\((?P<body>.*?)\)",
        re.DOTALL,
    )
    match = pattern.search(script_text)
    if match is None:
        raise ValueError(f"could not find bash array {array_name!r}")
    body = match.group("body")
    return re.findall(r'"([^"]+)"', body)


def _extract_string_tuple_paths(node: ast.AST, constant_name: str) -> list[str]:
    if not isinstance(node, (ast.Tuple, ast.List)):
        raise ValueError(f"{constant_name} is not a tuple/list literal")

    paths: list[str] = []
    for entry in node.elts:
        if not isinstance(entry, ast.Tuple) or len(entry.elts) < 1:
            raise ValueError(f"{constant_name} contains a non-tuple entry")
        first = entry.elts[0]
        if not isinstance(first, ast.Constant) or not isinstance(first.value, str):
            raise ValueError(f"{constant_name} contains a non-string path entry")
        paths.append(first.value)
    return paths


def parse_python_path_constant(script_text: str, constant_name: str) -> list[str]:
    module = ast.parse(script_text)
    for node in module.body:
        value: ast.AST | None = None
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == constant_name:
                    value = node.value
                    break
        elif isinstance(node, ast.AnnAssign):
            if isinstance(node.target, ast.Name) and node.target.id == constant_name:
                value = node.value
        if value is None:
            continue

        if isinstance(value, ast.Call) and isinstance(value.func, ast.Name) and value.func.id == "tuple":
            if len(value.args) != 1:
                raise ValueError(f"{constant_name} tuple() wrapper has unexpected arguments")
            value = value.args[0]
        return _extract_string_tuple_paths(value, constant_name)

    raise ValueError(f"could not find python constant {constant_name!r}")


def load_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise FileNotFoundError(f"missing required helper-surface file: {path}") from exc


def describe_alignment(source_paths: list[str], candidate_paths: list[str]) -> dict[str, object]:
    source_set = set(source_paths)
    candidate_set = set(candidate_paths)
    return {
        "ok": source_set == candidate_set,
        "missing": sorted(source_set - candidate_set),
        "extra": sorted(candidate_set - source_set),
    }


def collect_results(repo_root: Path) -> dict[str, object]:
    restore_script_path = repo_root / RESTORE_SCRIPT_RELATIVE_PATH
    restored_checkout_path = repo_root / RESTORED_CHECKOUT_RELATIVE_PATH
    saved_memory_inputs_path = repo_root / SAVED_MEMORY_INPUTS_RELATIVE_PATH

    restore_paths = parse_bash_array(load_text(restore_script_path), RESTORE_ARRAY_NAME)
    restored_checkout_paths = parse_python_path_constant(
        load_text(restored_checkout_path),
        RESTORED_CHECKOUT_CONSTANT,
    )
    saved_memory_inputs_paths = parse_python_path_constant(
        load_text(saved_memory_inputs_path),
        SAVED_MEMORY_INPUTS_CONSTANT,
    )

    restored_checkout_alignment = describe_alignment(restore_paths, restored_checkout_paths)
    saved_memory_inputs_alignment = describe_alignment(restore_paths, saved_memory_inputs_paths)

    return {
        "ok": restored_checkout_alignment["ok"] and saved_memory_inputs_alignment["ok"],
        "repo_root": str(repo_root),
        "restore_script": str(restore_script_path),
        "restored_checkout_helper": str(restored_checkout_path),
        "saved_memory_inputs_helper": str(saved_memory_inputs_path),
        "restore_surface_count": len(restore_paths),
        "restore_surface_paths": restore_paths,
        "restored_checkout_alignment": restored_checkout_alignment,
        "saved_memory_inputs_alignment": saved_memory_inputs_alignment,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Restore source: {result['restore_script']}")
    print(f"Restored-checkout helper: {result['restored_checkout_helper']}")
    print(f"Saved-memory helper: {result['saved_memory_inputs_helper']}")
    print(f"Restore helper-surface entries: {result['restore_surface_count']}")

    for label, key in (
        ("Restored-checkout helper", "restored_checkout_alignment"),
        ("Saved-memory helper", "saved_memory_inputs_alignment"),
    ):
        alignment = result[key]
        status = "PASS" if alignment["ok"] else "FAIL"
        print(f"{label}: [{status}]")
        if alignment["missing"]:
            print("  missing paths:")
            for path in alignment["missing"]:
                print(f"    - {path}")
        if alignment["extra"]:
            print("  extra paths:")
            for path in alignment["extra"]:
                print(f"    - {path}")
        if not alignment["missing"] and not alignment["extra"]:
            print("  exact match")

    if result["ok"]:
        print("\nRestore helper-surface contract check passed.")
        return

    print("\nRestore helper-surface contract check failed.", file=sys.stderr)
    print(
        "Suggested next step: align the Python helper-surface constants with "
        "scripts/linux/restore_saved_browser_snapshot.sh before trusting the "
        "saved-browser restore route.",
        file=sys.stderr,
    )


class RestoreHelperSurfaceContractTests(unittest.TestCase):
    def write_fixture(
        self,
        repo_root: Path,
        *,
        restore_paths: list[str],
        restored_checkout_paths: list[str],
        saved_memory_inputs_paths: list[str],
    ) -> None:
        restore_script = repo_root / RESTORE_SCRIPT_RELATIVE_PATH
        restore_script.parent.mkdir(parents=True, exist_ok=True)
        restore_script.write_text(
            "#!/usr/bin/env bash\n"
            f"declare -a {RESTORE_ARRAY_NAME}=(\n"
            f"{''.join(f'    \"{path}\"\n' for path in restore_paths)})\n",
            encoding="utf-8",
        )

        restored_checkout = repo_root / RESTORED_CHECKOUT_RELATIVE_PATH
        restored_checkout.parent.mkdir(parents=True, exist_ok=True)
        restored_checkout.write_text(
            f"{RESTORED_CHECKOUT_CONSTANT} = (\n"
            f"{''.join(f'    (\"{path}\", \"label\"),\n' for path in restored_checkout_paths)})\n",
            encoding="utf-8",
        )

        saved_memory_inputs = repo_root / SAVED_MEMORY_INPUTS_RELATIVE_PATH
        saved_memory_inputs.parent.mkdir(parents=True, exist_ok=True)
        saved_memory_inputs.write_text(
            f"{SAVED_MEMORY_INPUTS_CONSTANT}: tuple[tuple[str, str], ...] = (\n"
            f"{''.join(f'    (\"{path}\", \"label\"),\n' for path in saved_memory_inputs_paths)})\n",
            encoding="utf-8",
        )

    def test_collect_results_passes_when_surfaces_match(self) -> None:
        paths = [
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_fixture(
                repo_root,
                restore_paths=paths,
                restored_checkout_paths=paths,
                saved_memory_inputs_paths=paths,
            )
            result = collect_results(repo_root)

        self.assertTrue(result["ok"])
        self.assertEqual(result["restore_surface_count"], 3)
        self.assertEqual(result["saved_memory_inputs_alignment"]["missing"], [])

    def test_collect_results_reports_saved_memory_gap(self) -> None:
        restore_paths = [
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_fixture(
                repo_root,
                restore_paths=restore_paths,
                restored_checkout_paths=restore_paths,
                saved_memory_inputs_paths=[],
            )
            result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertEqual(
            result["saved_memory_inputs_alignment"]["missing"],
            sorted(restore_paths),
        )
        self.assertEqual(result["restored_checkout_alignment"]["missing"], [])

    def test_collect_results_reports_extra_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_fixture(
                repo_root,
                restore_paths=["docs/A.md"],
                restored_checkout_paths=["docs/A.md", "docs/EXTRA.md"],
                saved_memory_inputs_paths=["docs/A.md"],
            )
            result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertEqual(
            result["restored_checkout_alignment"]["extra"],
            ["docs/EXTRA.md"],
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoreHelperSurfaceContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps({"profile": "issue3-restore-helper-surface-contract", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
