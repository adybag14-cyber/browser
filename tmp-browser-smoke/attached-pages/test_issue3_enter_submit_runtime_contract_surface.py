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
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    - a writable checkout of `fork/headed-mode-foundation` is available
    - the current publication path can safely materialize the exact live file bodies
    - the current runtime can publish low-level blob/tree/commit updates from the real branch head
    - Use a branch-compatible Zig toolchain
    - python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
    - python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --page src/browser/Page.zig --win32 src/display/win32_backend.zig
    """,
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
    # Issue #3 Enter-Submit Runtime Revalidation

    - `src/browser/Page.zig`
    - `src/display/win32_backend.zig`
    - `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
    - `src/browser/tests/page/google_home_title_probe.html`
    - `Page.zig` still needs a way to defer native text-input Enter submit until keypress-time DOM behavior has had a chance to run.
    - `win32_backend.zig` still needs to suppress only the matching later `text_input` bytes that correspond to a just-handled printable keydown.
    - `test "Page reduced Google fixture defers native Enter submit until keypress"`
    - `test "win32 dispatchInput allows later real text when stale suppression bytes do not match"`
    - `test "win32 dispatchInput suppresses matching text after stale entries drop out of order"`
    """,
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
    $runtimeContractCheckerPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py"
    $pageSourcePath = Join-Path $resolvedRepoRoot "src\browser\Page.zig"
    $win32SourcePath = Join-Path $resolvedRepoRoot "src\display\win32_backend.zig"
    $linuxBuildReadinessScriptPath = Join-Path $resolvedRepoRoot "scripts\check_linux_build_readiness.py"
    $runtimeContractCheckCommand = "python " + $runtimeContractCheckerPath + " --page " + $pageSourcePath + " --win32 " + $win32SourcePath
    $runtimeContractSelfTestCommand = "python " + $runtimeContractCheckerPath + " --self-test"
    $linuxBuildReadinessSkipZigCommand = "python " + $linuxBuildReadinessScriptPath + " --repo-root " + $resolvedRepoRoot + " --skip-zig-check"
    $linuxBuildReadinessFullCommand = "python " + $linuxBuildReadinessScriptPath + " --repo-root " + $resolvedRepoRoot
    contract_check = $runtimeContractCheckCommand
    contract_self_test = $runtimeContractSelfTestCommand
    linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
    linux_build_readiness = $linuxBuildReadinessFullCommand
    focused_page_tests = "zig test src/browser/Page.zig"
    focused_win32_tests = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
    reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
    If the focused Zig tests fail in untouched branch files before the new assertions run, fall back to contract_check, the shared Enter-order ladder, and the reduced Google probe so the runtime boundary can still be narrowed honestly.
    """,
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": r"""
    CONTRACT_CHECK_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --page ${PAGE_SOURCE_PATH} --win32 ${WIN32_SOURCE_PATH}"
    CONTRACT_SELF_TEST_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --self-test"
    SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT} --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
    LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
    LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${REPO_ROOT}"
    LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check"
    LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT}"
    FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"
    FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
    REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
    Fallback Zig archive:
    src/browser/Page.zig
    src/display/win32_backend.zig
    """,
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": """
    PAGE_REQUIRED_MARKERS = (
        "_defer_native_text_input_enter_submit: bool = false",
        "_pending_native_enter_submit: ?*Element.Html.Input = null",
        "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
        "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
        "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
        "const focused = self.document.getFocusedElement() orelse return;",
        "if (focused.asNode() != input.asNode()) {",
        "if (self._defer_native_text_input_enter_submit) {",
        "self._pending_native_enter_submit = input;",
    )
    WIN32_REQUIRED_MARKERS = (
        "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
        "self.pending_text_input_suppressions.deinit(self.allocator);",
        "const defer_enter_submit = std.mem.eql(u8, key, \\"Enter\\");",
        "page.beginDeferredNativeTextInputEnterSubmit();",
        "page.endDeferredNativeTextInputEnterSubmit();",
        "queuePendingTextInputSuppression(self, key);",
        "if (defer_enter_submit and allow_text_input) {",
        "try page.applyDeferredNativeTextInputEnterSubmit();",
        "if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {",
        "self.pending_text_input_suppressions.clearRetainingCapacity();",
        "fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {",
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
    def evaluate_sources(page_source: str, win32_source: str) -> dict[str, object]:
        return {"ok": True}
    def run_self_test(json_output: bool) -> int:
        return 0
    parser.add_argument("--page")
    parser.add_argument("--win32")
    parser.add_argument("--self-test")
    parser.add_argument("--json")
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_MEMORY_FILES = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
        ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    )
    DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    parser.add_argument("--fallback-zig-archive")
    Saved Memory input check passed.
    """,
    "scripts/check_linux_build_readiness.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    def build_parser():
        parser.add_argument("--skip-zig-check")
        parser.add_argument("--fallback-zig-archive")
    """,
    "src/browser/Page.zig": """
    _defer_native_text_input_enter_submit: bool = false,
    _pending_native_enter_submit: ?*Element.Html.Input = null,
    pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {}
    pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {}
    pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {}
    const focused = self.document.getFocusedElement() orelse return;
    if (focused.asNode() != input.asNode()) {}
    if (self._defer_native_text_input_enter_submit) {}
    self._pending_native_enter_submit = input;
    test "Page reduced Google fixture defers native Enter submit until keypress" {}
    """,
    "src/display/win32_backend.zig": """
    pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},
    self.pending_text_input_suppressions.deinit(self.allocator);
    const defer_enter_submit = std.mem.eql(u8, key, "Enter");
    page.beginDeferredNativeTextInputEnterSubmit();
    page.endDeferredNativeTextInputEnterSubmit();
    queuePendingTextInputSuppression(self, key);
    if (defer_enter_submit and allow_text_input) {}
    try page.applyDeferredNativeTextInputEnterSubmit();
    if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {}
    self.pending_text_input_suppressions.clearRetainingCapacity();
    fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {}
    fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool { return false; }
    test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {}
    test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {}
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-runtime-contract-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3EnterSubmitRuntimeContractSurfaceTest(unittest.TestCase):
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
        cls.revalidation_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.windows_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.linux_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        )
        cls.contract_checker = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.page_source = read_text(cls.repo_root / "src/browser/Page.zig")
        cls.win32_source = read_text(cls.repo_root / "src/display/win32_backend.zig")

    def test_runtime_gates_keep_the_contract_checker_and_reentry_rules_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
            "a writable checkout of `fork/headed-mode-foundation` is available",
            "the current publication path can safely materialize the exact live file bodies",
            "the current runtime can publish low-level blob/tree/commit updates from the real branch head",
            "Use a branch-compatible Zig toolchain",
            "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test",
            "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --page src/browser/Page.zig --win32 src/display/win32_backend.zig",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_revalidation_note_keeps_the_narrow_runtime_boundary_visible(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html",
            "Page.zig` still needs a way to defer native text-input Enter submit until keypress-time DOM behavior has had a chance to run.",
            "win32_backend.zig` still needs to suppress only the matching later `text_input` bytes that correspond to a just-handled printable keydown.",
            'test "Page reduced Google fixture defers native Enter submit until keypress"',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match"',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order"',
        ):
            self.assertIn(fragment, self.revalidation_note)

    def test_windows_helper_keeps_contract_checks_linux_fallback_and_focused_commands(self) -> None:
        for fragment in (
            "check_issue3_enter_submit_runtime_contract.py",
            "scripts\\check_linux_build_readiness.py",
            "contract_check = $runtimeContractCheckCommand",
            "contract_self_test = $runtimeContractSelfTestCommand",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            'focused_page_tests = "zig test src/browser/Page.zig"',
            'focused_win32_tests = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            "fall back to contract_check, the shared Enter-order ladder, and the reduced Google probe",
        ):
            self.assertIn(fragment, self.windows_helper)

    def test_linux_route_keeps_contract_preflight_and_toolchain_gate_visible(self) -> None:
        for fragment in (
            "CONTRACT_CHECK_COMMAND",
            "CONTRACT_SELF_TEST_COMMAND",
            "SAVED_MEMORY_PREFLIGHT_COMMAND",
            "--fallback-zig-archive",
            "LINUX_BUILD_SURFACE_COMMAND",
            "LINUX_BUILD_ROUTE_COMMAND",
            "LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND",
            "LINUX_BUILD_READINESS_COMMAND",
            'FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"',
            'FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"',
            "REDUCED_GOOGLE_PROBE_COMMAND",
            "Fallback Zig archive:",
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
        ):
            self.assertIn(fragment, self.linux_route)

    def test_contract_checker_keeps_runtime_markers_self_test_and_cli_surface(self) -> None:
        for fragment in (
            "PAGE_REQUIRED_MARKERS = (",
            '_defer_native_text_input_enter_submit: bool = false',
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
            "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
            "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
            "const focused = self.document.getFocusedElement() orelse return;",
            "if (focused.asNode() != input.asNode()) {",
            "self._pending_native_enter_submit = input;",
            "WIN32_REQUIRED_MARKERS = (",
            'const defer_enter_submit = std.mem.eql(u8, key, \\"Enter\\");',
            "queuePendingTextInputSuppression(self, key);",
            "if (defer_enter_submit and allow_text_input) {",
            "try page.applyDeferredNativeTextInputEnterSubmit();",
            "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            "def evaluate_sources(page_source: str, win32_source: str) -> dict[str, object]:",
            "def run_self_test(json_output: bool) -> int:",
            'parser.add_argument("--page")',
            'parser.add_argument("--win32")',
            'parser.add_argument("--self-test")',
            'parser.add_argument("--json")',
        ):
            self.assertIn(fragment, self.contract_checker)

    def test_page_and_win32_sources_keep_the_markers_that_the_contract_checker_enforces(self) -> None:
        for fragment in (
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "beginDeferredNativeTextInputEnterSubmit",
            "endDeferredNativeTextInputEnterSubmit",
            "applyDeferredNativeTextInputEnterSubmit",
            "const focused = self.document.getFocusedElement() orelse return;",
            "if (focused.asNode() != input.asNode())",
            "self._pending_native_enter_submit = input;",
            'test "Page reduced Google fixture defers native Enter submit until keypress"',
        ):
            self.assertIn(fragment, self.page_source)

        for fragment in (
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "self.pending_text_input_suppressions.deinit(self.allocator);",
            'const defer_enter_submit = std.mem.eql(u8, key, "Enter");',
            "queuePendingTextInputSuppression(self, key);",
            "try page.applyDeferredNativeTextInputEnterSubmit();",
            "self.pending_text_input_suppressions.clearRetainingCapacity();",
            "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match"',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order"',
        ):
            self.assertIn(fragment, self.win32_source)

    def test_saved_memory_and_readiness_helpers_keep_the_runtime_contract_fallback_hooks_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--fallback-zig-archive",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "--skip-zig-check",
            "--fallback-zig-archive",
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
