#!/usr/bin/env python3

from __future__ import annotations

import argparse
import pathlib
import sys
import tempfile


PAGE_PATH = pathlib.Path("src/browser/Page.zig")
WIN32_PATH = pathlib.Path("src/display/win32_backend.zig")

PAGE_MARKERS = (
    "_defer_native_text_input_enter_submit: bool = false,",
    "_pending_native_enter_submit: ?*Element.Html.Input = null,",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
    "if (self._defer_native_text_input_enter_submit) {",
    "self._pending_native_enter_submit = input;",
    'test "Page reduced Google fixture defers native Enter submit until keypress" {',
)

WIN32_MARKERS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "page.endDeferredNativeTextInputEnterSubmit();",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
    "queuePendingTextInputSuppression(self, key);",
    "if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {",
    "fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {",
    "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
    'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
    'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
)


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="strict")


def missing_markers(text: str, markers: tuple[str, ...]) -> list[str]:
    return [marker for marker in markers if marker not in text]


def verify_paths(page: pathlib.Path, win32: pathlib.Path) -> int:
    missing_inputs = [str(path) for path in (page, win32) if not path.is_file()]
    if missing_inputs:
        print("ISSUE3_ENTER_SUBMIT_RUNTIME_PATCH=missing-inputs")
        for path in missing_inputs:
            print(f"MISSING_INPUT={path}")
        return 2

    page_text = read_text(page)
    win32_text = read_text(win32)

    page_missing = missing_markers(page_text, PAGE_MARKERS)
    win32_missing = missing_markers(win32_text, WIN32_MARKERS)

    if page_missing or win32_missing:
        print("ISSUE3_ENTER_SUBMIT_RUNTIME_PATCH=fail")
        print(f"PAGE_PATH={page}")
        print(f"WIN32_PATH={win32}")
        for marker in page_missing:
            print(f"PAGE_MISSING={marker}")
        for marker in win32_missing:
            print(f"WIN32_MISSING={marker}")
        print(f"PAGE_MARKER_COUNT={len(PAGE_MARKERS) - len(page_missing)}/{len(PAGE_MARKERS)}")
        print(f"WIN32_MARKER_COUNT={len(WIN32_MARKERS) - len(win32_missing)}/{len(WIN32_MARKERS)}")
        return 1

    print("ISSUE3_ENTER_SUBMIT_RUNTIME_PATCH=pass")
    print(f"PAGE_PATH={page}")
    print(f"WIN32_PATH={win32}")
    print(f"PAGE_MARKER_COUNT={len(PAGE_MARKERS)}")
    print(f"WIN32_MARKER_COUNT={len(WIN32_MARKERS)}")
    return 0


def verify_root(root: pathlib.Path) -> int:
    return verify_paths(root / PAGE_PATH, root / WIN32_PATH)


def write_sample_root(root: pathlib.Path) -> None:
    (root / PAGE_PATH).parent.mkdir(parents=True, exist_ok=True)
    (root / WIN32_PATH).parent.mkdir(parents=True, exist_ok=True)
    (root / PAGE_PATH).write_text("\n".join(PAGE_MARKERS) + "\n", encoding="utf-8")
    (root / WIN32_PATH).write_text("\n".join(WIN32_MARKERS) + "\n", encoding="utf-8")


def run_self_test() -> int:
    with tempfile.TemporaryDirectory(prefix="issue3-enter-submit-selftest-") as tmpdir:
        root = pathlib.Path(tmpdir)
        write_sample_root(root)
        result = verify_root(root)
        if result != 0:
            print("ISSUE3_ENTER_SUBMIT_RUNTIME_PATCH_SELF_TEST=fail")
            return result

        result = verify_paths(root / PAGE_PATH, root / WIN32_PATH)
        if result != 0:
            print("ISSUE3_ENTER_SUBMIT_RUNTIME_PATCH_SELF_TEST=fail")
            return result
    print("ISSUE3_ENTER_SUBMIT_RUNTIME_PATCH_SELF_TEST=pass")
    print("ISSUE3_ENTER_SUBMIT_RUNTIME_PATCH_SELF_TEST_CASE_COUNT=2")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check whether the issue #3 Enter-submit runtime patch markers are present."
    )
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path.cwd())
    parser.add_argument("--page", type=pathlib.Path)
    parser.add_argument("--win32", type=pathlib.Path)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--write-sample-root", type=pathlib.Path)
    args = parser.parse_args()
    if (args.page is None) != (args.win32 is None):
        parser.error("--page and --win32 must be provided together")
    return args


def main() -> int:
    args = parse_args()
    if args.self_test:
        return run_self_test()
    if args.write_sample_root is not None:
        write_sample_root(args.write_sample_root)
        print(f"ISSUE3_ENTER_SUBMIT_RUNTIME_PATCH_SAMPLE_ROOT={args.write_sample_root}")
        return 0
    if args.page is not None and args.win32 is not None:
        return verify_paths(args.page, args.win32)
    return verify_root(args.root)


if __name__ == "__main__":
    sys.exit(main())
