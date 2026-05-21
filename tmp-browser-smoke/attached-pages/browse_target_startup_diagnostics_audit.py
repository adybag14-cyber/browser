#!/usr/bin/env python3
"""Audit startup target diagnostics for headed browse targets."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "main_browser_internal_helper",
        "path": "src/main.zig",
        "snippet": 'fn browseTargetInternal(url: []const u8, scheme: []const u8) ?BrowseTargetInfo {',
        "why": "Browser-shell routes should keep their dedicated internal diagnostics helper.",
    },
    {
        "label": "main_browser_downloads_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies browser downloads pages as internal" {',
        "why": "browser://downloads should stay on the internal startup diagnostics path.",
    },
    {
        "label": "main_browser_settings_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps browser settings routes on the internal path" {',
        "why": "browser://settings routes should keep the same internal diagnostics classification.",
    },
    {
        "label": "main_about_internal_helper",
        "path": "src/main.zig",
        "snippet": 'fn browseTargetAbout(url: []const u8) ?BrowseTargetInfo {',
        "why": "about: pages should keep their internal startup diagnostics helper.",
    },
    {
        "label": "main_about_blank_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies about blank pages as internal" {',
        "why": "about:blank should stay on the internal startup diagnostics path.",
    },
    {
        "label": "main_about_fragment_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps about fragments on the internal path" {',
        "why": "about:blank#fragment should keep the internal diagnostics route.",
    },
    {
        "label": "main_local_path_candidate_helper",
        "path": "src/main.zig",
        "snippet": 'fn browseTargetLocalPathCandidate(url: []const u8) []const u8 {',
        "why": "Attached-page startup diagnostics should trim query and fragment suffixes before local-path classification.",
    },
    {
        "label": "main_local_html_query_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps attached html queries on the local path route" {',
        "why": "Local .html targets with ?query should stay on the local-path diagnostics route.",
    },
    {
        "label": "main_local_xhtml_fragment_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps attached xhtml fragments on the local path route" {',
        "why": "Local .xhtml targets with #fragment should stay on the local-path diagnostics route.",
    },
    {
        "label": "main_windows_local_path_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies windows attached html paths as local paths" {',
        "why": "Windows-style attached-page paths should keep the local-path diagnostics classification.",
    },
    {
        "label": "main_implicit_loopback_helper",
        "path": "src/main.zig",
        "snippet": 'fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo {',
        "why": "Scheme-less localhost targets should keep their dedicated loopback startup diagnostics helper.",
    },
    {
        "label": "main_localhost_loopback_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies scheme-less localhost pages as loopback" {',
        "why": "localhost:port targets should stay on the loopback diagnostics route.",
    },
    {
        "label": "main_localhost_query_loopback_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps loopback query targets on the implicit http route" {',
        "why": "Scheme-less localhost query targets should keep the implicit loopback diagnostics classification.",
    },
    {
        "label": "main_ipv4_loopback_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps loopback scope for scheme-less ipv4 pages" {',
        "why": "Scheme-less 127.0.0.1 targets should stay on the loopback diagnostics route.",
    },
    {
        "label": "main_implicit_remote_helper",
        "path": "src/main.zig",
        "snippet": 'fn browseTargetImplicitRemote(url: []const u8) ?BrowseTargetInfo {',
        "why": "Scheme-less remote hosts should keep their own startup diagnostics helper instead of falling through to local-path classification.",
    },
    {
        "label": "main_implicit_remote_regression",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies scheme-less remote hosts as implicit http" {',
        "why": "example.com/path should stay on the implicit remote diagnostics route.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether headed browse startup diagnostics still classify "
            "internal pages, local attached-page paths, and scheme-less loopback "
            "targets correctly."
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
        print(f"[{status}] browse target startup diagnostics audit")
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