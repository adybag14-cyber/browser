#!/usr/bin/env python3
"""Summarize headed Google input traces for issue 3 debugging.

This helper reads the pipe-delimited runtime and window trace logs emitted by the
headed Win32 path and prints a compact timeline plus a few targeted heuristics
for the current Google input regression.

Example:
  python scripts/windows/summarize_google_input_trace.py \
    tmp-browser-smoke/google-investigation-next/runtime-input-backend-1234.log \
    tmp-browser-smoke/google-investigation-next/wndproc-input-1234.log
"""

from __future__ import annotations

import argparse
import collections
import pathlib
import sys
from dataclasses import dataclass
from typing import Iterable


@dataclass
class TraceEvent:
    source: str
    line_no: int
    stage: str
    url: str
    fields: dict[str, str]
    raw: str


def parse_line(source: str, line_no: int, raw_line: str) -> TraceEvent | None:
    raw_line = raw_line.strip()
    if not raw_line:
        return None

    parts = raw_line.split("|")
    stage = parts[0]
    fields: dict[str, str] = {}
    detail_parts: list[str] = []

    for part in parts[1:]:
        if "=" in part:
            key, value = part.split("=", 1)
            fields[key] = value
        else:
            detail_parts.append(part)

    if detail_parts:
        fields["detail"] = "|".join(detail_parts)

    return TraceEvent(
        source=source,
        line_no=line_no,
        stage=stage,
        url=fields.get("url", ""),
        fields=fields,
        raw=raw_line,
    )


def iter_events(paths: Iterable[pathlib.Path]) -> list[TraceEvent]:
    events: list[TraceEvent] = []
    for path in paths:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            for line_no, raw_line in enumerate(handle, 1):
                event = parse_line(path.name, line_no, raw_line)
                if event is not None:
                    events.append(event)
    return events


def is_printable_key(value: str) -> bool:
    return len(value) == 1 and value.isprintable()


def compact_fields(event: TraceEvent) -> str:
    ordered_keys = [
        "key",
        "text",
        "vk",
        "default_allowed",
        "allow_text_input",
        "suppressed",
        "value_before",
        "value_after",
        "active_tag",
        "focused_matches",
        "foreground_matches",
        "wparam",
        "detail",
    ]
    parts: list[str] = []
    for key in ordered_keys:
        if key in event.fields:
            parts.append(f"{key}={event.fields[key]}")
    return " ".join(parts)


def print_stage_summary(events: list[TraceEvent]) -> None:
    counts = collections.Counter(event.stage for event in events)
    print("Stage counts:")
    for stage, count in counts.most_common():
        print(f"  {stage}: {count}")
    print()


def print_timeline(events: list[TraceEvent], limit: int) -> None:
    print("Timeline:")
    shown = events if limit <= 0 else events[:limit]
    for idx, event in enumerate(shown, 1):
        detail = compact_fields(event)
        print(f"  {idx:03d} {event.source}:{event.line_no} {event.stage} {detail}".rstrip())
    if limit > 0 and len(events) > limit:
        print(f"  ... {len(events) - limit} more events omitted")
    print()


def detect_findings(events: list[TraceEvent]) -> list[str]:
    findings: list[str] = []
    last_printable_key: str | None = None
    last_enter_index: int | None = None

    for idx, event in enumerate(events):
        key = event.fields.get("key")
        if key and is_printable_key(key):
            last_printable_key = key

        if key == "Enter":
            last_enter_index = idx

        text = event.fields.get("text")
        suppressed = event.fields.get("suppressed")
        if text is not None and suppressed not in (None, "0"):
            findings.append(
                f"suppressed text dispatch at event {idx + 1}: text={text!r} suppressed={suppressed}"
            )

        if text is not None and last_printable_key and text != last_printable_key:
            findings.append(
                f"possible stale text dispatch at event {idx + 1}: text={text!r} last_printable_key={last_printable_key!r}"
            )
            last_printable_key = None
        elif text is not None and text == last_printable_key:
            last_printable_key = None

        if key == "Enter" and event.fields.get("value_before") == event.fields.get("value_after"):
            findings.append(
                f"Enter keydown left value unchanged at event {idx + 1}: value={event.fields.get('value_after', '')!r}"
            )

    if last_enter_index is not None:
        tail = events[last_enter_index + 1 :]
        saw_submit_like = any(
            submit_token in later.stage or submit_token in later.raw.lower()
            for later in tail
            for submit_token in ("submit", "keypress")
        )
        if not saw_submit_like:
            findings.append(
                "no submit-like follow-up after the last Enter event; inspect deferred submit ordering"
            )

    return findings


def print_findings(events: list[TraceEvent]) -> None:
    findings = detect_findings(events)
    print("Heuristics:")
    if not findings:
        print("  no obvious stale-text or Enter-ordering anomalies detected")
    else:
        for finding in findings:
            print(f"  - {finding}")
    print()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", help="trace log paths to summarize")
    parser.add_argument(
        "--limit",
        type=int,
        default=200,
        help="max timeline rows to print; use 0 for all rows",
    )
    return parser


def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    paths = [pathlib.Path(value) for value in args.paths]
    missing = [str(path) for path in paths if not path.exists()]
    if missing:
        for path in missing:
            print(f"missing trace file: {path}", file=sys.stderr)
        return 1

    events = iter_events(paths)
    if not events:
        print("no trace events found", file=sys.stderr)
        return 1

    print_stage_summary(events)
    print_timeline(events, args.limit)
    print_findings(events)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
