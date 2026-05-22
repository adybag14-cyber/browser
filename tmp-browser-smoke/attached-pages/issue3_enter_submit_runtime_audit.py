#!/usr/bin/env python3
"""Audit the issue #3 deferred native Enter-submit runtime contract."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "page_deferred_enter_fields_present",
        "path": "src/browser/Page.zig",
        "snippet": "_defer_native_text_input_enter_submit: bool = false,",
        "why": (
            "Page.zig needs an explicit deferred-submit latch so native Enter "
            "does not submit before keypress work finishes on the Google path."
        ),
    },
    {
        "label": "page_pending_enter_pointer_present",
        "path": "src/browser/Page.zig",
        "snippet": "_pending_native_enter_submit: ?*Element.Html.Input = null,",
        "why": (
            "Page.zig should remember the submit-capable input that needs to be "
            "submitted only after the deferred Enter sequence completes."
        ),
    },
    {
        "label": "page_keyboard_text_suppression_depth_present",
        "path": "src/browser/Page.zig",
        "snippet": "_keyboard_text_suppression_depth: u32 = 0,",
        "why": (
            "Page.zig needs keyboard text-suppression depth tracking so the "
            "Win32 keydown path can block duplicate printable text before the "
            "later text-input event arrives."
        ),
    },
    {
        "label": "page_begin_deferred_submit_helper_present",
        "path": "src/browser/Page.zig",
        "snippet": "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
        "why": "The page runtime needs an explicit begin helper for deferred native Enter submit.",
    },
    {
        "label": "page_end_deferred_submit_helper_present",
        "path": "src/browser/Page.zig",
        "snippet": "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
        "why": "The page runtime should clear deferred native Enter state once the dispatch cycle ends.",
    },
    {
        "label": "page_apply_deferred_submit_helper_present",
        "path": "src/browser/Page.zig",
        "snippet": "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
        "why": "The page runtime needs an apply helper that performs the delayed form submit.",
    },
    {
        "label": "page_enter_submit_queues_pending_input",
        "path": "src/browser/Page.zig",
        "snippet": (
            "                        if (self._defer_native_text_input_enter_submit) {\n"
            "                            self._pending_native_enter_submit = input;\n"
            "                            return;\n"
            "                        }\n"
        ),
        "why": (
            "The page Enter path should queue the focused submit-capable input "
            "instead of submitting immediately while native text input is deferred."
        ),
    },
    {
        "label": "page_printable_input_respects_suppression_depth",
        "path": "src/browser/Page.zig",
        "snippet": (
            "        // Handle printable characters\n"
            "        if (!suppress_text and key.isPrintable() and !blocksTextInsertion(keyboard_event)) {\n"
            "            try input.innerInsert(key.asString(), self);\n"
            "        }\n"
        ),
        "why": (
            "The page keydown path should skip direct printable insertion while "
            "native text input is suppressed so stale and real text do not both land."
        ),
    },
    {
        "label": "page_enter_keypress_regression_present",
        "path": "src/browser/Page.zig",
        "snippet": 'test "Page reduced Google fixture defers native Enter submit until keypress" {',
        "why": (
            "A reduced Google fixture regression should prove Enter waits until "
            "keypress before the submit fires."
        ),
    },
    {
        "label": "win32_suppression_queue_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
        "why": (
            "The Win32 backend should queue stale text suppressions by bytes "
            "instead of dropping the next text event blindly."
        ),
    },
    {
        "label": "win32_queue_helper_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {",
        "why": "The Win32 backend should queue the exact stale text bytes after a printable keydown.",
    },
    {
        "label": "win32_matching_suppression_helper_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
        "why": (
            "The Win32 backend should match stale text by bytes so unrelated "
            "real input is not lost."
        ),
    },
    {
        "label": "win32_enter_deferral_begins_before_keypress",
        "path": "src/display/win32_backend.zig",
        "snippet": "                        page.beginDeferredNativeTextInputEnterSubmit();",
        "why": (
            "The Win32 backend should start the page-side Enter deferral before "
            "keypress-compatible text handling runs."
        ),
    },
    {
        "label": "win32_enter_deferral_ends_after_dispatch",
        "path": "src/display/win32_backend.zig",
        "snippet": "                        page.endDeferredNativeTextInputEnterSubmit();",
        "why": (
            "The Win32 backend should always end the page-side Enter deferral "
            "after the dispatch sequence, even when later steps return early."
        ),
    },
    {
        "label": "win32_enter_deferral_applies_after_keypress",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "                        if (defer_enter_submit and allow_text_input) {\n"
            "                            try page.applyDeferredNativeTextInputEnterSubmit();\n"
            "                        }\n"
        ),
        "why": (
            "The Win32 backend should apply the delayed submit only after the "
            "keypress-compatible text path completes."
        ),
    },
    {
        "label": "win32_mismatched_stale_text_regression_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
        "why": (
            "Regression coverage should prove mismatched stale text does not "
            "erase later real input."
        ),
    },
    {
        "label": "win32_out_of_order_stale_text_regression_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
        "why": (
            "Regression coverage should prove matching stale text can still be "
            "suppressed after queue order shifts."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 deferred native Enter-submit runtime "
            "contract is present in Page.zig and win32_backend.zig."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current script's repo.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the full audit summary as JSON.",
    )
    return parser.parse_args()


def audit(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    missing = 0

    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        exists = target.is_file()
        if exists:
            text = target.read_text(encoding="utf-8")
            present = expectation["snippet"] in text
        else:
            present = False
        if not present:
            missing += 1
        checks.append(
            {
                **expectation,
                "exists": exists,
                "present": present,
            }
        )

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(EXPECTATIONS),
        "missing_count": missing,
        "ok": missing == 0,
        "checks": checks,
    }


def main() -> int:
    args = parse_args()
    result = audit(args.repo_root.resolve())

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] issue #3 Enter-submit runtime audit")
        print(f"Repo root: {result['repo_root']}")
        print(
            f"Matched {result['expectation_count'] - result['missing_count']} of "
            f"{result['expectation_count']} expectations."
        )
        for check in result["checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {marker}: {check['label']} ({check['path']})")
            if not check["present"]:
                print(f"  Why: {check['why']}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())