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
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
# Issue #3 Enter-Submit Runtime Revalidation

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `chrome-google-home-title-probe.ps1`
- `google_home_title_probe.html?google-home-probe=1`

## Target `Page.zig` slice

## Target `win32_backend.zig` slice

## Focused regression coverage
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- restore the saved Rust `1.79.0` toolchain
- Prefer a Zig `0.15.2` toolchain
""",
    "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md": """
# Guide

- `check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
- `show_google_issue3_enter_submit_runtime_revalidation.ps1`
""",
    "docs/HEADED_MODE_ROADMAP.md": """
# Roadmap

- `check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
- `show_google_issue3_enter_submit_runtime_revalidation.ps1`
""",
    "docs/WINDOWS_FULL_USE.md": """
# Windows Full Use

- `google-form-controls-enter-order`
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
$route = [ordered]@{
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    )
    commands = [ordered]@{
        surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        contract_check = $runtimeContractCheckCommand
        linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
        linux_build_readiness = $linuxBuildReadinessFullCommand
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
        reduced_google_fixture = "& `"$resolvedBrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1`""
    }
    expected_signals = @(
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
}
Write-Host "Shared click-first route:"
""",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file" -Purpose "Gate note"),
    (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Runtime note"),
    (New-ValidationReference -Path "src/browser/Page.zig" -Kind "file" -Purpose "Page target"),
    (New-ValidationReference -Path "src/display/win32_backend.zig" -Kind "file" -Purpose "Win32 target"),
    (New-ValidationReference -Path "scripts/check_linux_build_readiness.py" -Kind "file" -Purpose "Build helper"),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "Route helper"),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "Contract checker")
)
$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Purpose "Gate note keeps runtime note visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "Guide keeps helper visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "Roadmap keeps checker visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Shared click-first route:" -Purpose "Helper output prints click-first route.")
)
""",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime note"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux note"
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|Linux surface checker"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Linux route helper"
    "scripts/check_linux_build_readiness.py|file|Build helper"
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|Contract checker"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|Gate note keeps Linux checker visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|Gate note keeps Linux helper visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|Linux helper prints contract check."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|Linux helper keeps build surface visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|Linux helper keeps build route visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|Linux helper prints reduced Google follow-up."
)
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": r"""
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh --repo-root ${REPO_ROOT}"
CONTRACT_CHECK_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --page ${PAGE_SOURCE_PATH} --win32 ${WIN32_SOURCE_PATH}"
CONTRACT_SELF_TEST_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --self-test"
LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${REPO_ROOT}"
LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check"
LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT}"
REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_MEMORY_FILES = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    ("repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "saved Rust toolchain archive"),
    ("repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip", "saved html5ever dependency archive"),
    ("repo_archives/browser/dependencies/03-boringssl-zig-main.zip", "saved BoringSSL archive"),
    ("repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip", "saved browser dependency archive"),
)
OPTIONAL_MEMORY_FILES = (
    ("repo_archives/browser/session_entry_register.yaml", "session entry register"),
)
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
parser.add_argument("--json")
parser.add_argument("--self-test")
parser.add_argument("--fallback-zig-archive")
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
""",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
def main():
    return 0
""",
    "src/browser/Page.zig": "test {}",
    "src/display/win32_backend.zig": "test {}",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runtime-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RuntimeRevalidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[1]

        cls.runtime_gates = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.runtime_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.production_guide = read_text(
            cls.repo_root / "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"
        )
        cls.roadmap = read_text(cls.repo_root / "docs/HEADED_MODE_ROADMAP.md")
        cls.windows_full_use = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")
        cls.windows_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.windows_surface = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.linux_surface = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
        )
        cls.linux_route = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        )
        cls.memory_helper = read_text(cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py")
        cls.build_helper = read_text(cls.repo_root / "scripts/check_linux_build_readiness.py")

    def test_runtime_gates_keep_runtime_and_build_reentry_surfaces_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_runtime_note_keeps_narrow_code_and_probe_targets_visible(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
            "Target `Page.zig` slice",
            "Target `win32_backend.zig` slice",
            "Focused regression coverage",
        ):
            self.assertIn(fragment, self.runtime_note)

    def test_windows_surfaces_keep_click_first_and_build_readiness_route_visible(self) -> None:
        for fragment in (
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            "shared_enter_google_click = Format-RepoRootCommand",
            "reduced_google_probe = Format-RepoRootCommand",
            "google_home_title_probe.html?google-home-probe=1",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Shared click-first route:",
        ):
            self.assertIn(fragment, self.windows_helper)

        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"scripts/check_linux_build_readiness.py"',
            '"scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            'show_google_issue3_enter_submit_runtime_revalidation.ps1',
            'check_google_issue3_enter_submit_runtime_revalidation_surface.ps1',
            'Shared click-first route:',
        ):
            self.assertIn(fragment, self.windows_surface)

    def test_linux_surfaces_keep_contract_and_build_recovery_commands_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|",
            "scripts/check_linux_build_readiness.py|file|",
            "check_issue3_enter_submit_runtime_contract.py|file|",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "check_issue3_linux_build_readiness_route_surface.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "chrome-google-home-title-probe.ps1",
        ):
            self.assertIn(fragment, self.linux_surface + self.linux_route)

    def test_saved_memory_preflight_keeps_required_archives_and_fallback_zig_visible(self) -> None:
        for fragment in (
            "01-browser-fork-headed-mode-foundation.zip",
            "README.md",
            "blocker_intelligence.yaml",
            "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
            "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
            "03-boringssl-zig-main.zip",
            "04-zig-browser-depo.tar.zip",
            "session_entry_register.yaml",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--fallback-zig-archive",
            "--json",
            "--self-test",
        ):
            self.assertIn(fragment, self.memory_helper)

    def test_guides_keep_runtime_helper_and_google_enter_route_visible(self) -> None:
        for fragment in (
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
        ):
            self.assertIn(fragment, self.production_guide)
            self.assertIn(fragment, self.roadmap)

        self.assertIn("google-form-controls-enter-order", self.windows_full_use)
        self.assertIn('REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")', self.build_helper)
        self.assertIn('OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)', self.build_helper)


if __name__ == "__main__":
    unittest.main()
