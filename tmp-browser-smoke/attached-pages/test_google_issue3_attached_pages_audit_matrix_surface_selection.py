import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_attached_pages_audit_matrix as helper


def make_surface(name: str, label: str, missing_count: int) -> dict[str, object]:
    return {
        "name": name,
        "label": label,
        "builder": lambda root: {
            "expectation_count": missing_count + 1,
            "missing_count": missing_count,
            "missing_path_count": 1 if missing_count else 0,
            "missing_paths": []
            if not missing_count
            else [
                {
                    "path": f"docs/{name}.md",
                    "first_missing_purpose": f"{label} drift.",
                    "first_missing_snippet": "example snippet",
                }
            ],
        },
    }


class GoogleIssue3AttachedPagesAuditMatrixSurfaceSelectionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.repo_root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def test_build_matrix_limits_output_to_selected_surfaces(self) -> None:
        matrix = helper.build_attached_pages_audit_matrix(
            self.repo_root,
            audits=[
                make_surface("branch-inventory", "Branch inventory", 0),
                make_surface("windows-full-use-route", "Windows full-use route", 2),
            ],
            selected_names={"windows-full-use-route"},
        )

        self.assertEqual(["windows-full-use-route"], matrix["selected_surfaces"])
        self.assertEqual(1, matrix["surface_count"])
        self.assertEqual("windows-full-use-route", matrix["surfaces"][0]["name"])

    def test_render_text_report_shows_selected_surfaces(self) -> None:
        matrix = helper.build_attached_pages_audit_matrix(
            self.repo_root,
            audits=[make_surface("windows-full-use-route", "Windows full-use route", 1)],
            selected_names={"windows-full-use-route"},
        )

        report = helper.render_text_report(matrix)

        self.assertIn("Selected surfaces: windows-full-use-route", report)

    def test_main_reports_invalid_surface_selection_in_json(self) -> None:
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--surface",
                    "not-a-real-surface",
                    "--json",
                ]
            )

        self.assertEqual(2, exit_code)
        self.assertIn('"error_type": "invalid_surface_selection"', output.getvalue())
        self.assertIn('"available_surfaces"', output.getvalue())
        self.assertIn('"not-a-real-surface"', output.getvalue())


if __name__ == "__main__":
    unittest.main()