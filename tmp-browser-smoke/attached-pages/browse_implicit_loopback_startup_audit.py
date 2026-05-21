#!/usr/bin/env python3
"""Audit whether scheme-less loopback startup diagnostics remain present."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "main_implicit_loopback_helper",
        "path": "src/main.zig",
        "snippet": "fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo {",
        "why": "Headed startup diagnostics should keep a dedicated helper for scheme-less loopback targets.",
    },
    {
        "label": "main_implicit_loopback_scheme",
        "path": "src/main.zig",
        "snippet": '.scheme = "implicit_http",',
        "why": "Scheme-less loopback targets should be labeled as implicit HTTP in startup diagnostics.",
    },
    {
        "label": "main_implicit_loopback_scope",
        "path": "src/main.zig",
        "snippet": '.scope = "loopback",',
        "why": "Scheme-less loopback targets should keep loopback scope classification.",
    },
    {
        "label": "main_implicit_loopback_host_guard",
        "path": "src/main.zig",
        "snippet": "if (!isLoopbackBrowseHost(host)) {",
        "why": "The helper should refuse non-loopback hosts before applying the implicit HTTP classification.",
    },
    {
        "label": "main_implicit_loopback_info_route",
        "path": "src/main.zig",
        "snippet": "if (browseTargetImplicitLoopback(url)) |implicit_loopback| {",
        "why": "browseTargetInfo should consult the implicit loopback helper before falling back to generic local-path handling.",
    },
    {
        "label": "main_browse_startup_target_scheme_log",
        "path": "src/main.zig",
        "snippet": ".target_scheme = browse_target.scheme,",
        "why": "Browse startup logs should still report the resolved target scheme.",
    },
    {
        "label": "main_browse_startup_target_scope_log",
        "path": "src/main.zig",
        "snippet": ".target_scope = browse_target.scope,",
        "why": "Browse startup logs should still report the resolved target scope.",
    },
    {
        "label": "main_localhost_loopback_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies scheme-less localhost pages as loopback" {',
        "why": "The localhost regression should keep proving scheme-less loopback pages stay on the headed localhost route.",
    },
    {
        "label": "main_localhost_loopback_target",
        "path": "src/main.zig",
        "snippet": 'const info = browseTargetInfo("localhost:8123/attached-page.html");',
        "why": "The localhost regression should use a representative local attached-page target.",
    },
    {
        "label": "main_ipv4_loopback_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps loopback scope for scheme-less ipv4 pages" {',
        "why": "The IPv4 regression should keep proving raw loopback addresses stay on the loopback route.",
    },
    {
        "label": "main_ipv4_loopback_target",
        "path": "src/main.zig",
        "snippet": 'const info = browseTargetInfo("127.0.0.1/replay.xhtml");',
        "why": "The IPv4 regression should use a representative local replay target.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether scheme-less loopback browse diagnostics remain wired "
            "through src/main.zig for headed localhost startup validation."
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
        checks.append(
            {
                **expectation,
                "exists": exists,
                "present": present,
            }
        )

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
        print(f"[{status}] scheme-less loopback startup diagnostics audit")
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
