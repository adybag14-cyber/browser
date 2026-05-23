#!/usr/bin/env python3

"""Summarize whether the direct issue #3 runtime patch is ready to reopen.

This helper keeps the two hard gates from docs/ISSUE3_RUNTIME_REENTRY_GATES.md
on one compact surface:
- Gate 1: safe publication path for Page.zig and win32_backend.zig
- Gate 2: branch-compatible validation toolchain and dependency staging
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")

TARGET_FILES: tuple[str, ...] = (
    "src/browser/Page.zig",
    "src/display/win32_backend.zig",
)

ROUTE_HELPERS: tuple[str, ...] = (
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/check_linux_build_readiness.py",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
)

PATH_DEPS: tuple[tuple[str, str], ...] = (
    ("zig-v8-fork", "../zig-v8-fork"),
    ("boringssl-zig", "../boringssl-zig"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Report whether the direct issue #3 Page.zig + win32_backend.zig "
            "runtime patch is ready to reopen from this checkout."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--expected-branch",
        default="fork/headed-mode-foundation",
        help="Expected git branch for a publishable checkout",
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


def parse_semver(version_text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(version_text)
    if not match:
        raise ValueError(f"Could not parse semantic version from {version_text!r}")
    return tuple(int(part) for part in match.groups())


def load_minimum_zig_version(repo_root: Path) -> tuple[str | None, list[str]]:
    zon_path = repo_root / "build.zig.zon"
    if not zon_path.is_file():
        return None, [f"missing build.zig.zon at {zon_path}"]
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        return None, [f"could not find .minimum_zig_version in {zon_path}"]
    return match.group(1), []


def run_command(command: list[str]) -> tuple[bool, str]:
    try:
        completed = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return False, "not found"
    except subprocess.CalledProcessError as exc:
        output = exc.stdout.strip() or exc.stderr.strip() or f"exit {exc.returncode}"
        return False, output

    output = completed.stdout.strip() or completed.stderr.strip() or "ok"
    return True, output


def collect_route_helper_checks(repo_root: Path) -> list[dict[str, object]]:
    checks = []
    for relative_path in ROUTE_HELPERS:
        path = repo_root / relative_path
        checks.append(
            {
                "path": relative_path,
                "exists": path.is_file(),
            }
        )
    return checks


def collect_target_file_checks(repo_root: Path) -> list[dict[str, object]]:
    checks = []
    for relative_path in TARGET_FILES:
        path = repo_root / relative_path
        checks.append(
            {
                "path": relative_path,
                "exists": path.is_file(),
                "writable": path.exists() and os_access_write(path),
            }
        )
    return checks


def os_access_write(path: Path) -> bool:
    try:
        return path.exists() and os_access(path)
    except OSError:
        return False


def os_access(path: Path) -> bool:
    import os

    return os.access(path, os.W_OK)


def collect_git_status(repo_root: Path, expected_branch: str) -> dict[str, object]:
    git_dir = repo_root / ".git"
    if not git_dir.exists():
        return {
            "present": False,
            "branch": None,
            "origin": None,
            "expected_branch": expected_branch,
            "branch_matches_expected": False,
            "origin_matches_repo": False,
        }

    branch_ok, branch_output = run_command(
        ["git", "-C", str(repo_root), "rev-parse", "--abbrev-ref", "HEAD"]
    )
    origin_ok, origin_output = run_command(
        ["git", "-C", str(repo_root), "remote", "get-url", "origin"]
    )
    branch = branch_output if branch_ok else None
    origin = origin_output if origin_ok else None
    return {
        "present": True,
        "branch": branch,
        "origin": origin,
        "expected_branch": expected_branch,
        "branch_matches_expected": branch == expected_branch,
        "origin_matches_repo": bool(origin) and "adybag14-cyber/browser" in origin,
    }


def collect_path_dep_checks(repo_root: Path) -> list[dict[str, object]]:
    checks = []
    for label, relative_path in PATH_DEPS:
        path = (repo_root / relative_path).resolve()
        checks.append(
            {
                "label": label,
                "path": str(path),
                "exists": path.is_dir(),
            }
        )
    return checks


def collect_zig_status(repo_root: Path, minimum_zig: str | None) -> dict[str, object]:
    zig_path = shutil.which("zig")
    if zig_path is None:
        return {
            "found": False,
            "path": None,
            "version": None,
            "meets_minimum": False,
            "matches_expected_line": False,
        }

    ok, output = run_command([zig_path, "version"])
    version = output if ok else None
    if not ok or minimum_zig is None or version is None:
        return {
            "found": True,
            "path": zig_path,
            "version": version,
            "meets_minimum": False,
            "matches_expected_line": False,
        }

    installed_parts = parse_semver(version)
    minimum_parts = parse_semver(minimum_zig)
    return {
        "found": True,
        "path": zig_path,
        "version": version,
        "meets_minimum": installed_parts >= minimum_parts,
        "matches_expected_line": installed_parts[:2] == minimum_parts[:2],
    }


def evaluate_publication_gate(
    git_status: dict[str, object],
    target_file_checks: list[dict[str, object]],
) -> tuple[str, list[str]]:
    reasons: list[str] = []
    if not git_status["present"]:
        reasons.append("no git metadata is present in this checkout")
    if not git_status["branch_matches_expected"]:
        reasons.append(
            f"current branch is {git_status['branch']!r}, expected {git_status['expected_branch']!r}"
        )
    if not git_status["origin_matches_repo"]:
        reasons.append("git origin does not point at adybag14-cyber/browser")
    missing_targets = [entry["path"] for entry in target_file_checks if not entry["exists"]]
    if missing_targets:
        reasons.append("missing target files: " + ", ".join(missing_targets))
    non_writable = [entry["path"] for entry in target_file_checks if entry["exists"] and not entry["writable"]]
    if non_writable:
        reasons.append("target files are not writable: " + ", ".join(non_writable))
    if reasons:
        return "closed", reasons
    return "green", ["git checkout, target branch, origin, and writable target files are present"]


def evaluate_toolchain_gate(
    minimum_zig: str | None,
    route_helper_checks: list[dict[str, object]],
    path_dep_checks: list[dict[str, object]],
    zig_status: dict[str, object],
) -> tuple[str, list[str]]:
    reasons: list[str] = []
    missing_helpers = [entry["path"] for entry in route_helper_checks if not entry["exists"]]
    if missing_helpers:
        reasons.append("missing route helpers: " + ", ".join(missing_helpers))
    if minimum_zig is None:
        reasons.append("branch minimum Zig version could not be read from build.zig.zon")
    missing_deps = [entry["label"] for entry in path_dep_checks if not entry["exists"]]
    if missing_deps:
        reasons.append("missing sibling dependencies: " + ", ".join(missing_deps))
    if not zig_status["found"]:
        reasons.append("zig is not available on PATH")
    else:
        if not zig_status["meets_minimum"]:
            reasons.append(
                f"zig {zig_status['version']!r} does not meet the branch minimum {minimum_zig!r}"
            )
        if not zig_status["matches_expected_line"]:
            reasons.append(
                f"zig {zig_status['version']!r} is not on the branch's expected {minimum_zig} line"
            )
    if reasons:
        return "closed", reasons
    return "green", ["route helpers, path dependencies, and a matching Zig line are present"]


def build_next_steps(publication_status: str, toolchain_status: str) -> list[str]:
    steps: list[str] = []
    if publication_status != "green":
        steps.append(
            "Reopen the direct runtime patch only from a writable fork/headed-mode-foundation checkout with the real target files present."
        )
    if toolchain_status != "green":
        steps.append(
            "Use the Linux build-readiness route and a Zig 0.15.2-compatible toolchain before trusting focused Page.zig or win32_backend.zig tests."
        )
    if publication_status == "green" and toolchain_status == "green":
        steps.append(
            "Both hard gates are green; the direct issue #3 runtime patch can be retried from this checkout."
        )
    return steps


def collect_status(repo_root: Path, expected_branch: str) -> dict[str, object]:
    minimum_zig, minimum_zig_errors = load_minimum_zig_version(repo_root)
    route_helper_checks = collect_route_helper_checks(repo_root)
    target_file_checks = collect_target_file_checks(repo_root)
    git_status = collect_git_status(repo_root, expected_branch)
    path_dep_checks = collect_path_dep_checks(repo_root)
    zig_status = collect_zig_status(repo_root, minimum_zig)
    publication_state, publication_reasons = evaluate_publication_gate(
        git_status, target_file_checks
    )
    toolchain_state, toolchain_reasons = evaluate_toolchain_gate(
        minimum_zig, route_helper_checks, path_dep_checks, zig_status
    )
    return {
        "repo_root": str(repo_root),
        "expected_branch": expected_branch,
        "minimum_zig": minimum_zig,
        "minimum_zig_errors": minimum_zig_errors,
        "publication_gate": {
            "state": publication_state,
            "reasons": publication_reasons,
        },
        "toolchain_gate": {
            "state": toolchain_state,
            "reasons": toolchain_reasons,
        },
        "git_status": git_status,
        "target_files": target_file_checks,
        "route_helpers": route_helper_checks,
        "path_dependencies": path_dep_checks,
        "zig_status": zig_status,
        "next_steps": build_next_steps(publication_state, toolchain_state),
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 runtime re-entry gate status")
    print()
    print(f"Repo root: {result['repo_root']}")
    print(f"Expected branch: {result['expected_branch']}")
    print(f"Minimum Zig: {result['minimum_zig'] or 'unavailable'}")
    print()
    print(f"Publication gate: {result['publication_gate']['state'].upper()}")
    for reason in result["publication_gate"]["reasons"]:
        print(f"  - {reason}")
    print()
    print(f"Toolchain gate: {result['toolchain_gate']['state'].upper()}")
    for reason in result["toolchain_gate"]["reasons"]:
        print(f"  - {reason}")
    print()
    print("Next steps:")
    for step in result["next_steps"]:
        print(f"  - {step}")


class GateStatusTests(unittest.TestCase):
    def test_parse_semver(self) -> None:
        self.assertEqual(parse_semver("0.15.2"), (0, 15, 2))

    def test_green_when_checkout_is_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / ".git").mkdir()
            (repo_root / "build.zig.zon").write_text(
                '.{ .minimum_zig_version = "0.15.2", .dependencies = .{} }',
                encoding="utf-8",
            )
            for relative_path in TARGET_FILES + ROUTE_HELPERS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")
            for _label, relative_path in PATH_DEPS:
                (repo_root / relative_path).resolve().mkdir(parents=True, exist_ok=True)

            original_run_command = globals()["run_command"]
            original_which = shutil.which
            try:
                globals()["run_command"] = lambda command: (
                    (True, "fork/headed-mode-foundation")
                    if "rev-parse" in command
                    else (True, "git@github.com:adybag14-cyber/browser.git")
                    if "get-url" in command
                    else (True, "0.15.2")
                )
                shutil.which = lambda name: "/usr/bin/zig" if name == "zig" else None
                result = collect_status(repo_root, "fork/headed-mode-foundation")
            finally:
                globals()["run_command"] = original_run_command
                shutil.which = original_which

            self.assertEqual(result["publication_gate"]["state"], "green")
            self.assertEqual(result["toolchain_gate"]["state"], "green")

    def test_closed_when_snapshot_lacks_git(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text(
                '.{ .minimum_zig_version = "0.15.2", .dependencies = .{} }',
                encoding="utf-8",
            )
            for relative_path in TARGET_FILES + ROUTE_HELPERS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            original_which = shutil.which
            try:
                shutil.which = lambda name: None
                result = collect_status(repo_root, "fork/headed-mode-foundation")
            finally:
                shutil.which = original_which

            self.assertEqual(result["publication_gate"]["state"], "closed")
            self.assertEqual(result["toolchain_gate"]["state"], "closed")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(GateStatusTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_status(repo_root, args.expected_branch)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    if (
        result["publication_gate"]["state"] == "green"
        and result["toolchain_gate"]["state"] == "green"
    ):
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
