#!/usr/bin/env python3

from __future__ import annotations

import argparse
import pathlib
import re
import sys


PATTERN_SPECS = (
    (
        "arg_iterator",
        re.compile(r"\bstd\.process\.ArgIterator\b"),
        "Old process iterator type name that needs Zig 0.17 Args.Iterator follow-up.",
    ),
    (
        "at_type_builtin",
        re.compile(r"@Type\s*\("),
        "Legacy type-reification builtin usage that Zig 0.17 rejects.",
    ),
    (
        "at_c_import",
        re.compile(r"@cImport\s*\("),
        "Top-level C import usage that still blocks newer Zig parser passes.",
    ),
    (
        "repeat_operator_spacing",
        re.compile(r"\s\*\*\s"),
        "Array/string repetition operator that still appears in the legacy spacing form.",
    ),
)

DEFAULT_ROOTS = ("build.zig", "src")
SKIP_DIRS = {
    ".git",
    ".zig-cache",
    "zig-cache",
    "zig-out",
    "vendor",
}


def iter_targets(repo_root: pathlib.Path, roots: tuple[str, ...]) -> list[pathlib.Path]:
    targets: list[pathlib.Path] = []
    for root in roots:
        candidate = repo_root / root
        if not candidate.exists():
            continue
        if candidate.is_file():
            targets.append(candidate)
            continue
        for path in sorted(candidate.rglob("*")):
            if any(part in SKIP_DIRS for part in path.parts):
                continue
            if path.is_file() and path.suffix in {".zig", ".zon"}:
                targets.append(path)
    return targets


def find_matches(repo_root: pathlib.Path, targets: list[pathlib.Path]) -> list[dict[str, object]]:
    matches: list[dict[str, object]] = []
    for path in targets:
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        for pattern_name, regex, summary in PATTERN_SPECS:
            for match in regex.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                line_start = text.rfind("\n", 0, match.start())
                column = match.start() - line_start
                snippet = text.splitlines()[line - 1].rstrip()
                matches.append(
                    {
                        "pattern": pattern_name,
                        "summary": summary,
                        "path": path.relative_to(repo_root).as_posix(),
                        "line": line,
                        "column": column,
                        "snippet": snippet,
                    }
                )
    return matches


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Scan the browser tree for known Zig 0.17 parser and build-port blockers "
            "that have repeatedly stopped headed-mode validation before focused tests run."
        )
    )
    parser.add_argument(
        "repo_root",
        nargs="?",
        default=".",
        help="Repository root to scan. Defaults to the current directory.",
    )
    parser.add_argument(
        "--roots",
        nargs="+",
        default=list(DEFAULT_ROOTS),
        help=f"Files or directories to scan. Defaults to: {', '.join(DEFAULT_ROOTS)}",
    )
    args = parser.parse_args()

    repo_root = pathlib.Path(args.repo_root).resolve()
    targets = iter_targets(repo_root, tuple(args.roots))
    if not targets:
        print(f"No Zig targets found under {repo_root}", file=sys.stderr)
        return 1

    matches = find_matches(repo_root, targets)

    print("Zig 0.17 blocker audit")
    print(f"Repo root: {repo_root}")
    print(f"Scanned files: {len(targets)}")
    print(f"Matches: {len(matches)}")

    if not matches:
        print("No known parser blockers matched the current patterns.")
        return 0

    grouped: dict[str, list[dict[str, object]]] = {}
    for match in matches:
        grouped.setdefault(match["pattern"], []).append(match)

    for pattern_name, _, summary in PATTERN_SPECS:
        pattern_matches = grouped.get(pattern_name, [])
        if not pattern_matches:
            continue
        print()
        print(f"[{pattern_name}] {len(pattern_matches)} match(es)")
        print(f"  {summary}")
        for match in pattern_matches:
            print(
                f"  - {match['path']}:{match['line']}:{match['column']} :: {match['snippet']}"
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
