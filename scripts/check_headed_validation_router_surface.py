#!/usr/bin/env python3

"""Fail-fast checker for the headed validation router surface.

This keeps the headed validation router honest around the newer first-line
rendering, network, browser-shell, popup, and attached-page routes that matter
for headed localhost follow-up.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


REFERENCE_FILES: tuple[tuple[str, str], ...] = (
    ("docs/HEADED_MODE_ROADMAP.md", "headed roadmap that prints the validation quick routes"),
    ("scripts/windows/show_headed_validation_suites.ps1", "top-level headed validation suite router"),
    ("scripts/windows/start_attached_pages_catalog.ps1", "attached-pages catalog launcher used by the router"),
    ("scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1", "issue #3 attached-html quickstart surface checker"),
    ("tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1", "rendering route layout probe"),
    (
        "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1",
        "rendering route screenshot completion probe",
    ),
    (
        "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1",
        "network route authenticated stylesheet probe",
    ),
    (
        "tmp-browser-smoke/fetch-credentials/chrome-fetch-credentials-probe.ps1",
        "network route fetch-credentials probe",
    ),
    ("tmp-browser-smoke/tabs/chrome-tabs-probe.ps1", "browser-shell tabs probe"),
    ("tmp-browser-smoke/settings/chrome-settings-home-probe.ps1", "browser-shell settings probe"),
    ("tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1", "popup route probe"),
)

CONTENT_EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "show_headed_validation_suites.ps1 -ChangeArea rendering",
        "roadmap keeps the rendering route visible",
    ),
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "show_headed_validation_suites.ps1 -ChangeArea network",
        "roadmap keeps the network route visible",
    ),
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "show_headed_validation_suites.ps1 -ChangeArea browser-shell",
        "roadmap keeps the browser-shell route visible",
    ),
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "show_headed_validation_suites.ps1 -ChangeArea popup",
        "roadmap keeps the popup route visible",
    ),
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "show_headed_validation_suites.ps1 -SuiteName google-attached-html",
        "roadmap keeps the Google attached-page suite visible",
    ),
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "show_headed_validation_suites.ps1 -SuiteName attached-html-target-bundle",
        "roadmap keeps the attached-page target bundle suite visible",
    ),
    (
        "docs/HEADED_MODE_ROADMAP.md",
        "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "roadmap keeps the replay attached-html fail-fast checker visible",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "\"network\", \"popup\", \"rendering\", \"stop-loading\")",
        "router exposes the rendering, network, and popup change areas",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "chrome-layout-flex-center-probe.ps1",
        "router still points at the layout rendering probe",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "chrome-screenshot-load-complete-probe.ps1",
        "router still points at the screenshot rendering probe",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "chrome-stylesheet-auth-probe.ps1",
        "router still points at the stylesheet auth probe",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "chrome-fetch-credentials-probe.ps1",
        "router still points at the fetch-credentials probe",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "chrome-tabs-probe.ps1",
        "router still points at the tabs probe",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "chrome-settings-home-probe.ps1",
        "router still points at the settings probe",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "chrome-popup-anchor-probe.ps1",
        "router still points at the popup probe",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        "start_attached_pages_catalog.ps1",
        "router still points at the attached-pages catalog launcher",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        'Write-Route -Name "rendering"',
        "router still prints the rendering route",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        'Write-Route -Name "network"',
        "router still prints the network route",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        'Write-Route -Name "browser-shell"',
        "router still prints the browser-shell route",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        'Write-Route -Name "popup"',
        "router still prints the popup route",
    ),
    (
        "scripts/windows/show_headed_validation_suites.ps1",
        'Write-Route -Name "issue3-attached-html-follow-up"',
        "router still prints the attached-html follow-up route",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the headed validation router still surfaces the current "
            "rendering, network, browser-shell, popup, and attached-page routes."
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


def check_surface(repo_root: Path) -> dict[str, object]:
    references = []
    for relative_path, purpose in REFERENCE_FILES:
        target = repo_root / relative_path
        references.append(
            {
                "path": relative_path,
                "purpose": purpose,
                "exists": target.is_file(),
            }
        )

    content_checks = []
    cache: dict[Path, str] = {}
    for relative_path, snippet, purpose in CONTENT_EXPECTATIONS:
        target = repo_root / relative_path
        if target not in cache and target.is_file():
            cache[target] = target.read_text(encoding="utf-8")
        content_checks.append(
            {
                "path": relative_path,
                "snippet": snippet,
                "purpose": purpose,
                "exists": target.is_file() and snippet in cache.get(target, ""),
            }
        )

    missing = [entry for entry in references if not entry["exists"]] + [
        entry for entry in content_checks if not entry["exists"]
    ]
    return {
        "profile": "headed-validation-router-surface",
        "repo_root": str(repo_root),
        "reference_count": len(references),
        "content_check_count": len(content_checks),
        "missing_count": len(missing),
        "references": references,
        "content_checks": content_checks,
        "ok": not missing,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Headed validation router surface check")
    print()
    print(f"Repo root: {result['repo_root']}")
    print()

    for entry in result["references"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  {entry['purpose']}")

    print()
    print("Helper source expectations:")
    for entry in result["content_checks"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  {entry['purpose']}")

    print()
    if result["ok"]:
        print("Headed validation router surface is intact.")
    else:
        print(
            f"Missing {result['missing_count']} headed validation router path or source contract check(s).",
            file=sys.stderr,
        )
        print(
            "Repair the missing headed route file or the roadmap/router command surface before trusting the first-line headed validation ladder.",
            file=sys.stderr,
        )


class HeadedValidationRouterSurfaceTests(unittest.TestCase):
    def write_minimal_root(self, root: Path) -> None:
        for relative_path, _purpose in REFERENCE_FILES:
            target = root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            if relative_path == "docs/HEADED_MODE_ROADMAP.md":
                target.write_text(
                    "\n".join(
                        [
                            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea rendering",
                            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea network",
                            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea browser-shell",
                            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea popup",
                            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-attached-html",
                            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName attached-html-target-bundle",
                            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
                        ]
                    ),
                    encoding="utf-8",
                )
            elif relative_path == "scripts/windows/show_headed_validation_suites.ps1":
                target.write_text(
                    "\n".join(
                        [
                            '"network", "popup", "rendering", "stop-loading")',
                            "chrome-layout-flex-center-probe.ps1",
                            "chrome-screenshot-load-complete-probe.ps1",
                            "chrome-stylesheet-auth-probe.ps1",
                            "chrome-fetch-credentials-probe.ps1",
                            "chrome-tabs-probe.ps1",
                            "chrome-settings-home-probe.ps1",
                            "chrome-popup-anchor-probe.ps1",
                            "start_attached_pages_catalog.ps1",
                            'Write-Route -Name "rendering"',
                            'Write-Route -Name "network"',
                            'Write-Route -Name "browser-shell"',
                            'Write-Route -Name "popup"',
                            'Write-Route -Name "issue3-attached-html-follow-up"',
                        ]
                    ),
                    encoding="utf-8",
                )
            else:
                target.write_text("placeholder\n", encoding="utf-8")

    def test_surface_passes_for_complete_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.write_minimal_root(root)
            result = check_surface(root)
            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_count"], 0)

    def test_surface_fails_when_router_probe_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.write_minimal_root(root)
            (root / "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1").unlink()
            result = check_surface(root)
            self.assertFalse(result["ok"])
            self.assertGreater(result["missing_count"], 0)

    def test_surface_fails_when_roadmap_drops_browser_shell_route(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.write_minimal_root(root)
            roadmap = root / "docs/HEADED_MODE_ROADMAP.md"
            roadmap.write_text(
                roadmap.read_text(encoding="utf-8").replace(
                    "show_headed_validation_suites.ps1 -ChangeArea browser-shell\n", ""
                ),
                encoding="utf-8",
            )
            result = check_surface(root)
            self.assertFalse(result["ok"])
            self.assertGreater(result["missing_count"], 0)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            HeadedValidationRouterSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    result = check_surface(Path(args.repo_root).resolve())
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
