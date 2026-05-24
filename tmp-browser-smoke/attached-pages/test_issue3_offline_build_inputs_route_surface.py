from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md": """
    # Issue #3 Offline Build Inputs Route

    - `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_offline_build_inputs_route.sh`
    - `scripts/linux/prepare_offline_build_inputs.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `bash ./scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh`
    - `--saved-archives-root /path/to/memory/repo_archives/browser/dependencies`
    - `--offline-deps-root /path/to/offline-deps`
    - `prepare_offline_build_inputs.sh --check-only`
    - `../zig-v8-fork`
    - `../boringssl-zig`
    - `../offline-deps`
    - `python scripts/check_issue3_saved_memory_inputs.py --repo-root .`
    - `python scripts/check_issue3_saved_archive_integrity.py --repo-root .`
    - Treat this route as the offline dependency staging step
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build Readiness Route

    - `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
    - `show_issue3_offline_build_inputs_route.sh`
    """,
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh": """
    Usage:
      bash scripts/linux/check_issue3_offline_build_inputs_route_surface.sh \
        [--repo-root /path/to/browser-repo] \
        [--json]
    declare -a REFERENCE_PATHS=(
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|file|Read-first offline build-inputs note"
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|file|Compact offline build-inputs route printer."
        "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper"
        "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory preflight helper"
        "scripts/check_issue3_saved_archive_integrity.py|file|Saved archive integrity helper"
        "scripts/check_linux_build_readiness.py|file|Readiness helper"
    )
    declare -a CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|scripts/linux/show_issue3_offline_build_inputs_route.sh|route helper"
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|prepare_offline_build_inputs.sh|raw restore helper"
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md|readiness note link"
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|Saved archive integrity preflight:|archive step"
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|Restore offline inputs from the saved archives:|restore step"
        "scripts/linux/show_issue3_offline_build_inputs_route.sh|Post-stage readiness check:|post-stage step"
        "scripts/linux/prepare_offline_build_inputs.sh|--offline-deps-root|offline root override"
        "scripts/linux/prepare_offline_build_inputs.sh|OFFLINE_DEPS_RELATIVE_ROOT|relative root"
    )
    """,
    "scripts/linux/show_issue3_offline_build_inputs_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_offline_build_inputs_route.sh \
        [--repo-root /path/to/browser-repo] \
        [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
        [--offline-deps-root /path/to/offline-deps] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--json]
    "saved_memory_inputs":
    "saved_archive_integrity":
    "prepare_check_only":
    "prepare_restore":
    "saved_rust_route":
    "zig_toolchain_route":
    "post_stage_readiness":
    "Run the saved_memory_inputs command before the restore commands"
    "Run the saved_archive_integrity command after the presence preflight"
    "The saved html5ever bundle is optional on this route"
    Surface check:
    Saved Memory input preflight:
    Saved archive integrity preflight:
    Restore offline inputs from the saved archives:
    Saved Rust toolchain route after staging:
    Zig toolchain recovery route after staging:
    Post-stage readiness check:
    --saved-archives-root
    --offline-deps-root
    fallback-zig-archive
    """,
    "scripts/linux/prepare_offline_build_inputs.sh": """
    Usage:
      scripts/linux/prepare_offline_build_inputs.sh \
        [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
        [--browser-deps-archive /path/to/zig-browser-depo.tar.zip] \
        [--boringssl-archive /path/to/boringssl-zig-main.zip] \
        [--html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip] \
        [--browser-root /path/to/browser-repo] \
        [--offline-deps-root /path/to/offline-deps] \
        [--check-only]
    ../zig-v8-fork
    ../boringssl-zig
    ../offline-deps/{brotli,zlib,nghttp2,curl}
    OFFLINE_DEPS_RELATIVE_ROOT
    Browser dependency archive is missing one or more expected offline inputs.
    Offline dependency surface check passed.
    Resolved restore targets:
    build.zig.zon offline root ->
    Suggested validation command:
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-offline-build-route-"))
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

        cls.route_doc = read_text(cls.repo_root / "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md")
        cls.build_readiness_doc = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.surface_script = read_text(
            cls.repo_root / "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh"
        )
        cls.route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_offline_build_inputs_route.sh"
        )
        cls.prepare_script = read_text(
            cls.repo_root / "scripts/linux/prepare_offline_build_inputs.sh"
        )

    def test_route_doc_keeps_preflight_restore_and_follow_up_surfaces_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "bash ./scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
            "bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "--offline-deps-root /path/to/offline-deps",
            "prepare_offline_build_inputs.sh --check-only",
            "../zig-v8-fork",
            "../boringssl-zig",
            "../offline-deps",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "python scripts/check_issue3_saved_archive_integrity.py --repo-root .",
            "Treat this route as the offline dependency staging step",
        ):
            self.assertIn(fragment, self.route_doc)

    def test_linux_build_readiness_doc_keeps_offline_route_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "show_issue3_offline_build_inputs_route.sh",
        ):
            self.assertIn(fragment, self.build_readiness_doc)

    def test_surface_script_keeps_reference_and_content_expectations_for_offline_route(self) -> None:
        for fragment in (
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh|Saved archive integrity preflight:",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh|Restore offline inputs from the saved archives:",
            "scripts/linux/show_issue3_offline_build_inputs_route.sh|Post-stage readiness check:",
            "scripts/linux/prepare_offline_build_inputs.sh|--offline-deps-root",
            "scripts/linux/prepare_offline_build_inputs.sh|OFFLINE_DEPS_RELATIVE_ROOT",
        ):
            self.assertIn(fragment, self.surface_script)

    def test_route_script_keeps_json_commands_and_printed_steps_visible(self) -> None:
        for fragment in (
            '"saved_memory_inputs"',
            '"saved_archive_integrity"',
            '"prepare_check_only"',
            '"prepare_restore"',
            '"saved_rust_route"',
            '"zig_toolchain_route"',
            '"post_stage_readiness"',
            "Run the saved_memory_inputs command before the restore commands",
            "Run the saved_archive_integrity command after the presence preflight",
            "The saved html5ever bundle is optional on this route",
            "Surface check:",
            "Saved Memory input preflight:",
            "Saved archive integrity preflight:",
            "Restore offline inputs from the saved archives:",
            "Saved Rust toolchain route after staging:",
            "Zig toolchain recovery route after staging:",
            "Post-stage readiness check:",
            "--saved-archives-root",
            "--offline-deps-root",
            "fallback-zig-archive",
        ):
            self.assertIn(fragment, self.route_script)

    def test_prepare_script_keeps_restore_contract_and_check_only_surface_visible(self) -> None:
        for fragment in (
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "--browser-deps-archive /path/to/zig-browser-depo.tar.zip",
            "--boringssl-archive /path/to/boringssl-zig-main.zip",
            "--html5ever-archive /path/to/litefetch-html5ever-linux-x86_64-deps.zip",
            "--browser-root /path/to/browser-repo",
            "--offline-deps-root /path/to/offline-deps",
            "--check-only",
            "../zig-v8-fork",
            "../boringssl-zig",
            "../offline-deps/{brotli,zlib,nghttp2,curl}",
            "OFFLINE_DEPS_RELATIVE_ROOT",
            "Browser dependency archive is missing one or more expected offline inputs.",
            "Offline dependency surface check passed.",
            "Resolved restore targets:",
            "build.zig.zon offline root ->",
            "Suggested validation command:",
        ):
            self.assertIn(fragment, self.prepare_script)


if __name__ == "__main__":
    unittest.main()
