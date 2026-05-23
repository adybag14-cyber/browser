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

    - `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    """,
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
    # Issue #3 Enter-Submit Runtime Revalidation

    - `src/browser/Page.zig`
    - `src/display/win32_backend.zig`
    - `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
    - `src/browser/tests/page/google_home_title_probe.html`
    - `zig test src/browser/Page.zig -O Debug`
    - `zig test src/display/win32_backend.zig -O Debug`
    - `Page.zig` still needs a way to defer native text-input Enter submit
    - `win32_backend.zig` still needs to suppress only the matching later `text_input` bytes
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh": r"""
    REFERENCE_PATHS=(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note that should stay read-first before the direct runtime route is reopened."
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md|file|Runtime revalidation note that should keep the Page.zig and win32_backend.zig target narrow."
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux or WSL build-readiness companion used when the direct runtime route is blocked on toolchain staging."
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|file|Fail-fast Linux or WSL surface checker for the direct issue #3 runtime route."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Compact Linux or WSL route printer for the direct issue #3 runtime lane."
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh|file|Fail-fast Linux build-readiness checker used before offline staging is blamed on source changes."
        "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Linux build-readiness route printer used before focused Zig output is trusted."
        "scripts/check_issue3_saved_memory_inputs.py|file|Saved-Memory preflight helper for the repo snapshot, dependency archives, and fallback Zig bundle used by the runtime re-entry route."
        "scripts/check_linux_build_readiness.py|file|Branch-local build-readiness helper used by the Linux or WSL recovery route."
        "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py|file|Source-based checker for the direct Page.zig and win32_backend.zig runtime bridge markers."
    )
    CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh|The gate note keeps the Linux or WSL runtime surface checker visible before the direct runtime patch is reopened."
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|The gate note keeps the compact Linux or WSL runtime helper visible before the direct runtime patch is reopened."
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|The gate note keeps the saved-memory preflight visible before Linux or WSL build-readiness commands are trusted."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|The Linux or WSL runtime helper prints the source-based runtime contract check."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_saved_memory_inputs.py|The Linux or WSL runtime helper prints the saved-memory preflight before broader build-readiness commands."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|fallback-zig-archive|The Linux or WSL runtime helper supports an explicit fallback Zig archive override during saved-checkout re-entry."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|Fallback Zig archive:|The Linux or WSL runtime helper prints the surfaced fallback Zig archive before Linux or WSL follow-up commands."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|The Linux or WSL runtime helper keeps the build-readiness surface check visible before focused Zig output is trusted."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|The Linux or WSL runtime helper keeps the build-readiness route printer visible when the toolchain gate is still closed."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|The Linux or WSL runtime helper still prints the reduced Google Windows follow-up probe."
    )
    """,
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": r"""
    SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh --repo-root ${REPO_ROOT}"
    CONTRACT_CHECK_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --page ${PAGE_SOURCE_PATH} --win32 ${WIN32_SOURCE_PATH}"
    CONTRACT_SELF_TEST_COMMAND="python ${RUNTIME_CONTRACT_CHECKER} --self-test"
    SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root ${REPO_ROOT} --fallback-zig-archive ${FALLBACK_ZIG_ARCHIVE}"
    LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root ${REPO_ROOT}"
    LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ${REPO_ROOT}"
    LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT} --skip-zig-check"
    LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root ${REPO_ROOT}"
    FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"
    FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
    WINDOWS_BUILD_COMMAND="zig build -Dtarget=x86_64-windows-msvc --summary all"
    REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ./tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
    REDUCED_GOOGLE_FIXTURE_COMMAND="${BROWSER_EXE} browse --headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
    LIVE_GOOGLE_COMMAND="${BROWSER_EXE} browse --headed https://www.google.com/"
    Fallback Zig archive:
    Target files
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
    )
    WIN32_REQUIRED_MARKERS = (
        "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
        "page.beginDeferredNativeTextInputEnterSubmit();",
        "page.endDeferredNativeTextInputEnterSubmit();",
        "try page.applyDeferredNativeTextInputEnterSubmit();",
    )
    PAGE_TEST_MARKERS = (
        'test "Page reduced Google fixture defers native Enter submit until keypress" {',
    )
    WIN32_TEST_MARKERS = (
        'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
        'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
    )
    def evaluate_sources(page_source: str, win32_source: str) -> dict[str, object]:
        return {"ok": True}
    def run_self_test(json_output: bool) -> int:
        return 0
    parser.add_argument("--self-test")
    parser.add_argument("--json")
    parser.add_argument("--page")
    parser.add_argument("--win32")
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
    test "Page reduced Google fixture defers native Enter submit until keypress" {}
    """,
    "src/display/win32_backend.zig": """
    pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},
    page.beginDeferredNativeTextInputEnterSubmit();
    page.endDeferredNativeTextInputEnterSubmit();
    try page.applyDeferredNativeTextInputEnterSubmit();
    test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {}
    test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {}
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-runtime-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3EnterSubmitRuntimeRevalidationRouteSurfaceTest(unittest.TestCase):
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
        cls.revalidation_note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
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
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_revalidation_note_keeps_the_narrow_runtime_slice_visible(self) -> None:
        for fragment in (
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html",
            "zig test src/browser/Page.zig -O Debug",
            "zig test src/display/win32_backend.zig -O Debug",
            "Page.zig` still needs a way to defer native text-input Enter submit",
            "win32_backend.zig` still needs to suppress only the matching later `text_input` bytes",
        ):
            self.assertIn(fragment, self.revalidation_note)

    def test_runtime_gates_and_build_readiness_note_still_point_back_to_runtime_route(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        ):
            self.assertIn(fragment, self.runtime_gates)

        for fragment in (
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_surface_checker_keeps_reference_paths_and_content_expectations_visible(self) -> None:
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
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|scripts/check_issue3_saved_memory_inputs.py|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_enter_submit_runtime_contract.py|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_saved_memory_inputs.py|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|fallback-zig-archive|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|Fallback Zig archive:|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|check_issue3_linux_build_readiness_route_surface.sh|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|show_issue3_linux_build_readiness_route.sh|',
            '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|chrome-google-home-title-probe.ps1|',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_contract_preflight_linux_gate_and_windows_followups_visible(self) -> None:
        for fragment in (
            'SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh',
            'CONTRACT_CHECK_COMMAND="python',
            'CONTRACT_SELF_TEST_COMMAND="python',
            'SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py',
            "--fallback-zig-archive",
            'LINUX_BUILD_SURFACE_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh',
            'LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh',
            'LINUX_BUILD_READINESS_SKIP_ZIG_COMMAND="python scripts/check_linux_build_readiness.py',
            "--skip-zig-check",
            'LINUX_BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py',
            'FOCUSED_PAGE_TESTS_COMMAND="zig test src/browser/Page.zig"',
            'FOCUSED_WIN32_TESTS_COMMAND="zig test src/display/win32_backend.zig -target x86_64-windows-gnu"',
            'WINDOWS_BUILD_COMMAND="zig build -Dtarget=x86_64-windows-msvc --summary all"',
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
            'LIVE_GOOGLE_COMMAND="${BROWSER_EXE} browse --headed https://www.google.com/"',
            "Fallback Zig archive:",
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_contract_checker_keeps_required_markers_and_self_test_surface(self) -> None:
        for fragment in (
            "PAGE_REQUIRED_MARKERS",
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "PAGE_TEST_MARKERS",
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            "WIN32_REQUIRED_MARKERS",
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "WIN32_TEST_MARKERS",
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            "def evaluate_sources(page_source: str, win32_source: str) -> dict[str, object]:",
            "def run_self_test(json_output: bool) -> int:",
            '--self-test',
            '--json',
            '--page',
            '--win32',
        ):
            self.assertIn(fragment, self.contract_checker)

    def test_saved_memory_and_readiness_helpers_keep_fallback_and_skip_zig_contracts_visible(self) -> None:
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

    def test_page_win32_and_manifest_keep_the_expected_runtime_and_toolchain_markers(self) -> None:
        for fragment in (
            "_defer_native_text_input_enter_submit: bool = false",
            "_pending_native_enter_submit: ?*Element.Html.Input = null",
            "beginDeferredNativeTextInputEnterSubmit",
            "endDeferredNativeTextInputEnterSubmit",
            "applyDeferredNativeTextInputEnterSubmit",
            'test "Page reduced Google fixture defers native Enter submit until keypress"',
        ):
            self.assertIn(fragment, self.page_source)

        for fragment in (
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            "beginDeferredNativeTextInputEnterSubmit",
            "endDeferredNativeTextInputEnterSubmit",
            "applyDeferredNativeTextInputEnterSubmit",
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match"',
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order"',
        ):
            self.assertIn(fragment, self.win32_source)

        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
            '.curl = .{ .url = "https://example.invalid/curl.tar.gz" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
