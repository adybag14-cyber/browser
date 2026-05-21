from __future__ import annotations

import unittest

from headed_shared_probe_helper_audit import (
    HELPER_AUDIT_TARGETS,
    audit_shared_probe_helpers,
    missing_explicit_headed_helpers,
)


class HeadedSharedProbeHelperAuditTests(unittest.TestCase):
    def test_audit_covers_expected_helper_families(self) -> None:
        self.assertEqual(
            [
                "attachment_downloads_common",
                "cookie_persistence_common",
                "fetch_credentials_common",
                "indexeddb_persistence_common",
                "localstorage_persistence_common",
                "sessionstorage_scope_common",
            ],
            [entry.name for entry in HELPER_AUDIT_TARGETS],
        )

    def test_all_shared_helpers_keep_explicit_headed_launches(self) -> None:
        results = audit_shared_probe_helpers()
        self.assertEqual(
            [],
            [result.name for result in results if not result.explicit_headed],
        )

    def test_missing_helper_report_is_empty_for_current_branch(self) -> None:
        self.assertEqual([], [result.name for result in missing_explicit_headed_helpers()])


if __name__ == "__main__":
    unittest.main()
