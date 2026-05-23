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
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
    - `show_issue3_offline_build_inputs_route.sh`
    - `show_issue3_saved_rust_toolchain_route.sh`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    """,
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md": """
    # Issue #3 Offline Build Inputs Route

    - `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_offline_build_inputs_route.sh`
    - `scripts/linux/prepare_offline_build_inputs.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    """,
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh": r"""
    REFERENCE_PATHS=(
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Read-first offline build-inputs note."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion."
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note."
        "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|file|Surface checker."
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Route printer."
        "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper."
        "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory preflight."
        "scripts/check_linux_build_readiness.py|file|Readiness helper."
    )
    CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|scripts/linux/show_issue3_offline_build_inputs_route.sh|Route note points at helper."
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|prepare_offline_build_inputs.sh|Route note points at raw restore helper."
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|Route note points at saved-Memory preflight."
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|scripts/check_linux_build_readiness.py|Route note points at post-stage readiness helper."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|Linux note points at offline-inputs route."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_offline_build_inputs_route.sh|Linux note names route printer."
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|prepare_offline_build_inputs.sh|Route printer points at raw restore helper."
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|--saved-archives-root|Route printer supports saved-archives override."
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|Saved Memory input preflight:|Route printer prints saved-Memory preflight."
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|Restore offline inputs from the saved archives:|Route printer prints restore command."
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|Post-stage readiness check:|Route printer prints post-stage readiness."
    )
    """,
    "scripts/linux/show_issue3_offline_build_inputs_route.sh": r"""
    SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_offline_build_inputs_route_surface.sh --repo-root ${REPO_ROOT}"
    SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT} --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
    PREPARE_CHECK_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root ${REPO_ROOT} --browser-deps-archive ${BROWSER_DEPS_ARCHIVE} --boringssl-archive ${BORINGSSL_ARCHIVE} --html5ever-archive ${HTML5EVER_ARCHIVE} --check-only"
    PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root ${REPO_ROOT} --browser-deps-archive ${BROWSER_DEPS_ARCHIVE} --boringssl-archive ${BORINGSSL_ARCHIVE} --html5ever-archive ${HTML5EVER_ARCHIVE}"
    SAVED_RUST_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh --browser-root ${REPO_ROOT}"
    ZIG_ROUTE_COMMAND="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root ${REPO_ROOT} --saved-archives-root ${SAVED_ARCHIVES_ROOT} --offline-deps-root ${OFFLINE_DEPS_ROOT}"
    POST_STAGE_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT} --expect-offline-deps --offline-deps-root ${OFFLINE_DEPS_ROOT}"
    Saved Memory input preflight:
    Restore offline inputs from the saved archives:
    Post-stage readiness check:
    """,
    "scripts/linux/prepare_offline_build_inputs.sh": r"""
    Usage:
      scripts/linux/prepare_offline_build_inputs.sh \
        --browser-deps-archive /path/to/zig-browser-depo.tar.zip \
        --boringssl-archive /path/to/boringssl-zig-main.zip \
        [--html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip] \
        [--browser-root /path/to/browser-repo] \
        [--check-only]
    This helper restores:
      ../zig-v8-fork
      ../boringssl-zig
      ../offline-deps/{brotli,zlib,nghttp2,curl}
    Use --check-only to validate the supplied paths and print the derived restore layout without mutating the repo.
    Browser dependency archive is missing one or more expected offline inputs.
    Offline dependency surface check passed.
    Archive contents:
    prebuilt V8 archive
    html5ever archive
    Restoring zig-v8-fork
    Restoring BoringSSL Zig sources
    Restoring brotli
    Restoring zlib
    Restoring nghttp2
    Restoring curl
    rewrote build.zig.zon to local offline dependency paths
    Offline dependency layout is ready.
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_MEMORY_FILES = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
        ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    )
    DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    def build_parser():
        parser.add_argument("--fallback-zig-archive")
    Saved Memory input check passed.
    """,
    "scripts/check_linux_build_readiness.py": """
    def build_parser():
        parser.add_argument("--skip-zig-check")
        parser.add_argument("--expect-saved-archives")
        parser.add_argument("--saved-archives-root")
        parser.add_argument("--expect-offline-deps")
        parser.add_argument("--offline-deps-root")
    OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
    PREBUILT_V8_GLOB = "libc_v8_*.a"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-offline-inputs-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3OfflineBuildInputsRouteSurfaceTest(unittest.TestCase):
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
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_offline_build_inputs_route.sh"
        )
        cls.prepare_helper = read_text(
            cls.repo_root / "scripts/linux/prepare_offline_build_inputs.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_route_note_keeps_restore_preflight_and_followup_helpers_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_helper_keeps_surface_restore_and_post_stage_commands_visible(self) -> None:
        for fragment in (
            'SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_offline_build_inputs_route_surface.sh',
            'SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py',
            "--fallback-zig-archive",
            'PREPARE_CHECK_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh',
            "--browser-deps-archive",
            "--boringssl-archive",
            "--html5ever-archive",
            "--check-only",
            'PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh',
            'SAVED_RUST_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh',
            'ZIG_ROUTE_COMMAND="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh',
            "--saved-archives-root",
            "--offline-deps-root",
            'POST_STAGE_READINESS_COMMAND="python scripts/check_linux_build_readiness.py',
            "--skip-zig-check",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "Saved Memory input preflight:",
            "Restore offline inputs from the saved archives:",
            "Post-stage readiness check:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_reference_paths_and_content_expectations_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/check_issue3_offline_build_inputs_route_surface.sh|file|',
            '"scripts/linux/show_issue3_offline_build_inputs_route.sh|file|',
            '"scripts/linux/prepare_offline_build_inputs.sh|file|',
            '"scripts/check_issue3_saved_memory_inputs.py|file|',
            '"scripts/check_linux_build_readiness.py|file|',
            '"docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|scripts/linux/show_issue3_offline_build_inputs_route.sh|',
            '"docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|prepare_offline_build_inputs.sh|',
            '"docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|',
            '"docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|scripts/check_linux_build_readiness.py|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_offline_build_inputs_route.sh|',
            '"scripts/linux/show_issue3_offline_build_inputs_route.sh|prepare_offline_build_inputs.sh|',
            '"scripts/linux/show_issue3_offline_build_inputs_route.sh|--saved-archives-root|',
            '"scripts/linux/show_issue3_offline_build_inputs_route.sh|Saved Memory input preflight:|',
            '"scripts/linux/show_issue3_offline_build_inputs_route.sh|Restore offline inputs from the saved archives:|',
            '"scripts/linux/show_issue3_offline_build_inputs_route.sh|Post-stage readiness check:|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_prepare_helper_keeps_check_only_restore_and_manifest_rewrite_surface(self) -> None:
        for fragment in (
            "--browser-deps-archive",
            "--boringssl-archive",
            "--html5ever-archive",
            "--browser-root",
            "--check-only",
            "../zig-v8-fork",
            "../boringssl-zig",
            "../offline-deps/{brotli,zlib,nghttp2,curl}",
            "Browser dependency archive is missing one or more expected offline inputs.",
            "Offline dependency surface check passed.",
            "Archive contents:",
            "prebuilt V8 archive",
            "html5ever archive",
            "Restoring zig-v8-fork",
            "Restoring BoringSSL Zig sources",
            "Restoring brotli",
            "Restoring zlib",
            "Restoring nghttp2",
            "Restoring curl",
            "rewrote build.zig.zon to local offline dependency paths",
            "Offline dependency layout is ready.",
        ):
            self.assertIn(fragment, self.prepare_helper)

    def test_companion_helpers_keep_saved_memory_and_offline_dependency_contracts_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--fallback-zig-archive",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

        for fragment in (
            "--skip-zig-check",
            "--expect-saved-archives",
            "--saved-archives-root",
            "--expect-offline-deps",
            "--offline-deps-root",
            'OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")',
            'PREBUILT_V8_GLOB = "libc_v8_*.a"',
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_runtime_gates_and_build_readiness_note_still_point_back_to_the_route(self) -> None:
        for fragment in (
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "show_issue3_offline_build_inputs_route.sh",
            "show_issue3_saved_rust_toolchain_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)


if __name__ == "__main__":
    unittest.main()
