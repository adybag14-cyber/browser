import argparse
import importlib.util
import json
from collections import defaultdict
from pathlib import Path
from types import ModuleType


DEFAULT_AUDIT_MODULE = "google_issue3_windows_replay_attached_html_quickstart_audit.py"
DEFAULT_TEST_MODULE = "test_google_issue3_windows_replay_attached_html_quickstart_audit.py"


def load_module(module_path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(module_path.stem, module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load module spec: {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def extract_expectations(module: ModuleType) -> list[dict[str, str]]:
    expectations = getattr(module, "EXPECTATIONS", None)
    if not isinstance(expectations, tuple):
        raise RuntimeError("audit module is missing EXPECTATIONS")

    normalized: list[dict[str, str]] = []
    for entry in expectations:
        if not isinstance(entry, dict):
            raise RuntimeError("EXPECTATIONS must contain dictionaries")
        path = entry.get("path")
        snippet = entry.get("snippet")
        purpose = entry.get("purpose", "")
        if not isinstance(path, str) or not isinstance(snippet, str):
            raise RuntimeError("EXPECTATIONS entries must include string path and snippet values")
        normalized.append({"path": path, "snippet": snippet, "purpose": purpose})
    return normalized


def extract_drift_cases(module: ModuleType) -> set[tuple[str, str]]:
    drift_cases = getattr(module, "DRIFT_CASES", None)
    if not isinstance(drift_cases, tuple):
        raise RuntimeError("test module is missing DRIFT_CASES")

    normalized: set[tuple[str, str]] = set()
    for entry in drift_cases:
        if not isinstance(entry, tuple) or len(entry) < 3:
            raise RuntimeError("DRIFT_CASES entries must be tuples with at least three items")
        _, path, snippet, *_ = entry
        if not isinstance(path, str) or not isinstance(snippet, str):
            raise RuntimeError("DRIFT_CASES entries must include string path and snippet values")
        normalized.add((path, snippet))
    return normalized


def build_missing_path_summary(uncovered: list[dict[str, str]]) -> list[dict[str, object]]:
    grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
    for entry in uncovered:
        grouped[entry["path"]].append(entry)

    summary: list[dict[str, object]] = []
    for path in sorted(grouped):
        missing_entries = grouped[path]
        first = missing_entries[0]
        summary.append(
            {
                "path": path,
                "missing_expectation_count": len(missing_entries),
                "first_missing_purpose": first["purpose"],
                "first_missing_snippet": first["snippet"],
            }
        )
    return summary


def build_coverage_report(audit_module_path: Path, test_module_path: Path) -> dict[str, object]:
    audit_module = load_module(audit_module_path)
    test_module = load_module(test_module_path)
    expectations = extract_expectations(audit_module)
    drift_cases = extract_drift_cases(test_module)

    uncovered = [
        expectation
        for expectation in expectations
        if (expectation["path"], expectation["snippet"]) not in drift_cases
    ]

    return {
        "audit_module_path": str(audit_module_path),
        "test_module_path": str(test_module_path),
        "expectation_count": len(expectations),
        "drift_case_count": len(drift_cases),
        "covered_count": len(expectations) - len(uncovered),
        "uncovered_count": len(uncovered),
        "uncovered": uncovered,
        "uncovered_paths": build_missing_path_summary(uncovered),
    }


def render_text_report(report: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Audit Contract Coverage",
        f"Audit module: {report['audit_module_path']}",
        f"Test module: {report['test_module_path']}",
        f"Expectations: {report['expectation_count']}",
        f"Drift cases: {report['drift_case_count']}",
        f"Covered expectations: {report['covered_count']}",
        f"Uncovered expectations: {report['uncovered_count']}",
    ]
    if report["uncovered"]:
        lines.append("Uncovered path summary:")
        for entry in report["uncovered_paths"]:
            lines.append(
                "[WARN] {path} ({missing_expectation_count} missing)".format(**entry)
            )
            lines.append(f"  first purpose: {entry['first_missing_purpose']}")
            lines.append(f"  first snippet: {entry['first_missing_snippet']}")
    else:
        lines.append("All audit expectations have a direct drift-case entry.")
    return "\n".join(lines)


def build_error_payload(audit_module_path: Path, test_module_path: Path, error: str) -> dict[str, object]:
    return {
        "error_type": "coverage_check_failed",
        "audit_module_path": str(audit_module_path),
        "test_module_path": str(test_module_path),
        "error": error,
        "expectation_count": None,
        "drift_case_count": None,
        "covered_count": None,
        "uncovered_count": None,
        "uncovered": [],
        "uncovered_paths": [],
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare issue #3 audit expectations with direct DRIFT_CASES coverage."
    )
    parser.add_argument(
        "--audit-module",
        type=Path,
        default=Path(__file__).with_name(DEFAULT_AUDIT_MODULE),
        help="Path to the audit module containing EXPECTATIONS.",
    )
    parser.add_argument(
        "--test-module",
        type=Path,
        default=Path(__file__).with_name(DEFAULT_TEST_MODULE),
        help="Path to the unittest module containing DRIFT_CASES.",
    )
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        report = build_coverage_report(args.audit_module, args.test_module)
    except Exception as exc:
        payload = build_error_payload(args.audit_module, args.test_module, str(exc))
        if args.json:
            print(json.dumps(payload, indent=2))
        else:
            print("Google Issue #3 Audit Contract Coverage")
            print(f"Audit module: {args.audit_module}")
            print(f"Test module: {args.test_module}")
            print(f"Error: {exc}")
        return 1

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(render_text_report(report))
    return 0 if report["uncovered_count"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
