#!/usr/bin/env python3

"""Probe whether a Zig candidate can clear a project-level build surface.

This helper keeps the blocked issue #3 runtime lane honest by answering one
question before `Page.zig` or `win32_backend.zig` are blamed again:

Does a selected Zig toolchain fail because the environment is still missing a
matching version or sibling inputs, or does it get far enough to suggest a real
branch/source problem?
"""

from __future__ import annotations

import argparse
import pathlib
import re
import shlex
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)
ENVIRONMENT_FAILURE_PATTERNS: tuple[tuple[str, str], ...] = (
    ("outside module path", "toolchain or module wiring mismatch"),
    ("FileNotFound", "missing dependency or input file"),
    ("No such file or directory", "missing dependency or input file"),
    ("unable to load", "missing dependency, archive, or generated input"),
    ("unable to find", "missing dependency, archive, or generated input"),
    ("is not a directory", "dependency layout is incomplete"),
    ("expected Zig", "toolchain line mismatch"),
    ("minimum_zig_version", "toolchain line mismatch"),
    ("unknown argument", "toolchain or command mismatch"),
    ("unrecognized parameter", "toolchain or command mismatch"),
)


def parse_semver(version_text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(version_text)
    if not match:
        raise ValueError(f"could not parse semantic version from {version_text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected_version: str, actual_version: str) -> bool:
    expected_parts = parse_semver(expected_version)
    actual_parts = parse_semver(actual_version)
    return actual_parts[:2] == expected_parts[:2]


def load_minimum_zig(repo_root: pathlib.Path) -> str:
    manifest_path = repo_root / "build.zig.zon"
    text = manifest_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"could not find minimum_zig_version in {manifest_path}")
    return match.group(1)


def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "toolchains").resolve()


def run_version_command(command: list[str]) -> tuple[bool, str]:
    try:
        completed = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        return False, str(exc)
    except subprocess.CalledProcessError as exc:
        output = (exc.stdout or "") + ("\n" if exc.stdout and exc.stderr else "") + (exc.stderr or "")
        return False, output.strip() or f"exit code {exc.returncode}"
    return True, (completed.stdout.strip() or completed.stderr.strip() or "").strip()


def discover_toolchain_zig_candidates(toolchains_root: pathlib.Path) -> list[pathlib.Path]:
    if not toolchains_root.is_dir():
        return []

    candidates: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for pattern in DEFAULT_ZIG_TOOLCHAIN_GLOBS:
        for path in sorted(toolchains_root.glob(pattern)):
            resolved = path.resolve()
            if not resolved.is_file() or resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def select_zig_candidate(
    repo_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    explicit_zig: str | None,
) -> tuple[pathlib.Path | None, str, list[str]]:
    notes: list[str] = []
    minimum_zig = load_minimum_zig(repo_root)

    if explicit_zig:
        candidate = pathlib.Path(explicit_zig).resolve()
        ok, version_output = run_version_command([str(candidate), "version"])
        if not ok:
            return None, minimum_zig, [f"explicit zig probe failed: {version_output}"]
        notes.append(f"using explicit zig {candidate} ({version_output})")
        if not same_version_line(minimum_zig, version_output):
            notes.append(
                f"explicit zig {version_output} does not match the branch's expected "
                f"{parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x line"
            )
        return candidate, minimum_zig, notes

    candidates = discover_toolchain_zig_candidates(toolchains_root)
    matching: list[tuple[pathlib.Path, str]] = []
    mismatched: list[tuple[pathlib.Path, str]] = []
    failed: list[str] = []
    for candidate in candidates:
        ok, version_output = run_version_command([str(candidate), "version"])
        if not ok:
            failed.append(f"{candidate}: {version_output}")
            continue
        if same_version_line(minimum_zig, version_output):
            matching.append((candidate, version_output))
        else:
            mismatched.append((candidate, version_output))

    if matching:
        selected, version_output = matching[0]
        notes.append(f"selected staged zig {selected} ({version_output})")
        for candidate, version_output in mismatched:
            notes.append(f"ignored staged zig {candidate} ({version_output}) because it is on a different version line")
        return selected, minimum_zig, notes

    if mismatched:
        first_candidate, version_output = mismatched[0]
        notes.append(
            f"no matching staged Zig candidate found; closest visible candidate is "
            f"{first_candidate} ({version_output})"
        )
    if failed:
        notes.extend(f"unusable candidate: {message}" for message in failed)
    return None, minimum_zig, notes


def classify_probe_failure(output: str) -> tuple[str, str]:
    lowered = output.lower()
    for pattern, reason in ENVIRONMENT_FAILURE_PATTERNS:
        if pattern.lower() in lowered:
            return "environment-blocked", reason
    return "source-or-build-failure", "did not match a known environment blocker signature"


def format_shell_command(command: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in command)


def build_probe_command(repo_root: pathlib.Path, zig_path: pathlib.Path, extra_args: list[str]) -> list[str]:
    return [str(zig_path), "build", "--summary", "all", *extra_args]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Probe whether a selected Zig toolchain can clear a project-level build "
            "surface before the blocked issue #3 runtime files are blamed again."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the staged Zig toolchains root (default: ../toolchains beside the repo)",
    )
    parser.add_argument(
        "--zig",
        default=None,
        help="Explicit zig executable to use instead of auto-selecting a staged matching candidate",
    )
    parser.add_argument(
        "--print-only",
        action="store_true",
        help="Print the selected probe command without executing it",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    parser.add_argument(
        "probe_args",
        nargs="*",
        help="Additional arguments passed to `zig build` after `--summary all`",
    )
    return parser


class ZigBuildProbeTests(unittest.TestCase):
    def test_classify_environment_blockers(self) -> None:
        status, reason = classify_probe_failure("error: import of file outside module path")
        self.assertEqual(status, "environment-blocked")
        self.assertIn("module wiring mismatch", reason)

    def test_classify_source_or_build_failure_fallback(self) -> None:
        status, reason = classify_probe_failure("error: expected type 'u32', found '[]const u8'")
        self.assertEqual(status, "source-or-build-failure")
        self.assertIn("did not match", reason)

    def test_same_version_line_uses_major_minor(self) -> None:
        self.assertTrue(same_version_line("0.15.2", "0.15.7"))
        self.assertFalse(same_version_line("0.15.2", "0.17.0-dev.299+a76ce7710"))

    def test_build_probe_command_prefix(self) -> None:
        command = build_probe_command(
            pathlib.Path("/tmp/browser"),
            pathlib.Path("/tmp/toolchains/zig-0.15.7/zig"),
            ["-Dtarget=x86_64-windows-msvc"],
        )
        self.assertEqual(
            command,
            [
                "/tmp/toolchains/zig-0.15.7/zig",
                "build",
                "--summary",
                "all",
                "-Dtarget=x86_64-windows-msvc",
            ],
        )

    def test_select_zig_candidate_prefers_matching_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            repo_root = root / "browser"
            toolchains_root = root / "toolchains"
            repo_root.mkdir()
            toolchains_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.{ .minimum_zig_version = "0.15.2", .dependencies = .{}, .paths = .{""}, }\n', encoding="utf-8")

            matching = toolchains_root / "zig-0.15.7" / "zig"
            mismatched = toolchains_root / "zig-0.17.0" / "zig"
            matching.parent.mkdir(parents=True)
            mismatched.parent.mkdir(parents=True)
            matching.write_text("#!/usr/bin/env bash\necho 0.15.7\n", encoding="utf-8")
            mismatched.write_text("#!/usr/bin/env bash\necho 0.17.0-dev.299+a76ce7710\n", encoding="utf-8")
            matching.chmod(0o755)
            mismatched.chmod(0o755)

            selected, minimum_zig, notes = select_zig_candidate(repo_root, toolchains_root, None)

            self.assertEqual(selected, matching.resolve())
            self.assertEqual(minimum_zig, "0.15.2")
            self.assertTrue(any("ignored staged zig" in note for note in notes))



def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ZigBuildProbeTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    toolchains_root = pathlib.Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    zig_path, minimum_zig, notes = select_zig_candidate(repo_root, toolchains_root, args.zig)

    print(f"Repo root: {repo_root}")
    print(f"Toolchains root: {toolchains_root}")
    print(f"Minimum Zig line: {minimum_zig}")
    for note in notes:
        print(f"Note: {note}")

    if zig_path is None:
        print(
            "\nProbe blocked: no branch-compatible Zig candidate is staged yet.",
            file=sys.stderr,
        )
        expected_parts = parse_semver(minimum_zig)
        print(
            "Suggested next step: stage a Zig "
            f"{expected_parts[0]}.{expected_parts[1]}.x toolchain under the shared toolchains "
            "folder, then rerun this probe.",
            file=sys.stderr,
        )
        return 2

    probe_command = build_probe_command(repo_root, zig_path, args.probe_args)
    print(f"Selected zig: {zig_path}")
    print(f"Probe command: {format_shell_command(probe_command)}")

    if args.print_only:
        print("\nProbe command printed without execution.")
        return 0

    completed = subprocess.run(
        probe_command,
        cwd=repo_root,
        capture_output=True,
        text=True,
    )
    combined_output = ((completed.stdout or "") + ("\n" if completed.stdout and completed.stderr else "") + (completed.stderr or "")).strip()

    if completed.returncode == 0:
        print("\nProbe result: build surface cleared with the selected Zig candidate.")
        if combined_output:
            print(combined_output)
        return 0

    status, reason = classify_probe_failure(combined_output)
    print(f"\nProbe result: {status}", file=sys.stderr)
    print(f"Classification: {reason}", file=sys.stderr)
    print(f"Exit code: {completed.returncode}", file=sys.stderr)
    if combined_output:
        print("Captured output:", file=sys.stderr)
        print(combined_output, file=sys.stderr)
    if status == "environment-blocked":
        print(
            "\nSuggested next step: keep the run on toolchain, dependency, or restore work "
            "until this project-level probe stops failing for environment reasons.",
            file=sys.stderr,
        )
    else:
        print(
            "\nSuggested next step: inspect the failing build output as a real branch/source "
            "problem before reopening the issue #3 runtime patch.",
            file=sys.stderr,
        )
    return 1


if __name__ == "__main__":
    sys.exit(main())
