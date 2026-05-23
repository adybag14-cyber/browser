from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`

### Gate 1: Writable publication path

### Gate 2: Branch-compatible validation toolchain

powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`

## Target `Page.zig` slice
## Target `win32_backend.zig` slice
## Focused regression coverage

zig test src/browser/Page.zig
zig test src/display/win32_backend.zig -target x86_64-windows-gnu
.\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": """
read_first = @(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
)
target_files = @(
    "src/browser/Page.zig",
    "src/display/win32_backend.zig"
)
surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
contract_check = "python"
linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
linux_build_readiness = $linuxBuildReadinessFullCommand
shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"
reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"
reduced_google_fixture = "google_home_title_probe.html?google-home-probe=1"
Stale queued suppression entries do not drop real later text_input bytes.
""",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": """
docs/ISSUE3_RUNTIME_REENTRY_GATES.md
docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md
docs/HEADED_MODE_ROADMAP.md
scripts/check_linux_build_readiness.py
scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1
tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py
show_google_issue3_enter_submit_runtime_revalidation.ps1
check_issue3_enter_submit_runtime_contract.py
""",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh": """
docs/ISSUE3_RUNTIME_REENTRY_GATES.md
docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
scripts/linux/show_issue3_linux_build_readiness_route.sh
scripts/check_linux_build_readiness.py
tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py
chrome-google-home-title-probe.ps1
""",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": """
docs/ISSUE3_RUNTIME_REENTRY_GATES.md
docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
python scripts/check_linux_build_readiness.py --repo-root
bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash scripts/linux/show_issue3_linux_build_readiness_route.sh
zig test src/browser/Page.zig
zig test src/display/win32_backend.zig -target x86_64-windows-gnu
powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1
""",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
PAGE_REQUIRED_MARKERS = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
)
WIN32_REQUIRED_MARKERS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
)
def run_self_test(json_output: bool) -> int:
    return 0
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runtime-reentry-"))
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
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.runtime_note = read_text(cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")
        cls.windows_route = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.windows_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.linux_surface = read_text(
            cls.repo_root / "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
        )
        cls.linux_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        )
        cls.contract_checker = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )

    def test_runtime_gate_note_keeps_direct_reentry_inputs_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "check_issue3_linux_build_readiness_route_surface.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "check_issue3_enter_submit_runtime_contract.py",
            "Gate 1: Writable publication path",
            "Gate 2: Branch-compatible validation toolchain",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_runtime_gate_note_keeps_preflight_commands_visible(self) -> None:
        for fragment in (
            ".\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "check_issue3_enter_submit_runtime_contract.py --self-test",
            "scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_runtime_note_keeps_two_file_patch_and_replay_scope_visible(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "Target `Page.zig` slice",
            "Target `win32_backend.zig` slice",
            "Focused regression coverage",
            "zig test src/browser/Page.zig",
            "zig test src/display/win32_backend.zig -target x86_64-windows-gnu",
            "google_home_title_probe.html?google-home-probe=1",
        ):
            self.assertIn(fragment, self.runtime_note)

    def test_windows_route_keeps_gate_note_targets_and_reduced_probe_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"src/browser/Page.zig"',
            '"src/display/win32_backend.zig"',
            'check_google_issue3_enter_submit_runtime_revalidation_surface.ps1',
            'linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand',
            'linux_build_readiness = $linuxBuildReadinessFullCommand',
            'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            'google_home_title_probe.html?google-home-probe=1',
            'Stale queued suppression entries do not drop real later text_input bytes.',
        ):
            self.assertIn(fragment, self.windows_route)

    def test_windows_surface_checker_keeps_branch_side_references_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
            "docs/HEADED_MODE_ROADMAP.md",
            "scripts/check_linux_build_readiness.py",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "check_issue3_enter_submit_runtime_contract.py",
        ):
            self.assertIn(fragment, self.windows_surface)

    def test_linux_surface_and_route_keep_build_readiness_bridge_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "check_issue3_linux_build_readiness_route_surface.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "scripts/check_linux_build_readiness.py",
            "chrome-google-home-title-probe.ps1",
        ):
            self.assertIn(fragment, self.linux_surface)
            self.assertIn(fragment, self.linux_route)

    def test_linux_route_keeps_focused_tests_and_windows_follow_up_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "zig test src/browser/Page.zig",
            "zig test src/display/win32_backend.zig -target x86_64-windows-gnu",
            "chrome-google-home-title-probe.ps1",
        ):
            self.assertIn(fragment, self.linux_route)

    def test_contract_checker_keeps_page_and_win32_bridge_markers_visible(self) -> None:
        for fragment in (
            "PAGE_REQUIRED_MARKERS",
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "WIN32_REQUIRED_MARKERS",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "try page.applyDeferredNativeTextInputEnterSubmit();",
            "run_self_test",
        ):
            self.assertIn(fragment, self.contract_checker)


if __name__ == "__main__":
    unittest.main()
