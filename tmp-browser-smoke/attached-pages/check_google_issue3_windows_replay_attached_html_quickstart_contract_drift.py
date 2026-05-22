#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter

import google_issue3_windows_replay_attached_html_quickstart_audit as helper
import test_google_issue3_windows_replay_attached_html_quickstart_audit as audit_test


def build_expectation_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for index, expectation in enumerate(helper.EXPECTATIONS, start=1):
        path = str(expectation["path"])
        snippet = str(expectation["snippet"])
        rows.append(
            {
                "index": index,
                "path": path,
                "snippet": snippet,
                "purpose": str(expectation.get("purpose", "")),
                "key": (path, snippet),
            }
        )
    return rows


def build_drift_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for index, drift_case in enumerate(audit_test.DRIFT_CASES, start=1):
        case_id, path, snippet, note = drift_case
        rows.append(
            {
                "index": index,
                "case_id": str(case_id),
                "path": str(path),
                "snippet": str(snippet),
                "note": str(note),
                "key": (str(path), str(snippet)),
            }
        )
    return rows


def build_duplicate_report(rows: list[dict[str, object]], id_field: str) -> list[dict[str, object]]:
    counts = Counter(row["key"] for row in rows)
    duplicates: list[dict[str, object]] = []
    for key, count in sorted(counts.items(), key=lambda item: (item[0][0], item[0][1])):
        if count < 2:
            continue
        matching_rows = [row for row in rows if row["key"] == key]
        duplicates.append(
            {
                "path": key[0],
                "snippet": key[1],
                "count": count,
                "entries": [row[id_field] for row in matching_rows],
            }
        )
    return duplicates


def build_missing_reports(
    source_rows: list[dict[str, object]],
    other_keys: set[tuple[str, str]],
    include_field: str,
) -> list[dict[str, object]]:
    missing: list[dict[str, object]] = []
    for row in source_rows:
        key = row["key"]
        if key in other_keys:
            continue
        report = {
            include_field: row[include_field],
            "path": row["path"],
            "snippet": row["snippet"],
        }
        if "purpose" in row:
            report["purpose"] = row["purpose"]
        if "note" in row and row["note"]:
            report["note"] = row["note"]
        missing.append(report)
    return missing


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Compare the replay-attached quickstart audit EXPECTATIONS with the "
            "paired DRIFT_CASES table and report any missing or stale mappings."
        )
    )
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON")
    args = parser.parse_args()

    expectation_rows = build_expectation_rows()
    drift_rows = build_drift_rows()
    expectation_keys = {row["key"] for row in expectation_rows}
    drift_keys = {row["key"] for row in drift_rows}

    missing_drift_cases = build_missing_reports(
        expectation_rows,
        drift_keys,
        "index",
    )
    stale_drift_cases = build_missing_reports(
        drift_rows,
        expectation_keys,
        "case_id",
    )
    duplicate_expectations = build_duplicate_report(expectation_rows, "index")
    duplicate_drift_cases = build_duplicate_report(drift_rows, "case_id")

    summary = {
        "profile": "google-issue3-windows-replay-attached-html-quickstart-contract-drift",
        "expectation_count": len(expectation_rows),
        "drift_case_count": len(drift_rows),
        "missing_drift_case_count": len(missing_drift_cases),
        "stale_drift_case_count": len(stale_drift_cases),
        "duplicate_expectation_count": len(duplicate_expectations),
        "duplicate_drift_case_count": len(duplicate_drift_cases),
        "ok": not any(
            (
                missing_drift_cases,
                stale_drift_cases,
                duplicate_expectations,
                duplicate_drift_cases,
            )
        ),
        "missing_drift_cases": missing_drift_cases,
        "stale_drift_cases": stale_drift_cases,
        "duplicate_expectations": duplicate_expectations,
        "duplicate_drift_cases": duplicate_drift_cases,
    }

    if args.json:
        json.dump(summary, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        print("Google issue #3 replay-attached quickstart contract drift check")
        print()
        print(f"Expectations: {summary['expectation_count']}")
        print(f"Drift cases:  {summary['drift_case_count']}")
        print()

        if summary["ok"]:
            print("PASS: EXPECTATIONS and DRIFT_CASES stay in sync.")
        else:
            print("FAIL: EXPECTATIONS and DRIFT_CASES have drift.")

        if missing_drift_cases:
            print()
            print("Missing drift cases:")
            for item in missing_drift_cases:
                print(f"- expectation #{item['index']}: {item['path']}")
                print(f"  snippet: {item['snippet']}")

        if stale_drift_cases:
            print()
            print("Stale drift cases:")
            for item in stale_drift_cases:
                print(f"- {item['case_id']}: {item['path']}")
                print(f"  snippet: {item['snippet']}")

        if duplicate_expectations:
            print()
            print("Duplicate expectations:")
            for item in duplicate_expectations:
                print(f"- {item['path']}")
                print(f"  entries: {', '.join(str(entry) for entry in item['entries'])}")

        if duplicate_drift_cases:
            print()
            print("Duplicate drift cases:")
            for item in duplicate_drift_cases:
                print(f"- {item['path']}")
                print(f"  entries: {', '.join(item['entries'])}")

    return 0 if summary["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
