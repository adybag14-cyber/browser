#!/usr/bin/env python3
"""Audit whether the headed Google Enter-submit patch is present."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "page_deferred_enter_submit_flag",
        "path": "src/browser/Page.zig",
        "snippet": "_defer_native_text_input_enter_submit: bool = false,",
        "why": "Page.zig should keep a deferred Enter-submit flag for native text input ordering.",
    },
    {
        "label": "page_pending_enter_submit_pointer",
        "path": "src/browser/Page.zig",
        "snippet": "_pending_native_enter_submit: ?*Element.Html.Input = null,",
        "why": "Page.zig should retain the focused input until the deferred Enter submit is applied.",
    },
    {
        "label": "page_begin_deferred_enter_submit_helper",
        "path": "src/browser/Page.zig",
        "snippet": "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
        "why": "Page.zig should expose the helper that starts deferred native Enter submit handling.",
    },
    {
        "label": "page_apply_deferred_enter_submit_helper",
        "path": "src/browser/Page.zig",
        "snippet": "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
        "why": "Page.zig should expose the helper that applies the deferred native Enter submit after keypress.",
    },
    {
        "label": "page_submit_deferral_guard",
        "path": "src/browser/Page.zig",
        "snippet": "if (self._defer_native_text_input_enter_submit) {",
        "why": "The Enter-submit path should defer native text-input submission while keypress still needs to run.",
    },
    {
        "label": "page_google_fixture_regression",
        "path": "src/browser/Page.zig",
        "snippet": "test \"Page reduced Google fixture defers native Enter submit until keypress\" {",
        "why": "The reduced Google fixture regression should prove submit waits until keypress.",
    },
    {
        "label": "win32_defer_enter_submit_switch",
        "path": "src/display/win32_backend.zig",
        "snippet": "const defer_enter_submit = std.mem.eql(u8, key, \"Enter\");",
        "why": "The Win32 backend should recognize Enter as the key that needs deferred native submit handling.",
    },
    {
        "label": "win32_begin_deferred_enter_submit",
        "path": "src/display/win32_backend.zig",
        "snippet": "page.beginDeferredNativeTextInputEnterSubmit();",
        "why": "The Win32 keydown path should start deferred native Enter submit handling before keypress runs.",
    },
    {
        "label": "win32_apply_deferred_enter_submit",
        "path": "src/display/win32_backend.zig",
        "snippet": "try page.applyDeferredNativeTextInputEnterSubmit();",
        "why": "The Win32 backend should apply deferred Enter submit after the keypress path allows text input.",
    },
    {
        "label": "win32_stale_text_suppression_regression",
        "path": "src/display/win32_backend.zig",
        "snippet": "test \"win32 dispatchInput allows later real text when stale suppression bytes do not match\" {",
        "why": "The Win32 backend should keep the byte-matched stale text suppression regression that protects later real input.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the headed Google Enter-submit patch is present in "
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
        print(f"[{status}] headed Google Enter-submit patch audit")
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
