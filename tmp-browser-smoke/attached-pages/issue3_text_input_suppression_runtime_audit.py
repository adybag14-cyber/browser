#!/usr/bin/env python3
"""Audit the issue #3 Win32 stale-text suppression runtime contract."""

from __future__ import annotations

import argparse
import json
import sys
import tempfile
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "win32_suppression_queue_is_byte_addressable",
        "path": "src/display/win32_backend.zig",
        "snippet": "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
        "why": (
            "The Win32 backend should track stale text suppressions as concrete "
            "queued text-input events instead of a blind counter."
        ),
    },
    {
        "label": "win32_make_text_input_event_helper_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "fn makeTextInputEvent(bytes: []const u8) ?Win32Backend.TextInputEvent {",
        "why": (
            "The runtime should normalize suppression bytes into the same "
            "TextInputEvent shape used by queued WM_CHAR input."
        ),
    },
    {
        "label": "win32_text_input_match_helper_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "fn textInputEventMatches(expected: Win32Backend.TextInputEvent, actual: []const u8) bool {",
        "why": (
            "The runtime should compare queued stale bytes against later text "
            "input by exact byte content."
        ),
    },
    {
        "label": "win32_queue_helper_uses_normalized_text_event",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {\n"
            "    const text_input = makeTextInputEvent(bytes) orelse return;\n"
        ),
        "why": (
            "Queued stale-text suppression should refuse invalid text shapes "
            "before appending them."
        ),
    },
    {
        "label": "win32_queue_helper_appends_specific_bytes",
        "path": "src/display/win32_backend.zig",
        "snippet": "self.pending_text_input_suppressions.append(self.allocator, text_input) catch {};",
        "why": (
            "The runtime should append the exact stale printable bytes so a "
            "later unrelated WM_CHAR does not get dropped."
        ),
    },
    {
        "label": "win32_dispatch_uses_byte_match_gate",
        "path": "src/display/win32_backend.zig",
        "snippet": "if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {",
        "why": (
            "The later text-input path should consult the byte-match gate "
            "instead of decrementing a raw suppression count."
        ),
    },
    {
        "label": "win32_match_helper_removes_only_matching_entry",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "        if (textInputEventMatches(expected, bytes)) {\n"
            "            const remaining = items[(idx + 1)..];\n"
            "            std.mem.copyForwards(Win32Backend.TextInputEvent, items[0..remaining.len], remaining);\n"
            "            self.pending_text_input_suppressions.items.len = remaining.len;\n"
            "            return true;\n"
            "        }\n"
        ),
        "why": (
            "Matching stale text should remove only the matching queued entry "
            "so later real input can still arrive."
        ),
    },
    {
        "label": "win32_match_helper_clears_queue_on_mismatch",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "    self.pending_text_input_suppressions.clearRetainingCapacity();\n"
            "    return false;\n"
        ),
        "why": (
            "A mismatched later WM_CHAR should flush stale queued bytes so the "
            "real typed text can land and the old suppression does not linger."
        ),
    },
    {
        "label": "win32_queue_reset_clears_retained_bytes",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "    self.pending_high_surrogate = null;\n"
            "    self.ime_composing = false;\n"
            "    self.suppress_wm_char_units = 0;\n"
            "    self.pending_text_input_suppressions.clearRetainingCapacity();\n"
            "}\n"
        ),
        "why": (
            "Resetting backend input state should drop any retained stale-text "
            "queue entries before the next headed input cycle."
        ),
    },
    {
        "label": "win32_mismatched_text_regression_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
        "why": (
            "Regression coverage should prove mismatched stale WM_CHAR bytes do "
            "not erase later real user input."
        ),
    },
    {
        "label": "win32_out_of_order_text_regression_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
        "why": (
            "Regression coverage should prove the queue still suppresses the "
            "right stale bytes even after ordering shifts."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 Win32 stale-text suppression runtime "
            "contract is present in src/display/win32_backend.zig."
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

        missing_label = "win32_match_helper_removes_only_matching_entry"
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
        print(f"[{status}] issue #3 text-input suppression runtime audit")
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
