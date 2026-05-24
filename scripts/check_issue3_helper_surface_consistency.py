#!/usr/bin/env python3

"""Audit helper-surface parity across the saved snapshot restore helpers.

This checker keeps the issue #3 Linux/WSL recovery route honest by verifying
that the helper-surface manifests used by the saved-memory preflight, the
restored-checkout checker, and the saved-browser restore script stay aligned.
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


TARGETS: tuple[tuple[str, str, str], ...] = (
    (
        "scripts/check_issue3_saved_memory_inputs.py",
        "python_tuple",
        "REQUIRED_RESTORED_HELPER_FILES",
    ),
    (
        "scripts/check_issue3_restored_checkout.py",
        "python_tuple",
        "HELPER_SURFACE_PATHS",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "bash_array",
        "HELPER_SURFACE_PATHS",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #3 helper-surface manifests stay aligned "
            "across the restore, readiness, and saved-memory helpers."
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


def parse_python_tuple(text: str, variable_name: str) -> list[str]:
    module = ast.parse(text)
    for node in module.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == variable_name:
                value = ast.literal_eval(node.value)
                return [entry[0] for entry in value]
    raise ValueError(f"Could not find Python tuple {variable_name!r}")


def parse_bash_array(text: str, variable_name: str) -> list[str]:
    pattern = re.compile(
        rf"declare\s+-a\s+{re.escape(variable_name)}=\((?P<body>.*?)\n\)",
        re.DOTALL,
    )
    match = pattern.search(text)
    if match is None:
        raise ValueError(f"Could not find bash array {variable_name!r}")
    body = match.group("body")
    return re.findall(r'"([^"]+)"', body)


def extract_manifest(repo_root: Path, relative_path: str, parser_kind: str, variable_name: str) -> dict[str, object]:
    path = repo_root / relative_path
    if not path.is_file():
        return {
            "path": relative_path,
            "exists": False,
            "entries": [],
            "error": f"Missing file: {relative_path}",
        }

    text = path.read_text(encoding="utf-8")
    try:
        if parser_kind == "python_tuple":
            entries = parse_python_tuple(text, variable_name)
        elif parser_kind == "bash_array":
            entries = parse_bash_array(text, variable_name)
        else:
            raise ValueError(f"Unsupported parser kind: {parser_kind}")
    except ValueError as exc:
        return {
            "path": relative_path,
            "exists": True,
            "entries": [],
            "error": str(exc),
        }

    return {
        "path": relative_path,
        "exists": True,
        "entries": entries,
        "error": None,
    }


def collect_results(repo_root: Path) -> dict[str, object]:
    manifests = [
        extract_manifest(repo_root, relative_path, parser_kind, variable_name)
        for relative_path, parser_kind, variable_name in TARGETS
    ]

    readable_manifests = [manifest for manifest in manifests if manifest["exists"] and manifest["error"] is None]
    baseline_entries = set(readable_manifests[0]["entries"]) if readable_manifests else set()

    comparisons: list[dict[str, object]] = []
    ok = True
    for manifest in manifests:
        entries = set(manifest["entries"])
        missing_from_manifest = sorted(baseline_entries - entries)
        extra_in_manifest = sorted(entries - baseline_entries)
        in_sync = manifest["exists"] and manifest["error"] is None and not missing_from_manifest and not extra_in_manifest
        if not in_sync:
            ok = False
        comparisons.append(
            {
                "path": manifest["path"],
                "exists": manifest["exists"],
                "error": manifest["error"],
                "entry_count": len(manifest["entries"]),
                "missing_from_manifest": missing_from_manifest,
                "extra_in_manifest": extra_in_manifest,
                "in_sync": in_sync,
            }
        )

    if not readable_manifests:
        ok = False

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "baseline_path": readable_manifests[0]["path"] if readable_manifests else None,
        "baseline_entry_count": len(readable_manifests[0]["entries"]) if readable_manifests else 0,
        "comparisons": comparisons,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Baseline manifest: {result['baseline_path'] or 'none'}")
    print(f"Baseline entries: {result['baseline_entry_count']}")
    print("Manifest comparisons:")
    for comparison in result["comparisons"]:
        if not comparison["exists"]:
            status = "FAIL"
        elif comparison["error"] is not None:
            status = "FAIL"
        elif comparison["in_sync"]:
            status = "PASS"
        else:
            status = "FAIL"
        print(f"  [{status}] {comparison['path']}")
        if comparison["error"] is not None:
            print(f"         parse error: {comparison['error']}")
        if comparison["missing_from_manifest"]:
            print(
                "         missing entries: "
                + ", ".join(comparison["missing_from_manifest"])
            )
        if comparison["extra_in_manifest"]:
            print(
                "         extra entries: "
                + ", ".join(comparison["extra_in_manifest"])
            )
    if result["ok"]:
        print("\nHelper-surface manifests are aligned.")
        return
    print("\nHelper-surface manifests are out of sync.", file=sys.stderr)
    print(
        "Suggested next step: update the drifted manifest before relying on restored-checkout readiness or helper-surface sync.",
        file=sys.stderr,
    )


class HelperSurfaceConsistencyTests(unittest.TestCase):
    def write_fixture_repo(
        self,
        root: Path,
        *,
        saved_entries: list[str],
        restored_entries: list[str] | None = None,
        restore_entries: list[str] | None = None,
    ) -> None:
        restored_entries = restored_entries if restored_entries is not None else saved_entries
        restore_entries = restore_entries if restore_entries is not None else saved_entries

        (root / "scripts/linux").mkdir(parents=True, exist_ok=True)

        saved_body = "\n".join(
            f'    ("{entry}", "label"),' for entry in saved_entries
        )
        (root / "scripts/check_issue3_saved_memory_inputs.py").write_text(
            "REQUIRED_RESTORED_HELPER_FILES = (\n"
            f"{saved_body}\n"
            ")\n",
            encoding="utf-8",
        )

        restored_body = "\n".join(
            f'    ("{entry}", "label"),' for entry in restored_entries
        )
        (root / "scripts/check_issue3_restored_checkout.py").write_text(
            "HELPER_SURFACE_PATHS = (\n"
            f"{restored_body}\n"
            ")\n",
            encoding="utf-8",
        )

        restore_body = "\n".join(f'    "{entry}"' for entry in restore_entries)
        (root / "scripts/linux/restore_saved_browser_snapshot.sh").write_text(
            "#!/usr/bin/env bash\n"
            "declare -a HELPER_SURFACE_PATHS=(\n"
            f"{restore_body}\n"
            ")\n",
            encoding="utf-8",
        )

    def test_collect_results_passes_when_manifests_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            entries = ["docs/A.md", "scripts/B.py", "scripts/linux/C.sh"]
            self.write_fixture_repo(repo_root, saved_entries=entries)

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertTrue(all(item["in_sync"] for item in result["comparisons"]))

    def test_collect_results_reports_missing_and_extra_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_fixture_repo(
                repo_root,
                saved_entries=["docs/A.md", "scripts/B.py"],
                restored_entries=["docs/A.md", "scripts/B.py", "scripts/linux/C.sh"],
                restore_entries=["docs/A.md"],
            )

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            restored = result["comparisons"][1]
            restore = result["comparisons"][2]
            self.assertEqual(restored["extra_in_manifest"], ["scripts/linux/C.sh"])
            self.assertEqual(restore["missing_from_manifest"], ["scripts/B.py"])

    def test_collect_results_reports_missing_target_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            entries = ["docs/A.md"]
            self.write_fixture_repo(repo_root, saved_entries=entries)
            (repo_root / "scripts/check_issue3_restored_checkout.py").unlink()

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertFalse(result["comparisons"][1]["exists"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            HelperSurfaceConsistencyTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps({"profile": "issue3-helper-surface-consistency", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
