#!/usr/bin/env python3

"""Check the pinned attached HTML compatibility bundle for issue #3.

This helper verifies that the current builder-attached compatibility bundle
still contains the three expected HTML pages before a localhost replay route is
trusted. It also prints the next launcher commands for the same locked bundle.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import unittest


PINNED_BUNDLE_FILENAMES: tuple[str, ...] = (
    "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html",
    "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html",
    "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html",
)

DEFAULT_PREFERRED_INITIAL_PAGE = PINNED_BUNDLE_FILENAMES[0]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the pinned three-page attached HTML compatibility "
            "bundle for issue #3 is present and print the next localhost "
            "launcher commands for that same bundle."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help=(
            "Path to the builder-attached files root "
            "(default: ../agent_files beside the repo workspace)"
        ),
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


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    in_repo = (repo_root / "agent_files").resolve()
    if in_repo.is_dir():
        return in_repo
    return (repo_root.parent / "agent_files").resolve()


def shell_quote(value: str) -> str:
    return "'" + value.replace("'", "'\"'\"'") + "'"


def powershell_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def collect_bundle_result(agent_files_root: Path) -> dict[str, object]:
    expected_paths = [
        {
            "filename": filename,
            "path": str(agent_files_root / filename),
            "exists": (agent_files_root / filename).is_file(),
        }
        for filename in PINNED_BUNDLE_FILENAMES
    ]
    missing_files = [entry["filename"] for entry in expected_paths if not entry["exists"]]
    present_files = [entry["filename"] for entry in expected_paths if entry["exists"]]
    extra_html_files = []
    if agent_files_root.is_dir():
        extra_html_files = sorted(
            path.name
            for path in agent_files_root.iterdir()
            if path.is_file()
            and path.suffix.lower() == ".html"
            and path.name not in PINNED_BUNDLE_FILENAMES
        )

    recommended_shell_inputs = " ".join(
        f"--input {shell_quote(str(agent_files_root / filename))}"
        for filename in PINNED_BUNDLE_FILENAMES
    )
    recommended_pwsh_inputs = ",".join(
        powershell_quote(str(agent_files_root / filename))
        for filename in PINNED_BUNDLE_FILENAMES
    )
    preferred_shell_page = shell_quote(str(agent_files_root / DEFAULT_PREFERRED_INITIAL_PAGE))
    preferred_pwsh_page = powershell_quote(str(agent_files_root / DEFAULT_PREFERRED_INITIAL_PAGE))

    return {
        "ok": agent_files_root.is_dir() and not missing_files,
        "agent_files_root": str(agent_files_root),
        "bundle_root_exists": agent_files_root.is_dir(),
        "expected_files": expected_paths,
        "present_files": present_files,
        "missing_files": missing_files,
        "extra_html_files": extra_html_files,
        "preferred_initial_page": DEFAULT_PREFERRED_INITIAL_PAGE,
        "recommended_commands": {
            "catalog_sidecar_audit": (
                "python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py "
                f"{recommended_shell_inputs} --google-style --audit-sidecars"
            ),
            "catalog_asset_audit": (
                "python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py "
                f"{recommended_shell_inputs} --google-style --audit-assets"
            ),
            "catalog_manifest": (
                "python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py "
                f"{recommended_shell_inputs} --preferred-initial-page {preferred_shell_page} "
                "--google-style --print-manifest"
            ),
            "windows_catalog_manifest": (
                "powershell -ExecutionPolicy Bypass -File "
                ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
                f"-InputPath {recommended_pwsh_inputs} "
                f"-PreferredInitialPage {preferred_pwsh_page} "
                "-GoogleStyle -PrintManifest"
            ),
        },
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 pinned attached HTML bundle check")
    print("")
    print(f"Agent files root: {result['agent_files_root']}")
    print(
        "Bundle root:      "
        + ("PASS" if result["bundle_root_exists"] else "FAIL")
    )
    if not result["bundle_root_exists"]:
        print("  agent_files root is missing, so the pinned compatibility bundle cannot be reused yet")
    print("")
    for entry in result["expected_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"[{status}] {entry['filename']}")
    if result["extra_html_files"]:
        print("")
        print("Additional HTML files present:")
        for filename in result["extra_html_files"]:
            print(f"- {filename}")
    print("")
    if result["ok"]:
        print(
            "Pinned compatibility bundle is present. Preferred initial page:"
            f" {result['preferred_initial_page']}"
        )
        print("Suggested next commands:")
        print(f"  {result['recommended_commands']['catalog_sidecar_audit']}")
        print(f"  {result['recommended_commands']['catalog_asset_audit']}")
        print(f"  {result['recommended_commands']['catalog_manifest']}")
        print(f"  {result['recommended_commands']['windows_catalog_manifest']}")
    else:
        print(
            "Pinned compatibility bundle is incomplete. Restore the missing HTML "
            "files before trusting the attached-page localhost replay route."
        )


class PinnedAttachedHtmlBundleTests(unittest.TestCase):
    def test_collect_bundle_result_passes_with_exact_bundle(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            for filename in PINNED_BUNDLE_FILENAMES:
                (root / filename).write_text("<html></html>", encoding="utf-8")

            result = collect_bundle_result(root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_files"], [])
            self.assertEqual(result["present_files"], list(PINNED_BUNDLE_FILENAMES))
            self.assertEqual(result["preferred_initial_page"], DEFAULT_PREFERRED_INITIAL_PAGE)

    def test_collect_bundle_result_fails_when_bundle_root_is_missing(self) -> None:
        result = collect_bundle_result(Path("/tmp/does-not-exist-for-bundle-test"))

        self.assertFalse(result["ok"])
        self.assertFalse(result["bundle_root_exists"])
        self.assertEqual(result["present_files"], [])
        self.assertEqual(result["missing_files"], list(PINNED_BUNDLE_FILENAMES))

    def test_collect_bundle_result_reports_missing_and_extra_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            for filename in PINNED_BUNDLE_FILENAMES[:2]:
                (root / filename).write_text("<html></html>", encoding="utf-8")
            (root / "Some Other Page.html").write_text("<html></html>", encoding="utf-8")

            result = collect_bundle_result(root)

            self.assertFalse(result["ok"])
            self.assertEqual(result["missing_files"], [PINNED_BUNDLE_FILENAMES[2]])
            self.assertEqual(result["extra_html_files"], ["Some Other Page.html"])
            self.assertIn("--google-style --print-manifest", result["recommended_commands"]["catalog_manifest"])

    def test_default_agent_files_root_prefers_repo_child_when_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            agent_files_root = repo_root / "agent_files"
            agent_files_root.mkdir(parents=True)

            self.assertEqual(resolve_default_agent_files_root(repo_root), agent_files_root.resolve())

    def test_default_agent_files_root_falls_back_to_repo_sibling(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "browser"
            repo_root.mkdir()
            sibling_agent_files = workspace_root / "agent_files"
            sibling_agent_files.mkdir()

            self.assertEqual(
                resolve_default_agent_files_root(repo_root),
                sibling_agent_files.resolve(),
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(PinnedAttachedHtmlBundleTests)
        run = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if run.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    agent_files_root = (
        Path(args.agent_files_root).resolve()
        if args.agent_files_root
        else resolve_default_agent_files_root(repo_root)
    )
    result = collect_bundle_result(agent_files_root)
    if args.json:
        print(json.dumps({"profile": "issue3-pinned-attached-html-bundle", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
