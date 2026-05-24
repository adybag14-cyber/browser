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

- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `scripts/check_linux_build_readiness.py`
- Prefer a Zig `0.15.2` toolchain
""",
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
# Issue #3 Zig Toolchain Recovery Route

- `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
- `0.15.2`
""",
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
# Issue #3 Zig Toolchain Archive Restore Route

Run The Surface Check First

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only
```

- `show_issue3_zig_toolchain_recovery_route.sh`
- `restore_zig_toolchain_archive.sh`
- Treat the attached Zig `0.17` dev bundle as a surfaced fallback input only
""",
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|"
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh|file|"
    "scripts/linux/restore_zig_toolchain_archive.sh|file|"
    "scripts/check_linux_build_readiness.py|file|"
    "build.zig.zon|file|"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/restore_issue3_fallback_zig_toolchain.sh|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|restore_zig_toolchain_archive.sh|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_issue3_zig_toolchain_recovery_route_surface.sh|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|restore_issue3_fallback_zig_toolchain.sh|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--saved-archives-root|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--offline-deps-root|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--fallback-zig-archive|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|surface_check|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|matching_readiness|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore_check|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Fallback archive staging|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Discovered Zig candidates: none|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|No branch-compatible Zig candidate is staged yet.|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Saved archives root:|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Offline deps root:|"
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh|--check-only|"
    "scripts/linux/restore_zig_toolchain_archive.sh|--check-only|"
)
""",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
Usage:
  --toolchains-root
  --saved-archives-root
  --offline-deps-root
  --fallback-zig-archive
build.zig.zon
check_linux_build_readiness.py
check_issue3_zig_toolchain_recovery_route_surface.sh
check_issue3_zig_toolchain_archive_restore_route_surface.sh
docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
restore_issue3_fallback_zig_toolchain.sh
surface_check
matching_readiness
fallback_restore_check
fallback_restore
Fallback archive staging
Discovered Zig candidates: none
No branch-compatible Zig candidate is staged yet.
zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
Saved archives root:
Offline deps root:
Archive restore surface check
""",
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"
    "scripts/linux/restore_zig_toolchain_archive.sh|file|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|"
    "scripts/check_linux_build_readiness.py|file|"
    "build.zig.zon|file|"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Run The Surface Check First|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only|"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_issue3_zig_toolchain_archive_restore_route_surface.sh|"
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
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh": """
--check-only
""",
    "scripts/linux/restore_zig_toolchain_archive.sh": """
--check-only
Saved Zig toolchain restore surface check passed.
Suggested follow-up commands:
""",
    "scripts/check_linux_build_readiness.py": """
SAVED_ARCHIVE_GLOBS = {
    "rust_toolchain": "01-rust-*.tar.xz",
    "html5ever": "02-litefetch-html5ever-*.zip",
    "boringssl": "03-boringssl-zig-main.zip",
    "browser_deps": "04-zig-browser-depo.tar.zip",
}
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
def build_parser():
    parser.add_argument("--toolchains-root")
    parser.add_argument("--saved-archives-root")
    parser.add_argument("--offline-deps-root")
    parser.add_argument("--fallback-zig-archive")
    parser.add_argument("--expect-saved-archives")
    parser.add_argument("--expect-offline-deps")
    parser.add_argument("--require-prebuilt-v8")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-recovery-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigToolchainRecoveryRoutesSurfaceTest(unittest.TestCase):
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
        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.archive_restore_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.recovery_surface = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.archive_restore_surface = read_text(
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

    def test_recovery_note_keeps_fallback_archive_archive_restore_and_readiness_links(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "0.15.2",
        ):
            self.assertIn(fragment, self.recovery_note)

    def test_archive_restore_note_keeps_surface_check_and_check_only_restore_commands(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "Run The Surface Check First",
            "bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "restore_zig_toolchain_archive.sh",
            "Treat the attached Zig `0.17` dev bundle as a surfaced fallback input only",
        ):
            self.assertIn(fragment, self.archive_restore_note)

    def test_recovery_surface_checker_keeps_route_archive_and_fallback_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"',
            '"scripts/linux/restore_issue3_fallback_zig_toolchain.sh|file|"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|file|"',
            '"scripts/check_linux_build_readiness.py|file|"',
            '"build.zig.zon|file|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|surface_check|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|matching_readiness|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore_check|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|fallback_restore|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Fallback archive staging|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Discovered Zig candidates: none|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|No branch-compatible Zig candidate is staged yet.|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Saved archives root:|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Offline deps root:|"',
            '"scripts/linux/restore_issue3_fallback_zig_toolchain.sh|--check-only|"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|--check-only|"',
        ):
            self.assertIn(fragment, self.recovery_surface)

    def test_recovery_route_keeps_archive_restore_surface_and_discovery_sections(self) -> None:
        for fragment in (
            "--toolchains-root",
            "--saved-archives-root",
            "--offline-deps-root",
            "--fallback-zig-archive",
            "build.zig.zon",
            "check_linux_build_readiness.py",
            "check_issue3_zig_toolchain_recovery_route_surface.sh",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "restore_issue3_fallback_zig_toolchain.sh",
            "surface_check",
            "matching_readiness",
            "fallback_restore_check",
            "fallback_restore",
            "Fallback archive staging",
            "Discovered Zig candidates: none",
            "No branch-compatible Zig candidate is staged yet.",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Saved archives root:",
            "Offline deps root:",
            "Archive restore surface check",
        ):
            self.assertIn(fragment, self.recovery_route)

    def test_archive_restore_surface_checker_keeps_restore_helper_and_runtime_gate_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"',
            '"scripts/linux/restore_zig_toolchain_archive.sh|file|"',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|"',
            '"scripts/check_linux_build_readiness.py|file|"',
            '"build.zig.zon|file|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|Run The Surface Check First|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh|"',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only|"',
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

    def test_restore_and_readiness_helpers_keep_check_only_and_cli_contracts(self) -> None:
        for fragment in (
            "--check-only",
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
        ):
            self.assertIn(fragment, self.restore_helper)

        for fragment in (
            "SAVED_ARCHIVE_GLOBS",
            '"rust_toolchain": "01-rust-*.tar.xz"',
            '"html5ever": "02-litefetch-html5ever-*.zip"',
            '"boringssl": "03-boringssl-zig-main.zip"',
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "--toolchains-root",
            "--saved-archives-root",
            "--offline-deps-root",
            "--fallback-zig-archive",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_runtime_gates_linux_route_and_manifest_keep_the_expected_zig_line_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/check_linux_build_readiness.py",
            "Prefer a Zig `0.15.2` toolchain",
        ):
            self.assertIn(fragment, self.linux_route)

        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()
