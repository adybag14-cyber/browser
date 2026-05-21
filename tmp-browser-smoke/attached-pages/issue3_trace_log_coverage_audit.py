from __future__ import annotations

import argparse
from pathlib import Path
from typing import Iterable, Mapping


REPRESENTATIVE_TRACE_URLS: dict[str, str] = {
    "google-home": "https://www.google.com/",
    "fixture-title-probe": "http://127.0.0.1:8000/google_home_title_probe.html",
    "fixture-onload-input": "http://127.0.0.1:8000/body_onload_keyboard_input.html",
    "fixture-mousedown-input": "http://127.0.0.1:8000/mouse_down_focus_input.html",
    "saved-google-safety": "file:///tmp/Control%20your%20online%20safety%20and%20privacy%20%E2%80%93%20Google%20Safety%20Centre.html",
    "saved-anthropic-job": "file:///tmp/Job%20Application%20for%20Research%20Manager%20at%20Anthropic.html",
    "saved-department-of-war": "file:///tmp/Presidential%20Unsealing%20and%20Reporting%20System%20for%20UAP%20Encounters%20_%20U.S.%20Department%20of%20War.html",
}

TRACE_LOG_PATTERNS: dict[str, str] = {
    "browse-render": "browse-render.log",
    "runtime-input": "runtime-input-backend-*.log",
    "wndproc-input": "wndproc-input-*.log",
}


def normalize_trace_text(text: str) -> str:
    return text.casefold()


def collect_matching_lines(log_root: str | Path, pattern: str) -> list[str]:
    root = Path(log_root)
    lines: list[str] = []
    for path in sorted(root.glob(pattern)):
        if not path.is_file():
            continue
        lines.extend(path.read_text(encoding="utf-8").splitlines())
    return lines


def matching_trace_urls(
    lines: Iterable[str],
    representative_urls: Mapping[str, str] = REPRESENTATIVE_TRACE_URLS,
) -> dict[str, bool]:
    normalized_lines = [normalize_trace_text(line) for line in lines]
    return {
        name: any(normalize_trace_text(url) in line for line in normalized_lines)
        for name, url in representative_urls.items()
    }


def missing_trace_urls(
    lines: Iterable[str],
    representative_urls: Mapping[str, str] = REPRESENTATIVE_TRACE_URLS,
) -> list[str]:
    return [
        name
        for name, present in matching_trace_urls(lines, representative_urls).items()
        if not present
    ]


def audit_trace_logs(
    log_root: str | Path,
    trace_log_patterns: Mapping[str, str] = TRACE_LOG_PATTERNS,
) -> dict[str, list[str]]:
    return {
        family: missing_trace_urls(collect_matching_lines(log_root, pattern))
        for family, pattern in trace_log_patterns.items()
    }


def format_gap_report(report: Mapping[str, list[str]]) -> str:
    lines: list[str] = []
    for family, missing in report.items():
        if not missing:
            lines.append(f"{family}: ok")
            continue
        lines.append(f"{family}: missing {len(missing)}")
        for name in missing:
            lines.append(f"  - {name}")
    return "\n".join(lines)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit issue #3 headed trace logs for representative Google and attached-page targets.",
    )
    parser.add_argument(
        "--log-root",
        type=Path,
        default=Path(__file__).resolve().parents[2] / "tmp-browser-smoke" / "google-investigation-next",
        help="Directory containing browse-render.log and the headed input trace logs.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    report = audit_trace_logs(args.log_root)
    print(format_gap_report(report))
    return 0 if all(not missing for missing in report.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())