#!/usr/bin/env python3

"""Check that issue #11 helper surfaces prefer `.toolchains` over `toolchains`.

This guard is intentionally narrow. It looks at the Linux/WSL re-entry helpers
that surface or default a shared toolchains root and fails when any of them
still prefer the visible `toolchains/` directory before the staged hidden
`.toolchains/` root.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


FILES = {
    "workspace_context": "scripts/check_issue3_workspace_context.py",
    "build_readiness": "scripts/check_linux_build_readiness.py",
    "progress_tracker_route": "scripts/linux/show_issue3_progress_tracker_route.sh",
}

EXPECTED_SNIPPETS: tuple[tuple[str, str, str], ...] = (
    (
        "workspace_context",
        'for relative_path in (".toolchains", "toolchains"):',
        "The workspace-context helper should surface the hidden staged toolchains root before the visible toolchains directory.",
    ),
    (
        "build_readiness",
        "located = locate_first_existing(repo_root, '.toolchains')",
        "The Linux build-readiness helper should default to the hidden staged toolchains root before it falls back to the visible toolchains directory.",
    ),
    (
        "build_readiness",
        "located = locate_first_existing(repo_root, 'toolchains')",
        "The Linux build-readiness helper should still keep the visible toolchains fallback after the hidden staged root check.",
    ),
    (
        "progress_tracker_route",
        'TOOLCHAINS_ROOT="$(resolve_first_existing_path "${HELPER_ROOT}" ".toolchains" || true)"',
        "The issue #11 progress-tracker route should surface the hidden staged toolchains root before the visible toolchains directory.",
    ),
    (
        "progress_tracker_route",
        'TOOLCHAINS_ROOT="$(resolve_first_existing_path "${HELPER_ROOT}" "toolchains" || true)"',
        "The issue #11 progress-tracker route should still keep the visible toolchains fallback after the hidden staged root check.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #11 Linux/WSL helper surfaces prefer "
            "`.toolchains` over `toolchains` when both roots are visible."
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
        help="Emit structured JSON instead of a line-oriented summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


def read_target_texts(repo_root: Path) -> tuple[dict[str, str], list[str]]:
    texts: dict[str, str] = {}
    missing_files: list[str] = []

    for key, relative_path in FILES.items():
        target = repo_root / relative_path
        try:
            texts[key] = target.read_text(encoding="utf-8")
        except OSError:
            texts[key] = ""
            missing_files.append(relative_path)

    return texts, missing_files


def snippet_order(text: str, first: str, second: str) -> str:
    first_index = text.find(first)
    second_index = text.find(second)

    if first_index != -1 and second_index == -1:
        return "preferred-first"
    if second_index != -1 and first_index == -1:
        return "fallback-first"
    if first_index == -1 and second_index == -1:
        return "missing"
    if first_index < second_index:
        return "preferred-first"
    return "fallback-first"


def collect_results(repo_root: Path) -> dict[str, object]:
    texts, missing_files = read_target_texts(repo_root)
    checks: list[dict[str, object]] = []
    failures: list[dict[str, str]] = []

    for file_key, snippet, purpose in EXPECTED_SNIPPETS:
        present = snippet in texts[file_key]
        checks.append(
            {
                "path": FILES[file_key],
                "snippet": snippet,
                "purpose": purpose,
                "present": present,
            }
        )
        if not present:
            failures.append(
                {
                    "path": FILES[file_key],
                    "reason": "missing-snippet",
                    "snippet": snippet,
                }
            )

    workspace_order = snippet_order(
        texts["workspace_context"],
        'for relative_path in (".toolchains", "toolchains"):',
        'for relative_path in ("toolchains", ".toolchains"):',
    )
    build_readiness_order = snippet_order(
        texts["build_readiness"],
        "located = locate_first_existing(repo_root, '.toolchains')",
        "located = locate_first_existing(repo_root, 'toolchains')",
    )
    progress_tracker_order = snippet_order(
        texts["progress_tracker_route"],
        'TOOLCHAINS_ROOT="$(resolve_first_existing_path "${HELPER_ROOT}" ".toolchains" || true)"',
        'TOOLCHAINS_ROOT="$(resolve_first_existing_path "${HELPER_ROOT}" "toolchains" || true)"',
    )

    order_checks = [
        ("scripts/check_issue3_workspace_context.py", workspace_order),
        ("scripts/check_linux_build_readiness.py", build_readiness_order),
        ("scripts/linux/show_issue3_progress_tracker_route.sh", progress_tracker_order),
    ]
    for path, order in order_checks:
        if order != "preferred-first":
            failures.append(
                {
                    "path": path,
                    "reason": "wrong-order",
                    "snippet": order,
                }
            )

    return {
        "ok": not missing_files and not failures,
        "repo_root": str(repo_root),
        "checks": checks,
        "missing_files": missing_files,
        "order_checks": {
            "workspace_context": workspace_order,
            "build_readiness": build_readiness_order,
            "progress_tracker_route": progress_tracker_order,
        },
        "failures": failures,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print("Order checks:")
    for key, value in result["order_checks"].items():
        print(f"  - {key}: {value}")

    for check in result["checks"]:
        status = "PASS" if check["present"] else "FAIL"
        print(f"[{status}] {check['path']}")
        print(f"  snippet: {check['snippet']}")
        print(f"  {check['purpose']}")

    if result["missing_files"]:
        print("Missing files:")
        for path in result["missing_files"]:
            print(f"  - {path}")

    if result["ok"]:
        print("Issue #11 toolchains-root consistency check passed.")
        return

    print("Issue #11 toolchains-root consistency check failed.", file=sys.stderr)
    for failure in result["failures"]:
        print(
            f"  - {failure['path']}: {failure['reason']} ({failure['snippet']})",
            file=sys.stderr,
        )


def make_fixture_repo(
    *,
    workspace_context_order: str = "preferred",
    build_readiness_order: str = "preferred",
    progress_tracker_order: str = "preferred",
) -> Path:
    root = Path(tempfile.mkdtemp(prefix="issue11-toolchains-root-"))
    for relative_path in FILES.values():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("", encoding="utf-8")

    workspace_context_text = (
        'for relative_path in (".toolchains", "toolchains"):\n'
        if workspace_context_order == "preferred"
        else 'for relative_path in ("toolchains", ".toolchains"):\n'
    )
    build_readiness_text = (
        "located = locate_first_existing(repo_root, '.toolchains')\n"
        "if located is not None and located.is_dir():\n"
        "    return located\n"
        "located = locate_first_existing(repo_root, 'toolchains')\n"
        if build_readiness_order == "preferred"
        else (
            "located = locate_first_existing(repo_root, 'toolchains')\n"
            "if located is not None and located.is_dir():\n"
            "    return located\n"
            "located = locate_first_existing(repo_root, '.toolchains')\n"
        )
    )
    progress_tracker_text = (
        'TOOLCHAINS_ROOT="$(resolve_first_existing_path "${HELPER_ROOT}" ".toolchains" || true)"\n'
        'if [[ -z "${TOOLCHAINS_ROOT}" ]]; then\n'
        '    TOOLCHAINS_ROOT="$(resolve_first_existing_path "${HELPER_ROOT}" "toolchains" || true)"\n'
        if progress_tracker_order == "preferred"
        else (
            'TOOLCHAINS_ROOT="$(resolve_first_existing_path "${HELPER_ROOT}" "toolchains" || true)"\n'
            'if [[ -z "${TOOLCHAINS_ROOT}" ]]; then\n'
            '    TOOLCHAINS_ROOT="$(resolve_first_existing_path "${HELPER_ROOT}" ".toolchains" || true)"\n'
        )
    )

    (root / FILES["workspace_context"]).write_text(workspace_context_text, encoding="utf-8")
    (root / FILES["build_readiness"]).write_text(build_readiness_text, encoding="utf-8")
    (root / FILES["progress_tracker_route"]).write_text(progress_tracker_text, encoding="utf-8")
    return root


class ToolchainsRootConsistencyTests(unittest.TestCase):
    def test_passes_when_all_targets_prefer_hidden_toolchains_root(self) -> None:
        repo_root = make_fixture_repo()
        result = collect_results(repo_root)
        self.assertTrue(result["ok"])
        self.assertEqual(result["order_checks"]["workspace_context"], "preferred-first")
        self.assertEqual(result["order_checks"]["build_readiness"], "preferred-first")
        self.assertEqual(result["order_checks"]["progress_tracker_route"], "preferred-first")

    def test_flags_workspace_context_when_visible_toolchains_comes_first(self) -> None:
        repo_root = make_fixture_repo(workspace_context_order="fallback")
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        self.assertEqual(result["order_checks"]["workspace_context"], "fallback-first")

    def test_flags_build_readiness_when_visible_toolchains_comes_first(self) -> None:
        repo_root = make_fixture_repo(build_readiness_order="fallback")
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        self.assertEqual(result["order_checks"]["build_readiness"], "fallback-first")

    def test_flags_progress_tracker_route_when_visible_toolchains_comes_first(self) -> None:
        repo_root = make_fixture_repo(progress_tracker_order="fallback")
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        self.assertEqual(result["order_checks"]["progress_tracker_route"], "fallback-first")

    def test_reports_missing_target_files(self) -> None:
        repo_root = make_fixture_repo()
        (repo_root / FILES["build_readiness"]).unlink()
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        self.assertIn(FILES["build_readiness"], result["missing_files"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ToolchainsRootConsistencyTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(
            json.dumps(
                {
                    "profile": "issue11-toolchains-root-consistency",
                    **result,
                },
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
