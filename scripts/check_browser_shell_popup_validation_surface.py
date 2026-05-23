#!/usr/bin/env python3

"""Check the browser-shell and popup headed validation surfaces.

This helper gives scheduled Linux runs one small fail-fast preflight before the
next Windows headed browser-shell or popup validation pass. It verifies that
the router, docs, and first-line probe files for the browser-shell and popup
change areas still exist and still advertise the expected route.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


REFERENCE_FILES: tuple[tuple[str, str], ...] = (
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "Roadmap quick routes should keep browser-shell and popup validation visible.",
    ),
    (
        "docs/WINDOWS_FULL_USE.md",
        "Windows runbook should keep browser-shell and popup validation visible.",
    ),
    (
        "docs/HEADED_MODE_VALIDATION_MATRIX.md",
        "Validation matrix should keep the browser-shell and popup route picks visible.",
    ),
    (
        "tmp-browser-smoke/README.md",
        "Smoke-suite guide should keep browser-shell and popup probe families visible.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "Validation router should keep browser-shell and popup change areas visible.",
    ),
    (
        "scripts/windows/HeadedValidationHelpers.ps1",
        "Shared helper surface should remain present for router-driven validation commands.",
    ),
    (
        "tmp-browser-smoke/browser-pages/chrome-browser-pages-start-shell-probe.ps1",
        "Browser-pages start-shell probe should remain available for shell follow-up.",
    ),
    (
        "tmp-browser-smoke/browser-pages/chrome-browser-pages-tabs-recovery-probe.ps1",
        "Browser-pages tab recovery probe should remain available for shell follow-up.",
    ),
    (
        "tmp-browser-smoke/browser-pages/chrome-browser-pages-home-restore-probe.ps1",
        "Browser-pages home restore probe should remain available for shell follow-up.",
    ),
    (
        "tmp-browser-smoke/browser-pages/chrome-browser-pages-title-fidelity-probe.ps1",
        "Browser-pages title fidelity probe should remain available for shell follow-up.",
    ),
    (
        "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1",
        "First-line tabs probe should remain available for browser-shell validation.",
    ),
    (
        "tmp-browser-smoke/tabs/chrome-duplicate-tab-probe.ps1",
        "Duplicate-tab follow-up probe should remain available for browser-shell validation.",
    ),
    (
        "tmp-browser-smoke/tabs/chrome-session-restore-probe.ps1",
        "Session-restore follow-up probe should remain available for browser-shell validation.",
    ),
    (
        "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1",
        "First-line settings probe should remain available for browser-shell validation.",
    ),
    (
        "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1",
        "Settings restore follow-up probe should remain available for browser-shell validation.",
    ),
    (
        "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1",
        "First-line popup anchor probe should remain available for popup validation.",
    ),
    (
        "tmp-browser-smoke/popup/chrome-popup-form-enter-probe.ps1",
        "Popup form-enter follow-up probe should remain available for popup validation.",
    ),
    (
        "tmp-browser-smoke/popup/chrome-popup-script-policy-probe.ps1",
        "Popup script-policy follow-up probe should remain available for popup validation.",
    ),
    (
        "tmp-browser-smoke/popup/chrome-popup-script-policy-block-probe.ps1",
        "Popup blocked-script follow-up probe should remain available for popup validation.",
    ),
)

CONTENT_EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "show_headed_validation_suites.ps1 -ChangeArea browser-shell",
        "Roadmap quick routes should advertise the browser-shell change area.",
    ),
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "show_headed_validation_suites.ps1 -ChangeArea popup",
        "Roadmap quick routes should advertise the popup change area.",
    ),
    (
        "docs/WINDOWS_FULL_USE.md",
        "show_headed_validation_suites.ps1 -ChangeArea browser-shell",
        "Windows runbook should advertise the browser-shell change area.",
    ),
    (
        "docs/WINDOWS_FULL_USE.md",
        "show_headed_validation_suites.ps1 -ChangeArea popup",
        "Windows runbook should advertise the popup change area.",
    ),
    (
        "docs/WINDOWS_FULL_USE.md",
        "tmp-browser-smoke\\browser-pages\\chrome-browser-pages-start-shell-probe.ps1",
        "Windows runbook should keep the browser-pages shell probe ladder visible.",
    ),
    (
        "docs/WINDOWS_FULL_USE.md",
        "tmp-browser-smoke\\popup\\chrome-popup-anchor-probe.ps1",
        "Windows runbook should keep the popup anchor probe visible.",
    ),
    (
        "docs/HEADED_MODE_VALIDATION_MATRIX.md",
        "show_headed_validation_suites.ps1 -ChangeArea browser-shell",
        "Validation matrix should advertise the browser-shell change area.",
    ),
    (
        "docs/HEADED_MODE_VALIDATION_MATRIX.md",
        "show_headed_validation_suites.ps1 -ChangeArea popup",
        "Validation matrix should advertise the popup change area.",
    ),
    (
        "docs/HEADED_MODE_VALIDATION_MATRIX.md",
        "tmp-browser-smoke\\tabs\\chrome-tabs-probe.ps1",
        "Validation matrix should keep the first-line tabs probe visible.",
    ),
    (
        "docs/HEADED_MODE_VALIDATION_MATRIX.md",
        "tmp-browser-smoke\\settings\\chrome-settings-home-probe.ps1",
        "Validation matrix should keep the first-line settings probe visible.",
    ),
    (
        "docs/HEADED_MODE_VALIDATION_MATRIX.md",
        "tmp-browser-smoke\\popup\\chrome-popup-anchor-probe.ps1",
        "Validation matrix should keep the first-line popup probe visible.",
    ),
    (
        "tmp-browser-smoke/README.md",
        "show_headed_validation_suites.ps1 -ChangeArea browser-shell",
        "Smoke-suite guide should advertise the browser-shell route.",
    ),
    (
        "tmp-browser-smoke/README.md",
        "show_headed_validation_suites.ps1 -ChangeArea popup",
        "Smoke-suite guide should advertise the popup route.",
    ),
    (
        "tmp-browser-smoke/README.md",
        "browser-pages/",
        "Smoke-suite guide should keep browser-pages probes visible for shell follow-up.",
    ),
    (
        "tmp-browser-smoke/README.md",
        "popup/",
        "Smoke-suite guide should keep popup probes visible for popup follow-up.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        '"browser-shell"',
        "Validation router should still declare the browser-shell change area.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        '"popup"',
        "Validation router should still declare the popup change area.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "function Get-BrowserShellRouteCommands",
        "Validation router should keep a dedicated browser-shell route helper.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "function Get-PopupRouteCommands",
        "Validation router should keep a dedicated popup route helper.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        ".\\tmp-browser-smoke\\tabs\\chrome-tabs-probe.ps1",
        "Validation router should keep the first-line tabs probe wired into the browser-shell route.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        ".\\tmp-browser-smoke\\settings\\chrome-settings-home-probe.ps1",
        "Validation router should keep the first-line settings probe wired into the browser-shell route.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        ".\\tmp-browser-smoke\\popup\\chrome-popup-anchor-probe.ps1",
        "Validation router should keep the first-line popup probe wired into the popup route.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        'Write-Route -Name "browser-shell"',
        "Validation router should print the browser-shell route.",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        'Write-Route -Name "popup"',
        "Validation router should print the popup route.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the browser-shell and popup headed validation surfaces "
            "are still present before a Windows headed rerun."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
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


def check_file(path: Path, label: str) -> dict[str, object]:
    exists = path.is_file()
    return {
        "label": label,
        "path": str(path),
        "exists": exists,
    }


def collect_results(repo_root: Path) -> dict[str, object]:
    reference_results = [
        check_file(repo_root / relative_path, label)
        for relative_path, label in REFERENCE_FILES
    ]

    content_cache: dict[Path, str] = {}
    content_results: list[dict[str, object]] = []
    for relative_path, snippet, label in CONTENT_EXPECTATIONS:
        target = repo_root / relative_path
        exists = target.is_file()
        snippet_found = False
        if exists:
            if target not in content_cache:
                content_cache[target] = target.read_text(encoding="utf-8")
            snippet_found = snippet in content_cache[target]

        content_results.append(
            {
                "label": label,
                "path": str(target),
                "exists": exists,
                "snippet": snippet,
                "snippet_found": snippet_found,
            }
        )

    missing_references = [entry for entry in reference_results if not entry["exists"]]
    missing_content = [
        entry
        for entry in content_results
        if not entry["exists"] or not entry["snippet_found"]
    ]

    return {
        "ok": not missing_references and not missing_content,
        "repo_root": str(repo_root),
        "reference_results": reference_results,
        "content_results": content_results,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print("Reference files:")
    for entry in result["reference_results"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
    print("Content expectations:")
    for entry in result["content_results"]:
        if not entry["exists"]:
            status = "FAIL"
        else:
            status = "PASS" if entry["snippet_found"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
    if result["ok"]:
        print("\nBrowser-shell and popup validation surface check passed.")
    else:
        print("\nBrowser-shell and popup validation surface check failed.", file=sys.stderr)
        print(
            "Suggested next step: repair the routed browser-shell or popup docs, "
            "probe paths, or router snippets before relying on that Windows validation lane.",
            file=sys.stderr,
        )


class BrowserShellPopupValidationSurfaceTests(unittest.TestCase):
    def _write_fixture_tree(self, root: Path) -> None:
        for relative_path, _label in REFERENCE_FILES:
            target = root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("", encoding="utf-8")

        snippets_by_path: dict[str, list[str]] = {}
        for relative_path, snippet, _label in CONTENT_EXPECTATIONS:
            snippets_by_path.setdefault(relative_path, []).append(snippet)

        for relative_path, snippets in snippets_by_path.items():
            target = root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("\n".join(snippets), encoding="utf-8")

    def test_collect_results_passes_with_complete_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self._write_fixture_tree(repo_root)
            result = collect_results(repo_root)
            self.assertTrue(result["ok"])

    def test_collect_results_fails_when_probe_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self._write_fixture_tree(repo_root)
            missing_probe = repo_root / "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1"
            missing_probe.unlink()
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            self.assertFalse(
                next(
                    entry
                    for entry in result["reference_results"]
                    if entry["path"] == str(missing_probe)
                )["exists"]
            )

    def test_collect_results_fails_when_router_snippet_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self._write_fixture_tree(repo_root)
            router_path = repo_root / "scripts/windows/show_headed_validation_suites.ps1"
            router_path.write_text(
                router_path.read_text(encoding="utf-8").replace(
                    'Write-Route -Name "popup"', ""
                ),
                encoding="utf-8",
            )
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            failed = next(
                entry
                for entry in result["content_results"]
                if entry["snippet"] == 'Write-Route -Name "popup"'
            )
            self.assertFalse(failed["snippet_found"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            BrowserShellPopupValidationSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps({"profile": "browser-shell-popup-validation-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())