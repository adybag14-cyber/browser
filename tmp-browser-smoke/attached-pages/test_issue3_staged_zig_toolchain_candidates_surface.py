from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "build.zig.zon": """
    .{
        .name = "browser",
        .version = "0.0.0",
        .minimum_zig_version = "0.15.2",
    }
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - `scripts/check_issue3_staged_zig_toolchain_candidates.py`
    - `scripts/check_issue3_build_readiness_rerun.py`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - saved Zig archive candidate discovery and restore selection
    - branch-compatible Zig recovery under `../toolchains`
    - surface the staged Zig candidate helper before unpacking the archive again
    - surface `scripts/check_issue3_build_readiness_rerun.py` after a matching staged toolchain appears
    - `python ./scripts/check_issue3_staged_zig_toolchain_candidates.py --repo-root .`
    - `python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .`
    """,
    "scripts/check_issue3_staged_zig_toolchain_candidates.py": """
    DEFAULT_CANDIDATE_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
        "*/zig",
        "*/bin/zig",
        "zig",
    )
    def classify_version(minimum_zig: str, actual: str | None) -> str:
        return "matches-expected-line"
    def resolve_default_toolchains_root(repo_root: Path) -> Path:
        located = locate_first_existing(repo_root, "toolchains")
        return (repo_root.parent / "toolchains").resolve()
    def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:
        return {
            "status": "passed",
            "preferred_candidate": {"status": "matches-expected-line"},
            "matching_candidates": [],
            "candidate_count": 1,
            "suggested_next_step": "restore a saved Zig 0.15.x archive under ../toolchains",
            "path_export": 'export PATH="/tmp/toolchains/zig:$PATH"',
            "zig_export": 'export ZIG="/tmp/toolchains/zig"',
        }
    "older-than-minimum"
    "matches-expected-line"
    "mismatched-line"
    "unknown version"
    "preferred_candidate"
    "matching_candidates"
    "candidate_count"
    "suggested_next_step"
    "path_export"
    "zig_export"
    "Discovered candidates:"
    "Preferred candidate:"
    "No staged Zig 0.15.x candidate is ready."
    """,
    "scripts/check_issue3_build_readiness_rerun.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
        "*/zig",
        "*/bin/zig",
        "zig",
    )
    def resolve_default_toolchains_root(repo_root: Path) -> Path:
        return (repo_root.parent / "toolchains").resolve()
    def resolve_default_saved_archives_root(repo_root: Path) -> Path:
        return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()
    def resolve_default_offline_deps_root(repo_root: Path) -> Path:
        return (repo_root.parent / "offline-deps").resolve()
    def resolve_fallback_zig_archive(repo_root: Path, explicit_archive: Path | None) -> Path | None:
        return explicit_archive
    def choose_matching_candidate(minimum_zig: str, toolchains_root: Path):
        return None, []
    def build_readiness_rerun_command(
        repo_root: Path,
        zig_path: Path,
        toolchains_root: Path,
        saved_archives_root: Path,
        offline_deps_root: Path,
        fallback_zig_archive: Path | None,
    ) -> list[str]:
        return []
    "suggested_readiness_rerun_command"
    "suggested_recovery_route_command"
    "scripts/check_linux_build_readiness.py"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    "--toolchains-root"
    "--saved-archives-root"
    "--offline-deps-root"
    "--fallback-zig-archive"
    "--expect-saved-archives"
    "--expect-offline-deps"
    "--require-prebuilt-v8"
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
        "*/zig",
        "*/bin/zig",
        "zig",
    )
    "suggested_next_step"
    "use the saved Rust toolchain"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-staged-zig-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3StagedZigToolchainCandidatesSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.progress_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.staged_zig_helper = read_text(
            cls.repo_root / "scripts/check_issue3_staged_zig_toolchain_candidates.py"
        )
        cls.rerun_helper = read_text(
            cls.repo_root / "scripts/check_issue3_build_readiness_rerun.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_progress_note_keeps_staged_zig_handoff_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            "scripts/check_issue3_build_readiness_rerun.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "saved Zig archive candidate discovery and restore selection",
            "branch-compatible Zig recovery under `../toolchains`",
            "surface the staged Zig candidate helper before unpacking the archive again",
            "surface `scripts/check_issue3_build_readiness_rerun.py` after a matching staged toolchain appears",
            "python ./scripts/check_issue3_staged_zig_toolchain_candidates.py --repo-root .",
            "python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .",
        ):
            self.assertIn(fragment, self.progress_note)

        staged_index = self.progress_note.index(
            "python ./scripts/check_issue3_staged_zig_toolchain_candidates.py --repo-root ."
        )
        rerun_index = self.progress_note.index(
            "python ./scripts/check_issue3_build_readiness_rerun.py --repo-root ."
        )
        self.assertLess(staged_index, rerun_index)

    def test_staged_zig_helper_keeps_candidate_and_export_contract_visible(self) -> None:
        for fragment in (
            "DEFAULT_CANDIDATE_GLOBS = (",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            '"*/zig"',
            '"*/bin/zig"',
            '"zig"',
            'locate_first_existing(repo_root, "toolchains")',
            '(repo_root.parent / "toolchains").resolve()',
            'def classify_version(minimum_zig: str, actual: str | None) -> str:',
            'def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:',
            '"older-than-minimum"',
            '"matches-expected-line"',
            '"mismatched-line"',
            '"unknown version"',
            '"preferred_candidate"',
            '"matching_candidates"',
            '"candidate_count"',
            '"suggested_next_step"',
            '"path_export"',
            '"zig_export"',
            '"Discovered candidates:"',
            '"Preferred candidate:"',
            '"No staged Zig 0.15.x candidate is ready."',
        ):
            self.assertIn(fragment, self.staged_zig_helper)

    def test_rerun_helper_keeps_staged_zig_followup_surface_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS = (",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            'def choose_matching_candidate(minimum_zig: str, toolchains_root: Path):',
            'def build_readiness_rerun_command(',
            '"suggested_readiness_rerun_command"',
            '"suggested_recovery_route_command"',
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            '"--toolchains-root"',
            '"--saved-archives-root"',
            '"--offline-deps-root"',
            '"--fallback-zig-archive"',
            '"--expect-saved-archives"',
            '"--expect-offline-deps"',
            '"--require-prebuilt-v8"',
        ):
            self.assertIn(fragment, self.rerun_helper)

        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS = (",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            '"suggested_next_step"',
            '"use the saved Rust toolchain"',
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_manifest_still_declares_branch_expected_zig_line(self) -> None:
        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()
