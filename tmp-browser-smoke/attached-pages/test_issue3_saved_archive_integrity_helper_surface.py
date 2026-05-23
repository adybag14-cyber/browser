from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_saved_archive_integrity.py": """
    EXPECTED_MEMORY_ARCHIVES = (
        (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "saved repo snapshot",
            "d1ce047d2f9dd5a9dd7c5a661f3f0caeeac0ff51a19bcdb3c9f3104c081babf0",
        ),
        (
            "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "saved Rust toolchain archive",
            "ce552d6bf22a2544ea78647d98cb405d5089af58dbcaa4efea711bf8becd71c5",
        ),
        (
            "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
            "saved html5ever dependency archive",
            "701e646bd43917993a20cd155472c1d122d0ac38d1ee908396beff44add74cea",
        ),
        (
            "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
            "saved BoringSSL archive",
            "db924bb0a15f31f3a6ff9848f357585ea09b20e80b584cccbd45ab69ffeda564",
        ),
        (
            "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
            "saved browser dependency archive",
            "e4905ad079f421dfc9c116172ab873666afab4eae8afdeed0d00dc8a4c4368f9",
        ),
    )
    DEFAULT_FALLBACK_ZIG_NAME = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"
    def build_parser():
        parser.add_argument("--fallback-zig-archive")
        parser.add_argument("--require-fallback-zig")
        parser.add_argument("--json")
        parser.add_argument("--self-test")
    def emit_text(result):
        print("Saved archive integrity:")
        print("Fallback Zig archive:")
        print("Saved archive integrity check passed.")
        print("Saved archive integrity check failed.")
        print("Suggested next step: refresh the mismatched archive from the saved Memory source before trusting restore, Linux build-readiness, or issue #3 runtime re-entry work.")
    class SavedArchiveIntegrityTests(unittest.TestCase):
        def test_collect_results_passes_with_matching_archives(self): ...
        def test_collect_results_fails_on_mismatch(self): ...
        def test_optional_fallback_zig_can_warn_without_failing(self): ...
    """,
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    FOLLOW_UP_MEMORY_CHECK="python ${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${DESTINATION}"
    FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK="python ${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py --repo-root ${DESTINATION}"
    echo "Suggested follow-up checks:"
    printf "  %s\\n" "${FOLLOW_UP_MEMORY_CHECK}"
    printf "  %s\\n" "${FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK}"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-archive-integrity-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedArchiveIntegrityHelperSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.archive_integrity_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )

    def test_archive_integrity_helper_keeps_saved_archive_catalog_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "saved repo snapshot",
            "d1ce047d2f9dd5a9dd7c5a661f3f0caeeac0ff51a19bcdb3c9f3104c081babf0",
            "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
            "03-boringssl-zig-main.zip",
            "04-zig-browser-depo.tar.zip",
            "saved browser dependency archive",
        ):
            self.assertIn(fragment, self.archive_integrity_helper)

    def test_archive_integrity_helper_keeps_fallback_zig_and_cli_surface_visible(self) -> None:
        for fragment in (
            "DEFAULT_FALLBACK_ZIG_NAME = \"zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz\"",
            "DEFAULT_FALLBACK_ZIG_SHA256 = \"f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818\"",
            "--fallback-zig-archive",
            "--require-fallback-zig",
            "--json",
            "--self-test",
            "Saved archive integrity:",
            "Fallback Zig archive:",
            "Saved archive integrity check passed.",
            "Saved archive integrity check failed.",
            "Suggested next step: refresh the mismatched archive from the saved Memory source",
        ):
            self.assertIn(fragment, self.archive_integrity_helper)

    def test_archive_integrity_helper_keeps_self_test_coverage_visible(self) -> None:
        for fragment in (
            "def test_collect_results_passes_with_matching_archives",
            "def test_collect_results_fails_on_mismatch",
            "def test_optional_fallback_zig_can_warn_without_failing",
        ):
            self.assertIn(fragment, self.archive_integrity_helper)

    def test_restore_helper_keeps_archive_integrity_follow_up_visible(self) -> None:
        for fragment in (
            "FOLLOW_UP_MEMORY_CHECK",
            "FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "Suggested follow-up checks:",
        ):
            self.assertIn(fragment, self.restore_helper)


if __name__ == "__main__":
    unittest.main()
