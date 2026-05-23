from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md": """
# Issue #3 Saved Rust Toolchain Restore Route

- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/restore_saved_rust_toolchain.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `../toolchains/rust-1.79.0`
- `PATH`, `CARGO`, and `RUSTC`
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_linux_build_readiness.py`
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
""",
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|"
    "scripts/linux/restore_saved_rust_toolchain.sh|file|"
    "scripts/check_linux_build_readiness.py|file|"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|"
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|"
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|restore_saved_rust_toolchain.sh|"
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_linux_build_readiness.py|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|restore_saved_rust_toolchain.sh|"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_linux_build_readiness.py|"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Saved Rust restore surface check:|"
    "scripts/linux/restore_saved_rust_toolchain.sh|--check-only|"
    "scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|"
)
""",
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": r"""
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh --repo-root ${BROWSER_ROOT}"
CHECK_ONLY_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${BROWSER_ROOT} --dependencies-root ${DEPENDENCIES_ROOT} --toolchain-root ${TOOLCHAIN_ROOT} --archive ${ARCHIVE_PATH} --check-only"
RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${BROWSER_ROOT} --dependencies-root ${DEPENDENCIES_ROOT} --toolchain-root ${TOOLCHAIN_ROOT} --archive ${ARCHIVE_PATH}"
PATH_COMMAND="export PATH=${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin:$PATH"
CARGO_COMMAND="export CARGO=${TOOLCHAIN_ROOT}/cargo/bin/cargo"
RUSTC_COMMAND="export RUSTC=${TOOLCHAIN_ROOT}/rustc/bin/rustc"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${BROWSER_ROOT} --skip-zig-check"
Saved Rust restore surface check:
Google issue #3 saved Rust toolchain restore route
""",
    "scripts/linux/restore_saved_rust_toolchain.sh": r"""
Defaults:
  dependencies root  <browser-root>/../memory/repo_archives/browser/dependencies
  archive            <dependencies-root>/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz
  toolchain root     <browser-root>/../toolchains/rust-1.79.0
After restore, the script prints the exact PATH/CARGO/RUSTC commands to reuse
The archive extracts to:
  <toolchain-root>
--check-only
--force
Suggested shell setup:
Suggested preflight:
Suggested build:
check_offline_build_prereqs.sh
zig build --summary all
rust-1.79.0-x86_64-unknown-linux-gnu
""",
    "scripts/check_linux_build_readiness.py": """
def build_parser():
    parser.add_argument("--skip-zig-check")
    parser.add_argument("--expect-saved-archives")
    parser.add_argument("--saved-archives-root")
    parser.add_argument("--expect-offline-deps")
    parser.add_argument("--require-prebuilt-v8")
    parser.add_argument("--self-test")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-rust-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedRustToolchainRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
        )
        cls.build_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_rust_toolchain.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_route_note_keeps_saved_rust_surface_and_handoff_guidance(self) -> None:
        for fragment in (
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "show_issue3_saved_rust_toolchain_route.sh",
            "restore_saved_rust_toolchain.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "../toolchains/rust-1.79.0",
            "PATH`, `CARGO`, and `RUSTC`",
        ):
            self.assertIn(fragment, self.route_note)

    def test_build_readiness_note_and_runtime_gates_keep_the_saved_rust_route_visible(
        self,
    ) -> None:
        for fragment in (
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "show_issue3_saved_rust_toolchain_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.build_route_note)
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_surface_checker_keeps_route_note_linux_note_and_restore_expectations(
        self,
    ) -> None:
        for fragment in (
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"',
            '"scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|"',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|"',
            '"scripts/linux/restore_saved_rust_toolchain.sh|file|"',
            '"scripts/check_linux_build_readiness.py|file|"',
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|"',
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|"',
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|restore_saved_rust_toolchain.sh|"',
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_linux_build_readiness.py|"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|"',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|"',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|restore_saved_rust_toolchain.sh|"',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_linux_build_readiness.py|"',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Saved Rust restore surface check:|"',
            '"scripts/linux/restore_saved_rust_toolchain.sh|--check-only|"',
            '"scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_surface_restore_exports_and_preflight_commands(
        self,
    ) -> None:
        for fragment in (
            'SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh',
            'CHECK_ONLY_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh',
            "--check-only",
            'RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh',
            'PATH_COMMAND="export PATH=',
            'CARGO_COMMAND="export CARGO=',
            'RUSTC_COMMAND="export RUSTC=',
            'PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root',
            "--skip-zig-check",
            "Saved Rust restore surface check:",
            "Google issue #3 saved Rust toolchain restore route",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_restore_helper_keeps_archive_defaults_and_shell_handoff_surface(
        self,
    ) -> None:
        for fragment in (
            "memory/repo_archives/browser/dependencies",
            "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "../toolchains/rust-1.79.0",
            "PATH/CARGO/RUSTC commands",
            "<toolchain-root>",
            "--check-only",
            "--force",
            "Suggested shell setup:",
            "Suggested preflight:",
            "Suggested build:",
            "check_offline_build_prereqs.sh",
            "zig build --summary all",
            "rust-1.79.0-x86_64-unknown-linux-gnu",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_readiness_helper_keeps_the_cli_switches_used_by_the_saved_rust_route(
        self,
    ) -> None:
        for fragment in (
            "--skip-zig-check",
            "--expect-saved-archives",
            "--saved-archives-root",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "--self-test",
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
