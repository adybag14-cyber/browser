#!/usr/bin/env python3

"""Summarize whether issue #3 is ready for the next runtime re-entry decision.

This helper is intentionally lightweight. It does not claim that the direct
Page.zig/win32_backend.zig patch can be landed automatically. Instead it keeps
the highest-signal facts on one small surface:

- whether the direct Enter-submit runtime patch markers are already present
- whether the branch-local helper surface for the re-entry route exists
- whether the saved Memory inputs that recent scheduled runs depend on exist
- whether the sibling checkout layout and fallback Zig archive are present

That lets a future run answer "should I reopen the runtime patch, stay on a
smaller helper slice, or repair the environment first?" without rereading the
full runbook stack by hand.
"""

from __future__ import annotations

import argparse
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest


PAGE_PATCH_MARKERS = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
    "self._pending_native_enter_submit = input;",
)

WIN32_PATCH_MARKERS = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    'const defer_enter_submit = std.mem.eql(u8, key, "Enter");',
    "queuePendingTextInputSuppression(self, key);",
    "if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {",
)

HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gates note"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note"),
    ("scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1", "Windows runtime route helper"),
    ("tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py", "runtime contract checker"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved Memory input checker"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness checker"),
)

MEMORY_PATHS: tuple[tuple[str, str], ...] = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    ("repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "saved Rust toolchain archive"),
    ("repo_archives/browser/dependencies/03-boringssl-zig-main.zip", "saved BoringSSL archive"),
    ("repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip", "saved browser dependency archive"),
)

SIBLING_PATHS: tuple[tuple[str, str], ...] = (
    ("../zig-v8-fork", "sibling zig-v8-fork checkout"),
    ("../boringssl-zig", "sibling boringssl-zig checkout"),
)

DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check the compact helper surface around the blocked issue #3 "
            "runtime re-entry path."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: ../memory beside the repo workspace)",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Path to the builder-attached files root (default: ../agent_files beside the repo workspace)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def find_missing_markers(source: str, markers: tuple[str, ...]) -> list[str]:
    return [marker for marker in markers if marker not in source]


def check_paths(base_root: Path, path_specs: tuple[tuple[str, str], ...]) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    for relative_path, label in path_specs:
        path = (base_root / relative_path).resolve()
        results.append(
            {
                "path": relative_path,
                "label": label,
                "exists": path.exists(),
            }
        )
    return results


def count_missing(entries: list[dict[str, object]]) -> int:
    return sum(1 for entry in entries if not entry["exists"])


def collect_results(
    *,
    repo_root: Path,
    memory_root: Path,
    agent_files_root: Path,
) -> dict[str, object]:
    page_path = repo_root / "src/browser/Page.zig"
    win32_path = repo_root / "src/display/win32_backend.zig"

    page_source = page_path.read_text(encoding="utf-8")
    win32_source = win32_path.read_text(encoding="utf-8")

    page_missing = find_missing_markers(page_source, PAGE_PATCH_MARKERS)
    win32_missing = find_missing_markers(win32_source, WIN32_PATCH_MARKERS)
    patch_landed = not page_missing and not win32_missing

    helper_surface = check_paths(repo_root, HELPER_SURFACE_PATHS)
    memory_surface = check_paths(memory_root, MEMORY_PATHS) if memory_root.exists() else [
        {"path": relative_path, "label": label, "exists": False}
        for relative_path, label in MEMORY_PATHS
    ]
    sibling_surface = check_paths(repo_root, SIBLING_PATHS)

    fallback_zig_archive = agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE
    fallback_zig_present = fallback_zig_archive.is_file()

    helper_surface_complete = count_missing(helper_surface) == 0
    memory_surface_complete = count_missing(memory_surface) == 0
    sibling_surface_complete = count_missing(sibling_surface) == 0

    if patch_landed:
        recommended_state = "runtime-patch-already-landed"
    elif helper_surface_complete and memory_surface_complete:
        recommended_state = "runtime-patch-still-missing"
    else:
        recommended_state = "reentry-surface-incomplete"

    next_commands = [
        (
            "runtime_contract",
            "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py "
            "--page src/browser/Page.zig --win32 src/display/win32_backend.zig",
        ),
        (
            "saved_memory_inputs",
            "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
        ),
        (
            "linux_build_readiness",
            "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
        ),
        (
            "windows_runtime_route",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1",
        ),
    ]

    return {
        "ok": helper_surface_complete and memory_surface_complete,
        "recommended_state": recommended_state,
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "agent_files_root": str(agent_files_root),
        "page_patch_missing_markers": page_missing,
        "win32_patch_missing_markers": win32_missing,
        "patch_landed": patch_landed,
        "helper_surface": helper_surface,
        "memory_surface": memory_surface,
        "sibling_surface": sibling_surface,
        "fallback_zig_archive": {
            "path": str(fallback_zig_archive),
            "exists": fallback_zig_present,
        },
        "writable_publication_path": "manual-check-required",
        "next_commands": next_commands,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"ISSUE3_RUNTIME_REENTRY_READY={'pass' if result['ok'] else 'fail'}")
    print(f"ISSUE3_RUNTIME_REENTRY_STATE={result['recommended_state']}")
    print(f"ISSUE3_RUNTIME_PATCH_LANDED={'yes' if result['patch_landed'] else 'no'}")
    print(f"ISSUE3_RUNTIME_PAGE_MISSING_MARKER_COUNT={len(result['page_patch_missing_markers'])}")
    for marker in result["page_patch_missing_markers"]:
        print(f"ISSUE3_RUNTIME_PAGE_MISSING_MARKER={marker}")
    print(f"ISSUE3_RUNTIME_WIN32_MISSING_MARKER_COUNT={len(result['win32_patch_missing_markers'])}")
    for marker in result["win32_patch_missing_markers"]:
        print(f"ISSUE3_RUNTIME_WIN32_MISSING_MARKER={marker}")

    for label, entries in (
        ("HELPER_SURFACE", result["helper_surface"]),
        ("MEMORY_SURFACE", result["memory_surface"]),
        ("SIBLING_SURFACE", result["sibling_surface"]),
    ):
        print(f"{label}_MISSING_COUNT={count_missing(entries)}")
        for entry in entries:
            status = "pass" if entry["exists"] else "fail"
            print(f"{label}_{status.upper()}={entry['path']}|{entry['label']}")

    print(
        "FALLBACK_ZIG_ARCHIVE={status}|{path}".format(
            status="pass" if result["fallback_zig_archive"]["exists"] else "fail",
            path=result["fallback_zig_archive"]["path"],
        )
    )
    print(f"WRITABLE_PUBLICATION_PATH={result['writable_publication_path']}")
    for name, command in result["next_commands"]:
        print(f"NEXT_COMMAND_{name.upper()}={command}")



def run_self_test(json_output: bool) -> int:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReadinessSelfTest)
    result = unittest.TextTestRunner(stream=io.StringIO(), verbosity=0).run(suite)
    ok = result.wasSuccessful()
    if json_output:
        print(json.dumps({"self_test": "pass" if ok else "fail", "cases": result.testsRun}, indent=2))
    else:
        print(f"ISSUE3_RUNTIME_REENTRY_READINESS_SELF_TEST={'pass' if ok else 'fail'}")
        print(f"ISSUE3_RUNTIME_REENTRY_READINESS_SELF_TEST_CASES={result.testsRun}")
    return 0 if ok else 1


class ReadinessSelfTest(unittest.TestCase):
    def create_tree(self, root: Path, *, landed: bool, helper_surface: bool, memory_surface: bool) -> tuple[Path, Path, Path]:
        repo_root = root / "browser"
        memory_root = root / "memory"
        agent_files_root = root / "agent_files"

        (repo_root / "src/browser").mkdir(parents=True, exist_ok=True)
        (repo_root / "src/display").mkdir(parents=True, exist_ok=True)
        if helper_surface:
            for relative_path, _label in HELPER_SURFACE_PATHS:
                path = repo_root / relative_path
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("helper\n", encoding="utf-8")
        else:
            (repo_root / "docs").mkdir(parents=True, exist_ok=True)

        for relative_path, _label in MEMORY_PATHS:
            path = memory_root / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            if memory_surface:
                path.write_text("memory\n", encoding="utf-8")

        for relative_path, _label in SIBLING_PATHS:
            path = (repo_root / relative_path).resolve()
            path.mkdir(parents=True, exist_ok=True)

        (agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE).parent.mkdir(parents=True, exist_ok=True)
        (agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE).write_text("zig\n", encoding="utf-8")

        page_text = "\n".join(PAGE_PATCH_MARKERS if landed else PAGE_PATCH_MARKERS[:1])
        win32_text = "\n".join(WIN32_PATCH_MARKERS if landed else WIN32_PATCH_MARKERS[:1])
        (repo_root / "src/browser/Page.zig").write_text(page_text, encoding="utf-8")
        (repo_root / "src/display/win32_backend.zig").write_text(win32_text, encoding="utf-8")
        return repo_root, memory_root, agent_files_root

    def test_reports_missing_patch_when_helper_surface_is_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root, memory_root, agent_files_root = self.create_tree(
                Path(tmp_dir),
                landed=False,
                helper_surface=True,
                memory_surface=True,
            )
            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
            )
            self.assertTrue(result["ok"])
            self.assertFalse(result["patch_landed"])
            self.assertEqual("runtime-patch-still-missing", result["recommended_state"])

    def test_reports_landed_patch_when_markers_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root, memory_root, agent_files_root = self.create_tree(
                Path(tmp_dir),
                landed=True,
                helper_surface=True,
                memory_surface=True,
            )
            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
            )
            self.assertTrue(result["ok"])
            self.assertTrue(result["patch_landed"])
            self.assertEqual("runtime-patch-already-landed", result["recommended_state"])

    def test_reports_incomplete_surface_when_memory_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root, memory_root, agent_files_root = self.create_tree(
                Path(tmp_dir),
                landed=False,
                helper_surface=True,
                memory_surface=False,
            )
            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
            )
            self.assertFalse(result["ok"])
            self.assertEqual("reentry-surface-incomplete", result["recommended_state"])



def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.self_test:
        return run_self_test(args.json)

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    agent_files_root = (
        Path(args.agent_files_root).resolve()
        if args.agent_files_root
        else resolve_default_agent_files_root(repo_root)
    )

    result = collect_results(
        repo_root=repo_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
    )

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
