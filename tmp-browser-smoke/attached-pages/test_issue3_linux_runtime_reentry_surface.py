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

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
# Issue #3 Enter-Submit Runtime Revalidation

Target `Page.zig` slice
Target `win32_backend.zig` slice
Focused regression coverage
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
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh": r"""
docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|
docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|
docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|
scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|
scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|
scripts/linux/show_issue3_linux_build_readiness_route.sh|file|
scripts/check_issue3_saved_memory_inputs.py|file|
scripts/check_linux_build_readiness.py|file|
tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|
docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|
docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|
docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_saved_memory_inputs.py|
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": r"""
docs/ISSUE3_RUNTIME_REENTRY_GATES.md
docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
CONTRACT_CHECK_COMMAND="python
CONTRACT_SELF_TEST_COMMAND="python
SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py
LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh
LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py
LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py
FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"
FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
WINDOWS_BUILD_COMMAND="zig build -Dtarget=x86_64-windows-msvc --summary all"
REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
google_home_title_probe.html?google-home-probe=1
Do not treat fallback Zig 0.17 dev failures in untouched branch files as issue #3 patch evidence.
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
)
OPTIONAL_MEMORY_FILES = (
    ("repo_archives/browser/session_entry_register.yaml", "session entry register"),
)
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
parser.add_argument("--fallback-zig-archive")
parser.add_argument("--json")
parser.add_argument("--self-test")
Saved Memory input check passed.
""",
    "scripts/check_linux_build_readiness.py": """
SAVED_ARCHIVE_GLOBS = {
    "rust_toolchain": "01-rust-*.tar.xz",
    "html5ever": "02-litefetch-html5ever-*.zip",
    "boringssl": "03-boringssl-zig-main.zip",
    "browser_deps": "04-zig-browser-depo.tar.zip",
}
REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)
parser.add_argument("--skip-zig-check")
parser.add_argument("--expect-saved-archives")
parser.add_argument("--saved-archives-root")
parser.add_argument("--expect-offline-deps")
parser.add_argument("--require-prebuilt-v8")
saved-archive restore command above, use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain.
""",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
PAGE_REQUIRED_MARKERS = ("_defer_native_text_input_enter_submit: bool = false",)
WIN32_REQUIRED_MARKERS = ("pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",)
PAGE_TEST_MARKERS = ('test "Page reduced Google fixture defers native Enter submit until keypress" {',)
WIN32_TEST_MARKERS = ('test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',)
run_self_test
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-linux-runtime-reentry-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LinuxRuntimeReentrySurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.runtime_note = read_text(cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")
        cls.linux_note = read_text(cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
        cls.linux_surface = read_text(
            cls.repo_root / "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
        )
        cls.linux_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        )
        cls.saved_memory_helper = read_text(cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py")
        cls.readiness_helper = read_text(cls.repo_root / "scripts/check_linux_build_readiness.py")
        cls.contract_checker = read_text(
            cls.repo_root / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )

    def test_runtime_docs_keep_linux_reentry_route_and_toolchain_guidance_visible(self) -> None:
        combined = self.runtime_gates + "\n" + self.runtime_note + "\n" + self.linux_note
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "check_issue3_enter_submit_runtime_contract.py",
            "Target `Page.zig` slice",
            "Target `win32_backend.zig` slice",
            "Focused regression coverage",
            "saved Rust `1.79.0` toolchain",
            "Prefer a Zig `0.15.2` toolchain",
        ):
            self.assertIn(fragment, combined)

    def test_linux_surface_checker_keeps_runtime_route_saved_memory_and_build_readiness_contracts(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|",
            "scripts/check_issue3_saved_memory_inputs.py|file|",
            "scripts/check_linux_build_readiness.py|file|",
            "check_issue3_enter_submit_runtime_contract.py|file|",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_saved_memory_inputs.py|",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|",
        ):
            self.assertIn(fragment, self.linux_surface)

    def test_linux_runtime_helper_keeps_surface_contract_preflights_and_followup_commands(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            'SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh',
            'CONTRACT_CHECK_COMMAND="python',
            'CONTRACT_SELF_TEST_COMMAND="python',
            'SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py',
            'LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh',
            'LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh',
            'LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py',
            'LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py',
            'FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"',
            'FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"',
            'WINDOWS_BUILD_COMMAND="zig build -Dtarget=x86_64-windows-msvc --summary all"',
            "google_home_title_probe.html?google-home-probe=1",
            "Do not treat fallback Zig 0.17 dev failures in untouched branch files as issue #3 patch evidence.",
        ):
            self.assertIn(fragment, self.linux_helper)

    def test_saved_memory_helper_keeps_expected_archive_contract_and_cli_switches(self) -> None:
        for fragment in (
            "01-browser-fork-headed-mode-foundation.zip",
            "README.md",
            "blocker_intelligence.yaml",
            "session_entry_register.yaml",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--fallback-zig-archive",
            "--json",
            "--self-test",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_linux_readiness_and_runtime_contract_helpers_keep_issue3_reentry_markers_visible(self) -> None:
        for fragment in (
            '"rust_toolchain": "01-rust-*.tar.xz"',
            '"html5ever": "02-litefetch-html5ever-*.zip"',
            '"boringssl": "03-boringssl-zig-main.zip"',
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            'REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")',
            'OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)',
            "--skip-zig-check",
            "--expect-saved-archives",
            "--saved-archives-root",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "saved-archive restore command above, use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain.",
            "_defer_native_text_input_enter_submit: bool = false",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            "run_self_test",
        ):
            haystack = self.readiness_helper + "\n" + self.contract_checker
            self.assertIn(fragment, haystack)


if __name__ == "__main__":
    unittest.main()
