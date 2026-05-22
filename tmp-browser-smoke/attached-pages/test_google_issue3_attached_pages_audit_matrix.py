import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_attached_pages_audit_matrix as helper


def make_surface(
    *,
    name: str,
    label: str,
    missing_count: int,
    missing_path_count: int,
    path: str = "docs/example.md",
    purpose: str = "Example drift purpose.",
    snippet: str = "example snippet",
) -> dict[str, object]:
    missing_paths = []
    if missing_count:
        missing_paths.append(
            {
                "path": path,
                "first_missing_purpose": purpose,
                "first_missing_snippet": snippet,
            }
        )
    return {
        "name": name,
        "label": label,
        "builder": lambda root: {
            "expectation_count": missing_count + 1,
            "missing_count": missing_count,
            "missing_path_count": missing_path_count,
            "missing_paths": missing_paths,
        },
    }


class GoogleIssue3AttachedPagesAuditMatrixTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.repo_root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def test_build_matrix_recommends_surface_with_largest_gap(self) -> None:
        matrix = helper.build_attached_pages_audit_matrix(
            self.repo_root,
            audits=[
                make_surface(
                    name="launcher-companion",
                    label="Launcher companion",
                    missing_count=2,
                    missing_path_count=1,
                    path="docs/launcher.md",
                    purpose="Launcher drift.",
                ),
                make_surface(
                    name="windows-replay-quickstart",
                    label="Windows replay quickstart",
                    missing_count=5,
                    missing_path_count=2,
                    path="docs/replay.md",
                    purpose="Replay drift.",
                ),
            ],
        )

        self.assertEqual(2, matrix["surface_count"])
        self.assertEqual(2, matrix["failing_surface_count"])
        self.assertEqual(7, matrix["total_missing_count"])
        self.assertEqual(
            "windows-replay-quickstart",
            matrix["recommended_focus"]["name"],
        )
        self.assertEqual(
            "docs/replay.md",
            matrix["recommended_focus"]["first_missing_path"],
        )

    def test_render_text_report_includes_recommended_focus(self) -> None:
        matrix = helper.build_attached_pages_audit_matrix(
            self.repo_root,
            audits=[
                make_surface(
                    name="launcher-companion",
                    label="Launcher companion",
                    missing_count=0,
                    missing_path_count=0,
                ),
                make_surface(
                    name="windows-replay-quickstart",
                    label="Windows replay quickstart",
                    missing_count=3,
                    missing_path_count=1,
                    path="docs/replay.md",
                    purpose="Replay drift.",
                ),
            ],
        )

        text = helper.render_text_report(matrix)

        self.assertIn("Recommended focus:", text)
        self.assertIn("Windows replay quickstart", text)
        self.assertIn("First path: docs/replay.md", text)
        self.assertIn("First purpose: Replay drift.", text)

    def test_main_returns_zero_for_clean_matrix(self) -> None:
        original_specs = helper.DEFAULT_AUDIT_SPECS
        helper.DEFAULT_AUDIT_SPECS = (
            make_surface(
                name="launcher-companion",
                label="Launcher companion",
                missing_count=0,
                missing_path_count=0,
            ),
        )
        try:
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                exit_code = helper.main(["--repo-root", str(self.repo_root)])
        finally:
            helper.DEFAULT_AUDIT_SPECS = original_specs

        self.assertEqual(0, exit_code)
        self.assertIn("Drifted surfaces: 0", output.getvalue())

    def test_main_reports_missing_repo_root_in_json(self) -> None:
        missing_root = self.repo_root / "missing"
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        self.assertIn('"error_type": "repo_root_not_found"', output.getvalue())
        self.assertIn(str(missing_root), output.getvalue())


if __name__ == "__main__":
    unittest.main()