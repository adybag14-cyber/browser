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
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
Target `Page.zig` slice
Target `win32_backend.zig` slice
Focused regression coverage
chrome-google-home-title-probe.ps1
google_home_title_probe.html?google-home-probe=1
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
REFERENCE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime note"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux route note"
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|Surface checker"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Route printer"
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Build-readiness surface"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Build-readiness route"
    "scripts/check_issue3_saved_memory_inputs.py|file|Saved-memory preflight"
    "scripts/check_linux_build_readiness.py|file|Build-readiness helper"
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|Runtime contract checker"
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|Gate note keeps the Linux runtime surface checker visible."
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|Gate note keeps the Linux runtime route visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|Route printer keeps the runtime contract checker visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|Route printer keeps the build-readiness surface visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|Route printer keeps the build-readiness route visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_saved_memory_inputs.py|Route printer keeps the saved-memory preflight visible."
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|Route printer keeps the reduced Google probe visible."
)
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": r"""
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh --repo-root ${REPO_ROOT}"
CONTRACT_CHECK_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --page ${PAGE_SOURCE_PATH} --win32 ${WIN32_SOURCE_PATH}"
CONTRACT_SELF_TEST_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --self-test"
LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${REPO_ROOT}"
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"
LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check"
LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT}"
FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"
FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
WINDOWS_BUILD_COMMAND="zig build -Dtarget=x86_64-windows-msvc --summary all"
REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
REDUCED_GOOGLE_FIXTURE_COMMAND="${BROWSER_EXE} browse --headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
LIVE_GOOGLE_COMMAND="${BROWSER_EXE} browse --headed https://www.google.com/"
Run surface_check first when the branch may have moved.
Run contract_check before build or replay.
Run contract_self_test when you want to prove the checker still distinguishes vulnerable and guarded samples.
Use linux_build_readiness_skip_zig when the saved archives or sibling dependencies may still be missing.
Use linux_build_readiness only after a matching Zig line is actually staged.
Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain; the attached Zig 0.17 dev fallback can fail in untouched branch files before the focused assertions run.
After the Linux or WSL gates turn green, move back to the Windows build and reduced Google probe before widening to live Google.
""",
    "scripts/check_issue3_saved_memory_inputs.py": """
DEFAULT_FALLBACK_ZIG = \"zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz\"
def main():
    print(\"Saved Memory input check passed.\")
""",
    "scripts/check_linux_build_readiness.py": """
def main():
    print(\"use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain.\")
""",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": 'echo "surface"',
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": 'echo "route"',
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": 'print("ok")',
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-linux-runtime-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LinuxRuntimeRevalidationSurfaceTest(unittest.TestCase):
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
        cls.linux_route_note = read_text(cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")
        cls.surface_checker = read_text(
            cls.repo_root / "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        )
        cls.saved_memory_helper = read_text(cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py")
        cls.readiness_helper = read_text(cls.repo_root / "scripts/check_linux_build_readiness.py")

    def test_runtime_gates_keep_linux_runtime_reentry_surfaces_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_linux_route_note_keeps_saved_memory_and_toolchain_guidance_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "saved Rust `1.79.0` toolchain",
            "Prefer a Zig `0.15.2` toolchain",
        ):
            self.assertIn(fragment, self.linux_route_note)

    def test_surface_checker_keeps_linux_runtime_contract_in_scope(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|',
            '"scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|',
            '"scripts/check_issue3_saved_memory_inputs.py|file|',
            '"scripts/check_linux_build_readiness.py|file|',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_saved_memory_inputs.py|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_runtime_checker_saved_memory_and_build_readiness_commands_visible(self) -> None:
        for fragment in (
            'SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh',
            'CONTRACT_CHECK_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --page ${PAGE_SOURCE_PATH} --win32 ${WIN32_SOURCE_PATH}"',
            'CONTRACT_SELF_TEST_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --self-test"',
            'LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh',
            'LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh',
            'SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT}"',
            'LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check"',
            'LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT}"',
            'FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"',
            'FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"',
            'WINDOWS_BUILD_COMMAND="zig build -Dtarget=x86_64-windows-msvc --summary all"',
            'REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"',
            "google_home_title_probe.html?google-home-probe=1",
            'LIVE_GOOGLE_COMMAND="${BROWSER_EXE} browse --headed https://www.google.com/"',
            "Run surface_check first when the branch may have moved.",
            "Run contract_check before build or replay.",
            "Run contract_self_test when you want to prove the checker still distinguishes vulnerable and guarded samples.",
            "Use linux_build_readiness_skip_zig when the saved archives or sibling dependencies may still be missing.",
            "Use linux_build_readiness only after a matching Zig line is actually staged.",
            "attached Zig 0.17 dev fallback can fail in untouched branch files",
            "After the Linux or WSL gates turn green, move back to the Windows build and reduced Google probe before widening to live Google.",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_runtime_note_keeps_direct_zig_slice_visible(self) -> None:
        for fragment in (
            "Target `Page.zig` slice",
            "Target `win32_backend.zig` slice",
            "Focused regression coverage",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
        ):
            self.assertIn(fragment, self.runtime_note)

    def test_saved_memory_and_readiness_helpers_keep_toolchain_story_visible(self) -> None:
        self.assertIn("zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz", self.saved_memory_helper)
        self.assertIn("Saved Memory input check passed.", self.saved_memory_helper)
        self.assertIn("saved Rust toolchain", self.readiness_helper)
        self.assertIn("Zig 0.15.2 toolchain", self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
