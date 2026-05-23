#!/usr/bin/env python3
"""Check the direct issue #3 Enter-submit runtime contract from source text.

This helper keeps the smallest high-signal branch-side guard for the direct
Page.zig and win32_backend.zig runtime bridge. It is intentionally source-based
so it can run in lightweight debugging environments where the Windows headed
binary or a branch-compatible Zig toolchain is unavailable.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


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


def find_missing_markers(source: str, markers: tuple[str, ...]) -> list[str]:
    return [marker for marker in markers if marker not in source]


def summarize_markers(markers: list[str], limit: int) -> str:
    return " | ".join(markers[:limit])


def build_result(
    *,
    label: str,
    required_markers: tuple[str, ...],
    test_markers: tuple[str, ...],
    source: str,
    success_detail: str,
) -> dict[str, object]:
    missing_required = find_missing_markers(source, required_markers)
    missing_tests = find_missing_markers(source, test_markers)
    ok = not missing_required and not missing_tests

    if missing_required:
        detail = f"{label} missing markers: {summarize_markers(missing_required, 3)}"
    elif missing_tests:
        detail = f"{label} missing regression coverage markers: {summarize_markers(missing_tests, 2)}"
    else:
        detail = success_detail

    return {
        "ok": ok,
        "detail": detail,
        "missing_required_markers": missing_required,
        "missing_test_markers": missing_tests,
        "required_marker_count": len(required_markers),
        "test_marker_count": len(test_markers),
        "matched_required_marker_count": len(required_markers) - len(missing_required),
        "matched_test_marker_count": len(test_markers) - len(missing_tests),
    }


def evaluate_page_source(source: str) -> dict[str, object]:
    return build_result(
        label="Page.zig",
        required_markers=PAGE_REQUIRED_MARKERS,
        test_markers=PAGE_TEST_MARKERS,
        source=source,
        success_detail="Page.zig retains the deferred native Enter-submit bridge",
    )


def evaluate_win32_source(source: str) -> dict[str, object]:
    return build_result(
        label="win32_backend.zig",
        required_markers=WIN32_REQUIRED_MARKERS,
        test_markers=WIN32_TEST_MARKERS,
        source=source,
        success_detail="win32_backend.zig retains the deferred Enter and byte-matched suppression bridge",
    )


def evaluate_sources(page_source: str, win32_source: str) -> dict[str, object]:
    page = evaluate_page_source(page_source)
    win32 = evaluate_win32_source(win32_source)
    ok = bool(page["ok"] and win32["ok"])
    return {
        "ok": ok,
        "page": page,
        "win32": win32,
    }


def emit_text_result(result: dict[str, object]) -> None:
    page = result["page"]
    win32 = result["win32"]
    print(f"ISSUE3_ENTER_SUBMIT_RUNTIME_CONTRACT={'pass' if result['ok'] else 'fail'}")
    print(f"PAGE_RUNTIME_CONTRACT={'pass' if page['ok'] else 'fail'}")
    print(f"PAGE_DETAIL={page['detail']}")
    print(f"PAGE_MISSING_REQUIRED_MARKER_COUNT={len(page['missing_required_markers'])}")
    print(f"PAGE_MISSING_TEST_MARKER_COUNT={len(page['missing_test_markers'])}")
    for marker in page["missing_required_markers"]:
        print(f"PAGE_MISSING_REQUIRED_MARKER={marker}")
    for marker in page["missing_test_markers"]:
        print(f"PAGE_MISSING_TEST_MARKER={marker}")
    print(f"WIN32_RUNTIME_CONTRACT={'pass' if win32['ok'] else 'fail'}")
    print(f"WIN32_DETAIL={win32['detail']}")
    print(f"WIN32_MISSING_REQUIRED_MARKER_COUNT={len(win32['missing_required_markers'])}")
    print(f"WIN32_MISSING_TEST_MARKER_COUNT={len(win32['missing_test_markers'])}")
    for marker in win32["missing_required_markers"]:
        print(f"WIN32_MISSING_REQUIRED_MARKER={marker}")
    for marker in win32["missing_test_markers"]:
        print(f"WIN32_MISSING_TEST_MARKER={marker}")


VULNERABLE_PAGE = """
_keyboard_text_suppression_depth: u32 = 0,

pub fn triggerWindowBlur(self: *Page) !void {
    const active = self.document.getFocusedElement() orelse return;
    try active.blur(self);
}

fn submitCurrentInput(self: *Page, input: *Element.Html.Input) !void {
    return self.submitForm(input.asElement(), input.getForm(self), .{});
}
"""


GUARDED_PAGE = """
_keyboard_text_suppression_depth: u32 = 0,
_defer_native_text_input_enter_submit: bool = false,
_pending_native_enter_submit: ?*Element.Html.Input = null,

pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {
    self._defer_native_text_input_enter_submit = true;
    self._pending_native_enter_submit = null;
}

pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {
    self._defer_native_text_input_enter_submit = false;
    self._pending_native_enter_submit = null;
}

pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {
    const input = self._pending_native_enter_submit orelse return;
    self._pending_native_enter_submit = null;
    const focused = self.document.getFocusedElement() orelse return;
    if (focused.asNode() != input.asNode()) {
        return;
    }
    try self.submitForm(input.asElement(), input.getForm(self), .{});
}

fn submitCurrentInput(self: *Page, input: *Element.Html.Input) !void {
    if (self._defer_native_text_input_enter_submit) {
        self._pending_native_enter_submit = input;
        return;
    }
    return self.submitForm(input.asElement(), input.getForm(self), .{});
}

test "Page reduced Google fixture defers native Enter submit until keypress" {
    page.beginDeferredNativeTextInputEnterSubmit();
    try page.applyDeferredNativeTextInputEnterSubmit();
}
"""


VULNERABLE_WIN32 = """
pending_text_input_suppressions: u32 = 0,

if (allow_text_input) {
    try page.insertText(key);
}
self.pending_text_input_suppressions +|= 1;
"""


GUARDED_WIN32 = """
pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},
self.pending_text_input_suppressions.deinit(self.allocator);
self.pending_text_input_suppressions.clearRetainingCapacity();

const defer_enter_submit = std.mem.eql(u8, key, "Enter");
page.beginDeferredNativeTextInputEnterSubmit();
page.endDeferredNativeTextInputEnterSubmit();
queuePendingTextInputSuppression(self, key);
if (defer_enter_submit and allow_text_input) {
    try page.applyDeferredNativeTextInputEnterSubmit();
}
if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {
    continue;
}

fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {}
fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool { return false; }

test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {}
test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {}
"""


def run_self_test(json_output: bool) -> int:
    bad_result = evaluate_sources(VULNERABLE_PAGE, VULNERABLE_WIN32)
    good_result = evaluate_sources(GUARDED_PAGE, GUARDED_WIN32)
    ok = (not bad_result["ok"]) and bool(good_result["ok"])

    if json_output:
        print(
            json.dumps(
                {
                    "profile": "issue3-enter-submit-runtime-contract-self-test",
                    "self_test": "pass" if ok else "fail",
                    "vulnerable_sample": bad_result,
                    "guarded_sample": good_result,
                },
                indent=2,
            )
        )
        return 0 if ok else 1

    if bad_result["ok"]:
        print("SELF_TEST=fail")
        print("DETAIL=vulnerable samples unexpectedly passed")
        emit_text_result(bad_result)
        return 1
    if not good_result["ok"]:
        print("SELF_TEST=fail")
        print("DETAIL=guarded samples unexpectedly failed")
        emit_text_result(good_result)
        return 1

    print("SELF_TEST=pass")
    print("VULNERABLE_SAMPLE_EXPECTATION=fail")
    emit_text_result(bad_result)
    print("GUARDED_SAMPLE_EXPECTATION=pass")
    emit_text_result(good_result)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the direct issue #3 Enter-submit runtime bridge is still "
            "present in Page.zig and win32_backend.zig."
        )
    )
    parser.add_argument("--page", type=Path, help="Path to src/browser/Page.zig")
    parser.add_argument("--win32", type=Path, help="Path to src/display/win32_backend.zig")
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run embedded vulnerable and guarded samples instead of reading files",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    args = parser.parse_args()

    if args.self_test:
        return run_self_test(args.json)

    if args.page is None or args.win32 is None:
        parser.error("either --self-test or both --page and --win32 are required")

    result = evaluate_sources(
        args.page.read_text(encoding="utf-8"),
        args.win32.read_text(encoding="utf-8"),
    )
    if args.json:
        print(json.dumps({"profile": "issue3-enter-submit-runtime-contract", **result}, indent=2))
    else:
        emit_text_result(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())