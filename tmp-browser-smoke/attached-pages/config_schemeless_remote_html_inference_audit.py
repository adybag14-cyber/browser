#!/usr/bin/env python3
"""Audit the Config.zig guardrails for scheme-less remote HTML inference."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "config_scheme_less_authority_scope_enum_present",
        "path": "src/Config.zig",
        "snippet": "const BrowseAuthorityScope = enum { local, loopback, remote };",
        "why": (
            "Scheme-less HTML inference should classify local paths, loopback "
            "hosts, and implicit remote hosts explicitly before auto-browse wins."
        ),
    },
    {
        "label": "config_scheme_less_authority_scope_helper_present",
        "path": "src/Config.zig",
        "snippet": "fn inferSchemeLessBrowseAuthorityScope(token: []const u8) BrowseAuthorityScope {",
        "why": (
            "The surviving startup mismatch needs a dedicated scheme-less "
            "authority classifier instead of treating every .html token as local."
        ),
    },
    {
        "label": "config_scheme_less_authority_extracts_leading_segment",
        "path": "src/Config.zig",
        "snippet": "const authority_end = std.mem.indexOfAny(u8, candidate, \"/\\\\\") orelse candidate.len;",
        "why": (
            "The scheme-less authority classifier should inspect the leading "
            "authority before any path segment."
        ),
    },
    {
        "label": "config_scheme_less_authority_strips_userinfo",
        "path": "src/Config.zig",
        "snippet": "const userinfo_index = std.mem.lastIndexOfScalar(u8, authority, '@');",
        "why": (
            "Userinfo should not confuse host classification when a scheme-less "
            "authority looks remote."
        ),
    },
    {
        "label": "config_scheme_less_loopback_localhost_guard",
        "path": "src/Config.zig",
        "snippet": "if (std.ascii.eqlIgnoreCase(host, \"localhost\") or std.ascii.endsWithIgnoreCase(host, \".localhost\")) {",
        "why": (
            "Scheme-less localhost targets should keep browse inference on the "
            "headed localhost route."
        ),
    },
    {
        "label": "config_scheme_less_loopback_ipv4_guard",
        "path": "src/Config.zig",
        "snippet": "if (std.mem.eql(u8, host, \"0.0.0.0\") or std.mem.startsWith(u8, host, \"127.\")) {",
        "why": (
            "Scheme-less loopback IPv4 targets should stay on browse instead of "
            "dropping to the generic fetch fallback."
        ),
    },
    {
        "label": "config_scheme_less_loopback_ipv6_guard",
        "path": "src/Config.zig",
        "snippet": "if (std.ascii.eqlIgnoreCase(host, \"[::1]\") or std.ascii.eqlIgnoreCase(host, \"[0:0:0:0:0:0:0:1]\")) {",
        "why": (
            "Scheme-less IPv6 loopback targets should keep the same local browse "
            "path as localhost and 127.x.x.x."
        ),
    },
    {
        "label": "config_scheme_less_remote_dotted_host_guard",
        "path": "src/Config.zig",
        "snippet": "if (std.mem.indexOfScalar(u8, host, '.') != null) {",
        "why": (
            "Dotted authorities such as example.com should stay on fetch when "
            "there is no explicit browse-only hint."
        ),
    },
    {
        "label": "config_scheme_less_remote_guard_precedes_html_suffix_autobrowse",
        "path": "src/Config.zig",
        "snippet": (
            "const authority_scope = inferSchemeLessBrowseAuthorityScope(token);\n"
            "    if (authority_scope == .remote) {\n"
            "        return false;\n"
            "    }\n"
            "    const candidate = trimLocalBrowseTarget(token);"
        ),
        "why": (
            "Remote scheme-less HTML targets should be rejected before local "
            "HTML/XHTML suffix checks auto-browse them."
        ),
    },
    {
        "label": "config_scheme_less_remote_html_fetch_regression",
        "path": "src/Config.zig",
        "snippet": "test \"infer mode keeps fetch for scheme-less remote html target without browse hint\" {",
        "why": (
            "Regression coverage should keep example.com/attached-page.html on "
            "the fetch fallback."
        ),
    },
    {
        "label": "config_scheme_less_remote_xhtml_fetch_regression",
        "path": "src/Config.zig",
        "snippet": "test \"infer mode keeps fetch for scheme-less remote xhtml target without browse hint\" {",
        "why": (
            "Regression coverage should keep scheme-less remote .xhtml targets on "
            "fetch when there is no explicit browse hint."
        ),
    },
    {
        "label": "config_scheme_less_loopback_html_browse_regression",
        "path": "src/Config.zig",
        "snippet": "test \"infer mode keeps browse for scheme-less loopback html target\" {",
        "why": (
            "Loopback hostname HTML targets should keep browse inference on the "
            "headed localhost path."
        ),
    },
    {
        "label": "config_scheme_less_ipv4_loopback_html_browse_regression",
        "path": "src/Config.zig",
        "snippet": "test \"infer mode keeps browse for scheme-less ipv4 loopback html target\" {",
        "why": (
            "IPv4 loopback HTML targets should keep browse inference even without "
            "an explicit scheme."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/Config.zig distinguishes scheme-less remote HTML/XHTML "
            "targets from local and loopback browse inputs."
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
        print(f"[{status}] Config scheme-less remote HTML inference audit")
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
