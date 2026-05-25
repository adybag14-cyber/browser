from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md": """
    # Issue #11 Linux Re-entry Route Index

    - `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`

    ```bash
    bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh
    bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
    bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
    bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
    python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
    python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
    ```
    """,
    "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Saved Rust Build-Readiness Bridge Route

    This route keeps the lower-volume issue `#11` status lane, the saved Rust
    archive-selection helpers, the staged Rust candidate helper, the saved Rust
    restore route, and the broader Linux build-readiness route on one
    branch-local surface.

    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_linux_build_readiness.py`

    Before unpacking the saved archive again, check whether a reusable Rust
    `1.79.x` toolchain is already staged:

    ```bash
    python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
    ```

    Use `--json` when another helper wants the preferred staged candidate or its
    recommended shell exports as structured output.
    """,
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md": """
    # Issue #3 Saved Rust Toolchain Restore Route

    This route keeps the staged-toolchain discovery step, the saved Rust archive
    check, the restore command, and the shell handoff on one branch-local surface.

    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_linux_build_readiness.py`

    ```bash
    python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
    ```

    Use `--json` when another helper wants the preferred staged candidate, its
    status, or the exact `PATH`, `CARGO`, and `RUSTC` exports as structured output.

    - When the staged-toolchain helper reports a preferred matching candidate,
      reuse its surfaced `PATH`, `CARGO`, and `RUSTC` exports before unpacking the
      saved archive again.
    """,
    "scripts/check_issue3_staged_rust_toolchain_candidates.py": """
    EXPECTED_RUST_VERSION = \"1.79.0\"
    EXPECTED_RUST_LINE = \"1.79.x\"
    EXPECTED_TOOLCHAIN_DIR = \"rust-1.79.0\"
    DEFAULT_CANDIDATE_GLOBS = (
        \"rust-*/cargo/bin/cargo\",
        \"*/cargo/bin/cargo\",
    )

    def resolve_default_toolchains_root(repo_root):
        located = locate_first_existing(repo_root, \"toolchains\")
        return (repo_root.parent / \"toolchains\").resolve()

    def discover_candidates(toolchains_root):
        return sorted(toolchains_root.glob(\"rust-*/cargo/bin/cargo\"))

    def choose_preferred_candidate(candidates, expected_dir):
        return max(candidates)

    \"cargo_classification\"
    \"rustc_classification\"
    \"matches-expected-line\"
    \"older-than-expected\"
    \"mismatched-line\"
    \"unknown-version\"
    \"path_export\"
    \"cargo_export\"
    \"rustc_export\"
    \"preferred_candidate\"
    \"suggested_next_step\"
    \"restore a saved Rust 1.79.x toolchain under ../toolchains\"
    \"Discovered candidates:\"
    \"Preferred candidate:\"
    """,
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh": """
    STAGED_RUST_HELPER=\"${REPO_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py\"
    STAGED_RUST_HELPER_COMMAND=\"python ${STAGED_RUST_HELPER} --repo-root ${REPO_ROOT} --toolchains-root ${TOOLCHAINS_ROOT}\"
    SAVED_RUST_ROUTE_COMMAND=\"bash ${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh\"
    BUILD_READINESS_ROUTE_COMMAND=\"bash ${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh\"
    \"Staged Rust toolchain candidates:\"
    \"Run the staged Rust toolchain helper before restoring the saved archive again\"
    \"a reusable Rust 1.79.x toolchain can be reused first\"
    """,
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": """
    STAGED_TOOLCHAIN_CANDIDATES_COMMAND=\"python ${BROWSER_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root ${BROWSER_ROOT} --toolchains-root ${TOOLCHAIN_PARENT}\"
    PATH_COMMAND=\"export PATH=${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin:$PATH\"
    CARGO_COMMAND=\"export CARGO=${TOOLCHAIN_ROOT}/cargo/bin/cargo\"
    RUSTC_COMMAND=\"export RUSTC=${TOOLCHAIN_ROOT}/rustc/bin/rustc\"
    \"Staged toolchain candidate discovery:\"
    \"Use --json when another helper wants the preferred staged candidate\"
    \"If the staged helper surfaces a preferred candidate, reuse its PATH/CARGO/RUSTC exports\"
    \"Quick readiness preflight after restore or staged reuse:\"
    """,
    "scripts/check_linux_build_readiness.py": """
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / \"toolchains\"
    parser.add_argument(
        \"--toolchains-root\",
    )
    parser.add_argument(
        \"--saved-archives-root\",
    )
    parser.add_argument(
        \"--skip-zig-check\",
    )
    \"suggested_next_step\"
    \"use the saved Rust toolchain\"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-staged-rust-surface-"))
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

        cls.issue11_index = read_text(
            cls.repo_root / "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md"
        )
        cls.bridge_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"
        )
        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
        )
        cls.staged_helper = read_text(
            cls.repo_root / "scripts/check_issue3_staged_rust_toolchain_candidates.py"
        )
        cls.bridge_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh"
        )
        cls.saved_rust_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_issue11_index_keeps_staged_rust_handoff_visible(self) -> None:
        for fragment in (
            "`docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`",
            "`docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`",
            "`scripts/check_issue3_saved_rust_archive_candidates.py`",
            "`scripts/check_issue3_staged_rust_toolchain_candidates.py`",
            "bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .",
        ):
            self.assertIn(fragment, self.issue11_index)

    def test_saved_rust_notes_keep_staged_candidate_reuse_visible(self) -> None:
        for fragment in (
            "staged Rust candidate helper",
            "`scripts/check_issue3_staged_rust_toolchain_candidates.py`",
            "python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .",
            "preferred staged candidate",
            "recommended shell exports",
        ):
            self.assertIn(fragment, self.bridge_note)

        for fragment in (
            "staged-toolchain discovery step",
            "`scripts/check_issue3_staged_rust_toolchain_candidates.py`",
            "python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .",
            "exact `PATH`, `CARGO`, and `RUSTC` exports",
            "reuse its surfaced `PATH`, `CARGO`, and `RUSTC` exports",
        ):
            self.assertIn(fragment, self.route_note)

    def test_staged_helper_keeps_expected_version_and_export_contract_visible(self) -> None:
        for fragment in (
            'EXPECTED_RUST_VERSION = "1.79.0"',
            'EXPECTED_RUST_LINE = "1.79.x"',
            'EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"',
            '"rust-*/cargo/bin/cargo"',
            '"*/cargo/bin/cargo"',
            'locate_first_existing(repo_root, "toolchains")',
            '(repo_root.parent / "toolchains").resolve()',
            '"cargo_classification"',
            '"rustc_classification"',
            '"matches-expected-line"',
            '"older-than-expected"',
            '"mismatched-line"',
            '"unknown-version"',
            '"path_export"',
            '"cargo_export"',
            '"rustc_export"',
            '"preferred_candidate"',
            '"suggested_next_step"',
            "restore a saved Rust 1.79.x toolchain under ../toolchains",
            "Discovered candidates:",
            "Preferred candidate:",
        ):
            self.assertIn(fragment, self.staged_helper)

    def test_route_printers_keep_staged_helper_and_readiness_handoff_visible(self) -> None:
        for fragment in (
            'STAGED_RUST_HELPER="${REPO_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py"',
            'STAGED_RUST_HELPER_COMMAND="python ${STAGED_RUST_HELPER} --repo-root ${REPO_ROOT} --toolchains-root ${TOOLCHAINS_ROOT}"',
            '"Staged Rust toolchain candidates:"',
            "Run the staged Rust toolchain helper before restoring the saved archive again",
            "a reusable Rust 1.79.x toolchain can be reused first",
            "show_issue3_saved_rust_toolchain_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
        ):
            self.assertIn(fragment, self.bridge_route)

        for fragment in (
            'STAGED_TOOLCHAIN_CANDIDATES_COMMAND="python ${BROWSER_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root ${BROWSER_ROOT} --toolchains-root ${TOOLCHAIN_PARENT}"',
            'PATH_COMMAND="export PATH=${TOOLCHAIN_ROOT}/cargo/bin:${TOOLCHAIN_ROOT}/rustc/bin:$PATH"',
            'CARGO_COMMAND="export CARGO=${TOOLCHAIN_ROOT}/cargo/bin/cargo"',
            'RUSTC_COMMAND="export RUSTC=${TOOLCHAIN_ROOT}/rustc/bin/rustc"',
            '"Staged toolchain candidate discovery:"',
            "preferred staged candidate",
            "reuse its PATH/CARGO/RUSTC exports",
            "Quick readiness preflight after restore or staged reuse:",
        ):
            self.assertIn(fragment, self.saved_rust_route)

        staged_index = self.saved_rust_route.index("Staged toolchain candidate discovery:")
        restore_index = self.saved_rust_route.index("Quick readiness preflight after restore or staged reuse:")
        self.assertLess(staged_index, restore_index)

    def test_readiness_helper_stays_compatible_with_staged_rust_reuse(self) -> None:
        for fragment in (
            'return repo_root.parent / "toolchains"',
            '"--toolchains-root"',
            '"--saved-archives-root"',
            '"--skip-zig-check"',
            '"suggested_next_step"',
            '"use the saved Rust toolchain"',
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
