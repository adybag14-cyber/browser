#!/usr/bin/env python3

"""Check that the saved-memory helper surface tracks the live restore helper.

This guard compares the hard-coded restored-helper file list in
`scripts/check_issue3_saved_memory_inputs.py` against the current
`HELPER_SURFACE_PATHS` list in `scripts/linux/restore_saved_browser_snapshot.sh`.
It fails fast when the saved-memory preflight is missing newer helper-surface
paths that the restore route now mirrors into restored checkouts.
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


ISSUE_LABEL = "Issue #11 saved-memory helper-surface contract"
JSON_PROFILE = "issue11-saved-memory-helper-surface-contract"
RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
SAVED_MEMORY_INPUTS_PATH = "scripts/check_issue3_saved_memory_inputs.py"
RESTORE_SURFACE_LINE_RE = re.compile(r'^\s*"([^"]+)"\s*$')


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the saved-memory preflight helper surface keeps up with "
            "the current restore helper surface for issue #11 re-entry work."
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
        help="Emit JSON instead of the human-readable report",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


def extract_restore_helper_paths(script_text: str) -> list[str]:
    marker = "declare -a HELPER_SURFACE_PATHS=("
    in_block = False
    paths: list[str] = []

    for line in script_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue

        if stripped == ")":
            break

        match = RESTORE_SURFACE_LINE_RE.match(line)
        if match is not None:
            paths.append(match.group(1))

    if not in_block:
        raise ValueError(
            f"Could not find HELPER_SURFACE_PATHS in {RESTORE_HELPER_PATH}"
        )
    if not paths:
        raise ValueError(f"HELPER_SURFACE_PATHS in {RESTORE_HELPER_PATH} is empty")
    return paths


def extract_saved_memory_required_paths(script_text: str) -> list[str]:
    module = ast.parse(script_text, filename=SAVED_MEMORY_INPUTS_PATH)
    for node in module.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == "REQUIRED_RESTORED_HELPER_FILES":
                return _extract_tuple_pair_paths(node.value)
    raise ValueError(
        f"Could not find REQUIRED_RESTORED_HELPER_FILES in {SAVED_MEMORY_INPUTS_PATH}"
    )


def _extract_tuple_pair_paths(value: ast.AST) -> list[str]:
    if not isinstance(value, (ast.Tuple, ast.List)):
        raise ValueError("Required helper list must be a tuple or list literal")

    paths: list[str] = []
    for element in value.elts:
        if not isinstance(element, ast.Tuple) or len(element.elts) < 1:
            raise ValueError("Required helper entries must be tuples")
        path_node = element.elts[0]
        if not isinstance(path_node, ast.Constant) or not isinstance(path_node.value, str):
            raise ValueError("Required helper paths must be string literals")
        paths.append(path_node.value)

    if not paths:
        raise ValueError("Required helper path list is empty")
    return paths


def collect_contract_report(repo_root: Path) -> dict[str, object]:
    restore_helper_path = repo_root / RESTORE_HELPER_PATH
    saved_memory_inputs_path = repo_root / SAVED_MEMORY_INPUTS_PATH

    restore_exists = restore_helper_path.is_file()
    saved_memory_exists = saved_memory_inputs_path.is_file()
    if not restore_exists or not saved_memory_exists:
        return {
            "ok": False,
            "repo_root": str(repo_root),
            "restore_helper_path": str(restore_helper_path),
            "saved_memory_inputs_path": str(saved_memory_inputs_path),
            "restore_helper_exists": restore_exists,
            "saved_memory_inputs_exists": saved_memory_exists,
            "restore_helper_count": 0,
            "saved_memory_required_count": 0,
            "missing_in_saved_memory_inputs": [],
            "extra_in_saved_memory_inputs": [],
        }

    restore_helper_paths = extract_restore_helper_paths(
        restore_helper_path.read_text(encoding="utf-8")
    )
    saved_memory_required_paths = extract_saved_memory_required_paths(
        saved_memory_inputs_path.read_text(encoding="utf-8")
    )

    restore_set = set(restore_helper_paths)
    saved_memory_set = set(saved_memory_required_paths)

    missing_in_saved_memory_inputs = sorted(restore_set - saved_memory_set)
    extra_in_saved_memory_inputs = sorted(saved_memory_set - restore_set)

    return {
        "ok": not missing_in_saved_memory_inputs,
        "repo_root": str(repo_root),
        "restore_helper_path": str(restore_helper_path),
        "saved_memory_inputs_path": str(saved_memory_inputs_path),
        "restore_helper_exists": True,
        "saved_memory_inputs_exists": True,
        "restore_helper_count": len(restore_helper_paths),
        "saved_memory_required_count": len(saved_memory_required_paths),
        "missing_in_saved_memory_inputs": missing_in_saved_memory_inputs,
        "extra_in_saved_memory_inputs": extra_in_saved_memory_inputs,
    }


def serialize_report(report: dict[str, object]) -> dict[str, object]:
    return {"profile": JSON_PROFILE, "issue": ISSUE_LABEL, **report}


def emit_text(report: dict[str, object]) -> None:
    print(ISSUE_LABEL)
    print()
    print(f"Repo root: {report['repo_root']}")
    print(
        "Restore helper paths: "
        f"{report['restore_helper_count']} | saved-memory required paths: "
        f"{report['saved_memory_required_count']}"
    )
    print()

    if not report["restore_helper_exists"]:
        print(f"[FAIL] missing {RESTORE_HELPER_PATH}")
    if not report["saved_memory_inputs_exists"]:
        print(f"[FAIL] missing {SAVED_MEMORY_INPUTS_PATH}")

    for relative_path in report["missing_in_saved_memory_inputs"]:
        print(f"[FAIL] saved-memory preflight is missing {relative_path}")

    for relative_path in report["extra_in_saved_memory_inputs"]:
        print(f"[INFO] saved-memory preflight tracks extra path {relative_path}")

    if report["ok"]:
        print("Saved-memory helper-surface contract passed.")
        return

    print()
    print("Suggested next step:")
    print(
        "  Update scripts/check_issue3_saved_memory_inputs.py so its restored "
        "helper-surface list covers every path mirrored by the restore helper."
    )


def _write_repo_files(repo_root: Path, *, restore_paths: list[str], required_paths: list[str]) -> None:
    restore_helper = repo_root / RESTORE_HELPER_PATH
    restore_helper.parent.mkdir(parents=True, exist_ok=True)
    restore_helper.write_text(
        "\n".join(
            [
                "#!/usr/bin/env bash",
                "",
                "declare -a HELPER_SURFACE_PATHS=(",
                *[f'    \"{path}\"' for path in restore_paths],
                ")",
                "",
            ]
        ),
        encoding="utf-8",
    )

    required_literal = "\n".join(
        f'    (\"{path}\", \"label\"),' for path in required_paths
    )
    saved_memory_inputs = repo_root / SAVED_MEMORY_INPUTS_PATH
    saved_memory_inputs.parent.mkdir(parents=True, exist_ok=True)
    saved_memory_inputs.write_text(
        "REQUIRED_RESTORED_HELPER_FILES = (\n"
        f"{required_literal}\n"
        ")\n",
        encoding="utf-8",
    )


class SavedMemoryHelperSurfaceContractTests(unittest.TestCase):
    def test_extract_restore_helper_paths_parses_array(self) -> None:
        script_text = textwrap.dedent(
            """\
            #!/usr/bin/env bash

            declare -a HELPER_SURFACE_PATHS=(
                \"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md\"
                \"scripts/check_issue3_workspace_context.py\"
            )
            """
        )

        self.assertEqual(
            extract_restore_helper_paths(script_text),
            [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_workspace_context.py",
            ],
        )

    def test_extract_saved_memory_required_paths_parses_tuple(self) -> None:
        script_text = textwrap.dedent(
            """\
            REQUIRED_RESTORED_HELPER_FILES = (
                (\"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md\", \"tracker\"),
                (\"scripts/check_issue3_workspace_context.py\", \"workspace\"),
            )
            """
        )

        self.assertEqual(
            extract_saved_memory_required_paths(script_text),
            [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_workspace_context.py",
            ],
        )

    def test_collect_contract_report_passes_when_saved_memory_covers_restore_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            paths = [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_workspace_context.py",
                "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
            ]
            _write_repo_files(repo_root, restore_paths=paths, required_paths=paths)

            report = collect_contract_report(repo_root)

            self.assertTrue(report["ok"])
            self.assertEqual(report["missing_in_saved_memory_inputs"], [])

    def test_collect_contract_report_flags_missing_restore_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            restore_paths = [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_workspace_context.py",
                "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
            ]
            required_paths = [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_workspace_context.py",
            ]
            _write_repo_files(
                repo_root,
                restore_paths=restore_paths,
                required_paths=required_paths,
            )

            report = collect_contract_report(repo_root)

            self.assertFalse(report["ok"])
            self.assertEqual(
                report["missing_in_saved_memory_inputs"],
                ["scripts/linux/show_issue3_saved_rust_build_readiness_route.sh"],
            )

    def test_collect_contract_report_keeps_extra_saved_memory_paths_informational(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            restore_paths = [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_workspace_context.py",
            ]
            required_paths = restore_paths + [
                "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            ]
            _write_repo_files(
                repo_root,
                restore_paths=restore_paths,
                required_paths=required_paths,
            )

            report = collect_contract_report(repo_root)

            self.assertTrue(report["ok"])
            self.assertEqual(report["missing_in_saved_memory_inputs"], [])
            self.assertEqual(
                report["extra_in_saved_memory_inputs"],
                ["docs/ISSUE3_RUNTIME_REENTRY_GATES.md"],
            )

    def test_collect_contract_report_flags_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            report = collect_contract_report(repo_root)

            self.assertFalse(report["ok"])
            self.assertFalse(report["restore_helper_exists"])
            self.assertFalse(report["saved_memory_inputs_exists"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedMemoryHelperSurfaceContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    report = collect_contract_report(repo_root)

    if args.json:
        print(json.dumps(serialize_report(report), indent=2))
    else:
        emit_text(report)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
