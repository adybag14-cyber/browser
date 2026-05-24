from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    - `--require-fallback-zig`
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
    SAVED_MEMORY_INPUTS_COMMAND="python ${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
    SAVED_ARCHIVE_INTEGRITY_COMMAND="python ${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py --repo-root ${REPO_ROOT}"
    PREFLIGHT_COMMAND="python ${REPO_ROOT}/scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies"
    if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
        SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
    fi
    "saved_archive_integrity"
    "Run the saved_archive_integrity command after the saved-memory preflight when the route needs to prove the saved repo and dependency bundles still match the expected exact artifacts before offline staging starts."
    Saved archive integrity preflight:
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_MEMORY_FILES = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
        ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    )
    DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    parser.add_argument("--fallback-zig-archive")
    Saved Memory input check passed.
    """,
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
        parser.add_argument("--memory-root")
        parser.add_argument("--agent-files-root")
        parser.add_argument("--fallback-zig-archive")
        parser.add_argument("--require-fallback-zig")
        parser.add_argument("--json")
        parser.add_argument("--self-test")
    def resolve_default_memory_root(repo_root):
        return (repo_root.parent / "memory").resolve()
    def resolve_default_agent_files_root(repo_root):
        return (repo_root.parent / "agent_files").resolve()
    def sha256_for_file(path):
        return "sha"
    def collect_results(**kwargs):
        return {}
    class SavedArchiveIntegrityTests(unittest.TestCase):
        def test_collect_results_passes_with_matching_archives(self): ...
        def test_collect_results_fails_on_mismatch(self): ...
        def test_optional_fallback_zig_can_warn_without_failing(self): ...
    "profile": "issue3-saved-archive-integrity"
    Saved archive integrity check passed.
    Saved archive integrity check failed.
    refresh the mismatched archive from the saved Memory source before trusting restore, Linux build-readiness, or issue #3 runtime re-entry work.
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-archive-integrity-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedArchiveIntegritySurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.integrity_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )

    def test_build_readiness_note_keeps_integrity_step_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "--require-fallback-zig",
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_runtime_gates_keep_the_linux_recovery_route_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_route_helper_keeps_saved_archive_integrity_ordering_visible(self) -> None:
        for fragment in (
            'SAVED_MEMORY_INPUTS_COMMAND="python',
            "scripts/check_issue3_saved_memory_inputs.py",
            'SAVED_ARCHIVE_INTEGRITY_COMMAND="python',
            "scripts/check_issue3_saved_archive_integrity.py",
            "--repo-root ${REPO_ROOT}",
            "--fallback-zig-archive",
            '"saved_archive_integrity"',
            "Run the saved_archive_integrity command after the saved-memory preflight",
            "Saved archive integrity preflight:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_saved_memory_helper_keeps_snapshot_blocker_and_fallback_inputs_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--fallback-zig-archive",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_integrity_helper_keeps_expected_archives_flags_and_status_output_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "saved repo snapshot",
            "d1ce047d2f9dd5a9dd7c5a661f3f0caeeac0ff51a19bcdb3c9f3104c081babf0",
            "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "ce552d6bf22a2544ea78647d98cb405d5089af58dbcaa4efea711bf8becd71c5",
            "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
            "701e646bd43917993a20cd155472c1d122d0ac38d1ee908396beff44add74cea",
            "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
            "db924bb0a15f31f3a6ff9848f357585ea09b20e80b584cccbd45ab69ffeda564",
            "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
            "e4905ad079f421dfc9c116172ab873666afab4eae8afdeed0d00dc8a4c4368f9",
            'DEFAULT_FALLBACK_ZIG_NAME = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_FALLBACK_ZIG_SHA256 = "f3eb931888470d2326c04e090b5e352bc72fcb0580c07120215936732cd99818"',
            "--memory-root",
            "--agent-files-root",
            "--fallback-zig-archive",
            "--require-fallback-zig",
            "--json",
            "--self-test",
            'resolve_default_memory_root',
            'resolve_default_agent_files_root',
            'sha256_for_file',
            'collect_results',
            'def test_collect_results_passes_with_matching_archives',
            'def test_collect_results_fails_on_mismatch',
            'def test_optional_fallback_zig_can_warn_without_failing',
            '"profile": "issue3-saved-archive-integrity"',
            "Saved archive integrity check passed.",
            "Saved archive integrity check failed.",
            "refresh the mismatched archive from the saved Memory source before trusting restore, Linux build-readiness, or issue #3 runtime re-entry work.",
        ):
            self.assertIn(fragment, self.integrity_helper)


if __name__ == "__main__":
    unittest.main()
