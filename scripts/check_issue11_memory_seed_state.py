#!/usr/bin/env python3

"""Check whether the issue #11 Memory inputs are seeded enough to continue.

This helper gives the Linux/WSL headed-mode re-entry lane a very small
preflight before the broader saved-memory or restore helpers run. Its job is
to tell future runs whether the Memory workspace is ready, partially seeded, or
effectively empty so the next step does not point at snapshot restore when the
snapshot itself is absent.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


REQUIRED_MEMORY_FILES: tuple[tuple[str, str], ...] = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    (
        "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
        "saved Rust toolchain archive",
    ),
    (
        "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
        "saved html5ever dependency archive",
    ),
    (
        "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
        "saved BoringSSL archive",
    ),
    (
        "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
        "saved browser dependency archive",
    ),
)

OPTIONAL_MEMORY_FILES: tuple[tuple[str, str], ...] = (
    ("repo_archives/browser/session_entry_register.yaml", "session entry register"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #11 Memory store is empty, partially "
            "seeded, or ready before reopening restore and build-readiness routes."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Browser checkout root used to discover the nearest memory folder (default: current directory)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Explicit memory root override (default: discover nearest ancestor memory folder or ../memory beside repo-root)",
    )
    parser.add_argument("--json", action="store_true", help="Emit structured JSON instead of line-oriented text")
    parser.add_argument("--self-test", action="store_true", help="Run focused helper tests and exit")
    return parser


def ancestor_chain(start: Path) -> list[Path]:
    chain: list[Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: Path, relative_path: str) -> Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def resolve_default_memory_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "memory").resolve()


def collect_file_state(memory_root: Path, relative_path: str, label: str) -> dict[str, object]:
    path = memory_root / relative_path
    return {
        "label": label,
        "relative_path": relative_path,
        "path": str(path),
        "exists": path.is_file(),
    }


def build_next_step(status: str, missing_required: list[dict[str, object]]) -> str | None:
    if status == "ready":
        return None
    if status == "empty":
        return (
            "Seed Memory with the saved browser snapshot, README, blocker intelligence, "
            "and dependency archives before running restore_saved_browser_snapshot.sh or "
            "check_issue3_saved_memory_inputs.py."
        )
    missing_labels = ", ".join(entry["label"] for entry in missing_required)
    return (
        "Repair the missing Memory artifacts before reopening restore or build-readiness work: "
        f"{missing_labels}."
    )


def collect_results(memory_root: Path) -> dict[str, object]:
    required_files = [
        collect_file_state(memory_root, relative_path, label)
        for relative_path, label in REQUIRED_MEMORY_FILES
    ]
    optional_files = [
        collect_file_state(memory_root, relative_path, label)
        for relative_path, label in OPTIONAL_MEMORY_FILES
    ]

    present_required = [entry for entry in required_files if entry["exists"]]
    missing_required = [entry for entry in required_files if not entry["exists"]]
    present_optional = [entry for entry in optional_files if entry["exists"]]

    if not missing_required:
        status = "ready"
    elif not present_required and not present_optional:
        status = "empty"
    else:
        status = "partial"

    return {
        "status": status,
        "memory_root": str(memory_root),
        "required_files": required_files,
        "optional_files": optional_files,
        "present_required_count": len(present_required),
        "missing_required_count": len(missing_required),
        "next_step": build_next_step(status, missing_required),
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Memory root: {result['memory_root']}")
    print(f"Seed state: {result['status']}")
    print("Required Memory inputs:")
    for entry in result["required_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
    print("Optional Memory inputs:")
    for entry in result["optional_files"]:
        status = "PASS" if entry["exists"] else "WARN"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
    if result["next_step"] is not None:
        print(f"Suggested next step: {result['next_step']}", file=sys.stderr)


class MemorySeedStateTests(unittest.TestCase):
    def test_collect_results_reports_empty_when_no_expected_files_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            result = collect_results(Path(tmpdir))
            self.assertEqual(result["status"], "empty")
            self.assertEqual(result["missing_required_count"], len(REQUIRED_MEMORY_FILES))
            self.assertIn("Seed Memory", result["next_step"])

    def test_collect_results_reports_partial_when_only_session_register_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            memory_root = Path(tmpdir)
            session_register = memory_root / OPTIONAL_MEMORY_FILES[0][0]
            session_register.parent.mkdir(parents=True, exist_ok=True)
            session_register.write_text("run_entries: []\n", encoding="utf-8")
            result = collect_results(memory_root)
            self.assertEqual(result["status"], "partial")
            self.assertIn("saved repo snapshot", result["next_step"])

    def test_collect_results_reports_ready_when_all_required_files_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            memory_root = Path(tmpdir)
            for relative_path, _label in REQUIRED_MEMORY_FILES:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")
            result = collect_results(memory_root)
            self.assertEqual(result["status"], "ready")
            self.assertIsNone(result["next_step"])

    def test_default_memory_root_discovers_nested_workspace_memory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir) / "workspace"
            repo_root = workspace_root / "runs" / "current" / "browser"
            memory_root = workspace_root / "memory"
            repo_root.mkdir(parents=True)
            memory_root.mkdir()
            self.assertEqual(resolve_default_memory_root(repo_root), memory_root.resolve())


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(MemorySeedStateTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    result = collect_results(memory_root)
    if args.json:
        print(json.dumps({"profile": "issue11-memory-seed-state", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["status"] == "ready" else 1


if __name__ == "__main__":
    sys.exit(main())
