#!/usr/bin/env python3
"""Audit headed attached-page trace-gate coverage across browser helpers."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
from dataclasses import dataclass


REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Target:
    label: str
    relative_path: str
    function_name: str

    @property
    def path(self) -> pathlib.Path:
        return REPO_ROOT / self.relative_path


TARGETS = {
    "session_wait": Target("session wait trace", "src/browser/Session.zig", "googleWaitTraceEnabled"),
    "win32_input": Target("Win32 input trace", "src/display/win32_backend.zig", "googleInputTraceEnabled"),
    "browse_render": Target("browse render trace", "src/lightpanda.zig", "googleRenderTraceEnabled"),
    "page_presentation": Target("page presentation trace", "src/browser/Page.zig", "googlePresentationTraceEnabled"),
}

STRING_LITERAL_RE = re.compile(r'"((?:\\.|[^"\\])*)"')


def extract_function_body(source: str, function_name: str) -> str:
    marker = f"fn {function_name}("
    start = source.find(marker)
    if start == -1:
        raise ValueError(f"could not find function {function_name}")

    brace_start = source.find("{", start)
    if brace_start == -1:
        raise ValueError(f"could not find body for function {function_name}")

    depth = 0
    for index in range(brace_start, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[brace_start + 1 : index]

    raise ValueError(f"unterminated function body for {function_name}")


def extract_string_literals(function_body: str) -> set[str]:
    values: set[str] = set()
    for raw_value in STRING_LITERAL_RE.findall(function_body):
        if raw_value:
            values.add(bytes(raw_value, "utf-8").decode("unicode_escape"))
    return values


def load_literals(target: Target) -> set[str]:
    source = target.path.read_text(encoding="utf-8", errors="strict")
    return extract_string_literals(extract_function_body(source, target.function_name))


def build_report() -> tuple[list[str], bool]:
    baseline = load_literals(TARGETS["session_wait"])
    lines = [
        "Attached trace-gate coverage audit",
        f"Baseline: {TARGETS['session_wait'].label} ({TARGETS['session_wait'].function_name})",
        "",
    ]
    any_missing = False

    for key in ("win32_input", "browse_render", "page_presentation"):
        target = TARGETS[key]
        current = load_literals(target)
        missing = sorted(baseline - current)
        lines.append(f"{target.label} [{target.function_name}]")
        if missing:
            any_missing = True
            lines.append(f"  missing {len(missing)} baseline target(s):")
            for value in missing:
                lines.append(f"    - {value}")
        else:
            lines.append("  missing 0 baseline target(s)")
        lines.append("")

    return lines, any_missing


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit with code 1 when any non-session trace gate is missing a baseline target.",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    lines, any_missing = build_report()
    print("\n".join(lines).rstrip())

    if args.check and any_missing:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
