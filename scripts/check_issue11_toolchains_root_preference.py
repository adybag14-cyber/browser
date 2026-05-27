#!/usr/bin/env python3

"""Audit issue #11 helper files for hidden .toolchains preference.

This helper is for the Linux/WSL headed-mode re-entry lane where future runs
need to know whether the branch-local helper surfaces truly prefer a shared
`.toolchains` root over a visible `toolchains/` sibling when both exist.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import textwrap
import unittest


TARGETS: tuple[dict[str, str], ...] = (
    {
        "path": "scripts/check_issue11_toolchains_root_candidates.py",
        "hidden": 'locate_first_existing(repo_root, ".toolchains")',
        "visible": 'locate_first_existing(repo_root, "toolchains")',
    },
    {
        "path": "scripts/check_linux_build_readiness.py",
        "hidden": "locate_first_existing(repo_root, '.toolchains')",
        "visible": "locate_first_existing(repo_root, 'toolchains')",
    },
    {
        "path": "scripts/check_issue3_workspace_context.py",
        "hidden": '".toolchains"',
        "visible": '"toolchains"',
    },
    {
        "path": "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "hidden": 'locate_first_existing "${BROWSER_ROOT}" ".toolchains"',
        "visible": 'locate_first_existing "${BROWSER_ROOT}" "toolchains"',
    },
    {
        "path": "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "hidden": 'resolve_first_existing_path "${REPO_ROOT}" ".toolchains"',
        "visible": 'resolve_first_existing_path "${REPO_ROOT}" "toolchains"',
    },
    {
        "path": "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "hidden": 'resolve_first_existing_path "${REPO_ROOT}" ".toolchains"',
        "visible": 'resolve_first_existing_path "${REPO_ROOT}" "toolchains"',
    },
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Audit issue #11 helper files for hidden .toolchains preference."
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
        help="Run focused unit tests and exit",
    )
    return parser



def inspect_target(repo_root: Path, target: dict[str, str]) -> dict[str, object]:
    file_path = repo_root / target["path"]
    result: dict[str, object] = {
        "path": target["path"],
        "status": "ok",
        "detail": "",
    }
    if not file_path.is_file():
        result["status"] = "missing"
        result["detail"] = "file not found under repo root"
        return result

    text = file_path.read_text(encoding="utf-8")
    hidden_index = text.find(target["hidden"])
    visible_index = text.find(target["visible"])

    if hidden_index == -1 or visible_index == -1:
        result["status"] = "unknown"
        missing = []
        if hidden_index == -1:
            missing.append("hidden-preference marker")
        if visible_index == -1:
            missing.append("visible-root marker")
        result["detail"] = "could not find " + " and ".join(missing)
        return result

    if hidden_index < visible_index:
        result["detail"] = "hidden .toolchains marker appears before visible toolchains marker"
        return result

    result["status"] = "visible-first"
    result["detail"] = "visible toolchains marker appears before hidden .toolchains marker"
    return result



def collect_report(repo_root: Path) -> dict[str, object]:
    checks = [inspect_target(repo_root, target) for target in TARGETS]
    problematic = [check for check in checks if check["status"] != "ok"]
    status = "passed" if not problematic else "attention"
    next_steps = []
    if problematic:
        next_steps.append(
            "Patch each visible-first helper so `.toolchains` is checked before `toolchains`."
        )
        next_steps.append(
            "Re-run this audit before trusting issue #11 route output in a nested or restored checkout."
        )
    return {
        "status": status,
        "repo_root": str(repo_root.resolve()),
        "checks": checks,
        "problem_count": len(problematic),
        "next_steps": next_steps,
    }



def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Status: {report['status']}")
    print(f"Problem count: {report['problem_count']}")
    print("Checks:")
    for check in report["checks"]:
        print(f"  - {check['path']}: {check['status']} ({check['detail']})")
    if report["next_steps"]:
        print("Next steps:")
        for step in report["next_steps"]:
            print(f"  - {step}")


class ToolchainsRootPreferenceAuditTests(unittest.TestCase):
    def make_repo(self, root: Path, *, hidden_first: bool) -> None:
        for target in TARGETS:
            file_path = root / target["path"]
            file_path.parent.mkdir(parents=True, exist_ok=True)
            ordered = (
                f"{target['hidden']}\n{target['visible']}\n"
                if hidden_first
                else f"{target['visible']}\n{target['hidden']}\n"
            )
            file_path.write_text(ordered, encoding="utf-8")

    def test_passes_when_all_targets_prefer_hidden_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.make_repo(repo_root, hidden_first=True)
            report = collect_report(repo_root)
            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["problem_count"], 0)

    def test_flags_visible_first_targets(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.make_repo(repo_root, hidden_first=False)
            report = collect_report(repo_root)
            self.assertEqual(report["status"], "attention")
            self.assertEqual(report["problem_count"], len(TARGETS))
            statuses = {check["status"] for check in report["checks"]}
            self.assertEqual(statuses, {"visible-first"})

    def test_marks_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            report = collect_report(Path(tmpdir))
            self.assertEqual(report["status"], "attention")
            self.assertEqual(report["problem_count"], len(TARGETS))
            statuses = {check["status"] for check in report["checks"]}
            self.assertEqual(statuses, {"missing"})

    def test_marks_unknown_when_marker_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            target = TARGETS[0]
            file_path = repo_root / target["path"]
            file_path.parent.mkdir(parents=True, exist_ok=True)
            file_path.write_text(
                textwrap.dedent(
                    """
                    # marker intentionally incomplete
                    locate_first_existing(repo_root, "toolchains")
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            report = collect_report(repo_root)
            first = report["checks"][0]
            self.assertEqual(first["status"], "unknown")



def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ToolchainsRootPreferenceAuditTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    report = collect_report(repo_root)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
