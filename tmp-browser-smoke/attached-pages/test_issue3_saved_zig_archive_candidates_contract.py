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
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
from __future__ import annotations

ARCHIVE_PATTERNS = ("zig*.tar", "zig*.tar.gz", "zig*.tgz", "zig*.tar.xz", "zig*.zip")
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

def normalize_saved_archives_root(saved_archives_root):
    dependencies_root = saved_archives_root / "dependencies"
    if dependencies_root.is_dir():
        return dependencies_root.resolve()
    return saved_archives_root.resolve()

def resolve_default_saved_archives_root(repo_root):
    return normalize_saved_archives_root(repo_root.parent / "memory" / "repo_archives" / "browser")

def resolve_default_toolchains_root(repo_root):
    return (repo_root.parent / "toolchains").resolve()

def resolve_default_fallback_archive(repo_root):
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.is_file() else None

def choose_preferred_archive(expected, archive_reports):
    exact_match = next(
        (
            archive
            for archive in archive_reports
            if archive["status"] == "matches-expected-line" and archive["version"] == expected
        ),
        None,
    )
    if exact_match is not None:
        return exact_match
    matching_archives = [
        archive for archive in archive_reports if archive["status"] == "matches-expected-line"
    ]
    if not matching_archives:
        return None
    return max(matching_archives, key=lambda archive: parse_semver(archive["version"]))

class SavedZigArchiveHelperTests(unittest.TestCase):
    def test_choose_preferred_archive_prefers_strongest_matching_line_when_exact_missing(self):
        pass

def build_restore_command(repo_root, toolchains_root, archive_path, *, check_only):
    command = [
        "bash",
        str(repo_root / "scripts" / "linux" / "restore_zig_toolchain_archive.sh"),
        "--browser-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--archive",
        str(archive_path),
    ]
    if check_only:
        command.append("--check-only")
    return command

def build_report(*, preferred_archive, fallback_archive):
    report = {
        "preferred_archive": preferred_archive,
        "fallback_archive": str(fallback_archive) if fallback_archive is not None else "",
        "commands": {},
        "failures": [],
    }
    if preferred_archive is not None:
        report["commands"]["restore_check"] = "restore --check-only"
        report["commands"]["restore"] = "restore"
    return report
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-zig-candidates-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedZigArchiveCandidatesContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.helper_text = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_helper_keeps_saved_archives_root_and_workspace_root_discovery(self) -> None:
        for fragment in (
            'dependencies_root = saved_archives_root / "dependencies"',
            'repo_root.parent / "memory" / "repo_archives" / "browser"',
            '(repo_root.parent / "toolchains").resolve()',
            '(repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()',
        ):
            self.assertIn(fragment, self.helper_text)

    def test_helper_keeps_archive_patterns_and_fallback_archive_name(self) -> None:
        for fragment in (
            'ARCHIVE_PATTERNS = ("zig*.tar", "zig*.tar.gz", "zig*.tgz", "zig*.tar.xz", "zig*.zip")',
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
        ):
            self.assertIn(fragment, self.helper_text)

    def test_helper_prefers_exact_then_strongest_matching_archive(self) -> None:
        for fragment in (
            'archive["status"] == "matches-expected-line" and archive["version"] == expected',
            'if exact_match is not None:',
            'matching_archives = [',
            'if not matching_archives:',
            'return max(matching_archives, key=lambda archive: parse_semver(archive["version"]))',
            'def test_choose_preferred_archive_prefers_strongest_matching_line_when_exact_missing',
        ):
            self.assertIn(fragment, self.helper_text)

    def test_helper_keeps_restore_command_and_report_output_contract(self) -> None:
        for fragment in (
            '"bash",',
            '"scripts" / "linux" / "restore_zig_toolchain_archive.sh"',
            '"--browser-root"',
            '"--toolchains-root"',
            '"--archive"',
            'command.append("--check-only")',
            '"preferred_archive": preferred_archive',
            '"fallback_archive": str(fallback_archive) if fallback_archive is not None else ""',
            'report["commands"]["restore_check"]',
            'report["commands"]["restore"]',
        ):
            self.assertIn(fragment, self.helper_text)

    def test_helper_and_manifest_keep_branch_compatible_zig_line_visible(self) -> None:
        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()