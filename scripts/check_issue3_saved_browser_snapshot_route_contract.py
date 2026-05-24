#!/usr/bin/env python3

"""Validate the saved-browser-snapshot restore route contract.

This helper keeps the compact restore route honest by checking the structured
`--check-only --json` output from `scripts/linux/restore_saved_browser_snapshot.sh`.
It makes sure the route still points at the saved browser snapshot archive and
still prints the follow-up commands that future Linux or WSL re-entry runs rely
on before reopening issue #3 runtime work.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest


EXPECTED_TOP_LEVEL = "browser-fork-headed-mode-foundation"
REQUIRED_JSON_KEYS: tuple[str, ...] = (
    "browser_root",
    "helper_root",
    "follow_up_helper_root",
    "memory_root",
    "archive_path",
    "destination",
    "archive_top_level",
    "follow_up_restored_checkout_check",
    "follow_up_memory_check",
    "follow_up_archive_integrity_check",
    "follow_up_build_route",
    "follow_up_runtime_route",
    "check_only",
    "sync_helper_surface",
    "sync_only",
)
REQUIRED_COMMAND_MARKERS: tuple[tuple[str, str], ...] = (
    ("follow_up_restored_checkout_check", "scripts/check_issue3_restored_checkout.py"),
    ("follow_up_memory_check", "scripts/check_issue3_saved_memory_inputs.py"),
    ("follow_up_archive_integrity_check", "scripts/check_issue3_saved_archive_integrity.py"),
    ("follow_up_build_route", "scripts/linux/show_issue3_linux_build_readiness_route.sh"),
    ("follow_up_runtime_route", "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the saved-browser-snapshot restore route still exposes "
            "the expected archive path and follow-up commands."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--route-script",
        default=None,
        help=(
            "Optional explicit path to restore_saved_browser_snapshot.sh "
            "(default: <repo-root>/scripts/linux/restore_saved_browser_snapshot.sh)"
        ),
    )
    parser.add_argument(
        "--sync-helper-surface",
        action="store_true",
        help="Validate the synced-helper-surface route variant as well.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit.",
    )
    return parser


def run_route_script(route_script: Path, *, sync_helper_surface: bool) -> dict[str, object]:
    command = ["bash", str(route_script), "--check-only", "--json"]
    if sync_helper_surface:
        command.append("--sync-helper-surface")
    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"route script exited with {completed.returncode}: {completed.stderr.strip() or completed.stdout.strip()}"
        )
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"route script did not return valid JSON: {exc}") from exc


def validate_route_result(
    result: dict[str, object],
    *,
    route_script: Path,
    sync_helper_surface: bool,
) -> list[str]:
    issues: list[str] = []

    for key in REQUIRED_JSON_KEYS:
        if key not in result:
            issues.append(f"missing JSON field: {key}")

    if issues:
        return issues

    if result.get("archive_top_level") != EXPECTED_TOP_LEVEL:
        issues.append(
            "archive_top_level drifted: "
            f"expected {EXPECTED_TOP_LEVEL!r}, got {result.get('archive_top_level')!r}"
        )

    if result.get("check_only") is not True:
        issues.append("route output should report check_only=true for the contract probe")

    if bool(result.get("sync_helper_surface")) != sync_helper_surface:
        issues.append(
            "sync_helper_surface flag drifted: "
            f"expected {sync_helper_surface}, got {result.get('sync_helper_surface')!r}"
        )

    if result.get("sync_only") is not False:
        issues.append("route output should report sync_only=false for the contract probe")

    for key, marker in REQUIRED_COMMAND_MARKERS:
        value = result.get(key)
        if not isinstance(value, str) or marker not in value:
            issues.append(f"{key} no longer references {marker}")

    route_script_path = route_script.resolve()
    build_route = str(result.get("follow_up_build_route", ""))
    runtime_route = str(result.get("follow_up_runtime_route", ""))
    if "bash " not in build_route or "bash " not in runtime_route:
        issues.append("follow-up route commands should stay on bash helper surfaces")

    if sync_helper_surface:
        if result.get("follow_up_helper_root") != result.get("destination"):
            issues.append(
                "synced helper route should switch follow_up_helper_root to the restored destination"
            )
    else:
        if result.get("follow_up_helper_root") != result.get("helper_root"):
            issues.append(
                "default helper route should keep follow_up_helper_root on the live helper root"
            )

    if route_script_path.name != "restore_saved_browser_snapshot.sh":
        issues.append("unexpected route script basename")

    return issues


def collect_result(
    *,
    repo_root: Path,
    route_script: Path,
    sync_helper_surface: bool,
) -> dict[str, object]:
    exists = route_script.is_file()
    route_output: dict[str, object] | None = None
    issues: list[str] = []

    if not exists:
        issues.append(f"route script is missing: {route_script}")
    else:
        try:
            route_output = run_route_script(route_script, sync_helper_surface=sync_helper_surface)
        except RuntimeError as exc:
            issues.append(str(exc))
        else:
            issues.extend(
                validate_route_result(
                    route_output,
                    route_script=route_script,
                    sync_helper_surface=sync_helper_surface,
                )
            )

    return {
        "ok": not issues,
        "repo_root": str(repo_root),
        "route_script": str(route_script),
        "sync_helper_surface": sync_helper_surface,
        "issues": issues,
        "route_output": route_output,
    }


def emit_text(result: dict[str, object]) -> None:
    status = "PASS" if result["ok"] else "FAIL"
    mode = "synced helper route" if result["sync_helper_surface"] else "default helper route"
    print(f"Saved browser snapshot route contract: [{status}] {mode}")
    print(f"Repo root:    {result['repo_root']}")
    print(f"Route script: {result['route_script']}")
    if result["route_output"] is not None:
        route_output = result["route_output"]
        print(f"Archive top level: {route_output['archive_top_level']}")
        print(f"Archive path:      {route_output['archive_path']}")
        print(f"Destination:       {route_output['destination']}")
        print(f"Helper root:       {route_output['helper_root']}")
        print(f"Follow-up root:    {route_output['follow_up_helper_root']}")
    if result["issues"]:
        print("Issues:")
        for issue in result["issues"]:
            print(f"- {issue}")


class SavedBrowserSnapshotRouteContractTests(unittest.TestCase):
    def test_validate_route_result_accepts_default_route(self) -> None:
        route_script = Path("/tmp/restore_saved_browser_snapshot.sh")
        result = {
            "browser_root": "/tmp/browser",
            "helper_root": "/tmp/browser",
            "follow_up_helper_root": "/tmp/browser",
            "memory_root": "/tmp/memory",
            "archive_path": "/tmp/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "destination": "/tmp/browser-memory-snapshot",
            "archive_top_level": EXPECTED_TOP_LEVEL,
            "follow_up_restored_checkout_check": "python /tmp/browser/scripts/check_issue3_restored_checkout.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_memory_check": "python /tmp/browser/scripts/check_issue3_saved_memory_inputs.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_archive_integrity_check": "python /tmp/browser/scripts/check_issue3_saved_archive_integrity.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_build_route": "bash /tmp/browser/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root /tmp/browser-memory-snapshot",
            "follow_up_runtime_route": "bash /tmp/browser/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root /tmp/browser-memory-snapshot",
            "check_only": True,
            "sync_helper_surface": False,
            "sync_only": False,
        }
        self.assertEqual(
            validate_route_result(result, route_script=route_script, sync_helper_surface=False),
            [],
        )

    def test_validate_route_result_flags_missing_follow_up_marker(self) -> None:
        route_script = Path("/tmp/restore_saved_browser_snapshot.sh")
        result = {
            "browser_root": "/tmp/browser",
            "helper_root": "/tmp/browser",
            "follow_up_helper_root": "/tmp/browser",
            "memory_root": "/tmp/memory",
            "archive_path": "/tmp/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "destination": "/tmp/browser-memory-snapshot",
            "archive_top_level": EXPECTED_TOP_LEVEL,
            "follow_up_restored_checkout_check": "python /tmp/browser/scripts/check_issue3_restored_checkout.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_memory_check": "python /tmp/browser/scripts/check_issue3_saved_memory_inputs.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_archive_integrity_check": "python /tmp/browser/scripts/check_issue3_saved_archive_integrity.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_build_route": "bash /tmp/browser/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root /tmp/browser-memory-snapshot",
            "follow_up_runtime_route": "bash /tmp/browser/scripts/linux/not-the-runtime-helper.sh --repo-root /tmp/browser-memory-snapshot",
            "check_only": True,
            "sync_helper_surface": False,
            "sync_only": False,
        }
        issues = validate_route_result(
            result,
            route_script=route_script,
            sync_helper_surface=False,
        )
        self.assertIn(
            "follow_up_runtime_route no longer references scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            issues,
        )

    def test_collect_result_runs_route_script_and_parses_json(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            route_script = repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
            route_script.parent.mkdir(parents=True, exist_ok=True)
            route_script.write_text(
                textwrap.dedent(
                    f"""\
                    #!/usr/bin/env bash
                    cat <<'EOF'
                    {{
                      "browser_root": "{repo_root}",
                      "helper_root": "{repo_root}",
                      "follow_up_helper_root": "{repo_root}",
                      "memory_root": "{root / 'memory'}",
                      "archive_path": "{root / 'memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip'}",
                      "destination": "{root / 'browser-memory-snapshot'}",
                      "archive_top_level": "{EXPECTED_TOP_LEVEL}",
                      "follow_up_restored_checkout_check": "python {repo_root}/scripts/check_issue3_restored_checkout.py --repo-root {root / 'browser-memory-snapshot'}",
                      "follow_up_memory_check": "python {repo_root}/scripts/check_issue3_saved_memory_inputs.py --repo-root {root / 'browser-memory-snapshot'}",
                      "follow_up_archive_integrity_check": "python {repo_root}/scripts/check_issue3_saved_archive_integrity.py --repo-root {root / 'browser-memory-snapshot'}",
                      "follow_up_build_route": "bash {repo_root}/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root {root / 'browser-memory-snapshot'}",
                      "follow_up_runtime_route": "bash {repo_root}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root {root / 'browser-memory-snapshot'}",
                      "check_only": true,
                      "sync_helper_surface": false,
                      "sync_only": false
                    }}
                    EOF
                    """
                ),
                encoding="utf-8",
            )
            route_script.chmod(0o755)
            result = collect_result(
                repo_root=repo_root,
                route_script=route_script,
                sync_helper_surface=False,
            )
            self.assertTrue(result["ok"])
            self.assertEqual(result["issues"], [])

    def test_collect_result_flags_missing_route_script(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            route_script = root / "browser/scripts/linux/restore_saved_browser_snapshot.sh"
            result = collect_result(
                repo_root=root / "browser",
                route_script=route_script,
                sync_helper_surface=False,
            )
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["issues"],
                [f"route script is missing: {route_script}"],
            )

    def test_validate_route_result_requires_destination_follow_up_root_when_synced(self) -> None:
        route_script = Path("/tmp/restore_saved_browser_snapshot.sh")
        result = {
            "browser_root": "/tmp/browser",
            "helper_root": "/tmp/browser",
            "follow_up_helper_root": "/tmp/browser",
            "memory_root": "/tmp/memory",
            "archive_path": "/tmp/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "destination": "/tmp/browser-memory-snapshot",
            "archive_top_level": EXPECTED_TOP_LEVEL,
            "follow_up_restored_checkout_check": "python /tmp/browser/scripts/check_issue3_restored_checkout.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_memory_check": "python /tmp/browser/scripts/check_issue3_saved_memory_inputs.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_archive_integrity_check": "python /tmp/browser/scripts/check_issue3_saved_archive_integrity.py --repo-root /tmp/browser-memory-snapshot",
            "follow_up_build_route": "bash /tmp/browser/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root /tmp/browser-memory-snapshot",
            "follow_up_runtime_route": "bash /tmp/browser/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root /tmp/browser-memory-snapshot",
            "check_only": True,
            "sync_helper_surface": True,
            "sync_only": False,
        }
        issues = validate_route_result(
            result,
            route_script=route_script,
            sync_helper_surface=True,
        )
        self.assertIn(
            "synced helper route should switch follow_up_helper_root to the restored destination",
            issues,
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedBrowserSnapshotRouteContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    route_script = (
        Path(args.route_script).resolve()
        if args.route_script
        else (repo_root / "scripts/linux/restore_saved_browser_snapshot.sh").resolve()
    )
    result = collect_result(
        repo_root=repo_root,
        route_script=route_script,
        sync_helper_surface=args.sync_helper_surface,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
