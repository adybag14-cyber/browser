#!/usr/bin/env python3
"""Summarize early Zig 0.17 parser and compile blockers for the browser tree."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path


ERROR_RE = re.compile(
    r"^(?P<path>.+?):(?P<line>\d+):(?P<column>\d+): error: (?P<message>.+)$"
)


@dataclass
class ZigError:
    path: str
    line: int
    column: int
    message: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run a Zig command inside the browser repo and summarize the first "
            "wave of parser/compile blockers."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Browser repo root to run the Zig command in.",
    )
    parser.add_argument(
        "--zig",
        required=True,
        help="Path to the Zig binary to run.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable JSON instead of a text summary.",
    )
    parser.add_argument(
        "zig_args",
        nargs=argparse.REMAINDER,
        help=(
            "Zig arguments to run. If omitted, defaults to: "
            "test src/Config.zig"
        ),
    )
    return parser.parse_args()


def normalize_command(zig_path: str, zig_args: list[str]) -> list[str]:
    if zig_args and zig_args[0] == "--":
        zig_args = zig_args[1:]
    if not zig_args:
        zig_args = ["test", "src/Config.zig"]
    return [zig_path, *zig_args]


def run_command(repo_root: Path, command: list[str]) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env.setdefault("NO_COLOR", "1")
    return subprocess.run(
        command,
        cwd=repo_root,
        env=env,
        capture_output=True,
        text=True,
    )


def parse_errors(stderr: str) -> list[ZigError]:
    errors: list[ZigError] = []
    for line in stderr.splitlines():
        match = ERROR_RE.match(line)
        if not match:
            continue
        errors.append(
            ZigError(
                path=match.group("path"),
                line=int(match.group("line")),
                column=int(match.group("column")),
                message=match.group("message"),
            )
        )
    return errors


def summarize(errors: list[ZigError]) -> dict[str, object]:
    by_message = Counter(error.message for error in errors)
    by_path: dict[str, list[dict[str, object]]] = defaultdict(list)
    for error in errors:
        by_path[error.path].append(
            {
                "line": error.line,
                "column": error.column,
                "message": error.message,
            }
        )
    return {
        "error_count": len(errors),
        "messages": dict(by_message.most_common()),
        "files": dict(sorted(by_path.items())),
    }


def print_text_summary(
    command: list[str],
    result: subprocess.CompletedProcess[str],
    summary: dict[str, object],
) -> int:
    print(f"command: {' '.join(command)}")
    print(f"exit_code: {result.returncode}")
    print(f"error_count: {summary['error_count']}")

    messages: dict[str, int] = summary["messages"]  # type: ignore[assignment]
    if messages:
        print("top_messages:")
        for message, count in messages.items():
            print(f"  - {count}x {message}")

    files: dict[str, list[dict[str, object]]] = summary["files"]  # type: ignore[assignment]
    if files:
        print("files:")
        for path, items in files.items():
            print(f"  - {path}")
            for item in items:
                print(
                    f"    {item['line']}:{item['column']} {item['message']}"
                )

    if result.stderr:
        print("stderr_preview:")
        for line in result.stderr.splitlines()[:20]:
            print(f"  {line}")

    return 0


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    command = normalize_command(args.zig, args.zig_args)
    result = run_command(repo_root, command)
    errors = parse_errors(result.stderr)
    summary = summarize(errors)

    payload = {
        "command": command,
        "cwd": str(repo_root),
        "exit_code": result.returncode,
        "summary": summary,
        "errors": [asdict(error) for error in errors],
    }

    if args.json:
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
        return 0

    return print_text_summary(command, result, summary)


if __name__ == "__main__":
    raise SystemExit(main())
