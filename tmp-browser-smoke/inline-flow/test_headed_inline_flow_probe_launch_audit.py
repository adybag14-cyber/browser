from __future__ import annotations

import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from headed_inline_flow_probe_launch_audit import (
    EXPLICIT_HEADED_LAUNCH_SNIPPET,
    PROBE_EXPECTATIONS,
    audit_inline_flow_probe_launches,
    summarize_missing_contracts,
)


class HeadedInlineFlowProbeLaunchAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        for expectation in PROBE_EXPECTATIONS:
            (self.root / expectation.filename).write_text(
                "\n".join(
                    (
                        "$browser = Start-Process -FilePath $browserExe -ArgumentList "
                        + EXPLICIT_HEADED_LAUNCH_SNIPPET
                        + expectation.expected_url,
                        "Send-SmokeEnter",
                    )
                ),
                encoding="utf-8",
            )

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def test_audit_covers_all_expected_probe_files(self) -> None:
        results = audit_inline_flow_probe_launches(self.root)
        self.assertEqual(
            [expectation.filename for expectation in PROBE_EXPECTATIONS],
            [result.filename for result in results],
        )

    def test_inline_flow_probes_keep_explicit_headed_launches(self) -> None:
        self.assertEqual([], summarize_missing_contracts(self.root))

    def test_audit_reports_missing_headed_launch_contracts(self) -> None:
        first = PROBE_EXPECTATIONS[0]
        (self.root / first.filename).write_text(
            "$browser = Start-Process -FilePath $browserExe -ArgumentList \"browse\"",
            encoding="utf-8",
        )
        self.assertEqual(
            [
                f"{first.filename}: missing explicit headed browse launch",
                f"{first.filename}: missing expected localhost page target",
            ],
            summarize_missing_contracts(self.root)[:2],
        )


if __name__ == "__main__":
    unittest.main()
