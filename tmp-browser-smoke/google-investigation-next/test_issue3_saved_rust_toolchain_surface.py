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
    - `scripts/check_saved_rust_toolchain.py`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `../toolchains/rust-1.79.0`
    - `PATH`, `CARGO`, and `RUSTC`
    - `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build Readiness Route

    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_saved_rust_toolchain.py`
    - `scripts/check_linux_build_readiness.py`
    - `../toolchains/rust-1.79.0`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_saved_rust_toolchain.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh": """
    declare -a REFERENCE_PATHS=(
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|file|Read-first saved Rust restore note"
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion"
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh|file|surface checker"
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|file|route printer"
        "scripts/linux/restore_saved_rust_toolchain.sh|file|restore helper"
        "scripts/check_saved_rust_toolchain.py|file|saved Rust checker"
        "scripts/check_linux_build_readiness.py|file|readiness helper"
    )
    declare -a CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_saved_rust_toolchain.py|The saved Rust route note points at the direct checker."
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|../toolchains/rust-1.79.0|The saved Rust route note keeps the aligned restore root visible."
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|scripts/check_saved_rust_toolchain.py|The route printer points at the direct checker."
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|Saved Rust checker:|The route printer keeps the checker step visible."
        "scripts/linux/restore_saved_rust_toolchain.sh|Suggested shell setup:|The restore helper prints shell exports."
        "scripts/check_saved_rust_toolchain.py|DEFAULT_EXPECTED_VERSION = \"1.79.0\"|The direct checker stays pinned to the saved Rust version."
    )
    """,
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": """
    Saved Rust checker:
      python ./scripts/check_saved_rust_toolchain.py --repo-root .

    Put the restored Rust toolchain first on PATH:
      export PATH=/tmp/toolchains/rust-1.79.0/cargo/bin:/tmp/toolchains/rust-1.79.0/rustc/bin:$PATH
      export CARGO=/tmp/toolchains/rust-1.79.0/cargo/bin/cargo
      export RUSTC=/tmp/toolchains/rust-1.79.0/rustc/bin/rustc

    Quick readiness preflight after restore:
      python ./scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
    """,
    "scripts/linux/restore_saved_rust_toolchain.sh": """
    Usage:
      scripts/linux/restore_saved_rust_toolchain.sh \\
        [--check-only] \\
        [--force]

    Suggested shell setup:
      export PATH='/tmp/toolchains/rust-1.79.0/cargo/bin:/tmp/toolchains/rust-1.79.0/rustc/bin:$PATH'
      export CARGO='/tmp/toolchains/rust-1.79.0/cargo/bin/cargo'
      export RUSTC='/tmp/toolchains/rust-1.79.0/rustc/bin/rustc'

    Suggested build:
      ZIG=/absolute/path/to/zig CARGO='/tmp/toolchains/rust-1.79.0/cargo/bin/cargo' RUSTC='/tmp/toolchains/rust-1.79.0/rustc/bin/rustc' zig build --summary all
    """,
    "scripts/check_saved_rust_toolchain.py": """
    DEFAULT_TOOLCHAIN_DIR_NAME = "rust-1.79.0"
    DEFAULT_EXPECTED_VERSION = "1.79.0"

    def resolve_default_toolchain_root(repo_root: Path) -> Path:
        return (repo_root.parent / "toolchains" / DEFAULT_TOOLCHAIN_DIR_NAME).resolve()

    def resolve_tool_paths(toolchain_root: Path) -> dict[str, Path]:
        return {
            "cargo": toolchain_root / "cargo" / "bin" / "cargo",
            "rustc": toolchain_root / "rustc" / "bin" / "rustc",
            "rustdoc": toolchain_root / "rust-docs" / "bin" / "rustdoc",
        }

    def collect_report(repo_root: Path, toolchain_root: Path, expected_version: str) -> dict[str, object]:
        warnings: list[str] = []
        failures: list[str] = []
        warnings.extend(["rustdoc does not exist: /tmp/toolchains/rust-1.79.0/rust-docs/bin/rustdoc"])
        failures.extend(["cargo version 1.80.0 does not match expected saved Rust version 1.79.0"])
        return {
            "export_path": "/tmp/toolchains/rust-1.79.0/cargo/bin:/tmp/toolchains/rust-1.79.0/rustc/bin",
            "warnings": warnings,
            "failures": failures,
        }
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    print("Suggested next step: run the saved-archive restore command above, use the saved Rust toolchain, and retry zig build with a Zig 0.15.2 toolchain.")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-rust-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedRustToolchainSurfaceTest(unittest.TestCase):
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
        cls.build_readiness_route = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
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
        cls.direct_checker = read_text(
            cls.repo_root / "scripts/check_saved_rust_toolchain.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_route_docs_keep_saved_rust_checker_and_aligned_toolchain_root_visible(self) -> None:
        for text in (
            self.saved_rust_route,
            self.build_readiness_route,
            self.runtime_gates,
        ):
            self.assertIn("scripts/check_saved_rust_toolchain.py", text)
            self.assertIn("scripts/check_linux_build_readiness.py", text)

        self.assertIn("../toolchains/rust-1.79.0", self.saved_rust_route)
        self.assertIn("../toolchains/rust-1.79.0", self.build_readiness_route)

    def test_route_surface_keeps_direct_checker_in_reference_and_content_expectations(self) -> None:
        for fragment in (
            '"scripts/check_saved_rust_toolchain.py|file|saved Rust checker"',
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|scripts/check_saved_rust_toolchain.py|",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md|../toolchains/rust-1.79.0|",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh|scripts/check_saved_rust_toolchain.py|",
            'scripts/check_saved_rust_toolchain.py|DEFAULT_EXPECTED_VERSION = \\\"1.79.0\\\"|',
        ):
            self.assertIn(fragment, self.route_surface)

    def test_route_printer_keeps_checker_shell_exports_and_readiness_handoff(self) -> None:
        for fragment in (
            "Saved Rust checker:",
            "python ./scripts/check_saved_rust_toolchain.py --repo-root .",
            "export PATH=",
            "export CARGO=",
            "export RUSTC=",
            "python ./scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_restore_helper_and_direct_checker_keep_saved_version_contract_visible(self) -> None:
        for fragment in (
            "--check-only",
            "Suggested shell setup:",
            "export CARGO=",
            "export RUSTC=",
            "Suggested build:",
        ):
            self.assertIn(fragment, self.restore_helper)

        for fragment in (
            'DEFAULT_TOOLCHAIN_DIR_NAME = "rust-1.79.0"',
            'DEFAULT_EXPECTED_VERSION = "1.79.0"',
            'toolchain_root / "cargo" / "bin" / "cargo"',
            'toolchain_root / "rustc" / "bin" / "rustc"',
            'toolchain_root / "rust-docs" / "bin" / "rustdoc"',
            "rustdoc does not exist:",
            "cargo version 1.80.0 does not match expected saved Rust version 1.79.0",
            '"export_path":',
        ):
            self.assertIn(fragment, self.direct_checker)

    def test_readiness_helper_still_points_next_steps_at_saved_rust_route(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "use the saved Rust toolchain",
            "retry zig build with a Zig 0.15.2 toolchain",
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
