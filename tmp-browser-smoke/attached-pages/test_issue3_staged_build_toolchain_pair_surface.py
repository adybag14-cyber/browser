from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUST_TOOLCHAIN_REENTRY_ROUTE.md": """
    # Issue #11 Rust Toolchain Re-entry Bridge

    - `scripts/check_issue3_rust_toolchain_reentry.py`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/check_issue3_staged_build_toolchain_pair.py`
    - `scripts/linux/restore_saved_rust_toolchain.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - the staged Rust and Zig toolchain pairs it can probe under `../toolchains`
    - the exact staged-pair helper command when the run wants one quick answer before the broader Linux build-readiness route
    - `python3 ./scripts/check_issue3_staged_build_toolchain_pair.py --repo-root .`
    - the exact `check_linux_build_readiness.py` rerun command when both the Rust and Zig sides are already reusable
    """,
    "scripts/check_issue3_staged_build_toolchain_pair.py": """
    EXPECTED_RUST_VERSION = "1.79.0"
    DEFAULT_ZIG_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
        "*/zig",
        "*/bin/zig",
        "zig",
    )
    DEFAULT_RUST_GLOBS = (
        "rust-*/cargo/bin/cargo",
        "*/cargo/bin/cargo",
    )
    MINIMUM_ZIG_RE = re.compile(r'\\.minimum_zig_version\\s*=\\s*"([^"]+)"')
    SEMVER_RE = re.compile(r"(\\d+)\\.(\\d+)\\.(\\d+)")
    def same_major_minor(expected: str, actual: str) -> bool:
        return True
    def resolve_default_toolchains_root(repo_root: Path) -> Path:
        return (repo_root.parent / "toolchains").resolve()
    def load_minimum_zig(repo_root: Path) -> str:
        return "0.15.2"
    def discover_candidates(toolchains_root: Path, patterns: tuple[str, ...]) -> list[Path]:
        return []
    def describe_zig_candidate(minimum_zig: str, zig_bin: Path) -> dict[str, object]:
        return {}
    def describe_rust_candidate(cargo_bin: Path) -> dict[str, object]:
        return {}
    def choose_preferred_zig(candidates: list[dict[str, object]]) -> dict[str, object] | None:
        return None
    def choose_preferred_rust(candidates: list[dict[str, object]]) -> dict[str, object] | None:
        return None
    def build_readiness_command(
        repo_root: Path,
        zig_bin: Path,
        cargo_bin: Path,
        rustc_bin: Path,
    ) -> str:
        return "python3 scripts/check_linux_build_readiness.py --zig zig --cargo cargo --rustc rustc"
    def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:
        return {}
    "path_export"
    "cargo_export"
    "rustc_export"
    "matches expected 1.79.0"
    "mismatched: expected 1.79.0"
    "cargo matches expected 1.79.0 but rustc is unavailable"
    "matches expected 0.15.x line"
    "older than minimum"
    "mismatched: expected 0.15.x line"
    "no staged Rust toolchain under"
    "no staged Zig toolchain under"
    "Issue #11 staged build-toolchain pair"
    "Staged Rust candidates:"
    "Staged Zig candidates:"
    "Preferred staged pair:"
    "Exact readiness rerun:"
    "No full staged Rust/Zig pair is ready."
    """,
    "scripts/check_linux_build_readiness.py": """
    parser.add_argument(
        "--zig",
    )
    parser.add_argument(
        "--cargo",
    )
    parser.add_argument(
        "--rustc",
    )
    "toolchains_root"
    "zig_candidates"
    "suggested_next_step"
    """,
    "build.zig.zon": """
    .{
        .name = .browser,
        .version = "0.0.0",
        .minimum_zig_version = "0.15.2",
    }
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-staged-build-toolchain-pair-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3StagedBuildToolchainPairSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.reentry_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUST_TOOLCHAIN_REENTRY_ROUTE.md"
        )
        cls.staged_pair_helper = read_text(
            cls.repo_root / "scripts/check_issue3_staged_build_toolchain_pair.py"
        )
        cls.build_readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_reentry_note_keeps_staged_pair_helper_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_rust_toolchain_reentry.py",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/check_issue3_staged_build_toolchain_pair.py",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "the staged Rust and Zig toolchain pairs it can probe under `../toolchains`",
            "the exact staged-pair helper command when the run wants one quick answer before the broader Linux build-readiness route",
            "python3 ./scripts/check_issue3_staged_build_toolchain_pair.py --repo-root .",
            "the exact `check_linux_build_readiness.py` rerun command when both the Rust and Zig sides are already reusable",
        ):
            self.assertIn(fragment, self.reentry_note)

    def test_staged_pair_helper_keeps_pair_discovery_and_readiness_contract_visible(
        self,
    ) -> None:
        for fragment in (
            'EXPECTED_RUST_VERSION = "1.79.0"',
            'DEFAULT_ZIG_GLOBS = (',
            '"zig*/zig"',
            '"zig*/bin/zig"',
            '"*/zig"',
            '"*/bin/zig"',
            '"zig"',
            'DEFAULT_RUST_GLOBS = (',
            '"rust-*/cargo/bin/cargo"',
            '"*/cargo/bin/cargo"',
            "def same_major_minor(expected: str, actual: str) -> bool:",
            "def resolve_default_toolchains_root(repo_root: Path) -> Path:",
            "def load_minimum_zig(repo_root: Path) -> str:",
            "def discover_candidates(toolchains_root: Path, patterns: tuple[str, ...]) -> list[Path]:",
            "def describe_zig_candidate(minimum_zig: str, zig_bin: Path) -> dict[str, object]:",
            "def describe_rust_candidate(cargo_bin: Path) -> dict[str, object]:",
            "def choose_preferred_zig(candidates: list[dict[str, object]]) -> dict[str, object] | None:",
            "def choose_preferred_rust(candidates: list[dict[str, object]]) -> dict[str, object] | None:",
            "def build_readiness_command(",
            "def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:",
            '"path_export"',
            '"cargo_export"',
            '"rustc_export"',
            '"matches expected 1.79.0"',
            '"mismatched: expected 1.79.0"',
            '"cargo matches expected 1.79.0 but rustc is unavailable"',
            '"matches expected 0.15.x line"',
            '"older than minimum"',
            '"mismatched: expected 0.15.x line"',
            '"no staged Rust toolchain under"',
            '"no staged Zig toolchain under"',
            '"Issue #11 staged build-toolchain pair"',
            '"Staged Rust candidates:"',
            '"Staged Zig candidates:"',
            '"Preferred staged pair:"',
            '"Exact readiness rerun:"',
            '"No full staged Rust/Zig pair is ready."',
        ):
            self.assertIn(fragment, self.staged_pair_helper)

    def test_readiness_helper_and_build_manifest_keep_pair_rerun_inputs_visible(
        self,
    ) -> None:
        for fragment in (
            '"--zig"',
            '"--cargo"',
            '"--rustc"',
            '"toolchains_root"',
            '"zig_candidates"',
            '"suggested_next_step"',
        ):
            self.assertIn(fragment, self.build_readiness_helper)

        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()
