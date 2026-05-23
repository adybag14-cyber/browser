#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def _text(value: Any) -> str:
    if value is None:
        return ""
    return str(value)


def _joined_tails(entries: list[dict[str, Any]]) -> str:
    return "\n".join(_text(entry.get("tail")) for entry in entries if entry.get("tail"))


def classify_probe(result: dict[str, Any]) -> tuple[str, list[str]]:
    notes: list[str] = []
    helper_outcome = _text(result.get("helper_outcome"))
    helper_failure_stage = _text(result.get("helper_failure_stage"))
    ready_active = _text(result.get("helper_ready_active_element"))
    ready_query = _text(result.get("helper_ready_query_element"))
    typed_value = _text(result.get("helper_typed_query_value"))
    enter_value = _text(result.get("helper_enter_query_value"))
    last_value = _text(result.get("helper_last_query_value"))
    typed_title = _text(result.get("helper_typed_title"))
    enter_title = _text(result.get("helper_enter_title"))
    last_title = _text(result.get("helper_last_title"))
    backend_tail = _joined_tails(result.get("backend_trace_tails") or [])
    wndproc_tail = _joined_tails(result.get("wndproc_trace_tails") or [])

    if helper_outcome != "completed":
        if helper_failure_stage:
            notes.append(f"probe helper did not complete; failure stage: {helper_failure_stage}")
        else:
            notes.append("probe helper did not complete")
        return "probe-failed", notes

    if "INPUT" not in ready_active and "INPUT" not in ready_query:
        notes.append("ready state never showed the Google query input as the active or query element")
        return "focus-drift", notes

    submit_seen = "SUBMIT:" in enter_title or "SUBMIT:" in last_title
    typed_seen = bool(typed_value or enter_value or last_value or "TYPED:" in typed_title)

    if not typed_seen:
        if "allow_text_input=True" in backend_tail and "dispatch_text_begin" in wndproc_tail:
            notes.append("keydown allowed text input and native text_input arrived, but the query value still stayed empty")
            notes.append("this points at text being dropped after the Win32/native input boundary")
            return "likely-text-suppression-or-drop", notes
        notes.append("the query never showed a typed value during the probe")
        return "typed-text-not-committed", notes

    if not submit_seen:
        if "KEYDOWN:" in enter_title or "KEYDOWN:" in last_title:
            notes.append("Enter reached the keydown/title stage but the title never transitioned to SUBMIT")
        else:
            notes.append("the probe typed text successfully, but submit did not complete")
        return "enter-submit-not-reached", notes

    notes.append("typed text and submit markers both appeared in the reduced Google probe")
    return "healthy-submit-path", notes


def summarize_probe(result: dict[str, Any]) -> dict[str, Any]:
    classification, notes = classify_probe(result)
    backend_files = result.get("backend_trace_files") or []
    wndproc_files = result.get("wndproc_trace_files") or []
    return {
        "classification": classification,
        "notes": notes,
        "ready_marker": _text(result.get("helper_ready_marker")),
        "typed_marker": _text(result.get("helper_typed_marker")),
        "enter_marker": _text(result.get("helper_enter_marker")),
        "last_marker": _text(result.get("helper_last_marker")),
        "ready_active_element": _text(result.get("helper_ready_active_element")),
        "ready_query_element": _text(result.get("helper_ready_query_element")),
        "typed_query_value": _text(result.get("helper_typed_query_value")),
        "enter_query_value": _text(result.get("helper_enter_query_value")),
        "last_query_value": _text(result.get("helper_last_query_value")),
        "helper_outcome": _text(result.get("helper_outcome")),
        "helper_failure_stage": _text(result.get("helper_failure_stage")),
        "backend_trace_files": backend_files,
        "wndproc_trace_files": wndproc_files,
        "backend_trace_tail": _joined_tails(result.get("backend_trace_tails") or []),
        "wndproc_trace_tail": _joined_tails(result.get("wndproc_trace_tails") or []),
    }


def format_summary(summary: dict[str, Any]) -> str:
    lines = [
        f"classification: {summary['classification']}",
        f"helper_outcome: {summary['helper_outcome'] or '(unknown)'}",
        f"ready_marker: {summary['ready_marker'] or '(missing)'}",
        f"typed_marker: {summary['typed_marker'] or '(missing)'}",
        f"enter_marker: {summary['enter_marker'] or '(missing)'}",
        f"last_marker: {summary['last_marker'] or '(missing)'}",
        f"ready_active_element: {summary['ready_active_element'] or '(missing)'}",
        f"ready_query_element: {summary['ready_query_element'] or '(missing)'}",
        f"typed_query_value: {summary['typed_query_value'] or '(empty)'}",
        f"enter_query_value: {summary['enter_query_value'] or '(empty)'}",
        f"last_query_value: {summary['last_query_value'] or '(empty)'}",
    ]

    for note in summary["notes"]:
        lines.append(f"note: {note}")

    if summary["backend_trace_files"]:
        lines.append("backend_trace_files: " + ", ".join(summary["backend_trace_files"]))
    if summary["wndproc_trace_files"]:
        lines.append("wndproc_trace_files: " + ", ".join(summary["wndproc_trace_files"]))
    if summary["backend_trace_tail"]:
        lines.append("backend_trace_tail:")
        lines.extend(f"  {line}" for line in summary["backend_trace_tail"].splitlines())
    if summary["wndproc_trace_tail"]:
        lines.append("wndproc_trace_tail:")
        lines.extend(f"  {line}" for line in summary["wndproc_trace_tail"].splitlines())
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Summarize the JSON output from chrome-google-home-title-probe.ps1."
    )
    parser.add_argument("probe_json", help="Path to the JSON file captured from the PowerShell probe.")
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the summarized diagnosis as JSON instead of plain text.",
    )
    parser.add_argument(
        "--fail-on-unhealthy",
        action="store_true",
        help="Exit non-zero unless the reduced Google probe reached a healthy submit path.",
    )
    args = parser.parse_args(argv)

    probe_path = Path(args.probe_json)
    result = json.loads(probe_path.read_text(encoding="utf-8"))
    summary = summarize_probe(result)

    if args.json:
        json.dump(summary, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        print(format_summary(summary))

    if args.fail-on-unhealthy and summary["classification"] != "healthy-submit-path":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
