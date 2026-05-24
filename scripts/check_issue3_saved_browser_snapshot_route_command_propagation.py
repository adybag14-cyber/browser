#!/usr/bin/env python3

"""Check saved-browser-snapshot route command propagation for issue #3.

This helper inspects the branch-local saved-browser-snapshot route printer and
restore helper to make sure an explicit fallback Zig archive override is kept
alive across both restore commands and follow-up commands.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import textwrap
import unittest


ROUTE_PRINTER_PATH = Path("scripts/linux/show_issue3_saved_browser_snapshot_route.sh")
RESTORE_HELPER_PATH = Path("scripts/linux/restore_saved_browser_snapshot.sh")
ROUTE_DOC_PATH = Path("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")

RESTORE_COMMAND_NAMES: tuple[str, ...] = (
    "SURFACE_CHECK_COMMAND",
    "RESTORE_COMMAND",
    "SYNC_SURFACE_CHECK_COMMAND",
    "SYNC_RESTORE_COMMAND",
)

FOLLOW_UP_COMMAND_NAMES: tuple[str, ...] = (
    "SAVED_MEMORY_PREFLIGHT_COMMAND",
    "SAVED_ARCHIVE_INTEGRITY_COMMAND",
    "LINUX_BUILD_ROUTE_COMMAND",
    "RUNTIME_ROUTE_COMMAND",
    "SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND",
    "SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND",
    "SYNC_LINUX_BUILD_ROUTE_COMMAND",
    "SYNC_RUNTIME_ROUTE_COMMAND",
)

ROUTE_OPTION_SNIPPETS: tuple[tuple[str, str], ...] = (
    ("--fallback-zig-archive)", "route printer accepts an explicit fallback Zig override"),
    ("fallback-zig-archive", "route printer mentions the fallback Zig override in output or JSON"),
)

RESTORE_OPTION_SNIPPETS: tuple[tuple[str, str], ...] = (
    ("--fallback-zig-archive)", "restore helper accepts an explicit fallback Zig override"),
    ("RESTORE_FALLBACK_FLAG", "restore helper threads the fallback Zig override into its surfaced commands"),
)

DOC_SNIPPETS: tuple[tuple[str, str], ...] = (
    ("--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz", "route note documents the explicit fallback Zig override"),
    ("show_issue3_saved_browser_snapshot_route.sh", "route note keeps the route printer visible"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved-browser-snapshot route keeps an explicit "
            "fallback Zig archive override alive across restore and follow-up commands."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
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


def command_has_fallback_propagation(route_text: str, command_name: str) -> bool:
    assignment_snippets = (
        f'{command_name}="${{{command_name}}}',
        f'{command_name}+=" --fallback-zig-archive ',
        f"{command_name}+=\" --fallback-zig-archive ",
        f"${{{command_name}}} --fallback-zig-archive",
        f"{command_name}=\\\"bash ",
    )
    if f"${{RESTORE_FALLBACK_FLAG}}" in route_text:
        # A shared restore flag is acceptable only for the restore command family.
        if command_name in RESTORE_COMMAND_NAMES:
            for line in route_text.splitlines():
                if line.startswith(f"{command_name}=") and "${RESTORE_FALLBACK_FLAG}" in line:
                    return True
    for line in route_text.splitlines():
        if not line.startswith(command_name):
            continue
        if "--fallback-zig-archive" in line:
            return True
        if "${RESTORE_FALLBACK_FLAG}" in line and command_name in RESTORE_COMMAND_NAMES:
            return True
    return any(snippet in route_text for snippet in assignment_snippets) and any(
        probe in route_text for probe in (f'{command_name}+=" --fallback-zig-archive ', f'{command_name}+=\" --fallback-zig-archive ')
    )


def check_named_commands(route_text: str, command_names: tuple[str, ...], *, family: str) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    for command_name in command_names:
        results.append(
            {
                "command_name": command_name,
                "family": family,
                "fallback_propagates": command_has_fallback_propagation(route_text, command_name),
            }
        )
    return results


def check_snippets(text: str, path: str, snippets: tuple[tuple[str, str], ...]) -> list[dict[str, object]]:
    return [
        {
            "path": path,
            "snippet": snippet,
            "purpose": purpose,
            "present": snippet in text,
        }
        for snippet, purpose in snippets
    ]


def collect_results(repo_root: Path) -> dict[str, object]:
    route_path = repo_root / ROUTE_PRINTER_PATH
    restore_path = repo_root / RESTORE_HELPER_PATH
    doc_path = repo_root / ROUTE_DOC_PATH

    route_text = route_path.read_text(encoding="utf-8")
    restore_text = restore_path.read_text(encoding="utf-8")
    doc_text = doc_path.read_text(encoding="utf-8")

    route_snippets = check_snippets(route_text, str(ROUTE_PRINTER_PATH), ROUTE_OPTION_SNIPPETS)
    restore_snippets = check_snippets(restore_text, str(RESTORE_HELPER_PATH), RESTORE_OPTION_SNIPPETS)
    doc_snippets = check_snippets(doc_text, str(ROUTE_DOC_PATH), DOC_SNIPPETS)
    restore_commands = check_named_commands(route_text, RESTORE_COMMAND_NAMES, family="restore")
    follow_up_commands = check_named_commands(route_text, FOLLOW_UP_COMMAND_NAMES, family="follow-up")

    missing_route_snippets = [entry for entry in route_snippets if not entry["present"]]
    missing_restore_snippets = [entry for entry in restore_snippets if not entry["present"]]
    missing_doc_snippets = [entry for entry in doc_snippets if not entry["present"]]
    broken_restore_commands = [entry for entry in restore_commands if not entry["fallback_propagates"]]
    broken_follow_up_commands = [entry for entry in follow_up_commands if not entry["fallback_propagates"]]

    ok = not (
        missing_route_snippets
        or missing_restore_snippets
        or missing_doc_snippets
        or broken_restore_commands
        or broken_follow_up_commands
    )

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "route_printer_path": str(ROUTE_PRINTER_PATH),
        "restore_helper_path": str(RESTORE_HELPER_PATH),
        "route_doc_path": str(ROUTE_DOC_PATH),
        "route_snippets": route_snippets,
        "restore_snippets": restore_snippets,
        "doc_snippets": doc_snippets,
        "restore_commands": restore_commands,
        "follow_up_commands": follow_up_commands,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Route printer: {result['route_printer_path']}")
    print(f"Restore helper: {result['restore_helper_path']}")
    print(f"Route note: {result['route_doc_path']}")
    print("Route printer surface:")
    for entry in result["route_snippets"]:
        status = "PASS" if entry["present"] else "FAIL"
        print(f"  [{status}] {entry['purpose']}")
    print("Restore helper surface:")
    for entry in result["restore_snippets"]:
        status = "PASS" if entry["present"] else "FAIL"
        print(f"  [{status}] {entry['purpose']}")
    print("Route note surface:")
    for entry in result["doc_snippets"]:
        status = "PASS" if entry["present"] else "FAIL"
        print(f"  [{status}] {entry['purpose']}")
    print("Restore-command fallback propagation:")
    for entry in result["restore_commands"]:
        status = "PASS" if entry["fallback_propagates"] else "FAIL"
        print(f"  [{status}] {entry['command_name']}")
    print("Follow-up fallback propagation:")
    for entry in result["follow_up_commands"]:
        status = "PASS" if entry["fallback_propagates"] else "FAIL"
        print(f"  [{status}] {entry['command_name']}")

    if result["ok"]:
        print("\nSaved-browser-snapshot route fallback propagation check passed.")
        return

    print("\nSaved-browser-snapshot route fallback propagation check failed.", file=sys.stderr)
    print(
        "Suggested next step: thread the explicit fallback Zig override through the restore and synced-restore command strings in show_issue3_saved_browser_snapshot_route.sh before trusting that route output.",
        file=sys.stderr,
    )


class CommandPropagationTests(unittest.TestCase):
    def write_fixture_repo(self, root: Path, *, fixed_restore_commands: bool) -> Path:
        repo_root = root / "browser"
        (repo_root / "scripts/linux").mkdir(parents=True, exist_ok=True)
        (repo_root / "docs").mkdir(parents=True, exist_ok=True)

        restore_suffix = "${RESTORE_FALLBACK_FLAG}" if fixed_restore_commands else ""
        route_text = textwrap.dedent(
            f"""\
            #!/usr/bin/env bash
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --fallback-zig-archive)
                        FALLBACK_ZIG_ARCHIVE="$2"
                        shift 2
                        ;;
                esac
            done
            ROUTE_SURFACE_COMMAND="bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
            RESTORE_FALLBACK_FLAG=""
            SURFACE_CHECK_COMMAND="bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only{restore_suffix}"
            RESTORE_COMMAND="bash ./scripts/linux/restore_saved_browser_snapshot.sh{restore_suffix}"
            SYNC_SURFACE_CHECK_COMMAND="bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface --check-only{restore_suffix}"
            SYNC_RESTORE_COMMAND="bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface{restore_suffix}"
            SAVED_MEMORY_PREFLIGHT_COMMAND="python ./scripts/check_issue3_saved_memory_inputs.py"
            SAVED_ARCHIVE_INTEGRITY_COMMAND="python ./scripts/check_issue3_saved_archive_integrity.py"
            LINUX_BUILD_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh"
            RUNTIME_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
            SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND="python ./scripts/check_issue3_saved_memory_inputs.py"
            SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND="python ./scripts/check_issue3_saved_archive_integrity.py"
            SYNC_LINUX_BUILD_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh"
            SYNC_RUNTIME_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
            if [[ -n "${{FALLBACK_ZIG_ARCHIVE}}" ]]; then
                SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive x"
                SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive x"
                LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive x"
                RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive x"
                SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive x"
                SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive x"
                SYNC_LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive x"
                SYNC_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive x"
            fi
            """
        )
        restore_text = textwrap.dedent(
            """\
            #!/usr/bin/env bash
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --fallback-zig-archive)
                        FALLBACK_ZIG_ARCHIVE="$2"
                        shift 2
                        ;;
                esac
            done
            RESTORE_FALLBACK_FLAG=" --fallback-zig-archive x"
            """
        )
        doc_text = textwrap.dedent(
            """\
            # Route

            Use --fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
            and show_issue3_saved_browser_snapshot_route.sh when the explicit fallback Zig archive matters.
            """
        )
        (repo_root / ROUTE_PRINTER_PATH).write_text(route_text, encoding="utf-8")
        (repo_root / RESTORE_HELPER_PATH).write_text(restore_text, encoding="utf-8")
        (repo_root / ROUTE_DOC_PATH).write_text(doc_text, encoding="utf-8")
        return repo_root

    def test_detects_missing_restore_command_propagation(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.write_fixture_repo(Path(tmpdir), fixed_restore_commands=False)
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            broken = {entry["command_name"] for entry in result["restore_commands"] if not entry["fallback_propagates"]}
            self.assertEqual(broken, set(RESTORE_COMMAND_NAMES))

    def test_accepts_fixed_restore_command_propagation(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.write_fixture_repo(Path(tmpdir), fixed_restore_commands=True)
            result = collect_results(repo_root)
            self.assertTrue(result["ok"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(CommandPropagationTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps({"profile": "issue3-saved-browser-snapshot-route-command-propagation", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
