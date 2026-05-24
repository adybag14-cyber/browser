#!/usr/bin/env python3

"""Check Issue #3 saved-snapshot helper surface alignment.

This helper keeps the saved-browser restore route honest by verifying that the
restore helper surface and the saved-memory preflight helper still enumerate the
same required companion files.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tempfile
import textwrap
import unittest


DEFAULT_RESTORE_HELPER = "scripts/linux/restore_saved_browser_snapshot.sh"
DEFAULT_PREFLIGHT_HELPER = "scripts/check_issue3_saved_memory_inputs.py"
RESTORE_ARRAY_NAME = "HELPER_SURFACE_PATHS"
PREFLIGHT_TUPLE_NAME = "REQUIRED_RESTORED_HELPER_FILES"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the Issue #3 saved-browser restore helper surface stays "
            "aligned with the saved-memory preflight helper."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Browser repo root containing the helper files (default: current directory)",
    )
    parser.add_argument(
        "--restore-helper",
        default=DEFAULT_RESTORE_HELPER,
        help=f"Path to the restore helper relative to repo root (default: {DEFAULT_RESTORE_HELPER})",
    )
    parser.add_argument(
        "--preflight-helper",
        default=DEFAULT_PREFLIGHT_HELPER,
        help=f"Path to the preflight helper relative to repo root (default: {DEFAULT_PREFLIGHT_HELPER})",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run helper tests and exit")
    return parser


def _extract_parenthesized_block(text: str, anchor_pattern: str) -> str:
    match = re.search(anchor_pattern, text)
    if match is None:
        raise ValueError(f"could not locate {anchor_pattern!r}")
    start = match.end()
    depth = 1
    index = start
    while index < len(text):
        char = text[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return text[start:index]
        index += 1
    raise ValueError(f"unterminated block for {anchor_pattern!r}")



def parse_restore_helper_surface_paths(text: str) -> list[str]:
    block = _extract_parenthesized_block(
        text, rf"declare\s+-a\s+{re.escape(RESTORE_ARRAY_NAME)}=\("
    )
    return re.findall(r'"([^"\n]+)"', block)



def parse_preflight_required_helper_paths(text: str) -> list[str]:
    block = _extract_parenthesized_block(
        text,
        rf"{re.escape(PREFLIGHT_TUPLE_NAME)}\s*:\s*tuple\[tuple\[str,\s*str\],\s*\.\.\.\]\s*=\s*\(",
    )
    return re.findall(r'\(\s*"([^"\n]+)"\s*,\s*"[^"\n]*"\s*\)', block)



def collect_alignment(repo_root: Path, restore_helper: Path, preflight_helper: Path) -> dict[str, object]:
    restore_path = (repo_root / restore_helper).resolve()
    preflight_path = (repo_root / preflight_helper).resolve()
    restore_text = restore_path.read_text(encoding="utf-8")
    preflight_text = preflight_path.read_text(encoding="utf-8")
    restore_paths = parse_restore_helper_surface_paths(restore_text)
    preflight_paths = parse_preflight_required_helper_paths(preflight_text)
    missing_in_preflight = sorted(set(restore_paths) - set(preflight_paths))
    extra_in_preflight = sorted(set(preflight_paths) - set(restore_paths))
    ok = not missing_in_preflight and not extra_in_preflight
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "restore_helper": str(restore_helper),
        "preflight_helper": str(preflight_helper),
        "restore_helper_count": len(restore_paths),
        "preflight_helper_count": len(preflight_paths),
        "restore_helper_paths": restore_paths,
        "preflight_helper_paths": preflight_paths,
        "missing_in_preflight": missing_in_preflight,
        "extra_in_preflight": extra_in_preflight,
    }



def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Restore helper: {result['restore_helper']}")
    print(f"Preflight helper: {result['preflight_helper']}")
    print(
        "Restore helper surface count: "
        f"{result['restore_helper_count']} | "
        f"Preflight helper surface count: {result['preflight_helper_count']}"
    )
    if result["missing_in_preflight"]:
        print("Missing in saved-memory preflight:")
        for path in result["missing_in_preflight"]:
            print(f"  - {path}")
    if result["extra_in_preflight"]:
        print("Only in saved-memory preflight:")
        for path in result["extra_in_preflight"]:
            print(f"  - {path}")
    if result["ok"]:
        print("\nIssue #3 saved-snapshot helper surface alignment check passed.")
    else:
        print(
            "\nIssue #3 saved-snapshot helper surface alignment check failed.",
            file=sys.stderr,
        )
        print(
            "Suggested next step: update the helper surface lists together before "
            "relying on the saved-browser restore route.",
            file=sys.stderr,
        )


class HelperSurfaceAlignmentTests(unittest.TestCase):
    def write_root(self, root: Path, *, restore_paths: list[str], preflight_paths: list[str]) -> None:
        restore_helper = root / DEFAULT_RESTORE_HELPER
        restore_helper.parent.mkdir(parents=True, exist_ok=True)
        restore_entries = "\n".join(f'    "{path}"' for path in restore_paths)
        restore_helper.write_text(
            textwrap.dedent(
                f"""\
                #!/usr/bin/env bash
                declare -a {RESTORE_ARRAY_NAME}=(
                {restore_entries}
                )
                """
            ),
            encoding="utf-8",
        )

        preflight_helper = root / DEFAULT_PREFLIGHT_HELPER
        preflight_helper.parent.mkdir(parents=True, exist_ok=True)
        preflight_entries = "\n".join(
            f'    ("{path}", "label {index}")' for index, path in enumerate(preflight_paths, start=1)
        )
        preflight_helper.write_text(
            textwrap.dedent(
                f"""\
                #!/usr/bin/env python3
                {PREFLIGHT_TUPLE_NAME}: tuple[tuple[str, str], ...] = (
                {preflight_entries}
                )
                """
            ),
            encoding="utf-8",
        )

    def test_alignment_passes_for_matching_surfaces(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            paths = [
                "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
                "scripts/check_issue3_saved_memory_inputs.py",
                "scripts/linux/restore_saved_browser_snapshot.sh",
            ]
            self.write_root(root, restore_paths=paths, preflight_paths=paths)
            result = collect_alignment(
                root, Path(DEFAULT_RESTORE_HELPER), Path(DEFAULT_PREFLIGHT_HELPER)
            )
            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_in_preflight"], [])
            self.assertEqual(result["extra_in_preflight"], [])

    def test_alignment_fails_when_restore_surface_grows(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            restore_paths = [
                "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
                "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
                "scripts/linux/restore_zig_toolchain_archive.sh",
            ]
            preflight_paths = ["docs/ISSUE3_RUNTIME_REENTRY_GATES.md"]
            self.write_root(root, restore_paths=restore_paths, preflight_paths=preflight_paths)
            result = collect_alignment(
                root, Path(DEFAULT_RESTORE_HELPER), Path(DEFAULT_PREFLIGHT_HELPER)
            )
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["missing_in_preflight"],
                [
                    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
                    "scripts/linux/restore_zig_toolchain_archive.sh",
                ],
            )
            self.assertEqual(result["extra_in_preflight"], [])

    def test_alignment_fails_when_preflight_keeps_stale_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            restore_paths = ["docs/ISSUE3_RUNTIME_REENTRY_GATES.md"]
            preflight_paths = [
                "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
                "scripts/linux/stale_helper.sh",
            ]
            self.write_root(root, restore_paths=restore_paths, preflight_paths=preflight_paths)
            result = collect_alignment(
                root, Path(DEFAULT_RESTORE_HELPER), Path(DEFAULT_PREFLIGHT_HELPER)
            )
            self.assertFalse(result["ok"])
            self.assertEqual(result["missing_in_preflight"], [])
            self.assertEqual(result["extra_in_preflight"], ["scripts/linux/stale_helper.sh"])

    def test_parser_rejects_missing_surface_blocks(self) -> None:
        with self.assertRaises(ValueError):
            parse_restore_helper_surface_paths("declare -a OTHER=(")
        with self.assertRaises(ValueError):
            parse_preflight_required_helper_paths("OPTIONAL_FILES = ()")



def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            HelperSurfaceAlignmentTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_alignment(
        repo_root,
        Path(args.restore_helper),
        Path(args.preflight_helper),
    )
    if args.json:
        print(json.dumps({"profile": "issue3-saved-snapshot-surface-alignment", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
