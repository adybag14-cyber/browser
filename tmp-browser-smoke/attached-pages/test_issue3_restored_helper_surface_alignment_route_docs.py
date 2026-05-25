from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import textwrap
import unittest


def load_alignment_helper(repo_root: Path):
    helper_path = repo_root / "scripts" / "check_issue3_restored_helper_surface_alignment.py"
    spec = importlib.util.spec_from_file_location("issue3_alignment_helper", helper_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class Issue3RestoredHelperSurfaceAlignmentRouteDocsTest(unittest.TestCase):
    def test_helper_flags_missing_route_docs_from_saved_memory_expectations(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            (repo_root / "scripts" / "linux").mkdir(parents=True, exist_ok=True)

            helper_source = textwrap.dedent(
                """\\
                import re

                RESTORE_LIST_RE = re.compile(r"declare -a HELPER_SURFACE_PATHS=\\((.*?)\\n\\)", re.S)
                PYTHON_LIST_RE = re.compile(
                    r"REQUIRED_RESTORED_HELPER_FILES:\\s*tuple\\[tuple\\[str, str\\], \\.\\.\\.\\]\\s*=\\s*\\((.*?)\\n\\)",
                    re.S,
                )
                SHELL_PATH_RE = re.compile(r'\"([^\"]+)\"')
                PYTHON_TUPLE_RE = re.compile(r'\\(\\s*\"([^\"]+)\"\\s*,\\s*\"([^\"]+)\"\\s*\\)')

                def parse_restore_paths(text: str) -> list[str]:
                    return SHELL_PATH_RE.findall(RESTORE_LIST_RE.search(text).group(1))

                def parse_required_paths(text: str) -> list[str]:
                    return [path for path, _label in PYTHON_TUPLE_RE.findall(PYTHON_LIST_RE.search(text).group(1))]

                def build_report(restore_paths: list[str], required_paths: list[str]) -> dict[str, object]:
                    restore_only = sorted(set(restore_paths) - set(required_paths))
                    required_only = sorted(set(required_paths) - set(restore_paths))
                    return {
                        "ok": not restore_only and not required_only,
                        "restore_only": restore_only,
                        "required_only": required_only,
                    }
                """
            )
            (repo_root / "scripts" / "check_issue3_restored_helper_surface_alignment.py").write_text(
                helper_source,
                encoding="utf-8",
            )

            helper = load_alignment_helper(repo_root)
            restore_text = textwrap.dedent(
                """\\
                declare -a HELPER_SURFACE_PATHS=(
                    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
                    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
                    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md"
                )
                """
            )
            required_text = textwrap.dedent(
                """\\
                REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide"),
                )
                """
            )

            report = helper.build_report(
                helper.parse_restore_paths(restore_text),
                helper.parse_required_paths(required_text),
            )

            self.assertFalse(report["ok"])
            self.assertEqual(
                report["restore_only"],
                [
                    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
                ],
            )
            self.assertEqual(report["required_only"], [])

    def test_helper_passes_when_route_docs_are_present_in_both_surfaces(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            (repo_root / "scripts").mkdir(parents=True, exist_ok=True)

            helper_source = textwrap.dedent(
                """\\
                def build_report(restore_paths: list[str], required_paths: list[str]) -> dict[str, object]:
                    restore_only = sorted(set(restore_paths) - set(required_paths))
                    required_only = sorted(set(required_paths) - set(restore_paths))
                    return {
                        "ok": not restore_only and not required_only,
                        "restore_only": restore_only,
                        "required_only": required_only,
                    }
                """
            )
            (repo_root / "scripts" / "check_issue3_restored_helper_surface_alignment.py").write_text(
                helper_source,
                encoding="utf-8",
            )

            helper = load_alignment_helper(repo_root)
            report = helper.build_report(
                [
                    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
                    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
                ],
                [
                    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
                    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
                ],
            )

            self.assertTrue(report["ok"])
            self.assertEqual(report["restore_only"], [])
            self.assertEqual(report["required_only"], [])


if __name__ == "__main__":
    unittest.main()
