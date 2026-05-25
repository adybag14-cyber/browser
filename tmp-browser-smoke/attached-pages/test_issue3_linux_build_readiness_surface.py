from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "build.zig.zon": """
    .{
        .name = "browser",
        .version = "0.0.0",
        .minimum_zig_version = "0.15.2",
        .dependencies = .{
            .v8 = .{ .path = "../zig-v8-fork" },
            .@"boringssl-zig" = .{ .path = "../boringssl-zig" },
            .brotli = .{ .url = "https://example.test/brotli.tar.gz" },
        },
    }
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
    - `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
    - `scripts/check_issue3_workspace_context.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
    - `scripts/linux/show_issue3_progress_tracker_route.sh`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/show_issue3_offline_build_inputs_route.sh`
    - `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
    - `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
    - `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `python scripts/check_issue3_workspace_context.py --repo-root .`
    - `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    - `bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_progress_tracker_route.sh`
    - `bash ./scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `saved Rust 1.79.0 restore command`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    - `0.15.x`
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
    normalize_saved_archives_root() {
        if [[ -d "${raw_root}/dependencies" ]]; then
            raw_root="${raw_root}/dependencies"
        fi
    }
    WORKSPACE_CONTEXT_COMMAND="python ..."
    SNAPSHOT_ROUTE_COMMAND="bash ..."
    RESTORED_CHECKOUT_ROUTE_SURFACE_COMMAND="bash ..."
    RESTORED_CHECKOUT_ROUTE_COMMAND="bash ..."
    SAVED_MEMORY_ROUTE_SURFACE_COMMAND="bash ..."
    SAVED_MEMORY_ROUTE_COMMAND="bash ..."
    PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND="bash ..."
    PROGRESS_TRACKER_ROUTE_COMMAND="bash ..."
    SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND="bash ..."
    SAVED_ARCHIVE_ROUTE_COMMAND="bash ..."
    SAVED_ARCHIVE_INTEGRITY_COMMAND="python ..."
    TOOLCHAIN_ROUTE_COMMAND="bash ..."
    TOOLCHAIN_MATCH_COMMAND="bash ..."
    ZIG_ARCHIVE_RESTORE_CHECK_COMMAND="bash ..."
    SAVED_RUST_SURFACE_COMMAND="bash ..."
    SAVED_RUST_ROUTE_COMMAND="bash ..."
    OFFLINE_ROUTE_COMMAND="bash ..."
    PREFLIGHT_COMMAND="python ..."
    PREPARE_COMMAND="bash ..."
    RUST_RESTORE_CHECK_COMMAND="bash ..."
    RUST_RESTORE_COMMAND="bash ..."
    FULL_READINESS_COMMAND="python ..."
    HTML5EVER_ARCHIVE_ARGUMENT=""
    if [[ -f "${HTML5EVER_ARCHIVE}" ]]; then
        HTML5EVER_ARCHIVE_ARGUMENT=" --html5ever-archive ..."
    fi
    "Workspace-context helper when the checkout sits deeper than the default sibling layout:"
    "Saved-browser-snapshot route when no reusable checkout exists yet:"
    "Restored-checkout route surface check:"
    "Restored-checkout re-entry route:"
    "Saved Memory route surface check:"
    "Saved Memory route:"
    "Progress-tracker route surface check:"
    "Progress-tracker route:"
    "Saved archive integrity route surface check:"
    "Saved archive integrity route:"
    "Saved archive integrity preflight:"
    "Zig toolchain recovery route:"
    "Zig matching-line gate:"
    "Saved Rust route surface check:"
    "Saved Rust toolchain route:"
    "Offline build-inputs route:"
    "Full Linux/WSL readiness check after offline staging:"
    "Fallback Zig archive:"
    "issue #11 should stay visible as the current status lane"
    "A caller-provided Rust toolchain dir now also defines the derived toolchains root"
    "Keep a caller-provided offline-deps root aligned across the offline build-inputs route"
    "The saved html5ever bundle is optional on this route"
    "The saved-archives-root override accepts either repo_archives/browser or repo_archives/browser/dependencies"
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
        "zig*/zig",
        "zig*/bin/zig",
        "*/zig",
        "*/bin/zig",
        "zig",
    )
    SAVED_ARCHIVE_GLOBS: dict[str, str] = {
        "rust_toolchain": "01-rust-*.tar.xz",
        "html5ever": "02-litefetch-html5ever-*.zip",
        "boringssl": "03-boringssl-zig-main.zip",
        "browser_deps": "04-zig-browser-depo.tar.zip",
    }
    REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
    OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)
    def resolve_default_toolchains_root(repo_root):
        return repo_root.parent / "toolchains"
    def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):
        return fallback_zig_archive
    def discover_toolchain_zig_candidates(toolchains_root):
        return []
    def normalize_saved_archives_root(saved_archives_root):
        return saved_archives_root
    def build_prepare_offline_command(repo_root, saved_archives):
        command.extend(("--html5ever-archive", str(html5ever_archive)))
    "saved Rust toolchain archive"
    "saved browser dependency archive"
    "saved html5ever dependency archive"
    "discovered a staged Zig candidate at "
    "fallback Zig archive "
    "does not match the branch's expected"
    "run the saved-archive restore command above"
    "stage sibling dependencies plus ../offline-deps"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-linux-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LinuxBuildReadinessSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")
        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_route_note_keeps_restore_and_tracker_surfaces_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "python scripts/check_issue3_workspace_context.py --repo-root .",
            "bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "bash ./scripts/linux/show_issue3_progress_tracker_route.sh",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_note_keeps_archive_toolchain_and_offline_handoffs_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "bash ./scripts/linux/check_issue3_zig_toolchain_match.sh",
            "saved Rust 1.79.0 restore command",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "0.15.x",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_helper_keeps_ordered_reentry_commands_and_overrides_visible(self) -> None:
        for fragment in (
            "normalize_saved_archives_root()",
            'raw_root="${raw_root}/dependencies"',
            "WORKSPACE_CONTEXT_COMMAND",
            "SNAPSHOT_ROUTE_COMMAND",
            "RESTORED_CHECKOUT_ROUTE_SURFACE_COMMAND",
            "RESTORED_CHECKOUT_ROUTE_COMMAND",
            "SAVED_MEMORY_ROUTE_SURFACE_COMMAND",
            "SAVED_MEMORY_ROUTE_COMMAND",
            "PROGRESS_TRACKER_ROUTE_SURFACE_COMMAND",
            "PROGRESS_TRACKER_ROUTE_COMMAND",
            "SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND",
            "SAVED_ARCHIVE_ROUTE_COMMAND",
            "SAVED_ARCHIVE_INTEGRITY_COMMAND",
            "TOOLCHAIN_ROUTE_COMMAND",
            "TOOLCHAIN_MATCH_COMMAND",
            "ZIG_ARCHIVE_RESTORE_CHECK_COMMAND",
            "SAVED_RUST_SURFACE_COMMAND",
            "SAVED_RUST_ROUTE_COMMAND",
            "OFFLINE_ROUTE_COMMAND",
            "PREFLIGHT_COMMAND",
            "PREPARE_COMMAND",
            "RUST_RESTORE_CHECK_COMMAND",
            "RUST_RESTORE_COMMAND",
            "FULL_READINESS_COMMAND",
            "HTML5EVER_ARCHIVE_ARGUMENT",
            '--html5ever-archive',
            "Workspace-context helper when the checkout sits deeper than the default sibling layout:",
            "Saved-browser-snapshot route when no reusable checkout exists yet:",
            "Restored-checkout route surface check:",
            "Restored-checkout re-entry route:",
            "Saved Memory route surface check:",
            "Saved Memory route:",
            "Progress-tracker route surface check:",
            "Progress-tracker route:",
            "Saved archive integrity route surface check:",
            "Saved archive integrity route:",
            "Saved archive integrity preflight:",
            "Zig toolchain recovery route:",
            "Zig matching-line gate:",
            "Saved Rust route surface check:",
            "Saved Rust toolchain route:",
            "Offline build-inputs route:",
            "Full Linux/WSL readiness check after offline staging:",
            "Fallback Zig archive:",
            "issue #11 should stay visible as the current status lane",
            "A caller-provided Rust toolchain dir now also defines the derived toolchains root",
            "Keep a caller-provided offline-deps root aligned across the offline build-inputs route",
            "The saved html5ever bundle is optional on this route",
            "The saved-archives-root override accepts either repo_archives/browser or repo_archives/browser/dependencies",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_readiness_helper_keeps_saved_archive_and_toolchain_discovery_surface(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "DEFAULT_ZIG_TOOLCHAIN_GLOBS = (",
            '"zig*/zig"',
            '"zig*/bin/zig"',
            '"*/zig"',
            '"*/bin/zig"',
            '"zig"',
            '"rust_toolchain": "01-rust-*.tar.xz"',
            '"html5ever": "02-litefetch-html5ever-*.zip"',
            '"boringssl": "03-boringssl-zig-main.zip"',
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            'REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")',
            'OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)',
            "def resolve_default_toolchains_root(repo_root):",
            "def resolve_fallback_zig_archive(repo_root, fallback_zig_archive):",
            "def discover_toolchain_zig_candidates(toolchains_root):",
            "def normalize_saved_archives_root(saved_archives_root):",
            "def build_prepare_offline_command(repo_root, saved_archives):",
            '--html5ever-archive',
            "saved Rust toolchain archive",
            "saved browser dependency archive",
            "saved html5ever dependency archive",
            "discovered a staged Zig candidate at ",
            "fallback Zig archive ",
            "does not match the branch's expected",
            "run the saved-archive restore command above",
            "stage sibling dependencies plus ../offline-deps",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_manifest_still_pins_expected_branch_line_and_path_dependencies(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            ".v8 = .{",
            '.path = "../zig-v8-fork"',
            '.@"boringssl-zig" = .{',
            '.path = "../boringssl-zig"',
            ".brotli = .{",
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
