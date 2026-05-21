#!/usr/bin/env python3
"""Audit Google issue #3 Enter-order trace probe results."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any


EXPECTED_STAGE_PREFIXES: tuple[tuple[str, str], ...] = (
    ("title_after_focus", "FOCUSED|"),
    ("title_after_type", "TYPED:"),
    ("title_after_keydown", "KEYDOWN:"),
    ("title_after_keypress", "KEYPRESS:"),
    ("title_after_submit", "SUBMIT:"),
)

TIMESTAMP_SEQUENCE: tuple[tuple[str, str], ...] = (
    ("server_ready_at_utc", "screenshot_ready_at_utc"),
    ("screenshot_ready_at_utc", "window_ready_at_utc"),
    ("window_ready_at_utc", "focus_observed_at_utc"),
    ("focus_observed_at_utc", "input_sent_at_utc"),
    ("input_sent_at_utc", "typed_observed_at_utc"),
    ("typed_observed_at_utc", "enter_sent_at_utc"),
    ("enter_sent_at_utc", "keydown_observed_at_utc"),
    ("keydown_observed_at_utc", "keypress_observed_at_utc"),
    ("keypress_observed_at_utc", "submit_observed_at_utc"),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Audit the JSON output from "
            "tmp-browser-smoke/google-investigation-next/"
            "chrome-google-home-enter-trace-probe.ps1."
        )
    )
    parser.add_argument(
        "result_json",
        type=Path,
        help="Path to a saved JSON result from the Google Enter trace probe.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the audit summary as JSON.",
    )
    return parser.parse_args()


def parse_timestamp(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def marker_matches(value: Any, prefix: str) -> bool:
    return isinstance(value, str) and value.startswith(prefix)


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def audit(result: dict[str, Any]) -> dict[str, Any]:
    checks: list[dict[str, Any]] = []

    def add_check(label: str, ok: bool, why: str, observed: Any = None) -> None:
        checks.append(
            {
                "label": label,
                "ok": ok,
                "why": why,
                "observed": observed,
            }
        )

    add_check(
        "focused_worked",
        bool(result.get("focused_worked")),
        "The reduced Google trace should prove the headed click reached the query input.",
        result.get("focused_worked"),
    )
    add_check(
        "typed_worked",
        bool(result.get("typed_worked")),
        "The trace should prove typed text appeared before submit is attempted.",
        result.get("typed_worked"),
    )

    submitted_worked = bool(result.get("submitted_worked"))
    server_saw_submit = bool(result.get("server_saw_submit"))
    add_check(
        "submit_evidence",
        submitted_worked or server_saw_submit,
        "Either the title probe or the local server should report submit evidence.",
        {
            "submitted_worked": submitted_worked,
            "server_saw_submit": server_saw_submit,
        },
    )

    for field, prefix in EXPECTED_STAGE_PREFIXES:
        value = result.get(field)
        required = field not in {"title_after_keypress"} or result.get("keypress_observed_at_utc")
        ok = marker_matches(value, prefix) if required else True
        add_check(
            f"{field}_marker",
            ok,
            f"{field} should start with {prefix!r} when that phase is present.",
            value,
        )

    for earlier_key, later_key in TIMESTAMP_SEQUENCE:
        earlier = parse_timestamp(result.get(earlier_key))
        later = parse_timestamp(result.get(later_key))
        required = earlier is not None and later is not None
        ok = (earlier <= later) if required else True
        add_check(
            f"{earlier_key}_before_{later_key}",
            ok,
            "Observed timestamps should move forward through focus, typing, Enter, and submit.",
            {
                "earlier": result.get(earlier_key),
                "later": result.get(later_key),
            },
        )

    trace_artifacts = result.get("trace_artifacts")
    artifact_list = trace_artifacts if isinstance(trace_artifacts, list) else []
    add_check(
        "runtime_input_trace_present",
        any("runtime-input-backend-" in str(path) for path in artifact_list),
        "The reduced trace should keep the backend input logs attached for issue #3 replays.",
        artifact_list,
    )
    add_check(
        "wndproc_trace_present",
        any("wndproc-input-" in str(path) for path in artifact_list),
        "The reduced trace should keep the Win32 wndproc logs attached for issue #3 replays.",
        artifact_list,
    )

    failure_stage = result.get("failure_stage")
    add_check(
        "failure_stage_consistent",
        failure_stage is None or not submitted_worked,
        "A completed submit path should not still report a failure stage.",
        failure_stage,
    )

    ok = all(check["ok"] for check in checks)
    return {
        "ok": ok,
        "failure_stage": failure_stage,
        "check_count": len(checks),
        "failed_checks": [check for check in checks if not check["ok"]],
        "checks": checks,
    }


def main() -> int:
    args = parse_args()
    result = read_json(args.result_json.resolve())
    summary = audit(result)

    if args.json:
        json.dump(summary, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if summary["ok"] else "FAIL"
        print(f"[{status}] google enter submit trace audit")
        if summary["failure_stage"]:
            print(f"Failure stage: {summary['failure_stage']}")
        print(
            f"Matched {summary['check_count'] - len(summary['failed_checks'])} of "
            f"{summary['check_count']} checks."
        )
        for check in summary["failed_checks"]:
            print(f"- {check['label']}: {check['why']}")
            print(f"  Observed: {check['observed']}")

    return 0 if summary["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())