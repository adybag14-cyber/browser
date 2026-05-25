#!/usr/bin/env python3

"""Choose the best issue #3 Zig re-entry path from staged and saved inputs."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shlex
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
TOOLCHAIN_PATTERNS = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.search(text)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def expected_line_label(version: str) -> str:
    major, minor, _patch = parse_semver(version)
    return f"{major}.{minor}.x"


def classify_version(expected: str, actual: str) -> str:
    expected_parts = parse_semver(expected)
    actual_parts = parse_semver(actual)
    if actual_parts < expected_parts:
        return "older-than-minimum"
    if actual_parts[:2] == expected_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def load_minimum_zig(repo_root: pathlib.Path) -> str:
    text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError("Could not find minimum_zig_version in build.zig.zon")
    return match.group(1)


def discover_staged_candidates(
    repo_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    expected: str,
) -> list[dict[str, str]]:
    candidates: list[dict[str, str]] = []
    seen: set[pathlib.Path] = set()
    if not toolchains_root.is_dir():
        return candidates

    for pattern in TOOLCHAIN_PATTERNS:
        for path in sorted(toolchains_root.glob(pattern)):
            resolved = path.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            try:
                completed = subprocess.run(
                    [str(resolved), "version"],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                version = completed.stdout.strip() or completed.stderr.strip()
                status = classify_version(expected, version)
            except Exception:
                version = "unusable"
                status = "version-probe-failed"

            candidates.append(
                {
                    "path": str(resolved),
                    "version": version,
                    "status": status,
                }
            )
    return candidates


def choose_preferred_versioned_record(
    expected: str,
    records: list[dict[str, str]],
) -> dict[str, str] | None:
    matching = [
        record
        for record in records
        if record.get("status") == "matches-expected-line" and record.get("version")
    ]
    if not matching:
        return None

    exact = next((record for record in matching if record["version"] == expected), None)
    if exact is not None:
        return exact
    return max(matching, key=lambda record: parse_semver(record["version"]))


def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_offline_deps_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_fallback_archive(repo_root: pathlib.Path) -> pathlib.Path | None:
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.is_file() else None


def load_saved_archive_report(
    repo_root: pathlib.Path,
    saved_archives_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    fallback_zig_archive: pathlib.Path | None,
) -> tuple[dict[str, object] | None, str | None]:
    helper = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
    if not helper.is_file():
        return None, f"saved archive candidate helper is missing: {helper}"

    command = [
        sys.executable,
        str(helper),
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
        "--json",
    ]
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return None, f"saved archive candidate helper could not run: {exc}"

    helper_stdout = completed.stdout.strip()
    if not helper_stdout:
        detail = completed.stderr.strip()
        suffix = f"; stderr: {detail}" if detail else ""
        return None, f"saved archive candidate helper produced no JSON output{suffix}"

    try:
        return json.loads(helper_stdout), None
    except json.JSONDecodeError as exc:
        return None, f"saved archive candidate helper returned invalid JSON: {exc}"


def build_report(
    *,
    repo_root: pathlib.Path,
    saved_archives_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    offline_deps_root: pathlib.Path,
    fallback_zig_archive: pathlib.Path | None,
    minimum_zig: str,
    staged_candidates: list[dict[str, str]],
    preferred_staged: dict[str, str] | None,
    saved_archive_report: dict[str, object] | None,
    saved_archive_warning: str | None,
) -> dict[str, object]:
    preferred_saved_archive = None
    if saved_archive_report is not None:
        preferred_saved_archive = saved_archive_report.get("preferred_archive")

    preferred_action = "blocked"
    next_command = ""
    reason = ""

    if preferred_staged is not None:
        preferred_action = "use-staged"
        next_command = format_command(
            [
                "python",
                str(repo_root / "scripts" / "check_linux_build_readiness.py"),
                "--repo-root",
                str(repo_root),
                "--zig",
                preferred_staged["path"],
                "--expect-saved-archives",
                "--saved-archives-root",
                str(saved_archives_root),
                "--expect-offline-deps",
                "--offline-deps-root",
                str(offline_deps_root),
                "--require-prebuilt-v8",
                "--toolchains-root",
                str(toolchains_root),
            ]
            + (
                ["--fallback-zig-archive", str(fallback_zig_archive)]
                if fallback_zig_archive is not None
                else []
            )
        )
        reason = (
            f"staged candidate {preferred_staged['version']} is already available under "
            f"{toolchains_root}"
        )
    elif isinstance(preferred_saved_archive, dict) and preferred_saved_archive.get("path"):
        preferred_action = "restore-saved-archive"
        saved_commands = saved_archive_report.get("commands") if saved_archive_report else {}
        next_command = str(saved_commands.get("restore_check") or "")
        reason = (
            f"saved archive {pathlib.Path(str(preferred_saved_archive['path'])).name} "
            "matches the branch line but is not staged yet"
        )
    elif fallback_zig_archive is not None:
        preferred_action = "stage-fallback"
        next_command = format_command(
            [
                "bash",
                str(repo_root / "scripts" / "linux" / "restore_issue3_fallback_zig_toolchain.sh"),
                "--browser-root",
                str(repo_root),
                "--toolchains-root",
                str(toolchains_root),
                "--archive",
                str(fallback_zig_archive),
                "--check-only",
            ]
        )
        reason = (
            "no staged or saved branch-compatible Zig toolchain is visible; only the "
            "surfaced fallback archive remains"
        )
    else:
        next_command = format_command(
            [
                "bash",
                str(repo_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"),
                "--repo-root",
                str(repo_root),
                "--toolchains-root",
                str(toolchains_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--offline-deps-root",
                str(offline_deps_root),
            ]
        )
        reason = "no staged, saved, or surfaced fallback Zig toolchain path is available"

    failures: list[str] = []
    if preferred_action != "use-staged":
        failures.append(reason)
    if saved_archive_warning is not None:
        failures.append(saved_archive_warning)

    return {
        "status": "passed" if preferred_action == "use-staged" else "failed",
        "repo_root": str(repo_root),
        "minimum_zig": minimum_zig,
        "expected_line": expected_line_label(minimum_zig),
        "toolchains_root": str(toolchains_root),
        "saved_archives_root": str(saved_archives_root),
        "offline_deps_root": str(offline_deps_root),
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else "",
        "staged_candidates": staged_candidates,
        "preferred_staged_candidate": preferred_staged,
        "saved_archive_report": saved_archive_report,
        "saved_archive_warning": saved_archive_warning or "",
        "preferred_action": preferred_action,
        "reason": reason,
        "next_command": next_command,
        "failures": failures,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Choose the best issue #3 Zig re-entry path for Linux/WSL."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to repo_archives/browser or its dependencies directory",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the shared toolchains directory",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Path to the offline dependency staging directory",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional path to the surfaced fallback Zig archive",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused helper tests")
    return parser


class ZigToolchainPlanTests(unittest.TestCase):
    def test_choose_preferred_versioned_record_prefers_exact_match(self) -> None:
        records = [
            {"version": "0.15.7", "status": "matches-expected-line", "path": "/tmp/zig-0.15.7/zig"},
            {"version": "0.15.2", "status": "matches-expected-line", "path": "/tmp/zig-0.15.2/zig"},
        ]
        preferred = choose_preferred_versioned_record("0.15.2", records)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "0.15.2")

    def test_choose_preferred_versioned_record_prefers_highest_patch_when_exact_missing(self) -> None:
        records = [
            {"version": "0.15.3", "status": "matches-expected-line", "path": "/tmp/zig-0.15.3/zig"},
            {"version": "0.15.11", "status": "matches-expected-line", "path": "/tmp/zig-0.15.11/zig"},
            {"version": "0.17.0", "status": "mismatched-line", "path": "/tmp/zig-0.17.0/zig"},
        ]
        preferred = choose_preferred_versioned_record("0.15.2", records)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "0.15.11")

    def test_build_report_prefers_staged_candidate(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        toolchains_root = pathlib.Path("/tmp/toolchains")
        report = build_report(
            repo_root=repo_root,
            saved_archives_root=pathlib.Path("/tmp/memory/repo_archives/browser"),
            toolchains_root=toolchains_root,
            offline_deps_root=pathlib.Path("/tmp/offline-deps"),
            fallback_zig_archive=None,
            minimum_zig="0.15.2",
            staged_candidates=[{"path": "/tmp/toolchains/zig-0.15.7/zig", "version": "0.15.7", "status": "matches-expected-line"}],
            preferred_staged={"path": "/tmp/toolchains/zig-0.15.7/zig", "version": "0.15.7", "status": "matches-expected-line"},
            saved_archive_report=None,
            saved_archive_warning=None,
        )
        self.assertEqual(report["preferred_action"], "use-staged")
        self.assertEqual(report["status"], "passed")
        self.assertIn("--zig /tmp/toolchains/zig-0.15.7/zig", report["next_command"])

    def test_build_report_prefers_saved_archive_when_no_staged_match_exists(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        report = build_report(
            repo_root=repo_root,
            saved_archives_root=pathlib.Path("/tmp/memory/repo_archives/browser"),
            toolchains_root=pathlib.Path("/tmp/toolchains"),
            offline_deps_root=pathlib.Path("/tmp/offline-deps"),
            fallback_zig_archive=None,
            minimum_zig="0.15.2",
            staged_candidates=[],
            preferred_staged=None,
            saved_archive_report={
                "preferred_archive": {
                    "path": "/tmp/memory/repo_archives/browser/zig-0.15.2.tar.xz",
                    "version": "0.15.2",
                    "status": "matches-expected-line",
                },
                "commands": {"restore_check": "bash restore --check-only"},
            },
            saved_archive_warning=None,
        )
        self.assertEqual(report["preferred_action"], "restore-saved-archive")
        self.assertEqual(report["next_command"], "bash restore --check-only")

    def test_discover_staged_candidates_classifies_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            toolchains_root = pathlib.Path(tmpdir)
            matching = toolchains_root / "zig-0.15.7" / "zig"
            mismatched = toolchains_root / "zig-0.17.0" / "bin" / "zig"
            for path, version in (
                (matching, "0.15.7"),
                (mismatched, "0.17.0-dev.299+a76ce7710"),
            ):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(f"#!/usr/bin/env bash\necho {version}\n", encoding="utf-8")
                path.chmod(0o755)

            candidates = discover_staged_candidates(pathlib.Path("/tmp/browser"), toolchains_root, "0.15.2")
            self.assertEqual(len(candidates), 2)
            statuses = {candidate["version"]: candidate["status"] for candidate in candidates}
            self.assertEqual(statuses["0.15.7"], "matches-expected-line")
            self.assertEqual(statuses["0.17.0-dev.299+a76ce7710"], "mismatched-line")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ZigToolchainPlanTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    saved_archives_root = (
        pathlib.Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )
    toolchains_root = (
        pathlib.Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_default_toolchains_root(repo_root)
    )
    offline_deps_root = (
        pathlib.Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else resolve_default_offline_deps_root(repo_root)
    )
    fallback_zig_archive = (
        pathlib.Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else resolve_default_fallback_archive(repo_root)
    )

    minimum_zig = load_minimum_zig(repo_root)
    staged_candidates = discover_staged_candidates(repo_root, toolchains_root, minimum_zig)
    preferred_staged = choose_preferred_versioned_record(minimum_zig, staged_candidates)
    saved_archive_report, saved_archive_warning = load_saved_archive_report(
        repo_root,
        saved_archives_root,
        toolchains_root,
        fallback_zig_archive,
    )
    report = build_report(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
        minimum_zig=minimum_zig,
        staged_candidates=staged_candidates,
        preferred_staged=preferred_staged,
        saved_archive_report=saved_archive_report,
        saved_archive_warning=saved_archive_warning,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 1 if report["failures"] else 0

    print("Issue #3 Zig toolchain plan")
    print()
    print(f"Repo root:             {report['repo_root']}")
    print(f"Minimum Zig line:      {report['minimum_zig']} ({report['expected_line']})")
    print(f"Toolchains root:       {report['toolchains_root']}")
    print(f"Saved archives root:   {report['saved_archives_root']}")
    print(f"Offline deps root:     {report['offline_deps_root']}")
    print(
        "Fallback archive:      "
        f"{report['fallback_zig_archive'] or 'not found beside the repo workspace'}"
    )
    print()
    if report["staged_candidates"]:
        print("Discovered staged Zig candidates:")
        for candidate in report["staged_candidates"]:
            print(f"  - {candidate['path']} [{candidate['version']}; {candidate['status']}]")
    else:
        print("Discovered staged Zig candidates: none")
    print()
    print(f"Preferred action:      {report['preferred_action']}")
    print(f"Reason:                {report['reason']}")
    print("Next command:")
    print(f"  {report['next_command']}")
    if report["saved_archive_warning"]:
        print()
        print(f"Saved archive helper warning: {report['saved_archive_warning']}")

    if report["failures"]:
        print("\nPlanning check failed:", file=sys.stderr)
        for failure in report["failures"]:
            print(f"  - {failure}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())