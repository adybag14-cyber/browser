from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "scripts/check_issue3_restored_helper_surface_alignment.py": """
#!/usr/bin/env python3
\"\"\"Check drift between restore-synced helper files and saved-memory preflight expectations.\"\"\"

RESTORE_LIST_RE = re.compile(r"declare -a HELPER_SURFACE_PATHS=\\((.*?)\\n\\)", re.S)
PYTHON_LIST_RE = re.compile(
    r"REQUIRED_RESTORED_HELPER_FILES:\\s*tuple\\[tuple\\[str, str\\], \\.\\.\\.\\]\\s*=\\s*\\((.*?)\\n\\)",
    re.S,
)

def build_report(restore_paths: list[str], required_paths: list[str]) -> dict[str, object]:
    restore_only = sorted(set(restore_paths) - set(required_paths))
    required_only = sorted(set(required_paths) - set(restore_paths))
    return {
        "ok": not restore_only and not required_only,
        "restore_only": restore_only,
        "required_only": required_only,
    }

def main() -> int:
    restore_script = repo_root / "scripts" / "linux" / "restore_saved_browser_snapshot.sh"
    saved_memory_helper = repo_root / "scripts" / "check_issue3_saved_memory_inputs.py"
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-restored-helper-surface-alignment-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RestoredHelperSurfaceAlignmentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = build_fixture_repo()

        cls.helper_text = (
            cls.repo_root / "scripts/check_issue3_restored_helper_surface_alignment.py"
        ).read_text(encoding="utf-8")

    def test_alignment_helper_tracks_restore_and_saved_memory_sources(self) -> None:
        for fragment in (
            "restore_saved_browser_snapshot.sh",
            "check_issue3_saved_memory_inputs.py",
            "HELPER_SURFACE_PATHS",
            "REQUIRED_RESTORED_HELPER_FILES",
        ):
            self.assertIn(fragment, self.helper_text)

    def test_alignment_helper_keeps_bidirectional_drift_fields(self) -> None:
        for fragment in (
            '"restore_only": restore_only',
            '"required_only": required_only',
            "not restore_only and not required_only",
        ):
            self.assertIn(fragment, self.helper_text)

    def test_alignment_helper_accepts_annotated_python_manifests(self) -> None:
        for fragment in (
            "PYTHON_LIST_RE = re.compile(",
            "REQUIRED_RESTORED_HELPER_FILES:\\s*tuple\\[tuple\\[str, str\\]",
            "saved-memory preflight expectations",
        ):
            self.assertIn(fragment, self.helper_text)


if __name__ == "__main__":
    unittest.main()
