#!/usr/bin/env python3

from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "docs/ISSUE3_STAGED_TOOLCHAIN_PAIR_ROUTE.md": """
    # Issue #11 Staged Toolchain Pair Check

    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/check_issue3_staged_zig_toolchain_candidates.py`
    - `scripts/check_issue3_staged_toolchain_pair.py`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

    python ./scripts/check_issue3_staged_toolchain_pair.py --repo-root .

    1. whether both staged-toolchain gates are green at the same time
    2. the embedded Rust helper result
    3. the embedded Zig helper result
    4. the combined shell exports to reuse when both candidates are ready
    5. the next recovery step when one side is still missing

    Run this helper after the saved Rust and Zig recovery routes have surfaced their
    candidate lists, and before treating `scripts/check_linux_build_readiness.py` as
    the next honest Linux or WSL rerun.
    """,
    "scripts/check_issue3_staged_toolchain_pair.py": """
    def build_combined_exports(rust_report: dict[str, object], zig_report: dict[str, object]) -> list[str]:
        rust_candidate = rust_report.get("preferred_candidate") or {}
        zig_candidate = zig_report.get("preferred_candidate") or {}
        rust_path = rust_candidate.get("path_export")
        rust_cargo = rust_candidate.get("cargo_export")
        rust_rustc = rust_candidate.get("rustc_export")
        zig_path = zig_candidate.get("path_export")
        zig_export = zig_candidate.get("zig_export")

    rust_helper = scripts_root / "check_issue3_staged_rust_toolchain_candidates.py"
    zig_helper = scripts_root / "check_issue3_staged_zig_toolchain_candidates.py"
    rust_report = run_json_helper(rust_helper, repo_root=repo_root, toolchains_root=toolchains_root)
    zig_report = run_json_helper(zig_helper, repo_root=repo_root, toolchains_root=toolchains_root)
    result = summarize_pairing(
        repo_root=repo_root,
        toolchains_root=toolchains_root,
        rust_report=rust_report,
        zig_report=zig_report,
    )
    "Use the surfaced exports and rerun scripts/check_linux_build_readiness.py with the same repo and toolchains roots."
    "No staged Rust 1.79.x candidate is ready yet."
    "No staged Zig candidate matches the branch minimum line yet."
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-staged-toolchain-pair-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3StagedToolchainPairRouteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = build_fixture_repo()

        cls.route_note = (
            cls.repo_root / "docs/ISSUE3_STAGED_TOOLCHAIN_PAIR_ROUTE.md"
        ).read_text(encoding="utf-8")
        cls.route_helper = (
            cls.repo_root / "scripts/check_issue3_staged_toolchain_pair.py"
        ).read_text(encoding="utf-8")

    def test_route_note_keeps_pair_helper_handoff_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            "scripts/check_issue3_staged_toolchain_pair.py",
            "scripts/check_linux_build_readiness.py",
            "python ./scripts/check_issue3_staged_toolchain_pair.py --repo-root .",
            "whether both staged-toolchain gates are green at the same time",
            "combined shell exports to reuse when both candidates are ready",
            "next honest Linux or WSL rerun",
        ):
            self.assertIn(fragment, self.route_note)

    def test_pair_helper_keeps_embedded_rust_and_zig_contract_visible(self) -> None:
        for fragment in (
            'rust_helper = scripts_root / "check_issue3_staged_rust_toolchain_candidates.py"',
            'zig_helper = scripts_root / "check_issue3_staged_zig_toolchain_candidates.py"',
            "def build_combined_exports(",
            'rust_path = rust_candidate.get("path_export")',
            'zig_export = zig_candidate.get("zig_export")',
            "rust_report = run_json_helper(",
            "zig_report = run_json_helper(",
            "result = summarize_pairing(",
            "Use the surfaced exports and rerun scripts/check_linux_build_readiness.py with the same repo and toolchains roots.",
            "No staged Rust 1.79.x candidate is ready yet.",
            "No staged Zig candidate matches the branch minimum line yet.",
        ):
            self.assertIn(fragment, self.route_helper)


if __name__ == "__main__":
    unittest.main()
