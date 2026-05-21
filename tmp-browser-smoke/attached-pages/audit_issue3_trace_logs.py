from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Iterable, Iterator

from issue3_trace_target_catalog import (
    REPRESENTATIVE_TRACE_URLS,
    matching_trace_urls,
    missing_trace_urls,
)


def iter_trace_paths(inputs: Iterable[str | Path]) -> Iterator[Path]:
    for raw in inputs:
        path = Path(raw)
        if path.is_dir():
            yield from sorted(candidate for candidate in path.glob("*.log") if candidate.is_file())
        elif path.is_file():
            yield path


def load_trace_lines(paths: Iterable[Path]) -> list[str]:
    lines: list[str] = []
    for path in paths:
        lines.extend(path.read_text(encoding="utf-8").splitlines())
    return lines


def format_report(paths: list[Path], lines: list[str]) -> str:
    seen = matching_trace_urls(lines)
    missing = missing_trace_urls(lines)
    present = [name for name, matched in seen.items() if matched]

    report_lines = [
        f"Trace files: {len(paths)}",
        f"Trace lines: {len(lines)}",
        f"Matched targets: {len(present)}/{len(REPRESENTATIVE_TRACE_URLS)}",
    ]
    if present:
        report_lines.append("Matched: " + ", ".join(present))
    if missing:
        report_lines.append("Missing: " + ", ".join(missing))
    else:
        report_lines.append("Missing: none")
    return "\n".join(report_lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Audit headed Google and attached-page trace logs against the issue #3 "
            "trace target catalog."
        )
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=["tmp-browser-smoke/google-investigation-next"],
        help="Trace log files or directories to scan. Directories are searched for *.log files.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    paths = list(iter_trace_paths(args.paths))
    if not paths:
        print("No trace log files found.", file=sys.stderr)
        return 2

    lines = load_trace_lines(paths)
    print(format_report(paths, lines))
    return 0 if not missing_trace_urls(lines) else 1


if __name__ == "__main__":
    raise SystemExit(main())
