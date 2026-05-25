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
    - `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `--browser-root /path/to/browser`
    - `--dependencies-root /path/to/memory/repo_archives/browser/dependencies`
    - `--toolchain-root /path/to/toolchains/rust-1.79.0`
    - `PATH`, `CARGO`, and `RUSTC`
    - `check_linux_build_readiness.py`
    - `../toolchains/rust-1.79.0`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/restore_saved_rust_toolchain.sh`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    - `python scripts/check_issue3_saved_memory_inputs.py --repo-root .`
    """,
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh": """
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
    scripts/linux/show_issue3_saved_rust_toolchain_route.sh
    scripts/linux/restore_saved_rust_toolchain.sh
    scripts/check_linux_build_readiness.py
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|restore_saved_rust_toolchain.sh
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_linux_build_readiness.py
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh
    scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Saved Rust restore surface check:
    scripts/linux/restore_saved_rust_toolchain.sh|--check-only
    scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:
    """,
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": """
    Google issue #3 saved Rust toolchain restore route
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    check_issue3_saved_rust_toolchain_route_surface.sh
    restore_saved_rust_toolchain.sh
    check_linux_build_readiness.py
    Surface check:
    Saved Rust restore surface check:
    Restore the saved Rust 1.79.0 toolchain:
    Quick readiness preflight after restore:
    export PATH=
    export CARGO=
    export RUSTC=
    ../toolchains/rust-1.79.0
    """,
    "scripts/linux/restore_saved_rust_toolchain.sh": """
    --browser-root /path/to/browser-repo
    --dependencies-root /path/to/dependencies
    --toolchain-root /path/to/toolchains/rust-1.79.0
    --toolchain-parent /path/to/toolchains
    --offline-deps-root /path/to/offline-deps
    --archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz
    --check-only
    --json
    --force
    DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"
    DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"
    if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved Rust toolchain restore surface check passed."
    echo "Suggested shell setup:"
    echo "Suggested preflight:"
    echo "Suggested build:"
    PREBUILT_V8_GLOB="libc_v8_*.a"
    """,
    "scripts/check_linux_build_readiness.py": """
    parser.add_argument(
        "--cargo",
    )
    parser.add_argument(
        "--rustc",
    )
    parser.add_argument(
        "--expect-offline-deps",
    )
    parser.add_argument(
        "--require-prebuilt-v8",
    )
    parser.add_argument(
        "--expect-saved-archives",
    )
    parser.add_argument(
        "--fallback-zig-archive",
    )
    parser.add_argument(
        "--toolchains-root",
    )
    "saved Rust toolchain archive"
    "suggested_prepare_command"
    "suggested_next_step"
    "use the saved Rust toolchain"
    "retry `zig build` with a Zig 0.15.2 toolchain"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-rust-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedRustToolchainRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.saved_rust_route = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
        )
        cls.linux_build_route = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.route_surface = read_text(
            cls.repo_root / "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_rust_toolchain.sh"
        )
        cls.build_readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_saved_rust_route_keeps_surface_restore_and_preflight_commands_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "--browser-root /path/to/browser",
            "--dependencies-root /path/to/memory/repo_archives/browser/dependencies",
            "--toolchain-root /path/to/toolchains/rust-1.79.0",
            "PATH`, `CARGO`, and `RUSTC`",
            "../toolchains/rust-1.79.0",
        ):
            self.assertIn(fragment, self.saved_rust_route)

    def test_linux_build_readiness_route_keeps_saved_rust_route_in_the_reentry_ladder(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/check_linux_build_readiness.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
        ):
            self.assertIn(fragment, self.linux_build_route)

    def test_route_surface_checker_tracks_docs_helpers_and_restore_output_contract(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|restore_saved_rust_toolchain.sh",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Saved Rust restore surface check:",
            'scripts/linux/restore_saved_rust_toolchain.sh|--check-only',
            'scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:',
        ):
            self.assertIn(fragment, self.route_surface)

    def test_route_printer_keeps_surface_check_restore_exports_and_preflight_together(self) -> None:
        for fragment in (
            "Google issue #3 saved Rust toolchain restore route",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "restore_saved_rust_toolchain.sh",
            "check_linux_build_readiness.py",
            "Saved Rust restore surface check:",
            "Surface check:",
            "Restore the saved Rust 1.79.0 toolchain:",
            "Quick readiness preflight after restore:",
            "export PATH=",
            "export CARGO=",
            "export RUSTC=",
            "../toolchains/rust-1.79.0",
        ):
            self.assertIn(fragment, self.route_printer)

        surface_index = self.route_printer.index("Surface check:")
        check_only_index = self.route_printer.index("Saved Rust restore surface check:")
        restore_index = self.route_printer.index(
            "Restore the saved Rust 1.79.0 toolchain:"
        )
        preflight_index = self.route_printer.index(
            "Quick readiness preflight after restore:"
        )
        self.assertLess(surface_index, check_only_index)
        self.assertLess(check_only_index, restore_index)
        self.assertLess(restore_index, preflight_index)

    def test_restore_helper_keeps_check_only_force_and_shell_handoff_surfaces(self) -> None:
        for fragment in (
            "--browser-root /path/to/browser-repo",
            "--dependencies-root /path/to/dependencies",
            "--toolchain-root /path/to/toolchains/rust-1.79.0",
            "--toolchain-parent /path/to/toolchains",
            "--offline-deps-root /path/to/offline-deps",
            "--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "--check-only",
            "--json",
            "--force",
            'DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"',
            'DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"',
            'if [[ "${CHECK_ONLY}" == "true" ]]; then',
            'echo "Saved Rust toolchain restore surface check passed."',
            'echo "Suggested shell setup:"',
            'echo "Suggested preflight:"',
            'echo "Suggested build:"',
            'PREBUILT_V8_GLOB="libc_v8_*.a"',
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_build_readiness_helper_keeps_saved_rust_and_archive_inputs_in_scope(self) -> None:
        for fragment in (
            '"--cargo"',
            '"--rustc"',
            '"--expect-offline-deps"',
            '"--require-prebuilt-v8"',
            '"--expect-saved-archives"',
            '"--fallback-zig-archive"',
            '"--toolchains-root"',
            '"saved Rust toolchain archive"',
            '"suggested_prepare_command"',
            '"suggested_next_step"',
            '"use the saved Rust toolchain"',
            '"retry `zig build` with a Zig 0.15.2 toolchain"',
        ):
            self.assertIn(fragment, self.build_readiness_helper)


if __name__ == "__main__":
    unittest.main()
