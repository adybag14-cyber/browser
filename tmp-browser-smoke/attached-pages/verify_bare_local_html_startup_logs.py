#!/usr/bin/env python3

from __future__ import annotations

import argparse
import pathlib
import shlex
import sys
from dataclasses import dataclass


DEFAULT_EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    ("attached-page.html", "path", "local_path"),
    ("attached-page.html?case=1", "path", "local_path"),
    ("attached-page.xhtml#focus-probe", "path", "local_path"),
    ("report.v1.html", "path", "local_path"),
    ("report.v1.xhtml#focus-probe", "path", "local_path"),
    ("localhost:8123/attached-page.html", "implicit_http", "loopback"),
    ("example.com/attached-page.html", "implicit_http", "remote"),
)

TARGET_MESSAGES = {
    "startup",
    "browse headed runtime",
    "browse headed fallback",
    "browse finished",
}


@dataclass(frozen=True)
class StartupTargetRecord:
    source: str
    line_number: int
    message: str
    url: str
    target_scheme: str
    target_scope: str


def parse_logfmt_line(line: str) -> dict[str, str]:
    result: dict[str, str] = {}
    try:
        parts = shlex.split(line, comments=False, posix=True)
    except ValueError:
        return result
    for part in parts:
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        result[key] = value
    return result


def extract_startup_records(text: str, source: str) -> list[StartupTargetRecord]:
    records: list[StartupTargetRecord] = []
    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        fields = parse_logfmt_line(raw_line)
        if fields.get("msg") not in TARGET_MESSAGES:
            continue
        url = fields.get("url")
        target_scheme = fields.get("target_scheme")
        target_scope = fields.get("target_scope")
        if not url or not target_scheme or not target_scope:
            continue
        records.append(
            StartupTargetRecord(
                source=source,
                line_number=line_number,
                message=fields["msg"],
                url=url,
                target_scheme=target_scheme,
                target_scope=target_scope,
            )
        )
    return records


def validate_records(
    records: list[StartupTargetRecord],
    expectations: tuple[tuple[str, str, str], ...] = DEFAULT_EXPECTATIONS,
) -> list[str]:
    failures: list[str] = []
    indexed = {record.url: record for record in records}
    for url, expected_scheme, expected_scope in expectations:
        record = indexed.get(url)
        if record is None:
            failures.append(f"missing startup target record for {url}")
            continue
        if record.target_scheme != expected_scheme or record.target_scope != expected_scope:
            failures.append(
                f"{url} expected {expected_scheme}/{expected_scope} "
                f"but saw {record.target_scheme}/{record.target_scope} "
                f"from {record.source}:{record.line_number}"
            )
    return failures


def load_records_from_path(path: pathlib.Path) -> list[StartupTargetRecord]:
    return extract_startup_records(path.read_text(encoding="utf-8"), str(path))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Validate headed startup log target classification for bare local "
            "HTML/XHTML pages and nearby loopback or remote comparison cases."
        )
    )
    parser.add_argument("paths", nargs="*", help="log files to inspect")
    parser.add_argument(
        "--stdin",
        action="store_true",
        help="read log text from standard input in addition to any file paths",
    )
    args = parser.parse_args(argv)

    records: list[StartupTargetRecord] = []
    if args.stdin:
        records.extend(extract_startup_records(sys.stdin.read(), "<stdin>"))
    for raw_path in args.paths:
        records.extend(load_records_from_path(pathlib.Path(raw_path)))

    if not records:
        print("No startup target records found.", file=sys.stderr)
        return 2

    failures = validate_records(records)
    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1

    checked_urls = ", ".join(url for url, _, _ in DEFAULT_EXPECTATIONS)
    print(f"OK: validated startup target routing for {checked_urls}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
