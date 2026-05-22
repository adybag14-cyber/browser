#!/usr/bin/env python3
"""Check the exact issue #3 Enter-submit patch contract across both Zig files."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "page_apply_helper_requires_same_focused_input",
        "path": "src/browser/Page.zig",
        "snippet": (
            "    const focused = self.document.getFocusedElement() orelse return;\n"
            "    if (focused.asNode() != input.asNode()) {\n"
            "        return;\n"
            "    }\n"
        ),
        "why": (
            "The deferred Enter submit helper should re-check the currently focused "
            "input before submitting so the queued native Enter does not submit the "
            "wrong control."
        ),
    },
    {
        "label": "page_apply_helper_submits_queued_form",
        "path": "src/browser/Page.zig",
        "snippet": "    try self.submitForm(input.asElement(), input.getForm(self), .{});\n",
        "why": (
            "The deferred Enter submit helper should still execute the form submit "
            "once the keypress-compatible text path has finished."
        ),
    },
    {
        "label": "page_deferred_enter_test_keeps_keydown_unsent",
        "path": "src/browser/Page.zig",
        "snippet": '    try testing.expect(std.mem.startsWith(u8, keydown_title, "KEYDOWN:n|"));\n',
        "why": (
            "The reduced Google fixture should prove Enter does not submit during "
            "keydown while native text input is being deferred."
        ),
    },
    {
        "label": "page_deferred_enter_test_submits_after_keypress",
        "path": "src/browser/Page.zig",
        "snippet": '    try testing.expect(std.mem.startsWith(u8, submit_title, "SUBMIT:n|"));\n',
        "why": (
            "The reduced Google fixture should prove the queued submit still fires "
            "after the keypress-compatible path runs."
        ),
    },
    {
        "label": "win32_keydown_queues_exact_text_bytes",
        "path": "src/display/win32_backend.zig",
        "snippet": "                        queuePendingTextInputSuppression(self, key);\n",
        "why": (
            "The Win32 keydown path should queue the exact stale text bytes it "
            "expects to suppress later."
        ),
    },
    {
        "label": "win32_text_input_matches_queued_bytes",
        "path": "src/display/win32_backend.zig",
        "snippet": "                    if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {\n",
        "why": (
            "The Win32 text-input path should suppress only the queued matching "
            "bytes instead of dropping the next text event blindly."
        ),
    },
    {
        "label": "win32_make_text_input_event_helper_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "fn makeTextInputEvent(bytes: []const u8) ?Win32Backend.TextInputEvent {\n",
        "why": (
            "The Win32 backend should normalize queued stale-text bytes through a "
            "dedicated helper before storing them."
        ),
    },
    {
        "label": "win32_matching_helper_clears_stale_queue_on_miss",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            "    self.pending_text_input_suppressions.clearRetainingCapacity();\n"
            "    return false;\n"
        ),
        "why": (
            "The Win32 stale-text matcher should flush the queue on a miss so old "
            "suppression entries do not poison later real text input."
        ),
    },
    {
        "label": "win32_mismatched_real_text_regression_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {\n',
        "why": (
            "Regression coverage should prove mismatched stale text leaves later "
            "real text intact."
        ),
    },
    {
        "label": "win32_out_of_order_stale_text_regression_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {\n',
        "why": (
            "Regression coverage should prove a matching stale text event is still "
            "suppressed even after queue order shifts."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 Enter-submit patch contract is present in "
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
        help="Emit the full contract summary as JSON.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run embedded fixture checks instead of auditing a real repo.",
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
        checks.append({**expectation, "exists": exists, "present": present})

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(EXPECTATIONS),
        "missing_count": missing,
        "ok": missing == 0,
        "checks": checks,
    }


def render_fixture_file(relative_path: str, *, missing_label: str | None = None) -> str:
    parts = [f"// synthetic {relative_path} fixture"]
    for expectation in EXPECTATIONS:
        if expectation["path"] != relative_path:
            continue
        if expectation["label"] == missing_label:
            continue
        parts.append(expectation["snippet"])
    return "".join(parts) if relative_path.endswith(".zig") else "\n".join(parts) + "\n"


def run_self_test() -> int:
    from tempfile import TemporaryDirectory

    grouped_paths = sorted({expectation["path"] for expectation in EXPECTATIONS})

    with TemporaryDirectory() as tmp_dir:
        repo_root = Path(tmp_dir)
        for relative_path in grouped_paths:
            target = repo_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(render_fixture_file(relative_path), encoding="utf-8")

        result = audit(repo_root)
        if not result["ok"]:
            print("self-test failed: expected full synthetic fixture to pass", file=sys.stderr)
            return 1

    with TemporaryDirectory() as tmp_dir:
        repo_root = Path(tmp_dir)
        for relative_path in grouped_paths:
            target = repo_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(
                render_fixture_file(
                    relative_path,
                    missing_label="win32_text_input_matches_queued_bytes"
                    if relative_path.endswith("win32_backend.zig")
                    else None,
                ),
                encoding="utf-8",
            )

        result = audit(repo_root)
        if result["ok"] or result["missing_count"] != 1:
            print("self-test failed: expected one missing Win32 contract", file=sys.stderr)
            return 1

    print("self-test passed")
    return 0


def main() -> int:
    args = parse_args()
    if args.self_test:
        return run_self_test()

    result = audit(args.repo_root.resolve())

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] issue #3 Enter-submit patch contract")
        print(f"Repo root: {result['repo_root']}")
        print(
            f"Matched {result['expectation_count'] - result['missing_count']} of "
            f"{result['expectation_count']} expectations."
        )
        for check in result["checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {check['label']}: {marker}")
            if not check["present"]:
                print(f"  why: {check['why']}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())