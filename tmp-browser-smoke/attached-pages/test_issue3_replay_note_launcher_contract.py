import tempfile
import unittest
from pathlib import Path

from issue3_replay_note_launcher_contract import audit_paths, failure_reasons, resolve_paths


DEFAULT_FILES = (
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
)


def write_default_files(root: Path, contents: str) -> list[Path]:
    paths: list[Path] = []
    for relative_path in DEFAULT_FILES:
        path = root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        paths.append(path)
    return paths


class ReplayNoteLauncherContractTests(unittest.TestCase):
    def test_resolve_paths_uses_default_replay_notes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            write_default_files(root, "placeholder")
            resolved = resolve_paths(root, None)
            self.assertEqual(2, len(resolved))

    def test_fails_when_raw_python_reference_remains(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(root, "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py")
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("raw Python attached-pages launcher references remain in replay notes", reasons)

    def test_fails_when_wrapper_lacks_sidecar_flags(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1",
            )
            audit = audit_paths(paths, root)
            reasons = failure_reasons(audit)
            self.assertIn("replay notes do not keep the wrapper-backed sidecar audit visible", reasons)
            self.assertIn(
                "replay notes do not keep the Google-style wrapper-backed sidecar audit visible",
                reasons,
            )

    def test_passes_with_google_wrapper_sidecar_contract(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = write_default_files(
                root,
                (
                    "powershell -ExecutionPolicy Bypass -File "
                    ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
                    "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars"
                ),
            )
            audit = audit_paths(paths, root)
            self.assertEqual([], failure_reasons(audit))


if __name__ == "__main__":
    unittest.main()