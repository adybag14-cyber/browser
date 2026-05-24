import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import check_issue3_runtime_reentry_route_contract as helper


class Issue3RuntimeReentryRouteContractTests(unittest.TestCase):
    maxDiff = None

    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_surface_files(
        self,
        *,
        doc_source: str = helper.GUARDED_DOC,
        helper_source: str = helper.GUARDED_HELPER,
    ) -> tuple[Path, Path]:
        doc_path = self.root / "docs" / "ISSUE3_RUNTIME_REENTRY_GATES.md"
        helper_path = (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        doc_path.parent.mkdir(parents=True, exist_ok=True)
        helper_path.parent.mkdir(parents=True, exist_ok=True)
        doc_path.write_text(doc_source, encoding="utf-8")
        helper_path.write_text(helper_source, encoding="utf-8")
        return doc_path, helper_path

    def test_self_test_passes(self) -> None:
        self.assertEqual(0, helper.run_self_test(json_output=False))

    def test_evaluate_sources_passes_for_guarded_samples(self) -> None:
        result = helper.evaluate_sources(helper.GUARDED_DOC, helper.GUARDED_HELPER)
        self.assertTrue(result["ok"])
        self.assertTrue(result["doc"]["ok"])
        self.assertTrue(result["helper"]["ok"])

    def test_evaluate_sources_reports_missing_doc_marker(self) -> None:
        drifted_doc = helper.GUARDED_DOC.replace(
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "",
        )
        result = helper.evaluate_sources(drifted_doc, helper.GUARDED_HELPER)
        self.assertFalse(result["ok"])
        self.assertIn(
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            result["doc"]["missing_markers"],
        )

    def test_evaluate_sources_reports_missing_helper_marker(self) -> None:
        drifted_helper = helper.GUARDED_HELPER.replace(
            "saved_memory_preflight = $savedMemoryPreflightCommand",
            "",
        )
        result = helper.evaluate_sources(helper.GUARDED_DOC, drifted_helper)
        self.assertFalse(result["ok"])
        self.assertIn(
            "saved_memory_preflight = $savedMemoryPreflightCommand",
            result["helper"]["missing_markers"],
        )

    def test_main_outputs_json_for_guarded_surface(self) -> None:
        doc_path, helper_path = self.write_surface_files()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main_from_args(
                ["--doc", str(doc_path), "--helper", str(helper_path), "--json"]
            )
        self.assertEqual(0, exit_code)
        payload = json.loads(output.getvalue())
        self.assertEqual("issue3-runtime-reentry-route-contract", payload["profile"])
        self.assertTrue(payload["ok"])

    def test_main_reports_missing_markers_in_text_output(self) -> None:
        doc_path, helper_path = self.write_surface_files(
            helper_source=helper.GUARDED_HELPER.replace(
                "linux_runtime_route = $linuxRuntimeRouteCommand",
                "",
            )
        )
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main_from_args(
                ["--doc", str(doc_path), "--helper", str(helper_path)]
            )
        self.assertEqual(1, exit_code)
        text = output.getvalue()
        self.assertIn("ISSUE3_RUNTIME_REENTRY_ROUTE_CONTRACT=fail", text)
        self.assertIn("HELPER_CONTRACT=fail", text)
        self.assertIn(
            "HELPER_MISSING_MARKER=linux_runtime_route = $linuxRuntimeRouteCommand",
            text,
        )


if __name__ == "__main__":
    unittest.main()