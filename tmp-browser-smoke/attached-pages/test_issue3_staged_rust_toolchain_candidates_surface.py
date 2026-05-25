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

    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `../toolchains`
    - `../toolchains/rust-1.79.0`
    - `PATH`, `CARGO`, and `RUSTC`
    - `python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .`
    - Use `--json`
    - reuse an already-staged Rust `1.79.0` candidate
    - reuse its surfaced `PATH`, `CARGO`, and `RUSTC` exports
    """,
    "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md": """
    # Issue #11 Linux Re-entry Route Index

    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `../toolchains/rust-1.79.0`
    - `PATH`, `CARGO`, and `RUSTC`
    - `show_issue3_saved_rust_toolchain_route.sh`
    """,
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": """
    Google issue #3 saved Rust toolchain restore route
    scripts/check_issue3_staged_rust_toolchain_candidates.py
    scripts/check_issue3_saved_rust_archive_candidates.py
    scripts/linux/restore_saved_rust_toolchain.sh
    scripts/check_linux_build_readiness.py
    Surface check:
    Saved archive candidate discovery:
    Staged toolchain candidate discovery:
    Saved Rust restore surface check:
    Quick readiness preflight after restore or staged reuse:
    export PATH=
    export CARGO=
    export RUSTC=
    ../toolchains/rust-1.79.0
    staged_toolchain_candidates
    """,
    "scripts/check_issue3_staged_rust_toolchain_candidates.py": """
    EXPECTED_RUST_VERSION = "1.79.0"
    EXPECTED_RUST_LINE = "1.79.x"
    EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"
    DEFAULT_CANDIDATE_GLOBS = (
        "rust-*/cargo/bin/cargo",
        "*/cargo/bin/cargo",
    )
    def classify_version(version: str | None) -> str:
        if version is None:
            return "unknown-version"
        return "matches-expected-line"
    def version_status(version: str | None) -> str:
        return "matches expected 1.79.x"
    def resolve_default_toolchains_root(repo_root: Path) -> Path:
        return repo_root.parent / "toolchains"
    def discover_candidates(toolchains_root: Path) -> list[Path]:
        return []
    "older-than-expected"
    "matches-expected-line"
    "mismatched-line"
    "unknown-version"
    "cargo matches expected 1.79.x but rustc is unavailable"
    "missing rustc beside cargo"
    "export PATH="
    "export CARGO="
    "export RUSTC="
    "status": "passed"
    "preferred_candidate"
    "suggested_next_step"
    "restore a saved Rust 1.79.x toolchain under ../toolchains"
    "prefer"
    "stable restore location"
    parser.add_argument("--toolchains-root"
    parser.add_argument("--json"
    parser.add_argument("--self-test"
    print("Discovered candidates: none")
    print(f"Expected Rust version: {EXPECTED_RUST_VERSION}")
    """,
    "scripts/check_linux_build_readiness.py": """
    parser.add_argument(
        "--toolchains-root",
    )
    parser.add_argument(
        "--saved-archives-root",
    )
    parser.add_argument(
        "--skip-zig-check",
    )
    "suggested_next_step"
    "use the saved Rust toolchain"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-staged-rust-candidates-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3StagedRustToolchainCandidatesSurfaceTest(unittest.TestCase):
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
        cls.issue11_index = read_text(
            cls.repo_root / "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md"
        )
        cls.saved_rust_route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        )
        cls.staged_helper = read_text(
            cls.repo_root / "scripts/check_issue3_staged_rust_toolchain_candidates.py"
        )
        cls.build_readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_saved_rust_route_keeps_staged_candidate_reuse_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py",
            "../toolchains",
            "../toolchains/rust-1.79.0",
            "PATH`, `CARGO`, and `RUSTC`",
            "python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .",
            "Use `--json`",
            "reuse an already-staged Rust `1.79.0` candidate",
            "reuse its surfaced `PATH`, `CARGO`, and `RUSTC` exports",
        ):
            self.assertIn(fragment, self.saved_rust_route)

    def test_issue11_index_keeps_staged_rust_handoff_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/check_linux_build_readiness.py",
            "../toolchains/rust-1.79.0",
            "PATH`, `CARGO`, and `RUSTC`",
            "show_issue3_saved_rust_toolchain_route.sh",
        ):
            self.assertIn(fragment, self.issue11_index)

    def test_saved_rust_route_helper_keeps_staged_candidate_commands_and_exports_visible(self) -> None:
        for fragment in (
            "Google issue #3 saved Rust toolchain restore route",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/check_linux_build_readiness.py",
            "Surface check:",
            "Saved archive candidate discovery:",
            "Staged toolchain candidate discovery:",
            "Saved Rust restore surface check:",
            "Quick readiness preflight after restore or staged reuse:",
            "export PATH=",
            "export CARGO=",
            "export RUSTC=",
            "../toolchains/rust-1.79.0",
            "staged_toolchain_candidates",
        ):
            self.assertIn(fragment, self.saved_rust_route_helper)

        staged_index = self.saved_rust_route_helper.index("Staged toolchain candidate discovery:")
        restore_index = self.saved_rust_route_helper.index("Saved Rust restore surface check:")
        preflight_index = self.saved_rust_route_helper.index(
            "Quick readiness preflight after restore or staged reuse:"
        )
        self.assertLess(staged_index, restore_index)
        self.assertLess(restore_index, preflight_index)

    def test_staged_helper_keeps_expected_version_candidate_classification_and_exports(self) -> None:
        for fragment in (
            'EXPECTED_RUST_VERSION = "1.79.0"',
            'EXPECTED_RUST_LINE = "1.79.x"',
            'EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"',
            'DEFAULT_CANDIDATE_GLOBS = (',
            '"rust-*/cargo/bin/cargo"',
            '"*/cargo/bin/cargo"',
            'return "unknown-version"',
            '"older-than-expected"',
            '"matches-expected-line"',
            '"mismatched-line"',
            '"cargo matches expected 1.79.x but rustc is unavailable"',
            '"missing rustc beside cargo"',
            '"export PATH="',
            '"export CARGO="',
            '"export RUSTC="',
            '"preferred_candidate"',
            '"suggested_next_step"',
            'restore a saved Rust 1.79.x toolchain under ../toolchains',
            '"stable restore location"',
            'parser.add_argument("--toolchains-root"',
            'parser.add_argument("--json"',
            'parser.add_argument("--self-test"',
            'print("Discovered candidates: none")',
            'print(f"Expected Rust version: {EXPECTED_RUST_VERSION}")',
        ):
            self.assertIn(fragment, self.staged_helper)

    def test_build_readiness_helper_stays_compatible_with_staged_rust_reuse(self) -> None:
        for fragment in (
            '"--toolchains-root"',
            '"--saved-archives-root"',
            '"--skip-zig-check"',
            '"suggested_next_step"',
            '"use the saved Rust toolchain"',
        ):
            self.assertIn(fragment, self.build_readiness_helper)


if __name__ == "__main__":
    unittest.main()
