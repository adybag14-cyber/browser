import contextlib
import io
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_attached_pages_audit_matrix as helper


class GoogleIssue3AttachedPagesAuditMatrixCliTests(unittest.TestCase):
    def test_normalize_selected_surface_names_trims_and_deduplicates(self) -> None:
        self.assertEqual(
            {"branch-inventory", "windows-full-use-route"},
            helper.normalize_selected_surface_names(
                [" branch-inventory ", "", "windows-full-use-route", "branch-inventory"]
            ),
        )

    def test_load_audit_specs_filters_to_selected_surfaces(self) -> None:
        specs = helper.load_audit_specs(
            selected_names={"branch-inventory", "windows-full-use-route"}
        )

        self.assertEqual(
            ["branch-inventory", "windows-full-use-route"],
            [spec["name"] for spec in specs],
        )

    def test_invalid_surface_selection_matrix_lists_available_surfaces(self) -> None:
        matrix = helper.build_invalid_surface_selection_matrix(
            None,
            {"not-a-surface"},
            {"branch-inventory", "windows-full-use-route"},
        )

        self.assertEqual("invalid_surface_selection", matrix["error_type"])
        self.assertEqual(["branch-inventory", "windows-full-use-route"], matrix["available_surfaces"])
        self.assertEqual(["not-a-surface"], matrix["selected_surfaces"])

    def test_render_text_report_includes_available_surfaces_for_invalid_selection(self) -> None:
        matrix = helper.build_invalid_surface_selection_matrix(
            None,
            {"not-a-surface"},
            {"branch-inventory", "windows-full-use-route"},
        )

        text = helper.render_text_report(matrix)

        self.assertIn("Selected surfaces: not-a-surface", text)
        self.assertIn(
            "Available surfaces: branch-inventory, windows-full-use-route",
            text,
        )
        self.assertIn("Error: unknown surface selection: not-a-surface", text)

    def test_main_returns_two_for_invalid_surface_selection(self) -> None:
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(["--surface", "not-a-surface"])

        self.assertEqual(2, exit_code)
        rendered = output.getvalue()
        self.assertIn("Available surfaces:", rendered)
        self.assertIn("unknown surface selection: not-a-surface", rendered)


if __name__ == "__main__":
    unittest.main()
