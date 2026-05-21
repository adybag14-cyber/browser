import tempfile
import unittest
from pathlib import Path

import google_issue3_attached_pages_launcher_companion_proof_paths_audit as helper


def build_contract_map() -> dict[str, str]:
    grouped: dict[str, list[str]] = {}
    for expectation in helper.EXPECTATIONS:
        grouped.setdefault(expectation["path"], []).append(expectation["snippet"])
    return {path: "\n\n".join(snippets) + "\n" for path, snippets in grouped.items()}


class LauncherCompanionProofPathsAuditTests(unittest.TestCase):
    def test_contract_passes_when_all_snippets_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            for relative_path, content in build_contract_map().items():
                target = root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(content, encoding="utf-8")

            self.assertEqual(helper.audit_repo_root(root), [])

    def test_each_expectation_fails_cleanly_when_removed(self) -> None:
        contract_map = build_contract_map()
        for expectation in helper.EXPECTATIONS:
            with self.subTest(expectation=expectation["purpose"]):
                with tempfile.TemporaryDirectory() as tmpdir:
                    root = Path(tmpdir)
                    for relative_path, content in contract_map.items():
                        target = root / relative_path
                        target.parent.mkdir(parents=True, exist_ok=True)
                        if relative_path == expectation["path"]:
                            content = content.replace(expectation["snippet"], "", 1)
                        target.write_text(content, encoding="utf-8")

                    missing = helper.audit_repo_root(root)
                    self.assertTrue(missing)
                    self.assertTrue(
                        any(
                            item["path"] == expectation["path"]
                            and item["purpose"] == expectation["purpose"]
                            for item in missing
                        )
                    )


if __name__ == "__main__":
    unittest.main()
