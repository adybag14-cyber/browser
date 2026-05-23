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
        .curl = .{ .url = "https://example.invalid/curl.tar.gz" },
    },
}
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- restore the saved Rust `1.79.0` toolchain
- Prefer a Zig `0.15.2` toolchain
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": r"""
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies"
PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root ${REPO_ROOT} --browser-deps-archive ${BROWSER_DEPS_ARCHIVE} --boringssl-archive ${BORINGSSL_ARCHIVE} --html5ever-archive ${HTML5EVER_ARCHIVE} --check-only"
RUST_RESTORE_COMMAND="mkdir -p ${RUST_TOOLCHAIN_DIR} && tar -xf ${RUST_ARCHIVE} -C ${RUST_TOOLCHAIN_DIR} --strip-components=1"
RUST_PATH_COMMAND="export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:$PATH"
FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --expect-saved-archives --saved-archives-root ${SAVED_ARCHIVES_ROOT}/dependencies --expect-offline-deps --require-prebuilt-v8"
Saved Memory input preflight:
Fallback Zig archive:
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux note"
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight"
    "scripts/check_linux_build_readiness.py|file|Python helper"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Route printer"
    "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper"
    "build.zig.zon|file|Manifest surface"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|Gate note keeps Linux route visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|Gate note keeps saved-Memory preflight visible."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|Linux note keeps saved-Memory preflight visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_memory_inputs.py|Route printer points at saved-Memory preflight."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory input preflight:|Route printer prints saved-Memory preflight label."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_linux_build_readiness.py|Linux note keeps readiness helper visible."
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|Route printer points back to surface checker."
    "scripts/check_linux_build_readiness.py|saved Rust toolchain archive|Readiness helper knows saved Rust archive contract."
    "scripts/linux/prepare_offline_build_inputs.sh|--check-only|Offline prep helper supports surface-only validation."
)
""",
    "scripts/check_linux_build_readiness.py": """
MINIMUM_ZIG_RE = re.compile(r'\\.minimum_zig_version\\s*=\\s*"([^"]+)"')
PATH_VALUE_RE = re.compile(r'\\.path\\s*=\\s*"([^"]+)"')
URL_VALUE_RE = re.compile(r'\\.url\\s*=\\s*"([^"]+)"')
OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
PREBUILT_V8_GLOB = "libc_v8_*.a"
SAVED_ARCHIVE_GLOBS = {
    "rust_toolchain": "01-rust-*.tar.xz",
    "html5ever": "02-litefetch-html5ever-*.zip",
    "boringssl": "03-boringssl-zig-main.zip",
    "browser_deps": "04-zig-browser-depo.tar.zip",
}
SAVED_ARCHIVE_LABELS = {
    "rust_toolchain": "saved Rust toolchain archive",
    "html5ever": "saved html5ever dependency archive",
    "boringssl": "saved BoringSSL archive",
    "browser_deps": "saved browser dependency archive",
}
REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)
def build_parser():
    parser.add_argument("--skip-zig-check")
    parser.add_argument("--expect-offline-deps")
    parser.add_argument("--require-prebuilt-v8")
    parser.add_argument("--expect-saved-archives")
    parser.add_argument("--saved-archives-root")
    parser.add_argument("--self-test")
def build_prepare_offline_command(repo_root, saved_archives):
    command = [
        str(repo_root / "scripts" / "linux" / "prepare_offline_build_inputs.sh"),
        "--browser-root",
        str(repo_root),
        "--browser-deps-archive",
        str(saved_archives["browser_deps"]),
        "--boringssl-archive",
        str(saved_archives["boringssl"]),
    ]
    command.extend(("--html5ever-archive", str(saved_archives["html5ever"])))
    command.append("--check-only")
    return command

class ReadinessHelperTests(unittest.TestCase):
    def test_saved_archives_root_finds_required_archives(self): ...
    def test_saved_archives_root_reports_missing_required_archives(self): ...
    def test_prepare_command_includes_optional_html5ever_archive(self): ...
    def test_offline_dependency_root_and_prebuilt_v8_pass(self): ...

def main():
    print("run the saved-archive restore command above, use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain.")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-linux-readiness-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class LinuxBuildReadinessHelperSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_route_note_keeps_saved_memory_archive_and_toolchain_guidance(self) -> None:
        for fragment in (
            "check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "saved Rust `1.79.0` toolchain",
            "Prefer a Zig `0.15.2` toolchain",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_helper_keeps_saved_memory_surface_preflight_restore_and_full_readiness_commands(self) -> None:
        for fragment in (
            'SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh',
            'SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py',
            "Saved Memory input preflight:",
            'PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py',
            "--skip-zig-check --expect-saved-archives",
            'PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh',
            "--browser-deps-archive",
            "--boringssl-archive",
            "--html5ever-archive",
            "--check-only",
            'RUST_RESTORE_COMMAND="mkdir -p ${RUST_TOOLCHAIN_DIR}',
            'RUST_PATH_COMMAND="export PATH=${RUST_TOOLCHAIN_DIR}/cargo/bin:$PATH"',
            'FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py',
            "--expect-offline-deps --require-prebuilt-v8",
            "Fallback Zig archive:",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_route_saved_memory_and_archive_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"scripts/check_issue3_saved_memory_inputs.py|file|',
            '"scripts/check_linux_build_readiness.py|file|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|',
            '"build.zig.zon|file|Manifest surface"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|scripts/check_issue3_saved_memory_inputs.py|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|Saved Memory input preflight:|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|scripts/check_linux_build_readiness.py|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|check_issue3_linux_build_readiness_route_surface.sh|',
            '"scripts/check_linux_build_readiness.py|saved Rust toolchain archive|',
            '"scripts/linux/prepare_offline_build_inputs.sh|--check-only|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_readiness_helper_keeps_archive_layout_and_cli_switches(self) -> None:
        for fragment in (
            'SAVED_ARCHIVE_GLOBS',
            '"rust_toolchain": "01-rust-*.tar.xz"',
            '"html5ever": "02-litefetch-html5ever-*.zip"',
            '"boringssl": "03-boringssl-zig-main.zip"',
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            '"saved Rust toolchain archive"',
            '"saved browser dependency archive"',
            'REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")',
            'OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)',
            '--expect-saved-archives',
            '--saved-archives-root',
            '--expect-offline-deps',
            '--require-prebuilt-v8',
            '--skip-zig-check',
            '--self-test',
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_readiness_helper_keeps_prepare_command_and_self_test_coverage(self) -> None:
        for fragment in (
            'str(repo_root / "scripts" / "linux" / "prepare_offline_build_inputs.sh")',
            '"--browser-deps-archive"',
            '"--boringssl-archive"',
            '"--html5ever-archive"',
            '"--check-only"',
            'def test_saved_archives_root_finds_required_archives',
            'def test_saved_archives_root_reports_missing_required_archives',
            'def test_prepare_command_includes_optional_html5ever_archive',
            'def test_offline_dependency_root_and_prebuilt_v8_pass',
            'saved-archive restore command above, use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain.',
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_runtime_gates_and_manifest_still_point_at_the_linux_readiness_surface(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
            '.curl = .{ .url = "https://example.invalid/curl.tar.gz" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
