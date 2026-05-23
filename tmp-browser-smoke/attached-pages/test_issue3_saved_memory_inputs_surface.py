from __future__ import annotations

import tempfile
import unittest
from pathlib import Path


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- a writable checkout of `fork/headed-mode-foundation` is available
- the current publication path can safely materialize the exact live file bodies
- the current runtime can publish low-level blob/tree/commit updates from the real branch head
- Use a branch-compatible Zig toolchain
- python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
- python scripts/check_issue3_saved_memory_inputs.py --repo-root .
- bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
- bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
- python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
- powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
- zig build -Dtarget=x86_64-windows-msvc --summary all
- stay on a smaller create-only docs, diagnostics, or validation slice
""",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
$runtimeContractCheckerPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py"
$linuxBuildReadinessScriptPath = Join-Path $resolvedRepoRoot "scripts\check_linux_build_readiness.py"
$runtimeContractCheckCommand = "python " + $runtimeContractCheckerPath + " --page " + $pageSourcePath + " --win32 " + $win32SourcePath
$runtimeContractSelfTestCommand = "python " + $runtimeContractCheckerPath + " --self-test"
$linuxBuildReadinessSkipZigCommand = "python " + $linuxBuildReadinessScriptPath + " --repo-root " + $resolvedRepoRoot + " --skip-zig-check"
$linuxBuildReadinessFullCommand = "python " + $linuxBuildReadinessScriptPath + " --repo-root " + $resolvedRepoRoot
surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
contract_check = $runtimeContractCheckCommand
contract_self_test = $runtimeContractSelfTestCommand
linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
linux_build_readiness = $linuxBuildReadinessFullCommand
build = "zig build -Dtarget=x86_64-windows-msvc --summary all"
focused_page_tests = "zig test src/browser/Page.zig"
focused_win32_tests = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"
shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("DeferredEnter")
shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder")
shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder", "ClickFocus")
reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
live_google = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"https://www.google.com/``""
- Read docs/ISSUE3_RUNTIME_REENTRY_GATES.md before docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md whenever the next run may reopen Page.zig or win32_backend.zig.
- Run contract_check before build or replay when you need a thin, source-based yes-or-no answer about whether the direct Page.zig and win32_backend.zig bridge markers are present on the current branch.
- Run contract_self_test when you want to prove the checker itself still distinguishes vulnerable and guarded samples before pointing it at a real checkout.
- Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging and you need to confirm the saved inputs before trusting focused Zig output.
- Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain; the attached Zig 0.17 dev fallback can fail in untouched branch files before these focused assertions run.
- Use shared_enter_google_click when reproducing the click-first path that most closely matches the real homepage boundary from issue #3.
- If the focused Zig tests fail in untouched branch files before the new assertions run, fall back to contract_check, the shared Enter-order ladder, and the reduced Google probe so the runtime boundary can still be narrowed honestly.
""",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
docs/ISSUE3_RUNTIME_REENTRY_GATES.md
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check --expect-saved-archives
Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only
Prefer a Zig 0.15.2 toolchain
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
def resolve_default_memory_root(repo_root):
    return (repo_root.parent / "memory").resolve()
def resolve_default_agent_files_root(repo_root):
    return (repo_root.parent / "agent_files").resolve()
def collect_results(*, repo_root, memory_root, agent_files_root, fallback_zig_archive):
    return {"ok": True}
def test_collect_results_passes_with_required_files(self): ...
def test_collect_results_fails_when_required_archive_is_missing(self): ...
def test_default_roots_follow_workspace_layout(self): ...
""",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
PAGE_REQUIRED_MARKERS = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
    "if (self._defer_native_text_input_enter_submit) {",
)
WIN32_REQUIRED_MARKERS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "page.endDeferredNativeTextInputEnterSubmit();",
    "queuePendingTextInputSuppression(self, key);",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
    "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
)
PAGE_TEST_MARKERS = (
    'test "Page reduced Google fixture defers native Enter submit until keypress" {',
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
)
WIN32_TEST_MARKERS = (
    'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
    'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
)
def run_self_test(json_output: bool) -> int:
    print("SELF_TEST=pass")
""",
}


def build_fixture_repo() -> Path:
    root = Path(tempfile.mkdtemp(prefix="lightpanda-issue3-reentry-gates-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedMemoryInputsSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = build_fixture_repo()
        cls.runtime_gates = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.windows_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.linux_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.runtime_contract_checker = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )

    def test_runtime_gates_keep_publication_toolchain_and_reentry_markers(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "a writable checkout of `fork/headed-mode-foundation` is available",
            "the current publication path can safely materialize the exact live file bodies",
            "the current runtime can publish low-level blob/tree/commit updates from the real branch head",
            "Use a branch-compatible Zig toolchain",
            "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "stay on a smaller create-only docs, diagnostics, or validation slice",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_windows_helper_keeps_contract_checks_and_replay_ladder(self) -> None:
        for fragment in (
            'check_issue3_enter_submit_runtime_contract.py',
            'scripts\\check_linux_build_readiness.py',
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            "contract_check = $runtimeContractCheckCommand",
            "contract_self_test = $runtimeContractSelfTestCommand",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            'build = "zig build -Dtarget=x86_64-windows-msvc --summary all"',
            'focused_page_tests = "zig test src/browser/Page.zig"',
            'focused_win32_tests = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"',
            "shared_enter_default = Format-RepoRootCommand",
            'shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Switches @("DeferredEnter")',
            'shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder")',
            'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Switches @("GoogleEnterOrder", "ClickFocus")',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            'live_google = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"https://www.google.com/``""',
            "Read docs/ISSUE3_RUNTIME_REENTRY_GATES.md before docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "Run contract_check before build or replay",
            "Run contract_self_test when you want to prove the checker itself",
            "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging",
            "Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain",
            "attached Zig 0.17 dev fallback can fail in untouched branch files",
            "Use shared_enter_google_click when reproducing the click-first path",
            "fall back to contract_check, the shared Enter-order ladder, and the reduced Google probe",
        ):
            self.assertIn(fragment, self.windows_helper)

    def test_runtime_contract_checker_keeps_bridge_markers_and_self_test(self) -> None:
        for fragment in (
            '_defer_native_text_input_enter_submit: bool = false',
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
            "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
            "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
            "if (self._defer_native_text_input_enter_submit) {",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "page.beginDeferredNativeTextInputEnterSubmit();",
            "page.endDeferredNativeTextInputEnterSubmit();",
            "queuePendingTextInputSuppression(self, key);",
            "try page.applyDeferredNativeTextInputEnterSubmit();",
            "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            "def run_self_test(json_output: bool) -> int:",
            'print("SELF_TEST=pass")',
        ):
            self.assertIn(fragment, self.runtime_contract_checker)

    def test_saved_memory_helper_keeps_archive_contract_and_workspace_defaults(self) -> None:
        for fragment in (
            '("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot")',
            '("repo_archives/browser/README.md", "saved repo notes")',
            '("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence")',
            '("repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "saved Rust toolchain archive")',
            '("repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip", "saved html5ever dependency archive")',
            '("repo_archives/browser/dependencies/03-boringssl-zig-main.zip", "saved BoringSSL archive")',
            '("repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip", "saved browser dependency archive")',
            '("repo_archives/browser/session_entry_register.yaml", "session entry register")',
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'return (repo_root.parent / "memory").resolve()',
            'return (repo_root.parent / "agent_files").resolve()',
            "def collect_results(*, repo_root, memory_root, agent_files_root, fallback_zig_archive):",
            "def test_collect_results_passes_with_required_files(self):",
            "def test_collect_results_fails_when_required_archive_is_missing(self):",
            "def test_default_roots_follow_workspace_layout(self):",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_linux_route_stays_aligned_with_gate_note_and_saved_memory_preflight(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check --expect-saved-archives",
            "Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only",
            "Prefer a Zig 0.15.2 toolchain",
        ):
            self.assertIn(fragment, self.linux_route)


if __name__ == "__main__":
    unittest.main()
