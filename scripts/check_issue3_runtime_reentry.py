#!/usr/bin/env python3

"""Check whether the issue #3 runtime re-entry path is ready to reopen.

This helper is intentionally lightweight and cross-platform. It does not try to
build the browser by itself. Instead it answers four practical questions:

1. Is there a real writable checkout for landing the narrowed runtime patch?
2. Are the branch-local docs and helper surfaces for the narrowed issue #3 path
   present?
3. Does the current source tree already contain the direct Page.zig and Win32
   runtime bridge markers?
4. Is the Linux/WSL preflight surface ready enough to trust a later Zig-driven
   replay?

That gives future runs one compact place to check the re-entry route before
reopening the blocked Page.zig and win32_backend.zig patch again.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import unittest
from dataclasses import asdict, dataclass
from pathlib import Path
from unittest import mock


REFERENCE_FILES = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note"),
    ("docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md", "top-level headed execution guide"),
    ("docs/WINDOWS_FULL_USE.md", "Windows headed runbook"),
    ("scripts/check_linux_build_readiness.py", "Linux/WSL build-readiness helper"),
    (
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "Windows-side issue #3 surface checker",
    ),
    (
        "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "Windows-side replay route helper",
    ),
    (
        "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
        "source-based runtime contract checker",
    ),
    (
        "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "reduced Google title probe",
    ),
    ("src/browser/Page.zig", "direct browser-side runtime target"),
    ("src/display/win32_backend.zig", "direct Win32 runtime target"),
)


@dataclass
class CheckResult:
    name: str
    ok: bool
    detail: str
    command: str | None = None


def repo_root_from(start: Path) -> Path:
    cursor = start.resolve()
    if cursor.is_file():
        cursor = cursor.parent
    while True:
        if (cursor / "build.zig").is_file():
            return cursor
        parent = cursor.parent
        if parent == cursor:
            raise FileNotFoundError("could not resolve repo root from the provided path")
        cursor = parent


def run_command(command: list[str], cwd: Path) -> tuple[bool, str]:
    try:
        completed = subprocess.run(
            command,
            cwd=cwd,
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError as exc:
        return False, f"command not found: {exc.filename}"

    output = (completed.stdout or "").strip()
    error = (completed.stderr or "").strip()
    summary = output or error or f"exit {completed.returncode}"
    return completed.returncode == 0, summary


def relative_to_repo(repo_root: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(repo_root.resolve()))
    except ValueError:
        return str(path)


def check_reference_files(repo_root: Path) -> list[CheckResult]:
    results: list[CheckResult] = []
    for relative_path, purpose in REFERENCE_FILES:
        full_path = repo_root / relative_path
        results.append(
            CheckResult(
                name=f"reference:{relative_path}",
                ok=full_path.is_file(),
                detail=f"{purpose}: {'present' if full_path.is_file() else 'missing'}",
            )
        )
    return results


def check_publication_path(repo_root: Path, page_path: Path, win32_path: Path) -> CheckResult:
    targets = (page_path, win32_path)
    missing_targets = [relative_to_repo(repo_root, path) for path in targets if not path.is_file()]
    if missing_targets:
        return CheckResult(
            name="publication_path",
            ok=False,
            detail="missing direct runtime targets: " + ", ".join(missing_targets),
        )

    git_dir = repo_root / ".git"
    if not git_dir.exists():
        writable_targets = [
            relative_to_repo(repo_root, path) for path in targets if os.access(path, os.W_OK)
        ]
        detail = (
            "repo root is missing .git; this looks like a restored archive or loose snapshot, "
            "so the direct issue #3 patch still lacks a writable checkout"
        )
        if writable_targets:
            detail += "; writable targets alone are not enough: " + ", ".join(writable_targets)
        return CheckResult(name="publication_path", ok=False, detail=detail)

    git_probe = ["git", "rev-parse", "--is-inside-work-tree"]
    ok, detail = run_command(git_probe, cwd=repo_root)
    if not ok:
        return CheckResult(
            name="publication_path",
            ok=False,
            detail=f"git checkout probe failed: {detail}",
            command=" ".join(git_probe),
        )
    if detail.strip().lower() != "true":
        return CheckResult(
            name="publication_path",
            ok=False,
            detail=f"git checkout probe returned unexpected output: {detail}",
            command=" ".join(git_probe),
        )

    unwritable_targets = [
        relative_to_repo(repo_root, path) for path in targets if not os.access(path, os.W_OK)
    ]
    if unwritable_targets:
        return CheckResult(
            name="publication_path",
            ok=False,
            detail="git checkout exists but direct runtime targets are not writable: "
            + ", ".join(unwritable_targets),
            command=" ".join(git_probe),
        )

    branch_probe = ["git", "branch", "--show-current"]
    branch_ok, branch_detail = run_command(branch_probe, cwd=repo_root)
    branch_suffix = f" on branch {branch_detail}" if branch_ok and branch_detail else ""
    return CheckResult(
        name="publication_path",
        ok=True,
        detail=f"git checkout present{branch_suffix} and direct runtime targets are writable",
        command=" ".join(git_probe),
    )


def check_runtime_contract(repo_root: Path, page_path: Path, win32_path: Path) -> CheckResult:
    checker_path = repo_root / "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"
    if not checker_path.is_file():
        return CheckResult(
            name="runtime_contract",
            ok=False,
            detail=f"missing checker: {checker_path}",
        )

    command = [
        sys.executable,
        str(checker_path),
        "--page",
        str(page_path),
        "--win32",
        str(win32_path),
    ]
    ok, detail = run_command(command, cwd=repo_root)
    return CheckResult(
        name="runtime_contract",
        ok=ok,
        detail=detail,
        command=" ".join(command),
    )


def check_linux_readiness(
    repo_root: Path,
    saved_archives_root: Path | None,
    include_zig_check: bool,
) -> CheckResult:
    helper_path = repo_root / "scripts/check_linux_build_readiness.py"
    if not helper_path.is_file():
        return CheckResult(
            name="linux_readiness",
            ok=False,
            detail=f"missing readiness helper: {helper_path}",
        )

    command = [
        sys.executable,
        str(helper_path),
        "--repo-root",
        str(repo_root),
        "--expect-saved-archives",
    ]
    if saved_archives_root is not None:
        command.extend(["--saved-archives-root", str(saved_archives_root)])
    if not include_zig_check:
        command.extend(["--skip-zig-check", "--skip-rust-check"])

    ok, detail = run_command(command, cwd=repo_root)
    return CheckResult(
        name="linux_readiness",
        ok=ok,
        detail=detail,
        command=" ".join(command),
    )


def build_windows_route(repo_root: Path, browser_exe: Path | None) -> list[str]:
    exe_path = browser_exe or (repo_root / "zig-out/bin/lightpanda.exe")
    return [
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --page src/browser/Page.zig --win32 src/display/win32_backend.zig",
        "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check --expect-saved-archives",
        "zig build -Dtarget=x86_64-windows-msvc --summary all",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1",
        f"\"{exe_path}\" browse --headed --window_width 1366 --window_height 900 \"https://www.google.com/\"",
    ]


def default_saved_archives_root(repo_root: Path) -> Path | None:
    candidates = (
        repo_root.parent / "memory" / "repo_archives" / "browser",
        repo_root.parent.parent / "memory" / "repo_archives" / "browser",
    )
    for candidate in candidates:
        if candidate.is_dir():
            return candidate.resolve()
    return None


def summarize(results: list[CheckResult]) -> dict[str, object]:
    failed = [asdict(result) for result in results if not result.ok]
    passed = [asdict(result) for result in results if result.ok]
    return {
        "ok": not failed,
        "passed_count": len(passed),
        "failed_count": len(failed),
        "failed_checks": failed,
        "passed_checks": passed,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check whether the narrowed issue #3 runtime re-entry path is ready to reopen."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root or any path inside it (default: current directory)",
    )
    parser.add_argument(
        "--page",
        default="src/browser/Page.zig",
        help="Path to the Page.zig target relative to the repo root",
    )
    parser.add_argument(
        "--win32",
        default="src/display/win32_backend.zig",
        help="Path to the win32_backend.zig target relative to the repo root",
    )
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Optional path to the saved archive root used by scripts/check_linux_build_readiness.py",
    )
    parser.add_argument(
        "--browser-exe",
        default=None,
        help="Optional explicit Windows browser binary path for the printed replay route",
    )
    parser.add_argument(
        "--include-zig-check",
        action="store_true",
        help="Include the readiness helper's Zig and Rust probes instead of the lighter saved-archive preflight",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable JSON instead of the default text report",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests for this helper and exit",
    )
    return parser


class Issue3RuntimeReentryTests(unittest.TestCase):
    def test_repo_root_from_finds_build_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            nested = root / "a" / "b"
            nested.mkdir(parents=True)
            (root / "build.zig").write_text("// marker\n", encoding="utf-8")
            resolved = repo_root_from(nested)
            self.assertEqual(resolved, root.resolve())

    def test_publication_path_requires_git_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            page = root / "src/browser/Page.zig"
            win32 = root / "src/display/win32_backend.zig"
            page.parent.mkdir(parents=True)
            win32.parent.mkdir(parents=True)
            page.write_text("// page\n", encoding="utf-8")
            win32.write_text("// win32\n", encoding="utf-8")
            result = check_publication_path(root, page, win32)
            self.assertFalse(result.ok)
            self.assertIn("missing .git", result.detail)

    def test_publication_path_accepts_writable_git_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            page = root / "src/browser/Page.zig"
            win32 = root / "src/display/win32_backend.zig"
            page.parent.mkdir(parents=True)
            win32.parent.mkdir(parents=True)
            page.write_text("// page\n", encoding="utf-8")
            win32.write_text("// win32\n", encoding="utf-8")
            (root / ".git").mkdir()
            with mock.patch(__name__ + ".run_command") as mocked_run:
                mocked_run.side_effect = [(True, "true"), (True, "fork/headed-mode-foundation")]
                result = check_publication_path(root, page, win32)
            self.assertTrue(result.ok)
            self.assertIn("writable", result.detail)
            self.assertIn("fork/headed-mode-foundation", result.detail)

    def test_summarize_counts_pass_and_fail(self) -> None:
        summary = summarize(
            [
                CheckResult(name="one", ok=True, detail="pass"),
                CheckResult(name="two", ok=False, detail="fail"),
            ]
        )
        self.assertFalse(summary["ok"])
        self.assertEqual(summary["passed_count"], 1)
        self.assertEqual(summary["failed_count"], 1)

    def test_windows_route_includes_contract_and_google_probe(self) -> None:
        route = build_windows_route(Path("/tmp/browser"), None)
        self.assertTrue(any("check_issue3_enter_submit_runtime_contract.py" in step for step in route))
        self.assertTrue(any("chrome-google-home-title-probe.ps1" in step for step in route))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(Issue3RuntimeReentryTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = repo_root_from(Path(args.repo_root))
    page_path = (repo_root / args.page).resolve()
    win32_path = (repo_root / args.win32).resolve()
    saved_archives_root = (
        Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else default_saved_archives_root(repo_root)
    )
    browser_exe = Path(args.browser_exe).resolve() if args.browser_exe else None

    results = check_reference_files(repo_root)
    results.append(check_publication_path(repo_root, page_path, win32_path))
    results.append(check_runtime_contract(repo_root, page_path, win32_path))
    results.append(check_linux_readiness(repo_root, saved_archives_root, args.include_zig_check))

    windows_route = build_windows_route(repo_root, browser_exe)
    summary = summarize(results)
    summary["repo_root"] = str(repo_root)
    summary["windows_route"] = windows_route

    if args.json:
        print(json.dumps(summary, indent=2))
        return 0 if summary["ok"] else 1

    print("Issue #3 runtime re-entry readiness")
    print("")
    print(f"Repo root: {repo_root}")
    print("")
    for result in results:
        status = "PASS" if result.ok else "FAIL"
        print(f"[{status}] {result.name}")
        print(f"  {result.detail}")
        if result.command:
            print(f"  Command: {result.command}")
    print("")
    print("Windows replay route")
    print("===================")
    for step in windows_route:
        print(f"- {step}")

    if summary["ok"]:
        print("")
        print("Ready to reopen the narrowed issue #3 runtime path.")
        return 0

    print("")
    print("Do not reopen the direct Page.zig and win32_backend.zig patch until the failed checks above are green.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
