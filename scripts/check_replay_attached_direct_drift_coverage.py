#!/usr/bin/env python3

"""Measure direct drift-case coverage for replay-attached audit expectations.

This helper compares the broad EXPECTATIONS table from the replay-attached
audit helper against the narrower DRIFT_CASES table in its paired unittest.
It lets scheduled runs answer one focused question quickly: which live helper
contracts are still only covered by the broad audit and do not yet have a
direct regression case of their own?
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import tempfile
import unittest


DEFAULT_HELPER_FILE = (
    "tmp-browser-smoke/attached-pages/"
    "google_issue3_windows_replay_attached_html_quickstart_audit.py"
)
DEFAULT_TEST_FILE = (
    "tmp-browser-smoke/attached-pages/"
    "test_google_issue3_windows_replay_attached_html_quickstart_audit.py"
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Compare replay-attached EXPECTATIONS against direct DRIFT_CASES "
            "coverage and report which broad audit expectations still lack a "
            "focused regression case."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--helper-file",
        default=DEFAULT_HELPER_FILE,
        help="Relative path to the replay-attached audit helper",
    )
    parser.add_argument(
        "--test-file",
        default=DEFAULT_TEST_FILE,
        help="Relative path to the paired replay-attached unittest",
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


def load_python_literal(path: Path, variable_name: str) -> object:
    module = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))

    for node in module.body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == variable_name:
                    return ast.literal_eval(node.value)
        if isinstance(node, ast.AnnAssign):
            target = node.target
            if isinstance(target, ast.Name) and target.id == variable_name:
                return ast.literal_eval(node.value)

    raise ValueError(f"Could not find {variable_name} in {path}")


def load_expectation_entries(path: Path) -> list[dict[str, str]]:
    raw_entries = load_python_literal(path, "EXPECTATIONS")
    if not isinstance(raw_entries, tuple):
        raise ValueError(f"EXPECTATIONS in {path} is not a tuple")

    entries: list[dict[str, str]] = []
    for index, raw_entry in enumerate(raw_entries):
        if not isinstance(raw_entry, dict):
            raise ValueError(f"EXPECTATIONS[{index}] in {path} is not a dict")
        expectation_path = raw_entry.get("path")
        snippet = raw_entry.get("snippet")
        purpose = raw_entry.get("purpose")
        if not all(isinstance(value, str) for value in (expectation_path, snippet, purpose)):
            raise ValueError(
                f"EXPECTATIONS[{index}] in {path} must provide string path, snippet, and purpose values"
            )
        entries.append(
            {
                "name": raw_entry.get("name") if isinstance(raw_entry.get("name"), str) else "",
                "path": expectation_path,
                "snippet": snippet,
                "purpose": purpose,
            }
        )
    return entries


def load_drift_entries(path: Path) -> list[dict[str, str]]:
    raw_entries = load_python_literal(path, "DRIFT_CASES")
    if not isinstance(raw_entries, tuple):
        raise ValueError(f"DRIFT_CASES in {path} is not a tuple")

    entries: list[dict[str, str]] = []
    for index, raw_entry in enumerate(raw_entries):
        if not (isinstance(raw_entry, tuple) and len(raw_entry) >= 3):
            raise ValueError(
                f"DRIFT_CASES[{index}] in {path} must be a tuple with at least three items"
            )
        case_name, drift_path, snippet = raw_entry[:3]
        if not all(isinstance(value, str) for value in (case_name, drift_path, snippet)):
            raise ValueError(
                f"DRIFT_CASES[{index}] in {path} must start with string case, path, and snippet values"
            )
        entries.append(
            {
                "name": case_name,
                "path": drift_path,
                "snippet": snippet,
            }
        )
    return entries


def build_direct_drift_coverage_report(
    repo_root: Path,
    helper_file: str = DEFAULT_HELPER_FILE,
    test_file: str = DEFAULT_TEST_FILE,
) -> dict[str, object]:
    helper_path = (repo_root / helper_file).resolve()
    test_path = (repo_root / test_file).resolve()

    errors: list[str] = []
    if not helper_path.is_file():
        errors.append(f"missing helper file: {helper_path}")
    if not test_path.is_file():
        errors.append(f"missing test file: {test_path}")
    if errors:
        return {
            "ok": False,
            "repo_root": str(repo_root),
            "helper_file": str(helper_path),
            "test_file": str(test_path),
            "error_type": "missing_input",
            "errors": errors,
        }

    expectations = load_expectation_entries(helper_path)
    drift_cases = load_drift_entries(test_path)
    drift_lookup = {(entry["path"], entry["snippet"]): entry["name"] for entry in drift_cases}

    missing_entries: list[dict[str, str]] = []
    covered_entries: list[dict[str, str]] = []
    missing_by_path: dict[str, dict[str, object]] = {}

    for expectation in expectations:
        key = (expectation["path"], expectation["snippet"])
        direct_case_name = drift_lookup.get(key)
        entry = {
            "path": expectation["path"],
            "snippet": expectation["snippet"],
            "purpose": expectation["purpose"],
        }
        if direct_case_name is None:
            missing_entries.append(entry)
            missing_summary = missing_by_path.get(expectation["path"])
            if missing_summary is None:
                missing_summary = {
                    "path": expectation["path"],
                    "missing_count": 0,
                    "first_missing_purpose": expectation["purpose"],
                    "first_missing_snippet": expectation["snippet"],
                }
                missing_by_path[expectation["path"]] = missing_summary
            missing_summary["missing_count"] += 1
        else:
            covered_entries.append({**entry, "drift_case": direct_case_name})

    return {
        "ok": not missing_entries,
        "repo_root": str(repo_root),
        "helper_file": str(helper_path),
        "test_file": str(test_path),
        "expectation_count": len(expectations),
        "direct_drift_case_count": len(drift_cases),
        "covered_count": len(covered_entries),
        "missing_count": len(missing_entries),
        "coverage_ratio": 0.0 if not expectations else len(covered_entries) / len(expectations),
        "missing_paths": list(missing_by_path.values()),
        "missing_entries": missing_entries,
    }


def render_text_report(report: dict[str, object]) -> str:
    lines = [
        "Replay Attached Direct Drift Coverage",
        "",
        f"Repo root: {report['repo_root']}",
        f"Helper file: {report['helper_file']}",
        f"Test file: {report['test_file']}",
    ]

    if report.get("error_type"):
        lines.append("Status: error")
        lines.append("Errors:")
        for error in report["errors"]:
            lines.append(f"- {error}")
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            f"Expectations: {report['expectation_count']}",
            f"Direct drift cases: {report['direct_drift_case_count']}",
            f"Covered directly: {report['covered_count']}",
            f"Missing direct coverage: {report['missing_count']}",
            f"Coverage ratio: {report['coverage_ratio']:.3f}",
        ]
    )

    if report["missing_paths"]:
        lines.append("")
        lines.append("Missing coverage by path:")
        for item in report["missing_paths"]:
            lines.append(f"- {item['path']} ({item['missing_count']} missing expectations)")
            lines.append(f"  First purpose: {item['first_missing_purpose']}")
            lines.append(f"  First snippet: {item['first_missing_snippet']}")

    if report["missing_entries"]:
        lines.append("")
        lines.append("Missing direct cases:")
        for item in report["missing_entries"]:
            lines.append(f"- {item['path']}")
            lines.append(f"  Purpose: {item['purpose']}")
            lines.append(f"  Snippet: {item['snippet']}")

    return "\n".join(lines).rstrip() + "\n"


class DirectDriftCoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.helper_path = self.root / DEFAULT_HELPER_FILE
        self.test_path = self.root / DEFAULT_TEST_FILE
        self.helper_path.parent.mkdir(parents=True, exist_ok=True)
        self.test_path.parent.mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_pair(self, helper_text: str, test_text: str) -> None:
        self.helper_path.write_text(helper_text, encoding="utf-8")
        self.test_path.write_text(test_text, encoding="utf-8")

    def test_reports_missing_direct_coverage(self) -> None:
        self.write_pair(
            """EXPECTATIONS = (\n    {\"path\": \"docs/one.md\", \"snippet\": \"alpha\", \"purpose\": \"first\"},\n    {\"path\": \"docs/two.md\", \"snippet\": \"beta\", \"purpose\": \"second\"},\n)\n""",
            """DRIFT_CASES = (\n    (\"alpha_case\", \"docs/one.md\", \"alpha\", \"\"),\n)\n""",
        )

        report = build_direct_drift_coverage_report(self.root)

        self.assertFalse(report["ok"])
        self.assertEqual(2, report["expectation_count"])
        self.assertEqual(1, report["covered_count"])
        self.assertEqual(1, report["missing_count"])
        self.assertEqual("docs/two.md", report["missing_entries"][0]["path"])

    def test_passes_when_every_expectation_has_direct_case(self) -> None:
        self.write_pair(
            """EXPECTATIONS = (\n    {\"path\": \"docs/one.md\", \"snippet\": \"alpha\", \"purpose\": \"first\"},\n)\n""",
            """DRIFT_CASES = (\n    (\"alpha_case\", \"docs/one.md\", \"alpha\", \"\"),\n)\n""",
        )

        report = build_direct_drift_coverage_report(self.root)

        self.assertTrue(report["ok"])
        self.assertEqual(0, report["missing_count"])
        self.assertEqual(1.0, report["coverage_ratio"])

    def test_reports_missing_files_cleanly(self) -> None:
        report = build_direct_drift_coverage_report(self.root)

        self.assertFalse(report["ok"])
        self.assertEqual("missing_input", report["error_type"])
        self.assertEqual(2, len(report["errors"]))

    def test_render_text_report_mentions_missing_paths(self) -> None:
        self.write_pair(
            """EXPECTATIONS = (\n    {\"path\": \"docs/one.md\", \"snippet\": \"alpha\", \"purpose\": \"first\"},\n    {\"path\": \"docs/one.md\", \"snippet\": \"beta\", \"purpose\": \"second\"},\n)\n""",
            """DRIFT_CASES = (\n    (\"alpha_case\", \"docs/one.md\", \"alpha\", \"\"),\n)\n""",
        )

        text = render_text_report(build_direct_drift_coverage_report(self.root))

        self.assertIn("Missing coverage by path:", text)
        self.assertIn("- docs/one.md (1 missing expectations)", text)
        self.assertIn("Snippet: beta", text)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(DirectDriftCoverageTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    report = build_direct_drift_coverage_report(
        repo_root,
        helper_file=args.helper_file,
        test_file=args.test_file,
    )
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(render_text_report(report), end="")
    return 0 if report.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
