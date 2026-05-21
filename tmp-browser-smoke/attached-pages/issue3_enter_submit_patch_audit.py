#!/usr/bin/env python3
"""Audit issue #3 Enter-submit safeguard snippets for headed Google input."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "page_deferred_enter_fields_present",
        "path": "src/browser/Page.zig",
        "snippet": (
            "_defer_native_text_input_enter_submit: bool = false,\n"
            "_pending_native_enter_submit: ?*Element.Html.Input = null,"
        ),
        "why": (
            "The page runtime needs explicit deferred-submit state so native Enter "
            "input can wait until text input finishes."
        ),
    },
    {
        "label": "page_deferred_enter_helpers_present",
        "path": "src/browser/Page.zig",
        "snippet": (
            "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {\n"
            "    self._defer_native_text_input_enter_submit = true;\n"
            "    self._pending_native_enter_submit = null;\n"
            "}\n"
            "\n"
            "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {\n"
            "    self._defer_native_text_input_enter_submit = false;\n"
            "    self._pending_native_enter_submit = null;\n"
            "}\n"
            "\n"
            "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {\n"
        ),
        "why": (
            "The deferred native Enter-submit helpers are the narrow issue-specific "
            "bridge that keeps submit ordering aligned with later keypress/text input."
        ),
    },
    {
        "label": "page_enter_submit_defers_text_inputs",
        "path": "src/browser/Page.zig",
        "snippet": (
            "                        if (self._defer_native_text_input_enter_submit) {\n"
            "                            self._pending_native_enter_submit = input;\n"
            "                            return;\n"
            "                        }\n"
            "                        return self.submitForm(input.asElement(), input.getForm(self), .{});"
        ),
        "why": (
            "Enter on text-like inputs should queue submit while native text input "
            "is still in flight instead of submitting too early."
        ),
    },
    {
        "label": "win32_text_suppression_queue_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
        "why": (
            "The Win32 backend needs queue-based stale-text suppression so deferred "
            "Enter does not swallow later real WM_CHAR input."
        ),
    },
    {
        "label": "win32_enter_deferral_wraps_native_key_dispatch",
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
            "The Win32 keydown path should bracket Enter with deferred-submit state "
            "so Google receives text input before submit."
        ),
    },
    {
        "label": "win32_enter_deferral_applies_after_text_input",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "                        if (defer_enter_submit and allow_text_input) {\n"
            "                            try page.applyDeferredNativeTextInputEnterSubmit();\n"
            "                        }"
        ),
        "why": (
            "After native text input is allowed through, the backend should apply "
            "the deferred Enter submit explicitly."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the live browser sources contain the issue #3 deferred "
            "Enter-submit safeguards for headed Google input."
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
        print(f"[{status}] issue #3 Enter-submit patch audit")
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