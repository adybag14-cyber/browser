from __future__ import annotations

import argparse
import json
import shlex
import sys
from pathlib import Path


SOURCE_EXPECTATIONS: tuple[dict[str, str], ...] = (
    {
        "label": "browser_target_helper_present",
        "snippet": 'fn browseTargetInternal(url: []const u8, scheme: []const u8) ?BrowseTargetInfo {',
        "why": "The startup classifier should keep a dedicated helper for browser:// routes.",
    },
    {
        "label": "about_target_helper_present",
        "snippet": 'fn browseTargetAbout(url: []const u8) ?BrowseTargetInfo {',
        "why": "The startup classifier should keep a dedicated helper for about: routes.",
    },
    {
        "label": "downloads_internal_test_present",
        "snippet": 'test "browse target info classifies browser downloads pages as internal" {',
        "why": "Downloads should stay covered as an internal browser-page startup target.",
    },
    {
        "label": "settings_internal_test_present",
        "snippet": 'test "browse target info keeps browser settings routes on the internal path" {',
        "why": "Browser settings routes should remain on the internal startup path.",
    },
    {
        "label": "about_blank_internal_test_present",
        "snippet": 'test "browse target info classifies about blank pages as internal" {',
        "why": "about:blank should remain covered as an internal page target.",
    },
    {
        "label": "about_fragment_internal_test_present",
        "snippet": 'test "browse target info keeps about fragments on the internal path" {',
        "why": "about: fragments should remain on the internal startup path.",
    },
)

INTERNAL_LOG_CASES: tuple[dict[str, object], ...] = (
    {
        "label": "browser_downloads_internal",
        "url": "browser://downloads",
        "expected_fields": {
            "target_scheme": "browser",
            "target_scope": "internal",
            "target_host": "downloads",
            "target_port": "(none)",
        },
        "why": "Downloads is a browser-shell route and should not look remote in startup diagnostics.",
    },
    {
        "label": "browser_settings_internal",
        "url": "browser://settings/homepage",
        "expected_fields": {
            "target_scheme": "browser",
            "target_scope": "internal",
            "target_host": "settings",
            "target_port": "(none)",
        },
        "why": "Settings routes should stay on the internal browser-page path.",
    },
    {
        "label": "about_blank_internal",
        "url": "about:blank",
        "expected_fields": {
            "target_scheme": "about",
            "target_scope": "internal",
            "target_host": "blank",
            "target_port": "(none)",
        },
        "why": "about:blank should remain internal in browse startup logs.",
    },
    {
        "label": "about_blank_fragment_internal",
        "url": "about:blank#popup-probe",
        "expected_fields": {
            "target_scheme": "about",
            "target_scope": "internal",
            "target_host": "blank",
            "target_port": "(none)",
        },
        "why": "about: fragments should stay internal even when popup probes append fragments.",
    },
)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Audit browser-page startup diagnostics for internal browser:// and about: "
            "targets in source or log output."
        )
    )
    parser.add_argument(
        "audit_kind",
        choices=("source", "log"),
        help="Whether to audit src/main.zig coverage or a startup log capture.",
    )
    parser.add_argument(
        "path",
        type=Path,
        help="Path to the source file or startup log to inspect.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the audit result as JSON.",
    )
    return parser.parse_args(argv)


def parse_logfmt_line(line: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for token in shlex.split(line):
        if "=" not in token:
            continue
        key, value = token.split("=", 1)
        fields[key] = value
    return fields


def audit_source(path: str | Path) -> dict[str, object]:
    source_path = Path(path)
    text = source_path.read_text(encoding="utf-8")
    checks = []
    missing = 0

    for expectation in SOURCE_EXPECTATIONS:
        present = expectation["snippet"] in text
        if not present:
            missing += 1
        checks.append({**expectation, "present": present})

    return {
        "audit_kind": "source",
        "path": str(source_path),
        "missing_count": missing,
        "ok": missing == 0,
        "checks": checks,
    }


def audit_log(path: str | Path) -> dict[str, object]:
    log_path = Path(path)
    parsed_lines = [parse_logfmt_line(line) for line in log_path.read_text(encoding="utf-8").splitlines()]
    checks = []
    missing = 0

    for case in INTERNAL_LOG_CASES:
        matched = False
        for fields in parsed_lines:
            if fields.get("url") != case["url"]:
                continue
            if all(fields.get(key) == value for key, value in case["expected_fields"].items()):
                matched = True
                break
        if not matched:
            missing += 1
        checks.append({**case, "present": matched})

    return {
        "audit_kind": "log",
        "path": str(log_path),
        "missing_count": missing,
        "ok": missing == 0,
        "checks": checks,
    }


def emit_result(result: dict[str, object], emit_json: bool) -> None:
    if emit_json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
        return

    status = "PASS" if result["ok"] else "FAIL"
    print(f"[{status}] browser-page internal startup diagnostics audit")
    print(f"Path: {result['path']}")
    print(f"Missing checks: {result['missing_count']}")
    for check in result["checks"]:
        marker = "ok" if check["present"] else "missing"
        print(f"- {marker}: {check['label']}")
        if not check["present"]:
            print(f"  Why: {check['why']}")



def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    result = audit_source(args.path) if args.audit_kind == "source" else audit_log(args.path)
    emit_result(result, args.json)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
