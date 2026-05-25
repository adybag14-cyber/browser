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
        .dependencies = .{
            .v8 = .{ .path = "../zig-v8-fork" },
            .@"boringssl-zig" = .{ .path = "../boringssl-zig" },
        },
    }
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet
    - `python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
    - `--saved-archives-root /path/to/memory/repo_archives/browser/dependencies`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    - `0.15.x`
    - attached Zig `0.17` dev bundle
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `0.15.x`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")
    def normalize_saved_archives_root(saved_archives_root):
        return saved_archives_root
    def resolve_default_saved_archives_root(repo_root):
        return repo_root
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / "toolchains"
    def resolve_default_fallback_archive(repo_root):
        return None
    def archive_contains_zig_binary(path):
        return True
    def looks_like_zig_toolchain_archive(path, version, top_level):
        return True
    def choose_preferred_archive(expected, archive_reports):
        return archive_reports[0]
    "status": "passed" if preferred_archive is not None else "failed"
    "preferred_archive": preferred_archive
    "fallback_archive": str(fallback_archive)
    "restore_check"
    "restore"
    "no saved Zig archive under"
    "use the fallback archive only as a surfaced stopgap"
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \
        [--repo-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-0.15.2.tar.xz] \
        [--offline-deps-root /path/to/offline-deps] \
        [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
        [--json]
    "saved_archive_candidates"
    "restore_check_only"
    "restore"
    "full_readiness"
    "recovery_route"
    "Saved archive discovery"
    "Archive restore commands"
    "show_issue3_zig_toolchain_recovery_route.sh"
    "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "check_issue3_saved_zig_archive_candidates.py"
    Replace <restored-zig-path>
    """,
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": """
    scripts/check_issue3_saved_zig_archive_candidates.py
    scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh
    scripts/linux/restore_zig_toolchain_archive.sh
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    scripts/check_linux_build_readiness.py
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
    scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|saved_archive_candidates
    scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Saved archive discovery
    scripts/linux/restore_zig_toolchain_archive.sh|Saved Zig toolchain restore surface check passed.
    scripts/linux/restore_zig_toolchain_archive.sh|Suggested follow-up commands:
    scripts/linux/restore_zig_toolchain_archive.sh|--saved-archives-root
    scripts/linux/restore_zig_toolchain_archive.sh|--offline-deps-root
    scripts/linux/restore_zig_toolchain_archive.sh|--expect-saved-archives
    scripts/linux/restore_zig_toolchain_archive.sh|--expect-offline-deps
    scripts/linux/restore_zig_toolchain_archive.sh|--require-prebuilt-v8
    scripts/check_linux_build_readiness.py|--toolchains-root
    All Zig archive restore route surfaces are present.
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": """
    Usage:
      scripts/linux/restore_zig_toolchain_archive.sh \
        [--browser-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-archive.tar.xz] \
        [--destination /path/to/toolchains/zig-0.15.2] \
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
        [--offline-deps-root /path/to/offline-deps] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--check-only] \
        [--json] \
        [--force]
    DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    def normalize_saved_archives_root()
    "saved_archives_root"
    "offline_deps_root"
    "fallback_zig_archive"
    "destination_exists"
    "follow_up_discovery"
    "follow_up_build_readiness"
    --saved-archives-root
    --offline-deps-root
    --expect-saved-archives
    --expect-offline-deps
    --require-prebuilt-v8
    Saved Zig toolchain restore surface check passed.
    Suggested follow-up commands:
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / "toolchains"
    def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):
        return fallback_zig_archive
    parser.add_argument(
        "--toolchains-root",
    )
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedZigArchiveRestoreSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.archive_restore_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.saved_archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_archive_restore_note_keeps_saved_archive_route_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "0.15.x",
            "attached Zig `0.17` dev bundle",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_saved_archive_helper_keeps_matching_restore_selection_surface(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")',
            "def normalize_saved_archives_root(saved_archives_root):",
            "def resolve_default_saved_archives_root(repo_root):",
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_default_fallback_archive(repo_root):",
            "def archive_contains_zig_binary(path):",
            "def looks_like_zig_toolchain_archive(path, version, top_level):",
            "def choose_preferred_archive(expected, archive_reports):",
            '"status": "passed" if preferred_archive is not None else "failed"',
            '"preferred_archive": preferred_archive',
            '"fallback_archive": str(fallback_archive)',
            '"restore_check"',
            '"restore"',
            '"no saved Zig archive under',
            "use the fallback archive only as a surfaced stopgap",
        ):
            self.assertIn(fragment, self.saved_archive_helper)

    def test_route_printer_and_surface_checker_keep_archive_followups_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "--offline-deps-root /path/to/offline-deps",
            '"saved_archive_candidates"',
            '"restore_check_only"',
            '"restore"',
            '"full_readiness"',
            '"recovery_route"',
            "Saved archive discovery",
            "Archive restore commands",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "check_issue3_saved_zig_archive_candidates.py",
            "Replace <restored-zig-path>",
        ):
            self.assertIn(fragment, self.route_printer)

        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|saved_archive_candidates",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Saved archive discovery",
            "scripts/linux/restore_zig_toolchain_archive.sh|Saved Zig toolchain restore surface check passed.",
            "scripts/linux/restore_zig_toolchain_archive.sh|Suggested follow-up commands:",
            "scripts/linux/restore_zig_toolchain_archive.sh|--saved-archives-root",
            "scripts/linux/restore_zig_toolchain_archive.sh|--offline-deps-root",
            "scripts/linux/restore_zig_toolchain_archive.sh|--expect-saved-archives",
            "scripts/linux/restore_zig_toolchain_archive.sh|--expect-offline-deps",
            "scripts/linux/restore_zig_toolchain_archive.sh|--require-prebuilt-v8",
            "scripts/check_linux_build_readiness.py|--toolchains-root",
            "All Zig archive restore route surfaces are present.",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_restore_helper_and_companion_notes_keep_reentry_wiring_visible(self) -> None:
        for fragment in (
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "--toolchains-root /path/to/toolchains",
            "--archive /path/to/zig-archive.tar.xz",
            "--destination /path/to/toolchains/zig-0.15.2",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--offline-deps-root /path/to/offline-deps",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--check-only",
            "--json",
            "--force",
            'DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "normalize_saved_archives_root()",
            '"saved_archives_root"',
            '"offline_deps_root"',
            '"fallback_zig_archive"',
            '"destination_exists"',
            '"follow_up_discovery"',
            '"follow_up_build_readiness"',
            "--saved-archives-root",
            "--offline-deps-root",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
        ):
            self.assertIn(fragment, self.restore_helper)

        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "0.15.x",
        ):
            self.assertIn(fragment, self.recovery_note)

        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
        ):
            self.assertIn(fragment, self.runtime_gates_note)