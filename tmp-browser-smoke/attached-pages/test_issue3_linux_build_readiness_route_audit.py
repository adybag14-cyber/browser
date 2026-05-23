import contextlib
import io
import json
import tempfile
import unittest
from collections import defaultdict
from pathlib import Path

import issue3_linux_build_readiness_route_audit as helper


def build_contract_map() -> dict[str, str]:
    grouped: dict[str, list[str]] = defaultdict(list)
    for expectation in helper.EXPECTATIONS:
        grouped[expectation["path"]].append(expectation["snippet"])
    return {path: "\n\n".join(snippets) + "\n" for path, snippets in grouped.items()}


DRIFT_CASES = (
    (
        "missing_roadmap_surface_check",
        "docs/HEADED_MODE_ROADMAP.md",
        "bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "",
    ),
    (
        "missing_production_guide_route_note",
        "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "",
    ),
    (
        "missing_runtime_gate_route_note",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "",
    ),
    (
        "missing_linux_note_fallback_archive",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        "",
    ),
    (
        "missing_surface_checker_route_printer_reference",
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "",
    ),
    (
        "missing_route_printer_fallback_label",
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Fallback Zig archive:",
        "",
    ),
)


class Issue3LinuxBuildReadinessRouteAuditTests(unittest.TestCase):
    maxDiff = None

    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(self, overrides: dict[str, str] | None = None) -> None:
        contract_map = build_contract_map()
        if overrides:
            contract_map.update(overrides)
        for rel_path, content in contract_map.items():
            path = self.root / rel_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()
        audit = helper.build_linux_build_readiness_route_audit(self.root)
        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_selected_contract_drift_cases(self) -> None:
        contract_map = build_contract_map()

        for name, path, snippet, replacement in DRIFT_CASES:
            with self.subTest(name=name):
                self.write_contract_files(
                    {path: contract_map[path].replace(snippet, replacement)}
                )
                audit = helper.build_linux_build_readiness_route_audit(self.root)
                self.assertGreater(audit["missing_count"], 0)
                failing = [
                    result["snippet"]
                    for result in audit["results"]
                    if not result["exists"]
                ]
                self.assertIn(snippet, failing)

    def test_missing_path_summary_groups_multiple_expectations_for_one_path(self) -> None:
        self.write_contract_files({"docs/ISSUE3_RUNTIME_REENTRY_GATES.md": "# drifted\n"})

        audit = helper.build_linux_build_readiness_route_audit(self.root)

        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", summary)
        self.assertGreater(
            summary["docs/ISSUE3_RUNTIME_REENTRY_GATES.md"][
                "missing_expectation_count"
            ],
            1,
        )
        self.assertIn(
            "build-readiness route note",
            summary["docs/ISSUE3_RUNTIME_REENTRY_GATES.md"][
                "first_missing_purpose"
            ],
        )
        self.assertIn(
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            summary["docs/ISSUE3_RUNTIME_REENTRY_GATES.md"][
                "first_missing_snippet"
            ],
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(
            {"scripts/linux/show_issue3_linux_build_readiness_route.sh": "# drifted\n"}
        )
        audit = helper.build_linux_build_readiness_route_audit(self.root)
        report = helper.render_text_report(audit)
        self.assertIn("Issue #3 Linux Build-Readiness Route Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn(
            "[FAIL] scripts/linux/show_issue3_linux_build_readiness_route.sh", report
        )
        self.assertIn("Missing path summary:", report)
        self.assertIn("first snippet:", report)

    def test_cli_json_output_returns_nonzero_and_grouped_summary_when_contract_drifts(
        self,
    ) -> None:
        self.write_contract_files({"docs/HEADED_MODE_ROADMAP.md": "# drifted\n"})
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])
        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)
        self.assertGreater(payload["missing_path_count"], 0)
        self.assertEqual("docs/HEADED_MODE_ROADMAP.md", payload["missing_paths"][0]["path"])
        self.assertGreater(
            payload["missing_paths"][0]["missing_expectation_count"],
            1,
        )
        self.assertIn(
            "check_issue3_linux_build_readiness_route_surface.sh",
            payload["missing_paths"][0]["first_missing_snippet"],
        )

    def test_cli_json_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(str(missing_root), payload["repo_root"])
        self.assertIsNone(payload["missing_count"])
        self.assertIn("repo root does not exist:", payload["error"])

    def test_cli_text_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root)])

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Issue #3 Linux Build-Readiness Route Audit", report)
        self.assertIn(f"Repo root: {missing_root}", report)
        self.assertIn("Error: repo root does not exist:", report)


if __name__ == "__main__":
    unittest.main()