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
        },
    }
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `src/browser/Page.zig`
    - `src/display/win32_backend.zig`
    - `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
    - `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
    - `scripts/check_linux_build_readiness.py`
    - a writable checkout of `fork/headed-mode-foundation` is available
    - the current runtime can publish low-level blob/tree/commit updates from the real branch head without rebuilding those files by hand
    - `../zig-v8-fork`
    - `../boringssl-zig`
    - `python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test`
    - `python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check`
    - `zig build -Dtarget=x86_64-windows-msvc --summary all`
    - `show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order`
    - `show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order`
    """,
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
    # Issue #3 Enter-Submit Runtime Revalidation

    - `src/browser/Page.zig`
    - `src/display/win32_backend.zig`
    - `_defer_native_text_input_enter_submit: bool`
    - `_pending_native_enter_submit: ?*Element.Html.Input`
    - `beginDeferredNativeTextInputEnterSubmit()`
    - `endDeferredNativeTextInputEnterSubmit()`
    - `applyDeferredNativeTextInputEnterSubmit()`
    - `pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent)`
    - `queuePendingTextInputSuppression(self, key);`
    - `shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])`
    - `test "Page reduced Google fixture accepts focused keyboard text and Enter submit"`
    - `test "win32 dispatchInput suppresses later text_input after printable keydown across batches"`
    - `zig build -Dtarget=x86_64-windows-msvc --summary all`
    - `chrome-google-home-title-probe.ps1`
    - `lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1`
    - `runtime-input-backend-*.log`
    - `wndproc-input-*.log`
    - `[_]u16{0} **`
    - writable checkout of `fork/headed-mode-foundation`
    """,
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
    $route = [ordered]@{
        read_first = @(
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        target_files = @(
            "src/browser/Page.zig",
            "src/display/win32_backend.zig"
        )
        related_files = @(
            "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
            "src/browser/tests/page/google_home_title_probe.html",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "scripts/check_linux_build_readiness.py"
        )
        commands = [ordered]@{
            surface_check = "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
            contract_check = "python check_issue3_enter_submit_runtime_contract.py --page src/browser/Page.zig --win32 src/display/win32_backend.zig"
            contract_self_test = "python check_issue3_enter_submit_runtime_contract.py --self-test"
            linux_build_readiness_skip_zig = "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check"
            linux_build_readiness = "python scripts/check_linux_build_readiness.py --repo-root ."
            build = "zig build -Dtarget=x86_64-windows-msvc --summary all"
            focused_page_tests = "zig test src/browser/Page.zig"
            focused_win32_tests = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
            shared_enter_default = "enter-submit-probe.ps1"
            shared_enter_deferred = "enter-submit-probe.ps1 -DeferredEnter"
            shared_enter_google = "enter-submit-probe.ps1 -GoogleEnterOrder"
            shared_enter_google_click = "enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus"
            reduced_google_probe = "chrome-google-home-title-probe.ps1"
            reduced_google_fixture = "lightpanda.exe browse --headed --window_width 1366 --window_height 900 http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
            live_google = "lightpanda.exe browse --headed --window_width 1366 --window_height 900 https://www.google.com/"
        }
        expected_signals = @(
            "Printable keydown and keypress leave text in the focused Google query input.",
            "Enter keydown alone does not force an early submit transition.",
            "Enter submit happens only after the later keypress-time DOM phase.",
            "Stale queued suppression entries do not drop real later text_input bytes."
        )
        notes = @(
            "Run surface_check first when branch state may have moved.",
            "Run contract_check before build or replay.",
            "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging.",
            "Use shared_enter_deferred after changes that touch delayed native Enter submit.",
            "Only jump to reduced_google_fixture or live_google after the source contract check, shared Enter-order ladder, and reduced Google probe agree on the same event ordering."
        )
    }
    """,
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": r"""
    REFERENCE_PATHS=(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note"
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Read-first Linux note"
        "scripts/check_linux_build_readiness.py|file|Python helper"
        "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Route printer"
        "scripts/linux/restore_saved_rust_toolchain.sh|file|Saved Rust restore helper"
        "scripts/linux/prepare_offline_build_inputs.sh|file|Offline restore helper"
        "build.zig.zon|file|Manifest surface"
    )
    CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|Gate note keeps Linux route visible."
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_linux_build_readiness.py|Gate note keeps readiness helper visible."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|saved Rust 1.79.0 restore command|Linux note keeps saved Rust restore visible."
        "scripts/linux/show_issue3_linux_build_readiness_route.sh|restore_saved_rust_toolchain.sh|Route printer points at saved Rust restore helper."
        "scripts/check_linux_build_readiness.py|saved browser dependency archive|Readiness helper knows saved browser dependency archive contract."
        "scripts/linux/prepare_offline_build_inputs.sh|--check-only|Offline prep helper supports surface-only validation."
    )
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
        'const defer_enter_submit = std.mem.eql(u8, key, "Enter");',
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
    def run_self_test(json_output: bool) -> int:
        return 0
    def main() -> int:
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


class Issue3RuntimeReentryRouteSurfaceTest(unittest.TestCase):
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
        cls.runtime_revalidation = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.runtime_helper = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.linux_surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
        )
        cls.runtime_contract_checker = read_text(
            cls.repo_root
            / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_runtime_gates_keep_hard_gates_and_reentry_order_visible(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
            "scripts/check_linux_build_readiness.py",
            "a writable checkout of `fork/headed-mode-foundation` is available",
            "the current runtime can publish low-level blob/tree/commit updates from the real branch head without rebuilding those files by hand",
            "../zig-v8-fork",
            "../boringssl-zig",
            "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test",
            "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order",
            "show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_runtime_revalidation_keeps_page_win32_slice_and_validation_caveats(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "_defer_native_text_input_enter_submit: bool",
            "_pending_native_enter_submit: ?*Element.Html.Input",
            "beginDeferredNativeTextInputEnterSubmit()",
            "endDeferredNativeTextInputEnterSubmit()",
            "applyDeferredNativeTextInputEnterSubmit()",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent)",
            "queuePendingTextInputSuppression(self, key);",
            "shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])",
            'test "Page reduced Google fixture accepts focused keyboard text and Enter submit"',
            'test "win32 dispatchInput suppresses later text_input after printable keydown across batches"',
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "chrome-google-home-title-probe.ps1",
            "lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1",
            "runtime-input-backend-*.log",
            "wndproc-input-*.log",
            "[_]u16{0} **",
            "writable checkout of `fork/headed-mode-foundation`",
        ):
            self.assertIn(fragment, self.runtime_revalidation)

    def test_runtime_helper_keeps_reentry_commands_and_notes(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"src/browser/Page.zig"',
            '"src/display/win32_backend.zig"',
            '"tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            '"scripts/check_linux_build_readiness.py"',
            '"check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            '"python check_issue3_enter_submit_runtime_contract.py --page src/browser/Page.zig --win32 src/display/win32_backend.zig"',
            '"python check_issue3_enter_submit_runtime_contract.py --self-test"',
            '"python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check"',
            '"python scripts/check_linux_build_readiness.py --repo-root ."',
            '"zig build -Dtarget=x86_64-windows-msvc --summary all"',
            '"zig test src/browser/Page.zig"',
            '"zig test src/display/win32_backend.zig -target x86_64-windows-gnu"',
            '"enter-submit-probe.ps1 -DeferredEnter"',
            '"enter-submit-probe.ps1 -GoogleEnterOrder"',
            '"enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus"',
            '"chrome-google-home-title-probe.ps1"',
            "https://www.google.com/",
            "Enter keydown alone does not force an early submit transition.",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Run surface_check first when branch state may have moved.",
            "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging.",
            "Only jump to reduced_google_fixture or live_google after the source contract check, shared Enter-order ladder, and reduced Google probe agree on the same event ordering.",
        ):
            self.assertIn(fragment, self.runtime_helper)

    def test_linux_surface_checker_keeps_runtime_route_dependencies(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"scripts/check_linux_build_readiness.py|file|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|file|',
            '"scripts/linux/restore_saved_rust_toolchain.sh|file|',
            '"scripts/linux/prepare_offline_build_inputs.sh|file|',
            '"build.zig.zon|file|Manifest surface"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_linux_build_readiness.py|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|saved Rust 1.79.0 restore command|',
            '"scripts/linux/show_issue3_linux_build_readiness_route.sh|restore_saved_rust_toolchain.sh|',
            '"scripts/check_linux_build_readiness.py|saved browser dependency archive|',
            '"scripts/linux/prepare_offline_build_inputs.sh|--check-only|',
        ):
            self.assertIn(fragment, self.linux_surface_checker)

    def test_runtime_contract_checker_keeps_markers_and_self_test_entrypoints(self) -> None:
        for fragment in (
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
            "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "page.beginDeferredNativeTextInputEnterSubmit();",
            "queuePendingTextInputSuppression(self, key);",
            "try page.applyDeferredNativeTextInputEnterSubmit();",
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            "def run_self_test(json_output: bool) -> int:",
        ):
            self.assertIn(fragment, self.runtime_contract_checker)

    def test_build_manifest_keeps_branch_zig_line_and_path_dependencies(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
