import argparse
import importlib
import json
import sys
from collections import defaultdict
from pathlib import Path


DEFAULT_HELPER_MODULE = "google_issue3_windows_replay_attached_html_quickstart_audit"
DEFAULT_TEST_MODULE = "test_google_issue3_windows_replay_attached_html_quickstart_audit"


def ensure_module_dir(module_dir: str | None) -> Path:
    base = Path(__file__).resolve().parent if module_dir is None else Path(module_dir)
    resolved = base.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"module directory does not exist: {resolved}")
    if str(resolved) not in sys.path:
        sys.path.insert(0, str(resolved))
    return resolved


def load_audit_modules(
    helper_module_name: str, test_module_name: str, module_dir: str | None
) -> tuple[object, object, Path]:
    resolved_dir = ensure_module_dir(module_dir)
    try:
        helper_module = importlib.import_module(helper_module_name)
        test_module = importlib.import_module(test_module_name)
    except ModuleNotFoundError as err:
        raise ImportError(str(err)) from err
    return helper_module, test_module, resolved_dir


def normalize_drift_cases(drift_cases: object) -> list[dict[str, str]]:
    normalized: list[dict[str, str]] = []
    for index, drift_case in enumerate(drift_cases):
        if not isinstance(drift_case, tuple) or len(drift_case) != 4:
            raise ValueError(f"drift case #{index} must be a 4-item tuple")
        name, path, snippet, replacement = drift_case
        normalized.append(
            {
                "name": str(name),
                "path": str(path),
                "snippet": str(snippet),
                "replacement": str(replacement),
            }
        )
    return normalized


def build_direct_coverage_audit(
    expectations: object, drift_cases: object
) -> dict[str, object]:
    normalized_drift_cases = normalize_drift_cases(drift_cases)
    drift_index: dict[tuple[str, str], list[str]] = defaultdict(list)
    for drift_case in normalized_drift_cases:
        drift_index[(drift_case["path"], drift_case["snippet"])].append(drift_case["name"])

    expectation_results: list[dict[str, object]] = []
    uncovered_paths: dict[str, dict[str, object]] = {}
    uncovered_count = 0

    for index, expectation in enumerate(expectations):
        if not isinstance(expectation, dict):
            raise ValueError(f"expectation #{index} must be a dict")
        path = str(expectation["path"])
        snippet = str(expectation["snippet"])
        purpose = str(expectation["purpose"])
        case_names = drift_index.get((path, snippet), [])
        has_direct_case = bool(case_names)
        if not has_direct_case:
            uncovered_count += 1
            uncovered_path = uncovered_paths.get(path)
            if uncovered_path is None:
                uncovered_path = {
                    "path": path,
                    "missing_expectation_count": 0,
                    "first_missing_purpose": purpose,
                    "first_missing_snippet": snippet,
                }
                uncovered_paths[path] = uncovered_path
            uncovered_path["missing_expectation_count"] += 1

        expectation_results.append(
            {
                "path": path,
                "snippet": snippet,
                "purpose": purpose,
                "has_direct_case": has_direct_case,
                "case_names": case_names,
            }
        )

    expected_pairs = {(result["path"], result["snippet"]) for result in expectation_results}
    orphan_drift_cases = [
        drift_case
        for drift_case in normalized_drift_cases
        if (drift_case["path"], drift_case["snippet"]) not in expected_pairs
    ]

    return {
        "expectation_count": len(expectation_results),
        "direct_case_count": len(normalized_drift_cases),
        "uncovered_count": uncovered_count,
        "uncovered_path_count": len(uncovered_paths),
        "uncovered_paths": list(uncovered_paths.values()),
        "orphan_drift_case_count": len(orphan_drift_cases),
        "orphan_drift_cases": orphan_drift_cases,
        "results": expectation_results,
    }


def build_error_audit(
    helper_module_name: str,
    test_module_name: str,
    module_dir: str | None,
    error_type: str,
    message: str,
) -> dict[str, object]:
    return {
        "helper_module": helper_module_name,
        "test_module": test_module_name,
        "module_dir": str(Path.cwd() if module_dir is None else Path(module_dir).expanduser()),
        "expectation_count": None,
        "direct_case_count": None,
        "uncovered_count": None,
        "uncovered_path_count": None,
        "uncovered_paths": [],
        "orphan_drift_case_count": None,
        "orphan_drift_cases": [],
        "results": [],
        "error_type": error_type,
        "error": message,
    }


def build_module_audit(
    helper_module_name: str, test_module_name: str, module_dir: str | None
) -> dict[str, object]:
    helper_module, test_module, resolved_dir = load_audit_modules(
        helper_module_name, test_module_name, module_dir
    )

    if not hasattr(helper_module, "EXPECTATIONS"):
        raise AttributeError(f"{helper_module_name} is missing EXPECTATIONS")
    if not hasattr(test_module, "DRIFT_CASES"):
        raise AttributeError(f"{test_module_name} is missing DRIFT_CASES")

    audit = build_direct_coverage_audit(
        getattr(helper_module, "EXPECTATIONS"), getattr(test_module, "DRIFT_CASES")
    )
    audit.update(
        {
            "helper_module": helper_module_name,
            "test_module": test_module_name,
            "module_dir": str(resolved_dir),
        }
    )
    return audit


def render_text_report(audit: dict[str, object]) -> str:
    if audit.get("error"):
        lines = [
            "Google Issue #3 Replay Attached Direct Coverage Audit",
            "",
            f"Helper module: {audit['helper_module']}",
            f"Test module: {audit['test_module']}",
            f"Module directory: {audit['module_dir']}",
            f"Error: {audit['error']}",
        ]
        return "\n".join(lines).rstrip() + "\n"

    lines = [
        "Google Issue #3 Replay Attached Direct Coverage Audit",
        "",
        f"Helper module: {audit['helper_module']}",
        f"Test module: {audit['test_module']}",
        f"Module directory: {audit['module_dir']}",
        f"Expectations checked: {audit['expectation_count']}",
        f"Direct drift cases: {audit['direct_case_count']}",
        f"Uncovered expectations: {audit['uncovered_count']}",
        f"Orphan drift cases: {audit['orphan_drift_case_count']}",
    ]

    if audit["uncovered_paths"]:
        lines.append("")
        lines.append("Uncovered paths:")
        for uncovered_path in audit["uncovered_paths"]:
            lines.append(
                f"- {uncovered_path['path']} ({uncovered_path['missing_expectation_count']} uncovered expectations)"
            )
            lines.append(f"  First purpose: {uncovered_path['first_missing_purpose']}")
            lines.append(f"  First snippet: {uncovered_path['first_missing_snippet']}")

    if audit["orphan_drift_cases"]:
        lines.append("")
        lines.append("Orphan drift cases:")
        for drift_case in audit["orphan_drift_cases"]:
            lines.append(f"- {drift_case['name']} -> {drift_case['path']}")
            lines.append(f"  Snippet: {drift_case['snippet']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Compare replay-attached EXPECTATIONS against the paired DRIFT_CASES "
            "table and report which expectations still lack explicit direct coverage."
        )
    )
    parser.add_argument("--helper-module", default=DEFAULT_HELPER_MODULE)
    parser.add_argument("--test-module", default=DEFAULT_TEST_MODULE)
    parser.add_argument(
        "--module-dir",
        help="Directory that contains the helper and test modules. Defaults to this file's directory.",
    )
    parser.add_argument("--json", action="store_true", help="Print structured JSON.")
    args = parser.parse_args(argv)

    try:
        audit = build_module_audit(
            args.helper_module, args.test_module, args.module_dir
        )
    except FileNotFoundError as err:
        audit = build_error_audit(
            args.helper_module,
            args.test_module,
            args.module_dir,
            "module_dir_not_found",
            str(err),
        )
    except (ImportError, AttributeError, ValueError) as err:
        audit = build_error_audit(
            args.helper_module,
            args.test_module,
            args.module_dir,
            "module_load_failed",
            str(err),
        )

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit.get("error") or audit["uncovered_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())