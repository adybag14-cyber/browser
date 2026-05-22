#!/usr/bin/env python3
"""Audit issue #3 Enter-submit runtime safeguards for headed Google input."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "page_deferred_enter_state_present",
        "path": "src/browser/Page.zig",
        "snippet": (
            "_keyboard_text_suppression_depth: u32 = 0,\n"
            "_defer_native_text_input_enter_submit: bool = false,\n"
            "_pending_native_enter_submit: ?*Element.Html.Input = null,"
        ),
        "why": (
            "Page state needs an explicit deferred native Enter-submit flag and pending "
            "input pointer so keydown and keypress can be coordinated on the Google path."
        ),
    },
    {
        "label": "page_deferred_enter_helpers_present",
        "path": "src/browser/Page.zig",
        "snippet": (
            "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {\n"
            "    self._defer_native_text_input_enter_submit = true;\n"
            "    self._pending_native_enter_submit = null;\n"
            "}\n\n"
            "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {\n"
            "    self._defer_native_text_input_enter_submit = false;\n"
            "    self._pending_native_enter_submit = null;\n"
            "}\n\n"
            "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {"
        ),
        "why": (
            "The page-side Enter-submit flow should expose explicit begin/end/apply helpers "
            "so the Win32 backend can defer submit until keypress has had a chance to run."
        ),
    },
    {
        "label": "page_enter_submit_defers_until_keypress",
        "path": "src/browser/Page.zig",
        "snippet": (
            "                    else => {\n"
            "                        if (self._defer_native_text_input_enter_submit) {\n"
            "                            self._pending_native_enter_submit = input;\n"
            "                            return;\n"
            "                        }\n"
            "                        return self.submitForm(input.asElement(), input.getForm(self), .{});\n"
            "                    },"
        ),
        "why": (
            "Submit-capable text inputs should defer native Enter activation until the keypress "
            "phase instead of submitting immediately on keydown."
        ),
    },
    {
        "label": "page_google_fixture_deferred_submit_test_present",
        "path": "src/browser/Page.zig",
        "snippet": 'test "Page reduced Google fixture defers native Enter submit until keypress" {',
        "why": (
            "The reduced Google fixture should keep a focused regression that proves Enter stays "
            "on KEYDOWN first and only reaches SUBMIT after keypress."
        ),
    },
    {
        "label": "win32_text_suppression_queue_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
        "why": (
            "Win32 text suppression should track queued byte-matched stale text entries rather "
            "than a single scalar counter."
        ),
    },
    {
        "label": "win32_enter_submit_deferral_wired",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "                    const defer_enter_submit = std.mem.eql(u8, key, \"Enter\");\n"
            "                    if (defer_enter_submit) {\n"
            "                        page.beginDeferredNativeTextInputEnterSubmit();\n"
            "                    }\n"
            "                    defer if (defer_enter_submit) {\n"
            "                        page.endDeferredNativeTextInputEnterSubmit();\n"
            "                    };"
        ),
        "why": (
            "The Win32 keydown pipeline should explicitly bracket native Enter handling with the "
            "page-side deferral helpers."
        ),
    },
    {
        "label": "win32_matching_text_suppression_queue_used",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "                        queuePendingTextInputSuppression(self, key);\n"
        ),
        "why": (
            "Printable keydown text should enqueue a matching suppression token instead of blindly "
            "dropping the next text_input event."
        ),
    },
    {
        "label": "win32_matching_text_suppression_helper_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
        "why": (
            "The backend needs a byte-matched suppression helper so stale text is suppressed only "
            "when it matches the queued keydown text."
        ),
    },
    {
        "label": "win32_mismatched_stale_text_test_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
        "why": (
            "Coverage should keep mismatched stale text from being suppressed accidentally."
        ),
    },
    {
        "label": "win32_out_of_order_stale_text_test_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
        "why": (
            "Coverage should keep the queued suppression logic honest when stale text arrives out of order."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue-3 Enter-submit runtime patch is still missing from "
            "Page.zig and win32_backend.zig."
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
        print(f"[{status}] issue #3 enter-submit runtime audit")
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
