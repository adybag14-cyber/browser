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
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `Print The Route`
    - `bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `--saved-archives-root /path/to/memory/repo_archives/browser/dependencies`
    - `0.15.x`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `saved-archive candidate list`
    - `preferred 0.15.x restore surface-check`
    - `0.15.x`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
    - writable publication path for large existing-file updates
    - branch-compatible build/test toolchain
    """,
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": r"""
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    scripts/linux/check_issue3_zig_toolchain_match.sh
    scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh
    scripts/linux/restore_zig_toolchain_archive.sh
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    scripts/check_linux_build_readiness.py
    build.zig.zon
    Print The Route
    bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh
    --saved-archives-root /path/to/memory/repo_archives/browser/dependencies
    Archive restore commands
    archive_restore_surface_check
    Saved Zig toolchain restore surface check passed.
    Suggested follow-up commands:
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": r"""
    "surface_check": surface_check,
    "recovery_route": recovery,
    result["commands"]["restore_check_only"] = restore_check
    result["commands"]["restore"] = restore_run
    result["commands"]["full_readiness"] = readiness
    print("Archive restore commands")
    print("Suggested follow-up")
    print("Read first")
    print("Working rules")
    print("  docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md")
    print("  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")
    print("  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
    print("  docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
    print("  Re-run with --archive /path/to/zig-0.15.2.tar.xz to print the exact check-only, restore, and readiness commands.")
    print("  - Prefer a Zig 0.15.x archive for honest branch validation on this headed-mode branch.")
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    "archive_restore_surface_check"
    "Archive restore surface check"
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": r"""
    [--archive /path/to/zig-archive.tar.xz]
    [--destination /path/to/toolchains/zig-0.15.2]
    [--check-only]
    [--json]
    [--force]
    Supported archive types:
      .tar, .tar.gz, .tgz, .zip, .tar.xz
    "archive_top_level":
    "destination":
    "follow_up_discovery":
    "follow_up_build_readiness":
    "check_only":
    "force_restore":
    "destination_exists":
    echo "Saved Zig toolchain restore surface check passed."
    echo "Suggested follow-up commands:"
    echo "Saved Zig toolchain is ready."
    """,
    "scripts/check_linux_build_readiness.py": """
    def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
        return (repo_root.parent / "toolchains").resolve()
    parser.add_argument(
        "--saved-archives-root",
        default=None,
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
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


class Issue3ZigArchiveRestoreRouteSurfaceTest(unittest.TestCase):
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
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_archive_restore_note_keeps_read_first_route_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "Print The Route",
            "bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "`0.15.x`",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_surface_checker_keeps_archive_restore_contract_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "build.zig.zon",
            "Print The Route",
            "bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "Archive restore commands",
            "archive_restore_surface_check",
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_keeps_surface_restore_and_followup_commands_visible(self) -> None:
        for fragment in (
            '"surface_check": surface_check,',
            '"recovery_route": recovery,',
            'result["commands"]["restore_check_only"] = restore_check',
            'result["commands"]["restore"] = restore_run',
            'result["commands"]["full_readiness"] = readiness',
            'print("Archive restore commands")',
            'print("Suggested follow-up")',
            'print("Read first")',
            'print("Working rules")',
            'print("  docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md")',
            'print("  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")',
            'print("  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")',
            'print("  docs/ISSUE3_RUNTIME_REENTRY_GATES.md")',
            "Re-run with --archive /path/to/zig-0.15.2.tar.xz",
            "Prefer a Zig 0.15.x archive for honest branch validation",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_restore_helper_keeps_check_only_and_followup_surface_visible(self) -> None:
        for fragment in (
            "[--archive /path/to/zig-archive.tar.xz]",
            "[--destination /path/to/toolchains/zig-0.15.2]",
            "[--check-only]",
            "[--json]",
            "[--force]",
            "Supported archive types:",
            ".tar.xz",
            '"archive_top_level":',
            '"destination":',
            '"follow_up_discovery":',
            '"follow_up_build_readiness":',
            '"check_only":',
            '"force_restore":',
            '"destination_exists":',
            'echo "Saved Zig toolchain restore surface check passed."',
            'echo "Suggested follow-up commands:"',
            'echo "Saved Zig toolchain is ready."',
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_recovery_and_build_readiness_notes_keep_archive_restore_handoff_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "saved-archive candidate list",
            "preferred 0.15.x restore surface-check",
        ):
            self.assertIn(fragment, self.recovery_note)

        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        self.assertIn(
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            self.runtime_gates_note,
        )

    def test_recovery_route_and_readiness_helper_keep_archive_restore_support_visible(self) -> None:
        for fragment in (
            'archive_restore_surface_script = repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_archive_restore_route_surface.sh"',
            '"archive_restore_surface_check"',
            '"Archive restore surface check"',
        ):
            self.assertIn(fragment, self.recovery_route)

        for fragment in (
            "def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:",
            '"--saved-archives-root"',
            '"--toolchains-root"',
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_manifest_still_pins_branch_expected_zig_line(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
