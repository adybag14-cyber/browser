from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_rust_toolchain_plan.py": """
    DEFAULT_EXPECTED_RUST = \"1.79.0\"
    DEFAULT_FALLBACK_ZIG_ARCHIVE = \"zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz\"
    def resolve_default_saved_archives_root(repo_root):
        return (repo_root.parent / \"memory\" / \"repo_archives\" / \"browser\").resolve()
    def resolve_default_toolchains_root(repo_root):
        return (repo_root.parent / \"toolchains\").resolve()
    def resolve_default_offline_deps_root(repo_root):
        return (repo_root.parent / \"offline-deps\").resolve()
    def resolve_default_fallback_zig_archive(repo_root):
        return candidate if candidate.is_file() else None
    def load_staged_candidate_report(repo_root, toolchains_root):
        helper = repo_root / \"scripts\" / \"check_issue3_staged_rust_toolchain_candidates.py\"
    def load_saved_archive_report(repo_root, saved_archives_root, toolchains_root):
        helper = repo_root / \"scripts\" / \"check_issue3_saved_rust_archive_candidates.py\"
    preferred_action = \"blocked\"
    preferred_action = \"use-staged\"
    preferred_action = \"restore-saved-archive\"
    reason = \"no staged or saved Rust 1.79.x toolchain path is ready\"
    \"check_issue3_zig_toolchain_plan.py\"
    \"show_issue3_saved_rust_toolchain_route.sh\"
    \"PATH\"
    \"CARGO\"
    \"RUSTC\"
    """,
    "scripts/check_issue3_linux_reentry_gate_status.py": """
    SAVED_ARCHIVE_PATTERNS = {
        \"repo_snapshot\": \"01-browser-fork-headed-mode-foundation.zip\",
        \"rust_toolchain\": \"dependencies/01-rust-*.tar.xz\",
        \"boringssl\": \"dependencies/03-boringssl-zig-main.zip\",
        \"browser_deps\": \"dependencies/04-zig-browser-depo.tar.zip\",
    }
    DEFAULT_FALLBACK_ZIG = \"zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz\"
    def resolve_workspace_root(repo_root):
        markers = (\"memory\", \"agent_files\", \"toolchains\", \"offline-deps\")
    \"saved-rust\"
    \"zig-recovery\"
    \"offline-inputs\"
    \"build-readiness\"
    \"show_issue3_saved_rust_toolchain_route.sh\"
    \"show_issue3_zig_toolchain_recovery_route.sh\"
    \"show_issue3_offline_build_inputs_route.sh\"
    \"check_linux_build_readiness.py\"
    """,
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md": """
    # Issue #3 Saved Rust Toolchain Restore Route
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/restore_saved_rust_toolchain.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `1.79.0`
    - `../toolchains/rust-1.79.0`
    - `PATH`, `CARGO`, and `RUSTC`
    """,
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh \\
        [--browser-root /path/to/browser-repo] \\
        [--dependencies-root /path/to/memory/repo_archives/browser/dependencies] \\
        [--toolchain-root /path/to/toolchains/rust-1.79.0] \\
        [--toolchain-parent /path/to/toolchains] \\
        [--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz] \\
        [--json]
    DEFAULT_TOOLCHAIN_DIR_NAME=\"rust-1.79.0\"
    DEFAULT_ARCHIVE_NAME=\"01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz\"
    SAVED_ARCHIVE_CANDIDATES_COMMAND=
    STAGED_TOOLCHAIN_CANDIDATES_COMMAND=
    CHECK_ONLY_COMMAND=
    RESTORE_COMMAND=
    PATH_COMMAND=
    CARGO_COMMAND=
    RUSTC_COMMAND=
    PREFLIGHT_COMMAND=
    \"saved_archive_candidates\"
    \"staged_toolchain_candidates\"
    \"check_only\"
    \"restore\"
    \"path\"
    \"cargo\"
    \"rustc\"
    \"preflight\"
    \"The default restore location now matches the broader Linux build-readiness route: ../toolchains/rust-1.79.0.\"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-rust-plan-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RustToolchainPlanSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.rust_plan_helper = read_text(
            cls.repo_root / "scripts/check_issue3_rust_toolchain_plan.py"
        )
        cls.gate_status_helper = read_text(
            cls.repo_root / "scripts/check_issue3_linux_reentry_gate_status.py"
        )
        cls.saved_rust_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
        )
        cls.saved_rust_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        )

    def test_rust_plan_helper_keeps_staged_saved_and_zig_handoffs_visible(self) -> None:
        for fragment in (
            'DEFAULT_EXPECTED_RUST = "1.79.0"',
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'repo_root.parent / "memory" / "repo_archives" / "browser"',
            'repo_root.parent / "toolchains"',
            'repo_root.parent / "offline-deps"',
            'check_issue3_staged_rust_toolchain_candidates.py',
            'check_issue3_saved_rust_archive_candidates.py',
            'preferred_action = "use-staged"',
            'preferred_action = "restore-saved-archive"',
            'preferred_action = "blocked"',
            'no staged or saved Rust 1.79.x toolchain path is ready',
            'check_issue3_zig_toolchain_plan.py',
            'show_issue3_saved_rust_toolchain_route.sh',
            '"PATH"',
            '"CARGO"',
            '"RUSTC"',
        ):
            self.assertIn(fragment, self.rust_plan_helper)

    def test_gate_status_helper_keeps_saved_rust_gate_before_zig_and_offline(self) -> None:
        for fragment in (
            '"repo_snapshot": "01-browser-fork-headed-mode-foundation.zip"',
            '"rust_toolchain": "dependencies/01-rust-*.tar.xz"',
            '"boringssl": "dependencies/03-boringssl-zig-main.zip"',
            '"browser_deps": "dependencies/04-zig-browser-depo.tar.zip"',
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'markers = ("memory", "agent_files", "toolchains", "offline-deps")',
            '"saved-rust"',
            '"zig-recovery"',
            '"offline-inputs"',
            '"build-readiness"',
            'show_issue3_saved_rust_toolchain_route.sh',
            'show_issue3_zig_toolchain_recovery_route.sh',
            'show_issue3_offline_build_inputs_route.sh',
            'check_linux_build_readiness.py',
        ):
            self.assertIn(fragment, self.gate_status_helper)

    def test_saved_rust_note_keeps_route_and_exports_visible(self) -> None:
        for fragment in (
            'scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh',
            'scripts/linux/show_issue3_saved_rust_toolchain_route.sh',
            'scripts/check_issue3_saved_rust_archive_candidates.py',
            'scripts/check_issue3_staged_rust_toolchain_candidates.py',
            'scripts/linux/restore_saved_rust_toolchain.sh',
            'scripts/check_linux_build_readiness.py',
            'docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md',
            '1.79.0',
            '../toolchains/rust-1.79.0',
            'PATH`, `CARGO`, and `RUSTC`',
        ):
            self.assertIn(fragment, self.saved_rust_note)

    def test_saved_rust_route_keeps_candidate_restore_and_export_commands(self) -> None:
        for fragment in (
            'bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh',
            '--dependencies-root /path/to/memory/repo_archives/browser/dependencies',
            '--toolchain-root /path/to/toolchains/rust-1.79.0',
            '--toolchain-parent /path/to/toolchains',
            '--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz',
            '--json',
            'DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"',
            'DEFAULT_ARCHIVE_NAME="01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"',
            'SAVED_ARCHIVE_CANDIDATES_COMMAND=',
            'STAGED_TOOLCHAIN_CANDIDATES_COMMAND=',
            'CHECK_ONLY_COMMAND=',
            'RESTORE_COMMAND=',
            'PATH_COMMAND=',
            'CARGO_COMMAND=',
            'RUSTC_COMMAND=',
            'PREFLIGHT_COMMAND=',
            '"saved_archive_candidates"',
            '"staged_toolchain_candidates"',
            '"check_only"',
            '"restore"',
            '"path"',
            '"cargo"',
            '"rustc"',
            '"preflight"',
            '../toolchains/rust-1.79.0',
        ):
            self.assertIn(fragment, self.saved_rust_route)


if __name__ == "__main__":
    unittest.main()
