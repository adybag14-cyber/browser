#!/usr/bin/env python3
"""Check the direct issue #3 Enter-submit runtime contract from source text.

This helper keeps the smallest high-signal branch-side guard for the direct
Page.zig and win32_backend.zig runtime bridge. It is intentionally source-based
so it can run in lightweight debugging environments where the Windows headed
binary or a branch-compatible Zig toolchain is unavailable.
"""

from __future__ import annotations

import argparse
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
    "const defer_enter_submit = std.mem.eql(u8, key, \"Enter\");",
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


def evaluate_page_source(source: str) -> tuple[bool, str]:
    missing = find_missing_markers(source, PAGE_REQUIRED_MARKERS)
    if missing:
        return False, f"Page.zig missing markers: {', '.join(missing[:3])}"

    test_missing = find_missing_markers(source, PAGE_TEST_MARKERS)
    if test_missing:
        return False, f"Page.zig missing regression coverage markers: {', '.join(test_missing[:2])}"

    return True, "Page.zig retains the deferred native Enter-submit bridge"


def evaluate_win32_source(source: str) -> tuple[bool, str]:
    missing = find_missing_markers(source, WIN32_REQUIRED_MARKERS)
    if missing:
        return False, f"win32_backend.zig missing markers: {', '.join(missing[:3])}"

    test_missing = find_missing_markers(source, WIN32_TEST_MARKERS)
    if test_missing:
        return False, f"win32_backend.zig missing regression coverage markers: {', '.join(test_missing[:2])}"

    return True, "win32_backend.zig retains the deferred Enter and byte-matched suppression bridge"


def evaluate_sources(page_source: str, win32_source: str) -> tuple[bool, list[str]]:
    page_ok, page_reason = evaluate_page_source(page_source)
    win32_ok, win32_reason = evaluate_win32_source(win32_source)
    details = [
        f"PAGE_RUNTIME_CONTRACT={'pass' if page_ok else 'fail'}",
        f"PAGE_DETAIL={page_reason}",
        f"WIN32_RUNTIME_CONTRACT={'pass' if win32_ok else 'fail'}",
        f"WIN32_DETAIL={win32_reason}",
    ]
    return page_ok and win32_ok, details


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


def run_self_test() -> int:
    bad_ok, bad_details = evaluate_sources(VULNERABLE_PAGE, VULNERABLE_WIN32)
    good_ok, good_details = evaluate_sources(GUARDED_PAGE, GUARDED_WIN32)

    if bad_ok:
        print("SELF_TEST=fail")
        print("DETAIL=vulnerable samples unexpectedly passed")
        return 1
    if not good_ok:
        print("SELF_TEST=fail")
        print("DETAIL=guarded samples unexpectedly failed")
        for detail in good_details:
            print(detail)
        return 1

    print("SELF_TEST=pass")
    for detail in bad_details:
        print(f"VULNERABLE_{detail}")
    for detail in good_details:
        print(f"GUARDED_{detail}")
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
    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    if args.page is None or args.win32 is None:
        parser.error("either --self-test or both --page and --win32 are required")

    ok, details = evaluate_sources(
        args.page.read_text(encoding="utf-8"),
        args.win32.read_text(encoding="utf-8"),
    )
    print(f"ISSUE3_ENTER_SUBMIT_RUNTIME_CONTRACT={'pass' if ok else 'fail'}")
    for detail in details:
        print(detail)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
