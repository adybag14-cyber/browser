from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_deferred_enter_submit_patch_audit import (
    PAGE_MARKERS,
    WIN32_MARKERS,
    audit_issue3_enter_submit_patch,
    find_missing_markers,
)


class Issue3DeferredEnterSubmitPatchAuditTest(unittest.TestCase):
    def test_find_missing_markers_returns_empty_tuple_when_all_markers_are_present(self) -> None:
        text = "\n".join(PAGE_MARKERS + WIN32_MARKERS)
        self.assertEqual((), find_missing_markers(text, PAGE_MARKERS))
        self.assertEqual((), find_missing_markers(text, WIN32_MARKERS))

    def test_find_missing_markers_reports_the_missing_entries(self) -> None:
        text = "\n".join(PAGE_MARKERS[:-1])
        self.assertEqual((PAGE_MARKERS[-1],), find_missing_markers(text, PAGE_MARKERS))

    def test_audit_issue3_enter_submit_patch_reads_repo_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            (root / "src/browser").mkdir(parents=True)
            (root / "src/display").mkdir(parents=True)
            (root / "src/browser/Page.zig").write_text("\n".join(PAGE_MARKERS), encoding="utf-8")
            (root / "src/display/win32_backend.zig").write_text("\n".join(WIN32_MARKERS), encoding="utf-8")

            audits = audit_issue3_enter_submit_patch(root)

        self.assertEqual(["src/browser/Page.zig", "src/display/win32_backend.zig"], [audit.relative_path for audit in audits])
        self.assertTrue(all(audit.ok for audit in audits))

    def test_audit_issue3_enter_submit_patch_flags_missing_page_markers(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            (root / "src/browser").mkdir(parents=True)
            (root / "src/display").mkdir(parents=True)
            (root / "src/browser/Page.zig").write_text("\n".join(PAGE_MARKERS[:-2]), encoding="utf-8")
            (root / "src/display/win32_backend.zig").write_text("\n".join(WIN32_MARKERS), encoding="utf-8")

            audits = audit_issue3_enter_submit_patch(root)

        self.assertFalse(audits[0].ok)
        self.assertEqual(PAGE_MARKERS[-2:], audits[0].missing_markers)
        self.assertTrue(audits[1].ok)


if __name__ == "__main__":
    unittest.main()
