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

    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `PATH`, `CARGO`, and `RUSTC`
    - `../toolchains/rust-1.79.0`
    - `python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .`
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - saved Rust archive candidate discovery and staged-toolchain reuse
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `PATH`, `CARGO`, and `RUSTC`
    """,
    "scripts/check_issue3_staged_rust_toolchain_candidates.py": """
    EXPECTED_RUST_VERSION = "1.79.0"
    EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"
    DEFAULT_CANDIDATE_GLOBS = (
        "rust-*/cargo/bin/cargo",
        "*/cargo/bin/cargo",
    )
    def resolve_default_toolchains_root(repo_root: Path) -> Path:
        return (repo_root.parent / "toolchains").resolve()
    def discover_candidates(toolchains_root: Path) -> list[Path]:
        return []
    def describe_candidate(cargo_bin: Path) -> dict[str, object]:
        return {}
    def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:
        return {}
    "path_export"
    "cargo_export"
    "rustc_export"
    "matches expected 1.79.0"
    "mismatched: expected 1.79.0"
    "cargo matches expected 1.79.0 but rustc is unavailable"
    "restore the saved Rust 1.79.0 toolchain under ../toolchains"
    "Discover staged Rust toolchain candidates for issue #3 Linux/WSL build re-entry."
    "Discovered candidates:"
    "Preferred candidate:"
    "No staged Rust 1.79.0 candidate is ready."
    "Suggested next step:"
    """,
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": """
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    STAGED_TOOLCHAIN_CANDIDATES_COMMAND=
    "staged_toolchain_candidates":
    "path":
    "cargo":
    "rustc":
    "preflight":
    Staged toolchain candidate discovery:
    Put the restored Rust toolchain first on PATH:
    If the staged helper surfaces a preferred candidate, reuse its PATH/CARGO/RUSTC exports before unpacking the archive again.
    check_issue3_staged_rust_toolchain_candidates.py
    """,
    "scripts/check_linux_build_readiness.py": """
    parser.add_argument(
        "--cargo",
    )
    parser.add_argument(
        "--rustc",
    )
    "saved Rust toolchain archive"
    "suggested_next_step"
    "use the saved Rust toolchain"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-staged-rust-toolchain-candidates-")
    )
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
        cls.progress_route = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.staged_helper = read_text(
            cls.repo_root / "scripts/check_issue3_staged_rust_toolchain_candidates.py"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        )
        cls.build_readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_saved_rust_route_keeps_staged_candidate_step_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "PATH`, `CARGO`, and `RUSTC`",
            "../toolchains/rust-1.79.0",
            "python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .",
        ):
            self.assertIn(fragment, self.saved_rust_route)

    def test_progress_route_keeps_staged_rust_reuse_visible_for_issue11(self) -> None:
        for fragment in (
            "issue `#11`",
            "saved Rust archive candidate discovery and staged-toolchain reuse",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "PATH`, `CARGO`, and `RUSTC`",
        ):
            self.assertIn(fragment, self.progress_route)

    def test_staged_helper_keeps_candidate_discovery_and_export_contract_visible(self) -> None:
        for fragment in (
            'EXPECTED_RUST_VERSION = "1.79.0"',
            'EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"',
            'DEFAULT_CANDIDATE_GLOBS = (',
            '"rust-*/cargo/bin/cargo"',
            '"*/cargo/bin/cargo"',
            "def resolve_default_toolchains_root(repo_root: Path) -> Path:",
            "def discover_candidates(toolchains_root: Path) -> list[Path]:",
            "def describe_candidate(cargo_bin: Path) -> dict[str, object]:",
            "def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:",
            '"path_export"',
            '"cargo_export"',
            '"rustc_export"',
            '"matches expected 1.79.0"',
            '"mismatched: expected 1.79.0"',
            '"cargo matches expected 1.79.0 but rustc is unavailable"',
            '"restore the saved Rust 1.79.0 toolchain under ../toolchains"',
            '"Discover staged Rust toolchain candidates for issue #3 Linux/WSL build re-entry."',
            '"Discovered candidates:"',
            '"Preferred candidate:"',
            '"No staged Rust 1.79.0 candidate is ready."',
            '"Suggested next step:"',
        ):
            self.assertIn(fragment, self.staged_helper)

    def test_route_printer_keeps_staged_helper_and_export_handoff_together(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "STAGED_TOOLCHAIN_CANDIDATES_COMMAND=",
            '"staged_toolchain_candidates":',
            '"path":',
            '"cargo":',
            '"rustc":',
            '"preflight":',
            "Staged toolchain candidate discovery:",
            "Put the restored Rust toolchain first on PATH:",
            "If the staged helper surfaces a preferred candidate, reuse its PATH/CARGO/RUSTC exports before unpacking the archive again.",
            "check_issue3_staged_rust_toolchain_candidates.py",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_build_readiness_helper_keeps_rust_handoff_flags_visible(self) -> None:
        for fragment in (
            '"--cargo"',
            '"--rustc"',
            '"saved Rust toolchain archive"',
            '"suggested_next_step"',
            '"use the saved Rust toolchain"',
        ):
            self.assertIn(fragment, self.build_readiness_helper)


if __name__ == "__main__":
    unittest.main()
