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
    - `scripts/check_issue3_build_readiness_rerun.py`
    - `scripts/check_issue3_staged_zig_toolchain_candidates.py`
    - `scripts/check_linux_build_readiness.py`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - build-readiness rerun command
    - exact Linux or WSL build-readiness command
    """,
    "scripts/check_issue3_build_readiness_rerun.py": r"""
    Surface the exact branch-compatible Zig rerun command for issue #11.
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
        return [
            "python",
            "scripts/check_linux_build_readiness.py",
            "--repo-root",
            str(repo_root),
            "--zig",
            str(zig_path),
            "--toolchains-root",
            str(toolchains_root),
            "--saved-archives-root",
            str(saved_archives_root),
            "--expect-saved-archives",
            "--offline-deps-root",
            str(offline_deps_root),
            "--expect-offline-deps",
            "--require-prebuilt-v8",
        ]
    "suggested_readiness_rerun_command"
    "suggested_recovery_route_command"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    "--fallback-zig-archive"
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
    def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:
        return {
            "status": "passed",
            "preferred_candidate": {"status": "matches-expected-line"},
            "matching_candidates": [],
            "path_export": 'export PATH="/tmp/toolchains/zig:$PATH"',
            "zig_export": 'export ZIG="/tmp/toolchains/zig"',
        }
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
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-rerun-helper-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3BuildReadinessRerunSurfaceTest(unittest.TestCase):
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
        cls.rerun_helper = read_text(
            cls.repo_root / "scripts/check_issue3_build_readiness_rerun.py"
        )
        cls.staged_zig_helper = read_text(
            cls.repo_root / "scripts/check_issue3_staged_zig_toolchain_candidates.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_progress_note_keeps_rerun_helper_visible(self) -> None:
        for fragment in (
            "issue `#11`",
            "scripts/check_issue3_build_readiness_rerun.py",
            "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            "scripts/check_linux_build_readiness.py",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "build-readiness rerun command",
            "exact Linux or WSL build-readiness command",
        ):
            self.assertIn(fragment, self.progress_note)

    def test_rerun_helper_keeps_candidate_and_recovery_contract_visible(self) -> None:
        for fragment in (
            "DEFAULT_FALLBACK_ZIG_ARCHIVE",
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            '"--saved-archives-root"',
            '"--offline-deps-root"',
            '"--expect-saved-archives"',
            '"--expect-offline-deps"',
            '"--require-prebuilt-v8"',
            '"suggested_readiness_rerun_command"',
            '"suggested_recovery_route_command"',
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "--fallback-zig-archive",
        ):
            self.assertIn(fragment, self.rerun_helper)

    def test_staged_zig_helper_keeps_preferred_candidate_surface_visible(self) -> None:
        for fragment in (
            "matches-expected-line",
            '"preferred_candidate"',
            '"matching_candidates"',
            "path_export",
            "zig_export",
            '"status": "passed"',
        ):
            self.assertIn(fragment, self.staged_zig_helper)

        for fragment in (
            "DEFAULT_FALLBACK_ZIG_ARCHIVE",
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS",
            '"zig*/zig"',
            '"zig*/bin/zig"',
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_manifest_still_declares_branch_expected_zig_line(self) -> None:
        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()
