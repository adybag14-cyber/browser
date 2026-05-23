#!/usr/bin/env python3

"""Check whether issue #3 runtime re-entry gates are open.

This helper condenses the two hard gates from docs/ISSUE3_RUNTIME_REENTRY_GATES.md
into one command:

1. publication gate: can this checkout safely carry a direct Page.zig and
   win32_backend.zig edit?
2. toolchain gate: does the checkout have the saved inputs, a matching Zig line,
   and the sibling dependency shape needed for honest Linux/WSL validation?
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
PATH_DEP_RE = re.compile(r'\.(?P<name>@?"[^"]+"|[A-Za-z0-9_]+)\s*=\s*\.\{(?P<body>.*?)\n\s*\}', re.S)
PATH_VALUE_RE = re.compile(r'\.path\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")

PAGE_PATH = "src/browser/Page.zig"
WIN32_PATH = "src/display/win32_backend.zig"
DEFAULT_MEMORY_CHECKER = "scripts/check_issue3_saved_memory_inputs.py"


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(text)
    if match is None:
        raise ValueError(f"could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def same_major_minor(expected: str, actual: str) -> bool:
    return parse_semver(expected)[:2] == parse_semver(actual)[:2]


def normalize_dep_name(raw: str) -> str:
    return raw.replace("@", "").strip('"')


def load_minimum_zig(repo_root: Path) -> str:
    text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError("minimum_zig_version was not found in build.zig.zon")
    return match.group(1)


def load_path_deps(repo_root: Path) -> list[tuple[str, Path]]:
    text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
    deps: list[tuple[str, Path]] = []
    for match in PATH_DEP_RE.finditer(text):
        body = match.group("body")
        path_match = PATH_VALUE_RE.search(body)
        if path_match is None:
            continue
        deps.append((normalize_dep_name(match.group("name")), (repo_root / path_match.group(1)).resolve()))
    return deps


def run_version(cmd: list[str]) -> tuple[bool, str]:
    try:
        completed = subprocess.run(cmd, check=True, capture_output=True, text=True)
    except FileNotFoundError:
        return False, "not found"
    except subprocess.CalledProcessError as exc:
        return False, f"probe failed with exit code {exc.returncode}"
    return True, completed.stdout.strip() or completed.stderr.strip() or "unknown"


def discover_zig_candidates(toolchains_root: Path, minimum_zig: str) -> tuple[list[dict[str, str]], dict[str, str] | None]:
    patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
    seen: set[Path] = set()
    reports: list[dict[str, str]] = []
    first_match: dict[str, str] | None = None

    if not toolchains_root.is_dir():
        return reports, None

    for pattern in patterns:
        for candidate in sorted(toolchains_root.glob(pattern)):
            resolved = candidate.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            ok, version = run_version([str(resolved), "version"])
            if not ok:
                status = "unusable"
            else:
                actual = parse_semver(version)
                expected = parse_semver(minimum_zig)
                if actual < expected:
                    status = "older-than-minimum"
                elif same_major_minor(minimum_zig, version):
                    status = "matches-expected-line"
                else:
                    status = "mismatched-line"
            report = {"path": str(resolved), "version": version, "status": status}
            reports.append(report)
            if first_match is None and status == "matches-expected-line":
                first_match = report

    return reports, first_match


def check_publication_gate(repo_root: Path) -> dict[str, object]:
    target_files = [repo_root / PAGE_PATH, repo_root / WIN32_PATH]
    missing = [str(path.relative_to(repo_root)) for path in target_files if not path.is_file()]
    not_writable = [str(path.relative_to(repo_root)) for path in target_files if path.exists() and not path.stat().st_mode & 0o200]
    git_dir = repo_root / ".git"
    build_zon = repo_root / "build.zig.zon"
    passed = not missing and not not_writable and git_dir.exists() and build_zon.is_file()

    reasons: list[str] = []
    if missing:
        reasons.append(f"missing target files: {', '.join(missing)}")
    if not_writable:
        reasons.append(f"target files are not writable: {', '.join(not_writable)}")
    if not git_dir.exists():
        reasons.append("checkout does not expose a local .git directory")
    if not build_zon.is_file():
        reasons.append("build.zig.zon is missing from the repo root")

    next_step = (
        "publication gate open"
        if passed
        else "restore or switch into a writable checkout before retrying the direct Page.zig and win32_backend.zig patch"
    )
    return {
        "passed": passed,
        "reasons": reasons,
        "target_files": [PAGE_PATH, WIN32_PATH],
        "next_step": next_step,
    }


def run_memory_checker(repo_root: Path, memory_checker: Path) -> tuple[bool, list[str], str]:
    if not memory_checker.is_file():
        return False, [f"memory checker is missing: {memory_checker}"], ""

    completed = subprocess.run(
        [sys.executable, str(memory_checker), "--repo-root", str(repo_root)],
        capture_output=True,
        text=True,
    )
    combined = "\n".join(part for part in (completed.stdout.strip(), completed.stderr.strip()) if part).strip()
    reasons = [] if completed.returncode == 0 else [f"saved Memory input preflight failed with exit code {completed.returncode}"]
    return completed.returncode == 0, reasons, combined


def check_toolchain_gate(repo_root: Path, toolchains_root: Path, memory_checker: Path, zig_cmd: str) -> dict[str, object]:
    minimum_zig = load_minimum_zig(repo_root)
    memory_ok, memory_reasons, memory_output = run_memory_checker(repo_root, memory_checker)
    path_deps = load_path_deps(repo_root)
    missing_path_deps = [f"{name}: {path}" for name, path in path_deps if not path.exists()]
    installed_ok, installed_version = run_version([zig_cmd, "version"])
    installed_matches = installed_ok and same_major_minor(minimum_zig, installed_version)
    candidates, matching_candidate = discover_zig_candidates(toolchains_root, minimum_zig)

    reasons = list(memory_reasons)
    if missing_path_deps:
        reasons.append("missing sibling dependencies: " + ", ".join(missing_path_deps))
    if not installed_ok:
        reasons.append(f"configured zig probe failed: {installed_version}")
    elif not installed_matches:
        reasons.append(
            f"configured zig is on {installed_version}, which does not match the branch's {parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x line"
        )
    if matching_candidate is None:
        reasons.append(f"no staged Zig candidate under {toolchains_root} matches the branch's {minimum_zig} line")

    passed = memory_ok and not missing_path_deps and (installed_matches or matching_candidate is not None)
    if passed:
        next_step = "toolchain gate open"
    elif matching_candidate is not None:
        next_step = (
            "rerun the Linux build-readiness helper with "
            f"`--zig {matching_candidate['path']}` after staging sibling dependencies and offline inputs"
        )
    else:
        next_step = "stage a Zig 0.15.x toolchain under ../toolchains and rerun the recovery helper before reopening issue #3 runtime validation"

    return {
        "passed": passed,
        "minimum_zig": minimum_zig,
        "configured_zig": {"command": zig_cmd, "ok": installed_ok, "version": installed_version},
        "matching_candidate": matching_candidate,
        "candidates": candidates,
        "missing_path_deps": missing_path_deps,
        "memory_check_passed": memory_ok,
        "memory_check_output": memory_output,
        "reasons": reasons,
        "next_step": next_step,
    }


def build_result(repo_root: Path, toolchains_root: Path, memory_checker: Path, zig_cmd: str) -> dict[str, object]:
    publication_gate = check_publication_gate(repo_root)
    toolchain_gate = check_toolchain_gate(repo_root, toolchains_root, memory_checker, zig_cmd)
    return {
        "repo_root": str(repo_root),
        "publication_gate": publication_gate,
        "toolchain_gate": toolchain_gate,
        "ready_for_direct_issue3_runtime_patch": publication_gate["passed"] and toolchain_gate["passed"],
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check whether the issue #3 runtime re-entry publication and toolchain gates are open."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser checkout root")
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the staged toolchains root (default: ../toolchains beside the repo root)",
    )
    parser.add_argument("--zig", default="zig", help="Zig executable to probe (default: zig)")
    parser.add_argument(
        "--memory-checker",
        default=None,
        help="Path to scripts/check_issue3_saved_memory_inputs.py (default: branch-local helper)",
    )
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class RuntimeReentryGateTests(unittest.TestCase):
    def create_repo(self, root: Path) -> Path:
        repo_root = root / "browser"
        (repo_root / "src/browser").mkdir(parents=True)
        (repo_root / "src/display").mkdir(parents=True)
        (repo_root / ".git").mkdir()
        (repo_root / "build.zig.zon").write_text(
            """
            .{
                .minimum_zig_version = "0.15.2",
                .dependencies = .{
                    .v8 = .{ .path = "../zig-v8-fork" },
                    .@"boringssl-zig" = .{ .path = "../boringssl-zig" },
                },
            }
            """,
            encoding="utf-8",
        )
        (repo_root / PAGE_PATH).write_text("// page", encoding="utf-8")
        (repo_root / WIN32_PATH).write_text("// win32", encoding="utf-8")
        return repo_root

    def test_publication_gate_passes_for_writable_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.create_repo(Path(tmpdir))
            result = check_publication_gate(repo_root)
            self.assertTrue(result["passed"])

    def test_publication_gate_fails_without_git_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.create_repo(Path(tmpdir))
            (repo_root / ".git").rmdir()
            result = check_publication_gate(repo_root)
            self.assertFalse(result["passed"])
            self.assertIn("local .git directory", result["reasons"][0])

    def test_discover_zig_candidates_finds_matching_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            toolchains_root = root / "toolchains"
            candidate = toolchains_root / "zig-0.15.7" / "zig"
            candidate.parent.mkdir(parents=True)
            candidate.write_text("#!/usr/bin/env bash\necho 0.15.7\n", encoding="utf-8")
            candidate.chmod(0o755)
            reports, match = discover_zig_candidates(toolchains_root, "0.15.2")
            self.assertEqual(len(reports), 1)
            self.assertEqual(match["version"], "0.15.7")

    def test_toolchain_gate_uses_matching_candidate_when_default_zig_mismatches(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self.create_repo(root)
            (root / "zig-v8-fork").mkdir()
            (root / "boringssl-zig").mkdir()
            checker = root / "checker.py"
            checker.write_text(
                "import sys\nprint('Saved Memory input check passed.')\nsys.exit(0)\n",
                encoding="utf-8",
            )
            toolchains_root = root / "toolchains"
            candidate = toolchains_root / "zig-0.15.7" / "zig"
            candidate.parent.mkdir(parents=True)
            candidate.write_text("#!/usr/bin/env bash\necho 0.15.7\n", encoding="utf-8")
            candidate.chmod(0o755)
            mismatched = root / "zig"
            mismatched.write_text("#!/usr/bin/env bash\necho 0.17.0-dev.299+a76ce7710\n", encoding="utf-8")
            mismatched.chmod(0o755)

            result = check_toolchain_gate(repo_root, toolchains_root, checker, str(mismatched))
            self.assertTrue(result["passed"])
            self.assertEqual(result["matching_candidate"]["version"], "0.15.7")

    def test_build_result_not_ready_when_memory_check_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self.create_repo(root)
            checker = root / "checker.py"
            checker.write_text("import sys\nsys.exit(1)\n", encoding="utf-8")
            result = build_result(repo_root, root / "toolchains", checker, "zig")
            self.assertFalse(result["ready_for_direct_issue3_runtime_patch"])


def emit_text(result: dict[str, object]) -> None:
    publication_gate = result["publication_gate"]
    toolchain_gate = result["toolchain_gate"]
    print(f"Repo root: {result['repo_root']}")
    print("Issue #3 runtime re-entry gates:")
    print(
        f"  - publication gate: {'PASS' if publication_gate['passed'] else 'FAIL'}"
    )
    for reason in publication_gate["reasons"]:
        print(f"    {reason}")
    print(f"    next: {publication_gate['next_step']}")
    print(
        f"  - toolchain gate: {'PASS' if toolchain_gate['passed'] else 'FAIL'}"
    )
    print(f"    minimum zig: {toolchain_gate['minimum_zig']}")
    print(
        f"    configured zig: {toolchain_gate['configured_zig']['version']}"
    )
    if toolchain_gate["matching_candidate"] is not None:
        print(
            "    matching staged zig: "
            f"{toolchain_gate['matching_candidate']['path']} "
            f"({toolchain_gate['matching_candidate']['version']})"
        )
    for reason in toolchain_gate["reasons"]:
        print(f"    {reason}")
    print(f"    next: {toolchain_gate['next_step']}")
    print()
    ready = result["ready_for_direct_issue3_runtime_patch"]
    print(
        "Direct issue #3 runtime patch readiness: "
        + ("READY" if ready else "BLOCKED")
    )


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RuntimeReentryGateTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    toolchains_root = (
        Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else (repo_root.parent / "toolchains").resolve()
    )
    memory_checker = (
        Path(args.memory_checker).resolve()
        if args.memory_checker
        else (repo_root / DEFAULT_MEMORY_CHECKER).resolve()
    )
    result = build_result(repo_root, toolchains_root, memory_checker, args.zig)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ready_for_direct_issue3_runtime_patch"] else 1


if __name__ == "__main__":
    sys.exit(main())