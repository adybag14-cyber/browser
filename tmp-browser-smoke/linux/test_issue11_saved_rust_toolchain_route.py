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
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    - `scripts/linux/restore_saved_rust_toolchain.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `../toolchains/rust-1.79.0`
    - `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .`
    - `python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .`
    - `bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `PATH`, `CARGO`, and `RUSTC`
    - `check_linux_build_readiness.py`
    - `../toolchains/rust-1.79.0`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": """
    # Issue #3 Progress Tracker Route

    - issue `#11`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `Goal:`
    - `Achieved:`
    """,
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh": """
    Usage:
      bash scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh \
        [--repo-root /path/to/browser-repo] \
        [--json]
    docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    scripts/linux/show_issue3_saved_rust_toolchain_route.sh
    scripts/check_issue3_saved_rust_archive_candidates.py
    scripts/check_issue3_staged_rust_toolchain_candidates.py
    scripts/linux/restore_saved_rust_toolchain.sh
    scripts/check_linux_build_readiness.py
    bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
    check_issue3_saved_rust_archive_candidates.py
    check_issue3_staged_rust_toolchain_candidates.py
    restore_saved_rust_toolchain.sh
    scripts/check_linux_build_readiness.py
    check_issue3_saved_rust_toolchain_route_surface.sh
    show_issue3_saved_rust_toolchain_route.sh
    Saved archive candidate discovery:
    Staged toolchain candidate discovery:
    --check-only
    Suggested shell setup:
    """,
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh \
        [--browser-root /path/to/browser-repo] \
        [--dependencies-root /path/to/memory/repo_archives/browser/dependencies] \
        [--toolchain-root /path/to/toolchains/rust-1.79.0] \
        [--toolchain-parent /path/to/toolchains] \
        [--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz] \
        [--json]
    DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"
    DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"
    DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"
    SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh") --repo-root $(format_shell_arg "${BROWSER_ROOT}")"
    SAVED_ARCHIVE_CANDIDATES_COMMAND="python $(format_shell_arg "${BROWSER_ROOT}/scripts/check_issue3_saved_rust_archive_candidates.py") --repo-root $(format_shell_arg "${BROWSER_ROOT}") --saved-archives-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAIN_PARENT}")"
    STAGED_TOOLCHAIN_CANDIDATES_COMMAND="python $(format_shell_arg "${BROWSER_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py") --repo-root $(format_shell_arg "${BROWSER_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAIN_PARENT}")"
    CHECK_ONLY_COMMAND="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh") --browser-root $(format_shell_arg "${BROWSER_ROOT}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --check-only"
    RESTORE_COMMAND="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh") --browser-root $(format_shell_arg "${BROWSER_ROOT}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}")"
    PATH_COMMAND="export PATH=$(format_shell_arg "${TOOLCHAIN_ROOT}/cargo/bin"):$(format_shell_arg "${TOOLCHAIN_ROOT}/rustc/bin"):\$PATH"
    CARGO_COMMAND="export CARGO=$(format_shell_arg "${TOOLCHAIN_ROOT}/cargo/bin/cargo")"
    RUSTC_COMMAND="export RUSTC=$(format_shell_arg "${TOOLCHAIN_ROOT}/rustc/bin/rustc")"
    PREFLIGHT_COMMAND="python $(format_shell_arg "${BROWSER_ROOT}/scripts/check_linux_build_readiness.py") --repo-root $(format_shell_arg "${BROWSER_ROOT}") --skip-zig-check"
    "saved_archive_candidates":
    "staged_toolchain_candidates":
    "check_only":
    "restore":
    "path":
    "cargo":
    "rustc":
    "preflight":
    Saved archive candidate discovery:
    Staged toolchain candidate discovery:
    Saved Rust restore surface check:
    Restore the saved Rust 1.79.0 toolchain:
    Put the restored Rust toolchain first on PATH:
    Quick readiness preflight after restore or staged reuse:
    """,
    "scripts/check_issue3_saved_rust_archive_candidates.py": """
    DEFAULT_EXPECTED_RUST = "1.79.0"
    ARCHIVE_RE = re.compile(r"01-rust-(\\d+\\.\\d+\\.\\d+)-([^.]+(?:\\.[^.]+)*)\\.tar\\.xz$")
    def normalize_saved_archives_root(saved_archives_root):
        dependencies_root = saved_archives_root / "dependencies"
    def choose_preferred_archive(expected, archive_reports):
        if archive["status"] == "matches-expected-line" and archive["version"] == expected:
    "saved_archives_root":
    "toolchains_root":
    "expected_rust":
    "rust_archives":
    "preferred_archive":
    "restore_check":
    "restore":
    """,
    "scripts/check_issue3_staged_rust_toolchain_candidates.py": """
    EXPECTED_RUST_VERSION = "1.79.0"
    EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"
    DEFAULT_CANDIDATE_GLOBS = (
        "rust-*/cargo/bin/cargo",
        "*/cargo/bin/cargo",
    )
    def resolve_default_toolchains_root(repo_root):
        return (repo_root.parent / "toolchains").resolve()
    def discover_candidates(toolchains_root):
        return []
    def describe_candidate(cargo_bin):
        rustc_bin = cargo_bin.parent.parent.parent / "rustc" / "bin" / "rustc"
    "preferred_candidate":
    "path_export":
    "cargo_export":
    "rustc_export":
    "suggested_next_step":
    """,
    "scripts/linux/restore_saved_rust_toolchain.sh": """
    Usage:
      scripts/linux/restore_saved_rust_toolchain.sh \
        [--browser-root /path/to/browser-repo] \
        [--dependencies-root /path/to/dependencies] \
        [--toolchain-root /path/to/toolchains/rust-1.79.0] \
        [--toolchain-parent /path/to/toolchains] \
        [--offline-deps-root /path/to/offline-deps] \
        [--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz] \
        [--check-only] \
        [--json] \
        [--force]
    DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"
    DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"
    DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"
    PREBUILT_V8_GLOB="libc_v8_*.a"
    "dependencies_root":
    "archive_path":
    "toolchain_parent":
    "toolchain_root":
    "offline_deps_root":
    "prebuilt_v8_path":
    "cargo_bin":
    "rustc_bin":
    "toolchain_path":
    "check_only":
    "force_restore":
    "toolchain_exists":
    if [[ "${CHECK_ONLY}" == "true" ]]; then
    Saved Rust toolchain restore surface check passed.
    Suggested shell setup:
    export PATH=
    export CARGO=
    export RUSTC=
    tar -xJf "${ARCHIVE_PATH}" -C "${TOOLCHAIN_ROOT}" --strip-components=1
    Restored toolchain is missing cargo:
    Restored toolchain is missing rustc:
    Saved Rust toolchain is ready.
    Suggested preflight:
    Suggested build:
    """,
    "scripts/check_linux_build_readiness.py": """
    def build_parser():
        parser.add_argument("--repo-root")
        parser.add_argument("--zig")
        parser.add_argument("--cargo")
        parser.add_argument("--rustc")
        parser.add_argument("--skip-zig-check")
        parser.add_argument("--skip-rust-check")
        parser.add_argument("--expect-offline-deps")
        parser.add_argument("--expect-saved-archives")
        parser.add_argument("--saved-archives-root")
        parser.add_argument("--toolchains-root")
        parser.add_argument("--fallback-zig-archive")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-rust-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11SavedRustToolchainRouteTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.progress_route_note = read_text(
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        )
        cls.surface_helper = read_text(
            cls.repo_root / "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
        )
        cls.saved_archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_rust_archive_candidates.py"
        )
        cls.staged_toolchain_helper = read_text(
            cls.repo_root / "scripts/check_issue3_staged_rust_toolchain_candidates.py"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_rust_toolchain.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_route_note_keeps_saved_rust_restore_and_exports_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "../toolchains/rust-1.79.0",
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .",
            "python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .",
            "bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "PATH`, `CARGO`, and `RUSTC",
            "check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.route_note)

    def test_companion_notes_keep_saved_rust_route_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        for fragment in (
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates_note)

        for fragment in (
            "issue `#11`",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.progress_route_note)

    def test_surface_helper_keeps_saved_rust_route_contract_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/restore_saved_rust_toolchain.sh",
            "scripts/check_linux_build_readiness.py",
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "check_issue3_saved_rust_archive_candidates.py",
            "check_issue3_staged_rust_toolchain_candidates.py",
            "restore_saved_rust_toolchain.sh",
            "scripts/check_linux_build_readiness.py",
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "show_issue3_saved_rust_toolchain_route.sh",
            "Saved archive candidate discovery:",
            "Staged toolchain candidate discovery:",
            "--check-only",
            "Suggested shell setup:",
        ):
            self.assertIn(fragment, self.surface_helper)

    def test_route_printer_keeps_restore_and_export_steps_visible(self) -> None:
        for fragment in (
            "--dependencies-root /path/to/memory/repo_archives/browser/dependencies",
            "--toolchain-root /path/to/toolchains/rust-1.79.0",
            "--toolchain-parent /path/to/toolchains",
            "--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            'DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"',
            'DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"',
            'DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"',
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "check_issue3_saved_rust_archive_candidates.py",
            "check_issue3_staged_rust_toolchain_candidates.py",
            "restore_saved_rust_toolchain.sh",
            "check_linux_build_readiness.py",
            '"saved_archive_candidates":',
            '"staged_toolchain_candidates":',
            '"check_only":',
            '"restore":',
            '"path":',
            '"cargo":',
            '"rustc":',
            '"preflight":',
            "Saved archive candidate discovery:",
            "Staged toolchain candidate discovery:",
            "Saved Rust restore surface check:",
            "Restore the saved Rust 1.79.0 toolchain:",
            "Put the restored Rust toolchain first on PATH:",
            "Quick readiness preflight after restore or staged reuse:",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_saved_archive_and_staged_toolchain_helpers_keep_preferred_contracts_visible(self) -> None:
        for fragment in (
            'DEFAULT_EXPECTED_RUST = "1.79.0"',
            'ARCHIVE_RE = re.compile(r"01-rust-(\\d+\\.\\d+\\.\\d+)-([^.]+(?:\\.[^.]+)*)\\.tar\\.xz$")',
            'dependencies_root = saved_archives_root / "dependencies"',
            'archive["status"] == "matches-expected-line"',
            '"saved_archives_root":',
            '"toolchains_root":',
            '"expected_rust":',
            '"rust_archives":',
            '"preferred_archive":',
            '"restore_check":',
            '"restore":',
        ):
            self.assertIn(fragment, self.saved_archive_helper)

        for fragment in (
            'EXPECTED_RUST_VERSION = "1.79.0"',
            'EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"',
            '"rust-*/cargo/bin/cargo"',
            '"*/cargo/bin/cargo"',
            'return (repo_root.parent / "toolchains").resolve()',
            'rustc_bin = cargo_bin.parent.parent.parent / "rustc" / "bin" / "rustc"',
            '"preferred_candidate":',
            '"path_export":',
            '"cargo_export":',
            '"rustc_export":',
            '"suggested_next_step":',
        ):
            self.assertIn(fragment, self.staged_toolchain_helper)

    def test_restore_helper_and_readiness_helper_keep_reentry_contract_visible(self) -> None:
        for fragment in (
            "--dependencies-root /path/to/dependencies",
            "--toolchain-root /path/to/toolchains/rust-1.79.0",
            "--toolchain-parent /path/to/toolchains",
            "--offline-deps-root /path/to/offline-deps",
            "--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "--check-only",
            "--json",
            "--force",
            'DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"',
            'DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"',
            'DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"',
            'PREBUILT_V8_GLOB="libc_v8_*.a"',
            '"dependencies_root":',
            '"archive_path":',
            '"toolchain_parent":',
            '"toolchain_root":',
            '"offline_deps_root":',
            '"prebuilt_v8_path":',
            '"cargo_bin":',
            '"rustc_bin":',
            '"toolchain_path":',
            '"check_only":',
            '"force_restore":',
            '"toolchain_exists":',
            'if [[ "${CHECK_ONLY}" == "true" ]]',
            "Saved Rust toolchain restore surface check passed.",
            "Suggested shell setup:",
            "export PATH=",
            "export CARGO=",
            "export RUSTC=",
            'tar -xJf "${ARCHIVE_PATH}" -C "${TOOLCHAIN_ROOT}" --strip-components=1',
            "Restored toolchain is missing cargo:",
            "Restored toolchain is missing rustc:",
            "Saved Rust toolchain is ready.",
            "Suggested preflight:",
            "Suggested build:",
        ):
            self.assertIn(fragment, self.restore_helper)

        for fragment in (
            'parser.add_argument("--repo-root")',
            'parser.add_argument("--zig")',
            'parser.add_argument("--cargo")',
            'parser.add_argument("--rustc")',
            'parser.add_argument("--skip-zig-check")',
            'parser.add_argument("--skip-rust-check")',
            'parser.add_argument("--expect-offline-deps")',
            'parser.add_argument("--expect-saved-archives")',
            'parser.add_argument("--saved-archives-root")',
            'parser.add_argument("--toolchains-root")',
            'parser.add_argument("--fallback-zig-archive")',
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
