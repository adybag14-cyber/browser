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
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `scripts/check_linux_build_readiness.py`
""",
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
# Issue #3 Zig Toolchain Recovery Route

- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
""",
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
# Issue #3 Zig Toolchain Archive Restore Route

Run The Surface Check First

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
```

Print The Route

```bash
bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh
```

```bash
bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \
  --repo-root /path/to/browser \
  --toolchains-root /path/to/toolchains \
  --archive /path/to/zig-0.15.2.tar.xz \
  --saved-archives-root /path/to/memory/repo_archives/browser/dependencies \
  --offline-deps-root /path/to/offline-deps
```

```bash
bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only
```

- `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `show_issue3_zig_toolchain_recovery_route.sh`
- Treat the attached Zig `0.17` dev bundle as a surfaced fallback input only
""",
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"
    "scripts/linux/check_issue3_zig_toolchain_match.sh|file|"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|file|"
    "scripts/linux/restore_zig_toolchain_archive.sh|file|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|"
    "scripts/check_linux_build_readiness.py|file|"
    "build.zig.zon|file|"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Print The Route|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|--saved-archives-root /path/to/memory/repo_archives/browser/dependencies|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|check_issue3_zig_toolchain_archive_restore_route_surface.sh|"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--saved-archives-root|"
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--offline-deps-root|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|archive_restore_surface_check|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Archive restore surface check|"
    "scripts/linux/restore_zig_toolchain_archive.sh|--check-only|"
    "scripts/linux/restore_zig_toolchain_archive.sh|Saved Zig toolchain restore surface check passed.|"
    "scripts/linux/restore_zig_toolchain_archive.sh|Suggested follow-up commands:|"
    "scripts/check_linux_build_readiness.py|--toolchains-root|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|"
)
""",
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": """
Usage:
  --saved-archives-root
  --offline-deps-root
check_issue3_zig_toolchain_archive_restore_route_surface.sh
restore_zig_toolchain_archive.sh
show_issue3_zig_toolchain_recovery_route.sh
Archive restore commands
""",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
archive_restore_surface_check
Archive restore surface check
check_issue3_zig_toolchain_archive_restore_route_surface.sh
""",
    "scripts/linux/restore_zig_toolchain_archive.sh": """
--check-only
Saved Zig toolchain restore surface check passed.
Suggested follow-up commands:
""",
    "scripts/check_linux_build_readiness.py": """
def build_parser():
    parser.add_argument("--toolchains-root")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-restore-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigToolchainArchiveRestoreRouteContractTest(unittest.TestCase):
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
        cls.linux_route = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.archive_restore_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.archive_restore_surface = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
        )
        cls.archive_restore_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.recovery_route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_archive_restore_note_keeps_surface_route_and_override_commands_visible(self) -> None:
        for fragment in (
            "Run The Surface Check First",
            "Print The Route",
            "bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "--offline-deps-root /path/to/offline-deps",
            "bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "Treat the attached Zig `0.17` dev bundle as a surfaced fallback input only",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_archive_restore_surface_checker_keeps_route_printer_restore_helper_and_gate_links(self) -> None:
        for fragment in (
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"',
            '"scripts/linux/check_issue3_zig_toolchain_match.sh|file|"',
            '"scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|file|"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|file|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|"',
            '"scripts/check_linux_build_readiness.py|file|"',
            '"build.zig.zon|file|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Print The Route|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|--saved-archives-root /path/to/memory/repo_archives/browser/dependencies|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|"',
            '"scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--saved-archives-root|"',
            '"scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|--offline-deps-root|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|archive_restore_surface_check|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Archive restore surface check|"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--check-only|"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|Saved Zig toolchain restore surface check passed.|"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|Suggested follow-up commands:|"',
            '"scripts/check_linux_build_readiness.py|--toolchains-root|"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|"',
        ):
            self.assertIn(fragment, self.archive_restore_surface)

    def test_route_printer_and_restore_helper_keep_archive_restore_contract_visible(self) -> None:
        for fragment in (
            "--saved-archives-root",
            "--offline-deps-root",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "restore_zig_toolchain_archive.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "Archive restore commands",
        ):
            self.assertIn(fragment, self.archive_restore_route)

        for fragment in (
            "--check-only",
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_recovery_linux_and_runtime_notes_keep_archive_restore_route_in_view(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
        ):
            self.assertIn(fragment, self.recovery_route)

        self.assertIn("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", self.linux_route)
        self.assertIn("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", self.runtime_gates)

    def test_readiness_helper_and_manifest_keep_branch_toolchain_contract_visible(self) -> None:
        self.assertIn("--toolchains-root", self.readiness_helper)
        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()
