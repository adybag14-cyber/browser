import contextlib
import importlib.util
import io
import os
import pathlib
import tempfile
import unittest


CHECKER_SOURCE = """#!/usr/bin/env python3
\"\"\"Guard the Config.zig contract for scheme-less remote HTML inference.

This helper is intentionally source-based rather than build-based so it can run
in lightweight debugging environments where the full browser toolchain or a
current writable checkout is unavailable.
\"\"\"

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
    match = re.search(rf"fn {re.escape(name)}\\([^)]*\\) [^{{]*\\{{", source)
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
    vulnerable = \"\"\"
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
\"\"\"

    guarded = \"\"\"
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
\"\"\"

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
"""


VULNERABLE_SOURCE = """
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


GUARDED_SOURCE = """
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


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-config-contract-checker-"))
    checker_path = root / "tmp-browser-smoke/command-inference/check_config_schemeless_remote_html_contract.py"
    checker_path.parent.mkdir(parents=True, exist_ok=True)
    checker_path.write_text(CHECKER_SOURCE, encoding="utf-8")
    return root


class ConfigSchemelessRemoteHtmlContractCheckerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        checker_path = cls.repo_root / "tmp-browser-smoke/command-inference/check_config_schemeless_remote_html_contract.py"
        spec = importlib.util.spec_from_file_location("config_contract_checker", checker_path)
        module = importlib.util.module_from_spec(spec)
        assert spec.loader is not None
        spec.loader.exec_module(module)
        cls.checker = module

    def test_unsafe_markers_cover_xhtml_html_and_htm(self) -> None:
        self.assertEqual(
            self.checker.UNSAFE_MARKERS,
            (
                'std.ascii.eqlIgnoreCase(candidate[candidate.len - 6 ..], ".xhtml")',
                'std.ascii.eqlIgnoreCase(candidate[candidate.len - 5 ..], ".html")',
                'std.ascii.eqlIgnoreCase(candidate[candidate.len - 4 ..], ".htm")',
            ),
        )

    def test_safety_markers_cover_loopback_and_remote_hints(self) -> None:
        for marker in (
            "authority",
            "loopback",
            "localhost",
            ".localhost",
            "127.",
            "0.0.0.0",
            "[::1]",
            "[0:0:0:0:0:0:0:1]",
            "remote",
        ):
            self.assertIn(marker, self.checker.SAFETY_MARKERS)

    def test_vulnerable_contract_fails_with_expected_reason(self) -> None:
        ok, reason = self.checker.evaluate_contract(VULNERABLE_SOURCE)
        self.assertFalse(ok)
        self.assertIn("blanket-matches scheme-less .html/.htm/.xhtml", reason)

    def test_guarded_contract_passes_with_expected_reason(self) -> None:
        ok, reason = self.checker.evaluate_contract(GUARDED_SOURCE)
        self.assertTrue(ok)
        self.assertEqual(
            reason,
            "contract looks guarded against scheme-less remote HTML auto-browse",
        )

    def test_missing_infer_local_function_fails_cleanly(self) -> None:
        ok, reason = self.checker.evaluate_contract("fn other() void {}")
        self.assertFalse(ok)
        self.assertEqual(reason, "missing function: inferLocalBrowseTarget")

    def test_self_test_reports_pass(self) -> None:
        stream = io.StringIO()
        with contextlib.redirect_stdout(stream):
            exit_code = self.checker.run_self_test()

        output = stream.getvalue()
        self.assertEqual(exit_code, 0)
        self.assertIn("SELF_TEST=pass", output)
        self.assertIn("VULNERABLE_SAMPLE=", output)
        self.assertIn("GUARDED_SAMPLE=", output)


if __name__ == "__main__":
    unittest.main()
