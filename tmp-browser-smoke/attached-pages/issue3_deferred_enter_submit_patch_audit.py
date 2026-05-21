from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from pathlib import Path

PAGE_MARKERS: tuple[str, ...] = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
    "if (self._defer_native_text_input_enter_submit) {",
    'test "Page reduced Google fixture defers native Enter submit until keypress" {',
)

WIN32_MARKERS: tuple[str, ...] = (
    'const defer_enter_submit = std.mem.eql(u8, key, "Enter");',
    "page.beginDeferredNativeTextInputEnterSubmit();",
    "page.endDeferredNativeTextInputEnterSubmit();",
    "if (defer_enter_submit and allow_text_input) {",
    "try page.applyDeferredNativeTextInputEnterSubmit();",
)


@dataclass(frozen=True)
class PatchAudit:
    relative_path: str
    missing_markers: tuple[str, ...]

    @property
    def ok(self) -> bool:
        return not self.missing_markers


def find_missing_markers(text: str, markers: tuple[str, ...]) -> tuple[str, ...]:
    return tuple(marker for marker in markers if marker not in text)


def audit_path(path: str | Path, markers: tuple[str, ...], relative_path: str | None = None) -> PatchAudit:
    file_path = Path(path)
    text = file_path.read_text(encoding="utf-8")
    return PatchAudit(
        relative_path=relative_path or file_path.as_posix(),
        missing_markers=find_missing_markers(text, markers),
    )


def audit_issue3_enter_submit_patch(repo_root: str | Path) -> list[PatchAudit]:
    root = Path(repo_root)
    return [
        audit_path(root / "src/browser/Page.zig", PAGE_MARKERS, "src/browser/Page.zig"),
        audit_path(root / "src/display/win32_backend.zig", WIN32_MARKERS, "src/display/win32_backend.zig"),
    ]


def failing_audits(repo_root: str | Path) -> list[PatchAudit]:
    return [audit for audit in audit_issue3_enter_submit_patch(repo_root) if not audit.ok]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 deferred native Enter-submit patch markers."
    )
    parser.add_argument("repo_root", help="Path to the browser repository root")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of plain text")
    args = parser.parse_args()

    audits = audit_issue3_enter_submit_patch(args.repo_root)
    failures = [audit for audit in audits if not audit.ok]

    if args.json:
        print(json.dumps([asdict(audit) for audit in audits], indent=2))
    else:
        for audit in audits:
            status = "ok" if audit.ok else "missing"
            print(f"{audit.relative_path}: {status}")
            for marker in audit.missing_markers:
                print(f"  - {marker}")

    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
