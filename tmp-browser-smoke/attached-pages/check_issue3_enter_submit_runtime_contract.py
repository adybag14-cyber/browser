#!/usr/bin/env python3
"""Source-level guard for the headed issue #3 Enter-submit runtime patch."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


PAGE_REQUIRED_SNIPPETS = (
    "_defer_native_text_input_enter_submit: bool = false,",
    "_pending_native_enter_submit: ?*Element.Html.Input = null,",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
    "self._pending_native_enter_submit = input;",
    "if (self._defer_native_text_input_enter_submit) {",
)

PAGE_FORBIDDEN_SNIPPETS = (
    "else => return self.submitForm(input.asElement(), input.getForm(self), .{}),",
)

WIN32_REQUIRED_SNIPPETS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    "self.pending_text_input_suppressions.deinit(self.allocator);",
    "const defer_enter_submit = std.mem.eql(u8, key, \"Enter\");",
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "page.endDeferredNativeTextInputEnterSubmit();",
    "if (defer_enter_submit and allow_text_input) {",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
    "queuePendingTextInputSuppression(self, key);",
    "if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {",
    "fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {",
    "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
)

WIN32_FORBIDDEN_SNIPPETS = (
    "pending_text_input_suppressions: u32 = 0,",
    "self.pending_text_input_suppressions +|= 1;",
    "if (self.pending_text_input_suppressions > 0) {",
)


def analyze_runtime_contract(page_text: str, win32_text: str) -> list[str]:
    failures: list[str] = []

    for snippet in PAGE_REQUIRED_SNIPPETS:
        if snippet not in page_text:
            failures.append(f"missing Page.zig snippet: {snippet}")
    for snippet in PAGE_FORBIDDEN_SNIPPETS:
        if snippet in page_text:
            failures.append(f"forbidden Page.zig snippet still present: {snippet}")

    for snippet in WIN32_REQUIRED_SNIPPETS:
        if snippet not in win32_text:
            failures.append(f"missing win32_backend.zig snippet: {snippet}")
    for snippet in WIN32_FORBIDDEN_SNIPPETS:
        if snippet in win32_text:
            failures.append(f"forbidden win32_backend.zig snippet still present: {snippet}")

    return failures


def _self_test() -> int:
    vulnerable_page = """
_keyboard_text_suppression_depth: u32 = 0,
else => return self.submitForm(input.asElement(), input.getForm(self), .{}),
"""
    vulnerable_win32 = """
pending_text_input_suppressions: u32 = 0,
self.pending_text_input_suppressions +|= 1;
if (self.pending_text_input_suppressions > 0) {
"""
    vulnerable_failures = analyze_runtime_contract(vulnerable_page, vulnerable_win32)
    if not vulnerable_failures:
        print("self-test expected the vulnerable sample to fail", file=sys.stderr)
        return 1

    fixed_page = """
_keyboard_text_suppression_depth: u32 = 0,
_defer_native_text_input_enter_submit: bool = false,
_pending_native_enter_submit: ?*Element.Html.Input = null,
pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {
    self._defer_native_text_input_enter_submit = true;
}
pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {
    self._defer_native_text_input_enter_submit = false;
}
pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {
    const input = self._pending_native_enter_submit orelse return;
}
if (self._defer_native_text_input_enter_submit) {
    self._pending_native_enter_submit = input;
    return;
}
"""
    fixed_win32 = """
pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},
self.pending_text_input_suppressions.deinit(self.allocator);
const defer_enter_submit = std.mem.eql(u8, key, "Enter");
page.beginDeferredNativeTextInputEnterSubmit();
page.endDeferredNativeTextInputEnterSubmit();
if (defer_enter_submit and allow_text_input) {
    try page.applyDeferredNativeTextInputEnterSubmit();
}
queuePendingTextInputSuppression(self, key);
if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {
    continue;
}
fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {
}
fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {
    return true;
}
"""
    fixed_failures = analyze_runtime_contract(fixed_page, fixed_win32)
    if fixed_failures:
        print("self-test expected the fixed sample to pass", file=sys.stderr)
        for failure in fixed_failures:
            print(failure, file=sys.stderr)
        return 1

    print("self-test passed")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check whether the headed issue #3 Enter-submit runtime patch is present in the source tree."
    )
    parser.add_argument("--page", type=Path, default=Path("src/browser/Page.zig"))
    parser.add_argument("--win32", type=Path, default=Path("src/display/win32_backend.zig"))
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args(argv)

    if args.self_test:
        return _self_test()

    page_text = args.page.read_text(encoding="utf-8")
    win32_text = args.win32.read_text(encoding="utf-8")
    failures = analyze_runtime_contract(page_text, win32_text)
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1

    print("issue #3 Enter-submit runtime contract satisfied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
