#!/usr/bin/env python3
"""Audit the issue #3 deferred native Enter-submit runtime contract."""

from __future__ import annotations

import argparse
import json
import sys
import tempfile
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
        "label": "page_apply_deferred_submit_rechecks_focus",
        "path": "src/browser/Page.zig",
        "snippet": (
            "    const focused = self.document.getFocusedElement() orelse return;\n"
            "    if (focused.asNode() != input.asNode()) {\n"
            "        return;\n"
            "    }\n"
        ),
        "why": (
            "The deferred Enter apply helper should re-check the focused input so "
            "a stale queued submit does not fire after focus has moved elsewhere."
        ),
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
        "label": "win32_suppression_queue_deinit_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "self.pending_text_input_suppressions.deinit(self.allocator);",
        "why": (
            "The Win32 backend should release queued stale-text suppression "
            "storage during teardown so old queue state does not linger."
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
        "label": "win32_queue_helper_wiring_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "                        queuePendingTextInputSuppression(self, key);",
        "why": (
            "The printable keydown dispatch path should actually queue the stale "
            "text bytes instead of leaving the byte-aware helper unused."
        ),
    },
    {
        "label": "win32_text_input_suppression_uses_byte_match",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "                    if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {\n"
            "                        continue;\n"
            "                    }\n"
        ),
        "why": (
            "The text-input dispatch path should use byte-matched suppression so "
            "real later WM_CHAR input is not dropped by a stale counter."
        ),
    },
    {
        "label": "win32_suppression_queue_reset_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "self.pending_text_input_suppressions.clearRetainingCapacity();",
        "why": (
            "The Win32 backend should clear queued stale-text suppressions when "
            "input state resets so old WM_CHAR matches do not bleed into later sessions."
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
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run an embedded audit self-test instead of reading a repository checkout.",
    )
    return parser.parse_args()


def render_file(relative_path: str, *, missing_label: str | None = None) -> str:
    parts = [f"// synthetic {relative_path} fixture"]
    for expectation in EXPECTATIONS:
        if expectation["path"] != relative_path:
            continue
        if expectation["label"] == missing_label:
            continue
        parts.append(expectation["snippet"])
    return "\n".join(parts) + "\n"


def render_repo(repo_root: Path, *, missing_label: str | None = None) -> None:
    grouped_paths = sorted({expectation["path"] for expectation in EXPECTATIONS})
    for relative_path in grouped_paths:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            render_file(relative_path, missing_label=missing_label),
            encoding="utf-8",
        )


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


def run_self_test() -> tuple[bool, list[str]]:
    details: list[str] = []

    with tempfile.TemporaryDirectory() as tmp_dir:
        repo_root = Path(tmp_dir)
        render_repo(repo_root)

        pass_result = audit(repo_root)
        if not pass_result["ok"]:
            details.append("full synthetic fixture unexpectedly failed")

        missing_label = "win32_enter_deferral_applies_after_keypress"
        render_repo(repo_root, missing_label=missing_label)
        fail_result = audit(repo_root)
        if fail_result["ok"]:
            details.append("missing-label synthetic fixture unexpectedly passed")
        else:
            failed = next(check for check in fail_result["checks"] if not check["present"])
            if failed["label"] != missing_label:
                details.append(
                    f"missing-label synthetic fixture failed on {failed['label']} instead of {missing_label}"
                )

    return (len(details) == 0, details)


def main() -> int:
    args = parse_args()

    if args.self_test:
        ok, details = run_self_test()
        print(f"SELF_TEST={'pass' if ok else 'fail'}")
        if ok:
            print("DETAIL=synthetic full and missing-label fixtures behaved as expected")
            return 0
        for detail in details:
            print(f"DETAIL={detail}")
        return 1

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