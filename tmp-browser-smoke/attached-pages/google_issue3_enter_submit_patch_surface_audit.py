#!/usr/bin/env python3
"""Audit whether the issue #3 Enter-submit patch surface is present."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "page_deferred_enter_fields",
        "path": "src/browser/Page.zig",
        "snippet": "_defer_native_text_input_enter_submit: bool = false,",
        "why": "Page state needs an explicit defer flag for native Enter-submit ordering.",
    },
    {
        "label": "page_pending_enter_pointer",
        "path": "src/browser/Page.zig",
        "snippet": "_pending_native_enter_submit: ?*Element.Html.Input = null,",
        "why": "Page state needs to remember the focused input queued for deferred submit.",
    },
    {
        "label": "page_begin_deferred_helper",
        "path": "src/browser/Page.zig",
        "snippet": "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
        "why": "Page needs a helper to begin native Enter-submit deferral.",
    },
    {
        "label": "page_apply_deferred_helper",
        "path": "src/browser/Page.zig",
        "snippet": "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
        "why": "Page needs a helper to replay deferred native Enter submit after keypress.",
    },
    {
        "label": "page_pending_submit_branch",
        "path": "src/browser/Page.zig",
        "snippet": "self._pending_native_enter_submit = input;",
        "why": "The Enter path must queue the focused input instead of submitting too early.",
    },
    {
        "label": "page_google_fixture_regression",
        "path": "src/browser/Page.zig",
        "snippet": "test \"Page reduced Google fixture defers native Enter submit until keypress\" {",
        "why": "The reduced Google fixture regression should lock the intended ordering.",
    },
    {
        "label": "win32_pending_suppression_queue",
        "path": "src/display/win32_backend.zig",
        "snippet": "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
        "why": "Win32 needs the stale-text suppression queue for delayed WM_CHAR handling.",
    },
    {
        "label": "win32_enter_deferral_flag",
        "path": "src/display/win32_backend.zig",
        "snippet": "const defer_enter_submit = std.mem.eql(u8, key, \"Enter\");",
        "why": "Win32 keydown processing should recognize the native Enter deferral path.",
    },
    {
        "label": "win32_begin_deferred_helper",
        "path": "src/display/win32_backend.zig",
        "snippet": "page.beginDeferredNativeTextInputEnterSubmit();",
        "why": "Win32 keydown handling must open the deferred submit window before keypress.",
    },
    {
        "label": "win32_apply_deferred_helper",
        "path": "src/display/win32_backend.zig",
        "snippet": "try page.applyDeferredNativeTextInputEnterSubmit();",
        "why": "Win32 keypress handling must replay deferred submit after text input is allowed.",
    },
    {
        "label": "win32_stale_text_regression",
        "path": "src/display/win32_backend.zig",
        "snippet": "test \"win32 dispatchInput allows later real text when stale suppression bytes do not match\" {",
        "why": "The stale WM_CHAR suppression regression should stay present with the Enter fix.",
    },
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 Enter-submit and stale-text suppression patch "
            "surface is present in the current browser checkout."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
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
        print(f"[{status}] issue #3 Enter-submit patch surface audit")
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
