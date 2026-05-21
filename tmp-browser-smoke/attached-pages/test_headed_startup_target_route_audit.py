from __future__ import annotations

import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import headed_startup_target_route_audit as helper


PASSING_MAIN = """fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo {
    return null;
}

fn browseTargetImplicitRemote(url: []const u8) ?BrowseTargetInfo {
    return null;
}

fn browseTargetInfo(url: []const u8) BrowseTargetInfo {
    if (browseTargetImplicitLoopback(url)) |implicit_loopback| {
        return implicit_loopback;
    }
    const local_path_candidate = browseTargetLocalPathCandidate(url);
    if (std.mem.indexOf(u8, local_path_candidate, "://") == null and
        (std.mem.indexOfScalar(u8, local_path_candidate, '/') != null or
            std.mem.indexOfScalar(u8, local_path_candidate, '\\\\') != null or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".xhtml") or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".html") or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".htm")))
    {
        return .{};
    }
    if (browseTargetImplicitRemote(url)) |implicit_remote| {
        return implicit_remote;
    }
    return .{};
}

test "browse target info classifies attached html filenames as local paths" {}
test "browse target info keeps attached html queries on the local path route" {}
test "browse target info keeps attached xhtml fragments on the local path route" {}
test "browse target info classifies scheme-less localhost pages as loopback" {}
test "browse target info keeps ipv6 loopback hosts on the implicit http route" {}
"""


def make_buggy_main() -> str:
    return PASSING_MAIN.replace(
        """    const local_path_candidate = browseTargetLocalPathCandidate(url);
    if (std.mem.indexOf(u8, local_path_candidate, "://") == null and
        (std.mem.indexOfScalar(u8, local_path_candidate, '/') != null or
            std.mem.indexOfScalar(u8, local_path_candidate, '\\\\') != null or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".xhtml") or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".html") or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".htm")))
    {
        return .{};
    }
    if (browseTargetImplicitRemote(url)) |implicit_remote| {
        return implicit_remote;
    }
""",
        """    if (browseTargetImplicitRemote(url)) |implicit_remote| {
        return implicit_remote;
    }
    const local_path_candidate = browseTargetLocalPathCandidate(url);
    if (std.mem.indexOf(u8, local_path_candidate, "://") == null and
        (std.mem.indexOfScalar(u8, local_path_candidate, '/') != null or
            std.mem.indexOfScalar(u8, local_path_candidate, '\\\\') != null or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".xhtml") or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".html") or
            std.ascii.endsWithIgnoreCase(local_path_candidate, ".htm")))
    {
        return .{};
    }
""",
    )


class HeadedStartupTargetRouteAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.repo_root = Path(self.tempdir.name)
        (self.repo_root / "src").mkdir()

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_main(self, content: str) -> None:
        (self.repo_root / "src" / "main.zig").write_text(content, encoding="utf-8")

    def test_audit_passes_when_expected_guards_are_present_and_ordered_safely(self) -> None:
        self.write_main(PASSING_MAIN)

        audit = helper.build_startup_target_route_audit(self.repo_root)

        self.assertTrue(audit["ok"])
        self.assertEqual(0, audit["missing_count"])
        self.assertFalse(audit["bug_present"])

    def test_audit_flags_when_implicit_remote_preempts_local_html_fallback(self) -> None:
        self.write_main(make_buggy_main())

        audit = helper.build_startup_target_route_audit(self.repo_root)

        self.assertFalse(audit["ok"])
        self.assertTrue(audit["bug_present"])
        self.assertIn("implicit remote branch still appears before the bare local HTML fallback", audit["bug_details"][0])

    def test_audit_reports_missing_expected_test_snippets(self) -> None:
        self.write_main(PASSING_MAIN.replace('test "browse target info keeps attached html queries on the local path route" {}', ""))

        audit = helper.build_startup_target_route_audit(self.repo_root)

        self.assertFalse(audit["ok"])
        self.assertEqual(1, audit["missing_count"])
        missing_labels = [result["label"] for result in audit["results"] if not result["present"]]
        self.assertEqual(["attached_html_query_test"], missing_labels)

    def test_cli_json_output_reports_bug_and_nonzero_exit(self) -> None:
        self.write_main(make_buggy_main())

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.repo_root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertTrue(payload["bug_present"])
        self.assertFalse(payload["ok"])

    def test_missing_repo_root_is_reported_cleanly(self) -> None:
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.repo_root / "missing"), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])


if __name__ == "__main__":
    unittest.main()
