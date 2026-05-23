#!/usr/bin/env python3
"""Audit the headed runtime activation logging contract in src/main.zig."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "headed_runtime_helper",
        "path": "src/main.zig",
        "snippet": (
            "fn headedRuntimeActive(requested_mode: Config.BrowserMode, "
            "runtime_mode: Config.BrowserMode) bool {\n"
            "    return requested_mode == .headed and runtime_mode == .headed;\n"
            "}"
        ),
        "why": "The activation log should stay gated on an explicit headed-runtime helper.",
    },
    {
        "label": "headed_runtime_binding",
        "path": "src/main.zig",
        "snippet": (
            "const headed_runtime_active = headedRuntimeActive("
            "requested_browser_mode, browser_mode);"
        ),
        "why": "The run path should bind the helper result once and reuse it for both command surfaces.",
    },
    {
        "label": "serve_headed_runtime_log",
        "path": "src/main.zig",
        "snippet": (
            'log.info(.app, "serve headed runtime", .{\n'
            "                    .host = opts.host,\n"
            "                    .port = opts.port,\n"
            "                    .requested = @tagName(requested_browser_mode),\n"
            "                    .runtime = @tagName(browser_mode),\n"
            "                    .target_class = @tagName(lp.build_config.target_class),\n"
            "                    .os = @tagName(builtin.os.tag),\n"
            '                    .window = "enabled",\n'
            "                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),\n"
            "                    .window_width = args.windowWidth(),\n"
            "                    .window_height = args.windowHeight(),\n"
            "                    .snapshot = app.snapshot.fromEmbedded(),\n"
            "                });"
        ),
        "why": "Serve mode should keep the full headed activation evidence on one info log line.",
    },
    {
        "label": "browse_headed_runtime_log",
        "path": "src/main.zig",
        "snippet": (
            'log.info(.app, "browse headed runtime", .{\n'
            "                    .url = url,\n"
            "                    .requested = @tagName(requested_browser_mode),\n"
            "                    .runtime = @tagName(browser_mode),\n"
            "                    .target_class = @tagName(lp.build_config.target_class),\n"
            "                    .os = @tagName(builtin.os.tag),\n"
            '                    .window = "enabled",\n'
            "                    .profile_dir = resolvedProfileDirLabel(app.app_dir_path),\n"
            "                    .window_width = args.windowWidth(),\n"
            "                    .window_height = args.windowHeight(),\n"
            "                    .snapshot = app.snapshot.fromEmbedded(),\n"
            "                });"
        ),
        "why": "Browse mode should keep the headed activation signal and target URL visible together.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig still exposes the headed runtime "
            "activation helper and the paired serve/browse info logs."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current script's repo.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the full audit summary as JSON.",
    )
    return parser.parse_args()


def audit(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    missing = 0

    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        exists = target.is_file()
        if exists:
            text = target.read_text(encoding="utf-8")
            present = expectation["snippet"] in text
        else:
            present = False
        if not present:
            missing += 1
        checks.append({**expectation, "exists": exists, "present": present})

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(EXPECTATIONS),
        "missing_count": missing,
        "ok": missing == 0,
        "checks": checks,
    }


def main() -> int:
    args = parse_args()
    result = audit(args.repo_root.resolve())

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] headed runtime activation log audit")
        print(f"Repo root: {result['repo_root']}")
        print(
            f"Matched {result['expectation_count'] - result['missing_count']} of "
            f"{result['expectation_count']} expectations."
        )
        for check in result["checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {marker}: {check['label']} ({check['path']})")
            if not check["present"]:
                print(f"  Why: {check['why']}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
