#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import os
import subprocess
import sys
import tempfile
import unittest

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from issue3_enter_submit_runtime_publication_guard import (
    DEFAULT_PAGE_PATCH,
    DEFAULT_WIN32_PATCH,
    EXPECTED_PAGE_SHA,
    EXPECTED_WIN32_SHA,
    PAGE_PATH,
    WIN32_PATH,
    build_argument_parser,
    git_blob_sha,
    patch_dry_run,
    resolve_patch_path,
)


REPO_ROOT = pathlib.Path(
    os.environ.get(
        "LP_ISSUE3_GUARD_REPO_ROOT",
        str(pathlib.Path(__file__).resolve().parents[2]),
    )
).resolve()


class Issue3EnterSubmitRuntimePublicationGuardTests(unittest.TestCase):
    def test_git_blob_sha_matches_expected_live_base(self) -> None:
        self.assertEqual(EXPECTED_PAGE_SHA, git_blob_sha(REPO_ROOT, PAGE_PATH))
        self.assertEqual(EXPECTED_WIN32_SHA, git_blob_sha(REPO_ROOT, WIN32_PATH))

    def test_resolve_patch_path_is_repo_relative_by_default(self) -> None:
        page_patch = resolve_patch_path(REPO_ROOT, DEFAULT_PAGE_PATCH)
        win32_patch = resolve_patch_path(REPO_ROOT, DEFAULT_WIN32_PATCH)

        self.assertEqual(REPO_ROOT / DEFAULT_PAGE_PATCH, page_patch)
        self.assertEqual(REPO_ROOT / DEFAULT_WIN32_PATCH, win32_patch)

    def test_patch_dry_run_succeeds_against_revalidated_base(self) -> None:
        page_ok, page_output = patch_dry_run(
            REPO_ROOT, resolve_patch_path(REPO_ROOT, DEFAULT_PAGE_PATCH)
        )
        win32_ok, win32_output = patch_dry_run(
            REPO_ROOT, resolve_patch_path(REPO_ROOT, DEFAULT_WIN32_PATCH)
        )

        self.assertTrue(page_ok, page_output)
        self.assertTrue(win32_ok, win32_output)

    def test_patch_dry_run_reports_missing_patch(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            missing_patch = pathlib.Path(temp_dir) / "missing.patch"
            ok, output = patch_dry_run(REPO_ROOT, missing_patch)

        self.assertFalse(ok)
        self.assertIn("missing patch file", output)

    def test_argument_parser_uses_expected_defaults(self) -> None:
        args = build_argument_parser().parse_args([])

        self.assertEqual(".", args.repo_root)
        self.assertEqual(DEFAULT_PAGE_PATCH, args.page_patch)
        self.assertEqual(DEFAULT_WIN32_PATCH, args.win32_patch)
        self.assertFalse(args.skip_patch_check)

    def test_main_script_succeeds_with_skip_patch_check(self) -> None:
        result = subprocess.run(
            [
                "python3",
                str(REPO_ROOT / "tmp-browser-smoke/google-investigation-next/issue3_enter_submit_runtime_publication_guard.py"),
                "--repo-root",
                str(REPO_ROOT),
                "--skip-patch-check",
            ],
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertIn("base_match=yes", result.stdout)
        self.assertIn("patch_check=skipped", result.stdout)


if __name__ == "__main__":
    unittest.main()
