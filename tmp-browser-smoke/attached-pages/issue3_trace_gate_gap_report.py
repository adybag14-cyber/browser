from __future__ import annotations

import argparse
from pathlib import Path
from typing import Mapping

from issue3_trace_target_catalog import ISSUE3_TRACE_HINTS, normalize_trace_text


TRACE_GATE_FUNCTIONS: dict[str, str] = {
    "src/lightpanda.zig": "googleRenderTraceEnabled",
    "src/display/win32_backend.zig": "googleInputTraceEnabled",
    "src/browser/Page.zig": "googlePresentationTraceEnabled",
}


def extract_function_block(source: str, function_name: str) -> str:
    anchor = f"fn {function_name}("
    start = source.find(anchor)
    if start == -1:
        raise ValueError(f"missing function: {function_name}")

    brace_index = source.find("{", start)
    if brace_index == -1:
        raise ValueError(f"missing function body: {function_name}")

    depth = 0
    for index in range(brace_index, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start : index + 1]

    raise ValueError(f"unterminated function body: {function_name}")


def matching_gate_hints(
    source: str,
    function_name: str,
    hints: tuple[str, ...] = ISSUE3_TRACE_HINTS,
) -> dict[str, bool]:
    function_block = normalize_trace_text(extract_function_block(source, function_name))
    return {
        hint: normalize_trace_text(hint) in function_block
        for hint in hints
    }


def missing_gate_hints(
    source: str,
    function_name: str,
    hints: tuple[str, ...] = ISSUE3_TRACE_HINTS,
) -> list[str]:
    return [
        hint
        for hint, present in matching_gate_hints(source, function_name, hints).items()
        if not present
    ]


def audit_trace_gate_source(path: str | Path, function_name: str) -> list[str]:
    source_path = Path(path)
    return missing_gate_hints(source_path.read_text(encoding="utf-8"), function_name)


def audit_trace_gate_sources(
    base_dir: str | Path,
    trace_gate_functions: Mapping[str, str] = TRACE_GATE_FUNCTIONS,
) -> dict[str, list[str]]:
    root = Path(base_dir)
    return {
        relative_path: audit_trace_gate_source(root / relative_path, function_name)
        for relative_path, function_name in trace_gate_functions.items()
    }


def format_gap_report(report: Mapping[str, list[str]]) -> str:
    lines: list[str] = []
    for relative_path, missing in report.items():
        if not missing:
            lines.append(f"{relative_path}: ok")
            continue
        lines.append(f"{relative_path}: missing {len(missing)}")
        for hint in missing:
            lines.append(f"  - {hint}")
    return "\n".join(lines)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit issue #3 trace-gate helpers against the shared attached-page target catalog.",
    )
    parser.add_argument(
        "--base-dir",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Repository root containing the Zig source files to audit.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    report = audit_trace_gate_sources(args.base_dir)
    print(format_gap_report(report))
    return 0 if all(not missing for missing in report.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
