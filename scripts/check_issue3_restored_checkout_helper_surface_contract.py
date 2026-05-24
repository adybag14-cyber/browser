#!/usr/bin/env python3

"""Check that the restored-checkout helper surface includes its own route files.

This catches a specific drift risk in the issue #3 saved-snapshot recovery path:
the restored-checkout route can exist on the live branch, but the helper-surface
lists used for restore, sync, and preflight can lag behind and omit the route's
own surface scripts.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import textwrap
import unittest


ROUTE_DOC = "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
REQUIRED_ROUTE_SCRIPTS: tuple[str, ...] = (
    "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
)
CONTRACT_TARGETS: tuple[tuple[str, str], ...] = (
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper surface"),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout helper surface"),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved-browser restore helper surface"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #3 restored-checkout route scripts are present "
            "on the branch and included in the helper-surface sync and preflight "
            "contracts that future saved-snapshot reruns depend on."
        )
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
        help="Run focused helper tests and exit",
    )
    return parser


def collect_results(repo_root: Path) -> dict[str, object]:
    route_doc_path = repo_root / ROUTE_DOC
    route_doc_exists = route_doc_path.is_file()
    route_doc_text = route_doc_path.read_text(encoding="utf-8") if route_doc_exists else ""

    route_scripts = []
    missing_count = 0
    for relative_path in REQUIRED_ROUTE_SCRIPTS:
        exists = (repo_root / relative_path).is_file()
        mentioned_in_doc = relative_path in route_doc_text
        if not exists or not mentioned_in_doc:
            missing_count += 1
        route_scripts.append(
            {
                "path": relative_path,
                "exists": exists,
                "mentioned_in_route_doc": mentioned_in_doc,
            }
        )

    contract_targets = []
    for relative_path, label in CONTRACT_TARGETS:
        path = repo_root / relative_path
        exists = path.is_file()
        text = path.read_text(encoding="utf-8") if exists else ""
        referenced_scripts = []
        for script_path in REQUIRED_ROUTE_SCRIPTS:
            mentioned = script_path in text
            if not mentioned:
                missing_count += 1
            referenced_scripts.append(
                {
                    "path": script_path,
                    "mentioned": mentioned,
                }
            )
        contract_targets.append(
            {
                "path": relative_path,
                "label": label,
                "exists": exists,
                "referenced_scripts": referenced_scripts,
            }
        )
        if not exists:
            missing_count += 1

    return {
        "ok": route_doc_exists and missing_count == 0,
        "repo_root": str(repo_root),
        "route_doc": {
            "path": ROUTE_DOC,
            "exists": route_doc_exists,
        },
        "route_scripts": route_scripts,
        "contract_targets": contract_targets,
        "missing_count": missing_count,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    route_doc = result["route_doc"]
    print("Route note:")
    print(f"  [{'PASS' if route_doc['exists'] else 'FAIL'}] {route_doc['path']}")

    print("Restored-checkout route scripts:")
    for entry in result["route_scripts"]:
        status = "PASS" if entry["exists"] and entry["mentioned_in_route_doc"] else "FAIL"
        print(f"  [{status}] {entry['path']}")
        if not entry["exists"]:
            print("         missing from the branch")
        elif not entry["mentioned_in_route_doc"]:
            print("         not named in the restored-checkout route note")

    print("Helper-surface contract targets:")
    for target in result["contract_targets"]:
        status = "PASS" if target["exists"] else "FAIL"
        print(f"  [{status}] {target['path']}: {target['label']}")
        for referenced in target["referenced_scripts"]:
            ref_status = "PASS" if referenced["mentioned"] else "FAIL"
            print(f"         [{ref_status}] includes {referenced['path']}")

    if result["ok"]:
        print("\nRestored-checkout helper-surface contract check passed.")
        return

    print("\nRestored-checkout helper-surface contract check failed.", file=sys.stderr)
    print(
        "Suggested next step: add the restored-checkout route scripts to each helper-surface list before trusting synced restore or saved-memory follow-up work.",
        file=sys.stderr,
    )


class RestoredCheckoutHelperSurfaceContractTests(unittest.TestCase):
    def write(self, root: Path, relative_path: str, content: str) -> None:
        path = root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def test_passes_when_all_contract_targets_reference_route_scripts(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            route_doc = "\n".join(REQUIRED_ROUTE_SCRIPTS)
            self.write(root, ROUTE_DOC, route_doc)
            for relative_path in REQUIRED_ROUTE_SCRIPTS:
                self.write(root, relative_path, "#!/usr/bin/env bash\n")
            contract_body = textwrap.dedent(
                f"""
                helper paths
                {REQUIRED_ROUTE_SCRIPTS[0]}
                {REQUIRED_ROUTE_SCRIPTS[1]}
                """
            )
            for relative_path, _label in CONTRACT_TARGETS:
                self.write(root, relative_path, contract_body)

            result = collect_results(root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_count"], 0)

    def test_fails_when_saved_memory_helper_omits_route_scripts(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            route_doc = "\n".join(REQUIRED_ROUTE_SCRIPTS)
            self.write(root, ROUTE_DOC, route_doc)
            for relative_path in REQUIRED_ROUTE_SCRIPTS:
                self.write(root, relative_path, "#!/usr/bin/env bash\n")
            self.write(root, CONTRACT_TARGETS[0][0], "helper paths without restored-checkout route scripts")
            for relative_path, _label in CONTRACT_TARGETS[1:]:
                self.write(
                    root,
                    relative_path,
                    "\n".join(REQUIRED_ROUTE_SCRIPTS),
                )

            result = collect_results(root)

            self.assertFalse(result["ok"])
            self.assertGreaterEqual(result["missing_count"], 2)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoredCheckoutHelperSurfaceContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    result = collect_results(Path(args.repo_root).resolve())
    if args.json:
        print(json.dumps({"profile": "issue3-restored-checkout-helper-surface-contract", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
