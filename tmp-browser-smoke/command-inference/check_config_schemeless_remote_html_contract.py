#!/usr/bin/env python3
"""Guard the Config.zig contract for scheme-less remote HTML inference.

This helper is intentionally source-based rather than build-based so it can run
in lightweight debugging environments where the full browser toolchain or a
current writable checkout is unavailable.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


UNSAFE_MARKERS = (
    'std.ascii.eqlIgnoreCase(candidate[candidate.len - 6 ..], ".xhtml")',
    'std.ascii.eqlIgnoreCase(candidate[candidate.len - 5 ..], ".html")',
    'std.ascii.eqlIgnoreCase(candidate[candidate.len - 4 ..], ".htm")',
)

SAFETY_MARKERS = (
    "authority",
    "loopback",
    "localhost",
    ".localhost",
    "127.",
    "0.0.0.0",
    "[::1]",
    "[0:0:0:0:0:0:0:1]",
    "remote",
)


def extract_function(source: str, name: str) -> str:
    match = re.search(rf"fn {re.escape(name)}\([^)]*\) [^{{]*\{{", source)
    if not match:
        raise ValueError(f"missing function: {name}")

    start = match.start()
    brace_index = source.find("{", match.end() - 1)
    depth = 0
    for index in range(brace_index, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start : index + 1]

    raise ValueError(f"unterminated function: {name}")


def detect_blanket_html_browse(function_text: str) -> bool:
    if "trimLocalBrowseTarget(token)" not in function_text:
        return False
    if not all(marker in function_text for marker in UNSAFE_MARKERS):
        return False
    return not any(marker in function_text for marker in SAFETY_MARKERS)


def evaluate_contract(source: str) -> tuple[bool, str]:
    try:
        infer_local = extract_function(source, "inferLocalBrowseTarget")
    except ValueError as exc:
        return False, str(exc)

    if "file://" not in infer_local:
        return False, "inferLocalBrowseTarget no longer recognizes explicit file:// targets"

    if 'std.mem.indexOf(u8, token, "://") != null' not in infer_local:
        return False, 'inferLocalBrowseTarget no longer short-circuits fully qualified URLs before local HTML inference'

    if detect_blanket_html_browse(infer_local):
        return False, (
            "inferLocalBrowseTarget still blanket-matches scheme-less .html/.htm/.xhtml "
            "targets without a loopback-or-authority check"
        )

    return True, "contract looks guarded against scheme-less remote HTML auto-browse"


def run_self_test() -> int:
    vulnerable = """
fn trimLocalBrowseTarget(token: []const u8) []const u8 {
    return token;
}

fn inferLocalBrowseTarget(token: []const u8) bool {
    if (std.ascii.startsWithIgnoreCase(token, "file://")) {
        return true;
    }
    if (std.mem.indexOf(u8, token, "://") != null) {
        return false;
    }
    const candidate = trimLocalBrowseTarget(token);
    if (candidate.len >= 6 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 6 ..], ".xhtml")) {
        return true;
    }
    if (candidate.len >= 5 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 5 ..], ".html")) {
        return true;
    }
    if (candidate.len >= 4 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 4 ..], ".htm")) {
        return true;
    }
    return false;
}
"""

    guarded = """
fn trimLocalBrowseTarget(token: []const u8) []const u8 {
    return token;
}

fn inferLocalBrowseTargetAuthorityLooksRemote(authority: []const u8) bool {
    return std.mem.indexOfScalar(u8, authority, '.') != null and
        !std.ascii.eqlIgnoreCase(authority, "localhost") and
        !std.ascii.endsWithIgnoreCase(authority, ".localhost") and
        !std.ascii.startsWithIgnoreCase(authority, "127.") and
        !std.mem.eql(u8, authority, "0.0.0.0");
}

fn inferLocalBrowseTarget(token: []const u8) bool {
    if (std.ascii.startsWithIgnoreCase(token, "file://")) {
        return true;
    }
    if (std.mem.indexOf(u8, token, "://") != null) {
        return false;
    }
    const candidate = trimLocalBrowseTarget(token);
    const authority = candidate;
    if (inferLocalBrowseTargetAuthorityLooksRemote(authority)) {
        return false;
    }
    if (candidate.len >= 6 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 6 ..], ".xhtml")) {
        return true;
    }
    if (candidate.len >= 5 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 5 ..], ".html")) {
        return true;
    }
    if (candidate.len >= 4 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 4 ..], ".htm")) {
        return true;
    }
    return false;
}
"""

    vulnerable_ok, vulnerable_reason = evaluate_contract(vulnerable)
    guarded_ok, guarded_reason = evaluate_contract(guarded)

    if vulnerable_ok:
        print("SELF_TEST=fail")
        print("DETAIL=vulnerable sample unexpectedly passed")
        return 1
    if not guarded_ok:
        print("SELF_TEST=fail")
        print(f"DETAIL=guarded sample unexpectedly failed: {guarded_reason}")
        return 1

    print("SELF_TEST=pass")
    print(f"VULNERABLE_SAMPLE={vulnerable_reason}")
    print(f"GUARDED_SAMPLE={guarded_reason}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Check that Config.zig no longer blanket-routes scheme-less remote "
            "HTML/XHTML targets into browse mode."
        )
    )
    parser.add_argument(
        "--config",
        type=Path,
        help="Path to Config.zig to inspect",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run embedded regression samples instead of reading a file",
    )
    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    if args.config is None:
        parser.error("either --self-test or --config is required")

    ok, reason = evaluate_contract(args.config.read_text(encoding="utf-8"))
    print(f"CONFIG_SCHEMELESS_REMOTE_HTML_CONTRACT={'pass' if ok else 'fail'}")
    print(f"DETAIL={reason}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
