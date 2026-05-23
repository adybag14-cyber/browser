from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- A saved Rust `1.79.0` restore command
- The attached fallback Zig archive location
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
RUST_RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${REPO_ROOT} --dependencies-root ${SAVED_ARCHIVES_ROOT}/dependencies --toolchain-root ${RUST_TOOLCHAIN_DIR}"
RUST_RESTORE_CHECK_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${REPO_ROOT} --dependencies-root ${SAVED_ARCHIVES_ROOT}/dependencies --toolchain-root ${RUST_TOOLCHAIN_DIR} --check-only"
RUST_PATH_COMMAND="export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:${RUST_TOOLCHAIN_DIR}/rustc/bin:\$PATH"
Saved Rust restore surface check:
Restore the saved Rust 1.79.0 toolchain:
Put the restored Rust toolchain first on PATH:
Fallback Zig archive:
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": r"""
REFERENCE_PATHS=(
    "scripts/linux/restore_saved_rust_toolchain.sh|file|Saved Rust restore helper"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|saved Rust 1.79.0 restore command|The Linux build-readiness note keeps the saved Rust restore step visible before trusting Linux or WSL Zig output."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|restore_saved_rust_toolchain.sh|The Linux route printer still points at the saved Rust restore helper."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Fallback Zig archive:|The Linux route printer still prints the attached fallback Zig archive surface."
    "scripts/linux/restore_saved_rust_toolchain.sh|--check-only|The saved Rust restore helper still supports surface-only validation without extraction."
    "scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|The saved Rust restore helper still prints the PATH/CARGO/RUSTC handoff surface."
)
""",
    "scripts/linux/restore_saved_rust_toolchain.sh": r"""
DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"
DEFAULT_ARCHIVE_NAME="01-${DEFAULT_TOOLCHAIN_DIR_NAME}.tar.xz"
CARGO_BIN="${TOOLCHAIN_ROOT}/cargo/bin/cargo"
RUSTC_BIN="${TOOLCHAIN_ROOT}/rustc/bin/rustc"
TOOLCHAIN_PATH="${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin"
    [--check-only] \
    [--json] \
    [--force]
Saved Rust toolchain restore surface check passed.
Suggested shell setup:
  export PATH='${TOOLCHAIN_PATH}:$PATH'
  export CARGO='${CARGO_BIN}'
  export RUSTC='${RUSTC_BIN}'
Suggested preflight:
Suggested build:
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-rust-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedRustToolchainRestoreSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_rust_toolchain.sh"
        )

    def test_route_note_keeps_saved_rust_restore_step_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "saved Rust `1.79.0` restore command",
            "fallback Zig archive location",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_helper_keeps_restore_check_restore_and_path_exports(self) -> None:
        for fragment in (
            'RUST_RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh',
            "--dependencies-root",
            "--toolchain-root",
            'RUST_RESTORE_CHECK_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh',
            "--check-only",
            'RUST_PATH_COMMAND="export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:${RUST_TOOLCHAIN_DIR}/rustc/bin:',
            "Saved Rust restore surface check:",
            "Restore the saved Rust 1.79.0 toolchain:",
            "Put the restored Rust toolchain first on PATH:",
            "Fallback Zig archive:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_restore_helper_expectations(self) -> None:
        for fragment in (
            '"scripts/linux/restore_saved_rust_toolchain.sh|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|saved Rust 1.79.0 restore command|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|restore_saved_rust_toolchain.sh|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|Fallback Zig archive:|',
            '"scripts/linux/restore_saved_rust_toolchain.sh|--check-only|',
            '"scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_restore_helper_keeps_archive_defaults_and_shell_handoff(self) -> None:
        for fragment in (
            'DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"',
            'DEFAULT_ARCHIVE_NAME="01-${DEFAULT_TOOLCHAIN_DIR_NAME}.tar.xz"',
            'CARGO_BIN="${TOOLCHAIN_ROOT}/cargo/bin/cargo"',
            'RUSTC_BIN="${TOOLCHAIN_ROOT}/rustc/bin/rustc"',
            'TOOLCHAIN_PATH="${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin"',
            "--check-only",
            "--json",
            "--force",
            "Saved Rust toolchain restore surface check passed.",
            "Suggested shell setup:",
            "export PATH=",
            "export CARGO=",
            "export RUSTC=",
            "Suggested preflight:",
            "Suggested build:",
        ):
            self.assertIn(fragment, self.restore_helper)


if __name__ == "__main__":
    unittest.main()
