#!/usr/bin/env python3

"""Check that the issue #3 restore helper surface and preflight surface match.

This keeps the saved-browser-snapshot restore route honest. The restore helper
can sync a branch-local helper surface into a restored checkout, and the saved
Memory preflight later decides whether that restored checkout is ready. If the
two helper-path lists drift apart, a restored checkout can look ready while
still missing newer recovery helpers.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import sys
import tempfile
import textwrap
import unittest


RESTORE_ARRAY_RE = re.compile(
    r'declare -a HELPER_SURFACE_PATHS=\(\n(?P<body>.*?)\n\)',
    re.DOTALL,
)
RESTORE_PATH_RE = re.compile(r'"([^"\n]+)"')
PRECHECK_TUPLE_RE = re.compile(
    r"REQUIRED_RESTORED_HELPER_FILES:\s*tuple\[tuple\[str, str\], \.\.\.\]\s*=\s*\(\n(?P<body>.*?)\n\)",
    re.DOTALL,
)
PRECHECK_PATH_RE = re.compile(r'\(\s*"([^"\n]+)"\s*,\s*"[^"\n]+"\s*\)', re.DOTALL)


@dataclass(frozen=True)
class AlignmentResult:
    restore_script: Path
    preflight_script: Path
    restore_paths: tuple[str, ...]
    preflight_paths: tuple[str, ...]
    missing_in_preflight: tuple[str, ...]
    extra_in_preflight: tuple[str, ...]

    @property
    def ok(self) -> bool:
        return not self.missing_in_preflight and not self.extra_in_preflight


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the saved-browser-snapshot restore helper surface and "
            "the saved-Memory restored-checkout preflight expect the same files."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--restore-script",
        default=None,
        help="Optional explicit path to scripts/linux/restore_saved_browser_snapshot.sh",
    )
    parser.add_argument(
        "--preflight-script",
        default=None,
        help="Optional explicit path to scripts/check_issue3_saved_memory_inputs.py",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def parse_restore_helper_surface(path: Path) -> tuple[str, ...]:
    text = path.read_text(encoding="utf-8")
    match = RESTORE_ARRAY_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find HELPER_SURFACE_PATHS in {path}")
    return tuple(RESTORE_PATH_RE.findall(match.group("body")))


def parse_preflight_helper_surface(path: Path) -> tuple[str, ...]:
    text = path.read_text(encoding="utf-8")
    match = PRECHECK_TUPLE_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find REQUIRED_RESTORED_HELPER_FILES in {path}")
    return tuple(PRECHECK_PATH_RE.findall(match.group("body")))


def collect_alignment_result(
    restore_script: Path,
    preflight_script: Path,
) -> AlignmentResult:
    restore_paths = parse_restore_helper_surface(restore_script)
    preflight_paths = parse_preflight_helper_surface(preflight_script)

    restore_set = set(restore_paths)
    preflight_set = set(preflight_paths)

    missing_in_preflight = tuple(sorted(restore_set - preflight_set))
    extra_in_preflight = tuple(sorted(preflight_set - restore_set))

    return AlignmentResult(
        restore_script=restore_script,
        preflight_script=preflight_script,
        restore_paths=restore_paths,
        preflight_paths=preflight_paths,
        missing_in_preflight=missing_in_preflight,
        extra_in_preflight=extra_in_preflight,
    )


def emit_result(result: AlignmentResult) -> None:
    print(f"Restore script: {result.restore_script}")
    print(f"Preflight script: {result.preflight_script}")
    print(f"Restore helper surface entries: {len(result.restore_paths)}")
    print(f"Preflight helper surface entries: {len(result.preflight_paths)}")
    if result.missing_in_preflight:
        print("Missing from restored-checkout preflight:")
        for relative_path in result.missing_in_preflight:
            print(f"  - {relative_path}")
    if result.extra_in_preflight:
        print("Present only in restored-checkout preflight:")
        for relative_path in result.extra_in_preflight:
            print(f"  - {relative_path}")
    if result.ok:
        print("\nHelper surface alignment check passed.")
    else:
        print("\nHelper surface alignment check failed.", file=sys.stderr)
        print(
            "Suggested next step: update scripts/check_issue3_saved_memory_inputs.py "
            "or scripts/linux/restore_saved_browser_snapshot.sh so both surfaces "
            "describe the same restored-checkout helper contract.",
            file=sys.stderr,
        )


class HelperSurfaceAlignmentTests(unittest.TestCase):
    def test_parsers_extract_expected_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            restore_script = root / "restore.sh"
            restore_script.write_text(
                textwrap.dedent(
                    """\
                    declare -a HELPER_SURFACE_PATHS=(
                        "docs/A.md"
                        "scripts/linux/show_a.sh"
                        "scripts/check_a.py"
                    )
                    """
                ),
                encoding="utf-8",
            )
            preflight_script = root / "preflight.py"
            preflight_script.write_text(
                textwrap.dedent(
                    """\
                    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                        ("docs/A.md", "doc"),
                        ("scripts/linux/show_a.sh", "route"),
                        ("scripts/check_a.py", "helper"),
                    )
                    """
                ),
                encoding="utf-8",
            )

            self.assertEqual(
                parse_restore_helper_surface(restore_script),
                ("docs/A.md", "scripts/linux/show_a.sh", "scripts/check_a.py"),
            )
            self.assertEqual(
                parse_preflight_helper_surface(preflight_script),
                ("docs/A.md", "scripts/linux/show_a.sh", "scripts/check_a.py"),
            )

    def test_alignment_flags_missing_and_extra_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            restore_script = root / "restore.sh"
            restore_script.write_text(
                textwrap.dedent(
                    """\
                    declare -a HELPER_SURFACE_PATHS=(
                        "docs/A.md"
                        "scripts/check_a.py"
                        "scripts/linux/show_a.sh"
                    )
                    """
                ),
                encoding="utf-8",
            )
            preflight_script = root / "preflight.py"
            preflight_script.write_text(
                textwrap.dedent(
                    """\
                    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                        ("docs/A.md", "doc"),
                        ("scripts/check_b.py", "stale"),
                    )
                    """
                ),
                encoding="utf-8",
            )

            result = collect_alignment_result(restore_script, preflight_script)

            self.assertFalse(result.ok)
            self.assertEqual(
                result.missing_in_preflight,
                ("scripts/check_a.py", "scripts/linux/show_a.sh"),
            )
            self.assertEqual(result.extra_in_preflight, ("scripts/check_b.py",))

    def test_alignment_passes_when_sets_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            restore_script = root / "restore.sh"
            restore_script.write_text(
                textwrap.dedent(
                    """\
                    declare -a HELPER_SURFACE_PATHS=(
                        "docs/A.md"
                        "scripts/check_a.py"
                    )
                    """
                ),
                encoding="utf-8",
            )
            preflight_script = root / "preflight.py"
            preflight_script.write_text(
                textwrap.dedent(
                    """\
                    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                        ("scripts/check_a.py", "helper"),
                        ("docs/A.md", "doc"),
                    )
                    """
                ),
                encoding="utf-8",
            )

            result = collect_alignment_result(restore_script, preflight_script)

            self.assertTrue(result.ok)
            self.assertEqual(result.missing_in_preflight, ())
            self.assertEqual(result.extra_in_preflight, ())


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(HelperSurfaceAlignmentTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    restore_script = (
        Path(args.restore_script).resolve()
        if args.restore_script
        else (repo_root / "scripts" / "linux" / "restore_saved_browser_snapshot.sh").resolve()
    )
    preflight_script = (
        Path(args.preflight_script).resolve()
        if args.preflight_script
        else (repo_root / "scripts" / "check_issue3_saved_memory_inputs.py").resolve()
    )

    result = collect_alignment_result(restore_script, preflight_script)
    emit_result(result)
    return 0 if result.ok else 1


if __name__ == "__main__":
    sys.exit(main())