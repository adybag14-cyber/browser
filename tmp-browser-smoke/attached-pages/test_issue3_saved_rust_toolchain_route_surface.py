from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - restore the saved Rust `1.79.0` toolchain
    """,
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md": """
    # Issue #3 Saved Rust Toolchain Restore Route

    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/restore_saved_rust_toolchain.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `../toolchains/rust-1.79.0`
    - `PATH`, `CARGO`, and `RUSTC`
    - Run `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    """,
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh": r"""
    REFERENCE_PATHS=(
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Read-first saved Rust restore note."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion."
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note."
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|Surface checker."
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|Route printer."
        "scripts/linux/restore_saved_rust_toolchain.sh|file|Restore helper."
        "scripts/check_linux_build_readiness.py|file|Readiness helper."
    )
    CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|Route note prints the surface-check command."
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|restore_saved_rust_toolchain.sh|Route note points at the restore helper."
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_linux_build_readiness.py|Route note points at the readiness preflight."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|Linux note keeps the saved Rust checker visible."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|Linux note names the saved Rust route printer."
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|Route printer points back to the surface checker."
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|restore_saved_rust_toolchain.sh|Route printer points at the restore helper."
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_linux_build_readiness.py|Route printer points at the readiness helper."
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Saved Rust restore surface check:|Route printer keeps the check-only step visible."
        "scripts/linux/restore_saved_rust_toolchain.sh|--check-only|Restore helper supports surface-only validation."
        "scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|Restore helper prints the PATH/CARGO/RUSTC handoff."
    )
    """,
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": r"""
    DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"
    DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"
    DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"
    SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh --repo-root ${BROWSER_ROOT}"
    CHECK_ONLY_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${BROWSER_ROOT} --dependencies-root ${DEPENDENCIES_ROOT} --toolchain-root ${TOOLCHAIN_ROOT} --archive ${ARCHIVE_PATH} --check-only"
    RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root ${BROWSER_ROOT} --dependencies-root ${DEPENDENCIES_ROOT} --toolchain-root ${TOOLCHAIN_ROOT} --archive ${ARCHIVE_PATH}"
    PATH_COMMAND="export PATH=${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin:$PATH"
    CARGO_COMMAND="export CARGO=${TOOLCHAIN_ROOT}/cargo/bin/cargo"
    RUSTC_COMMAND="export RUSTC=${TOOLCHAIN_ROOT}/rustc/bin/rustc"
    PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${BROWSER_ROOT} --skip-zig-check"
    Saved Rust restore surface check:
    Put the restored Rust toolchain first on PATH:
    The default restore location now matches the broader Linux build-readiness route: ../toolchains/rust-1.79.0.
    """,
    "scripts/linux/restore_saved_rust_toolchain.sh": r"""
    Usage:
      scripts/linux/restore_saved_rust_toolchain.sh \
        [--browser-root /path/to/browser-repo] \
        [--dependencies-root /path/to/dependencies] \
        [--toolchain-root /path/to/toolchains/rust-1.79.0] \
        [--toolchain-parent /path/to/toolchains] \
        [--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz] \
        [--check-only] \
        [--json] \
        [--force]

    DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"
    DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"
    DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"
    TOOLCHAIN_PATH="${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin"
    CARGO_BIN="${TOOLCHAIN_ROOT}/cargo/bin/cargo"
    RUSTC_BIN="${TOOLCHAIN_ROOT}/rustc/bin/rustc"
    if [[ "${CHECK_ONLY}" == "true" ]]; then
        echo "Saved Rust toolchain restore surface check passed."
        echo "Suggested shell setup:"
        printf "  export PATH='%s:$PATH'\n" "${TOOLCHAIN_PATH}"
        printf "  export CARGO='%s'\n" "${CARGO_BIN}"
        printf "  export RUSTC='%s'\n" "${RUSTC_BIN}"
    fi
    echo "Suggested preflight:"
    echo "Suggested build:"
    """,
    "scripts/check_linux_build_readiness.py": """
    def build_parser():
        parser.add_argument("--skip-zig-check")
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

        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.linux_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.saved_rust_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
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

    def test_route_note_keeps_saved_rust_route_guidance_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "../toolchains/rust-1.79.0",
            "PATH`, `CARGO`, and `RUSTC",
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        ):
            self.assertIn(fragment, self.saved_rust_route_note)

    def test_linux_note_and_runtime_gates_still_point_back_to_saved_rust_route(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "show_issue3_saved_rust_toolchain_route.sh",
            "saved Rust `1.79.0` toolchain",
        ):
            self.assertIn(fragment, self.linux_route_note)

        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_surface_checker_keeps_route_contract_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|',
            '"scripts/linux/restore_saved_rust_toolchain.sh|file|',
            '"scripts/check_linux_build_readiness.py|file|',
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|',
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|restore_saved_rust_toolchain.sh|',
            '"docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_linux_build_readiness.py|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|check_issue3_saved_rust_toolchain_route_surface.sh|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_saved_rust_toolchain_route.sh|',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_issue3_saved_rust_toolchain_route_surface.sh|',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|restore_saved_rust_toolchain.sh|',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|check_linux_build_readiness.py|',
            '"scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Saved Rust restore surface check:|',
            '"scripts/linux/restore_saved_rust_toolchain.sh|--check-only|',
            '"scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_restore_and_shell_handoff_visible(self) -> None:
        for fragment in (
            'DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"',
            'DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"',
            'DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"',
            'SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh',
            'CHECK_ONLY_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh',
            "--check-only",
            'RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh',
            'PATH_COMMAND="export PATH=${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin:$PATH"',
            'CARGO_COMMAND="export CARGO=${TOOLCHAIN_ROOT}/cargo/bin/cargo"',
            'RUSTC_COMMAND="export RUSTC=${TOOLCHAIN_ROOT}/rustc/bin/rustc"',
            'PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${BROWSER_ROOT} --skip-zig-check"',
            "Saved Rust restore surface check:",
            "Put the restored Rust toolchain first on PATH:",
            "../toolchains/rust-1.79.0",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_restore_helper_keeps_check_only_json_and_shell_exports_visible(self) -> None:
        for fragment in (
            "--check-only",
            "--json",
            "--force",
            'DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"',
            'DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"',
            'DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"',
            'TOOLCHAIN_PATH="${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin"',
            'CARGO_BIN="${TOOLCHAIN_ROOT}/cargo/bin/cargo"',
            'RUSTC_BIN="${TOOLCHAIN_ROOT}/rustc/bin/rustc"',
            "Saved Rust toolchain restore surface check passed.",
            "Suggested shell setup:",
            "export PATH=",
            "export CARGO=",
            "export RUSTC=",
            "Suggested preflight:",
            "Suggested build:",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_readiness_helper_still_keeps_skip_zig_switch_visible(self) -> None:
        self.assertIn("--skip-zig-check", self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
