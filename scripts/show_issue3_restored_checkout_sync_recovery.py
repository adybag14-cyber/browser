#!/usr/bin/env python3

"""Print exact sync-recovery commands for a restored issue #3 checkout.

This helper is meant for the common scheduled-run failure mode where the saved
browser snapshot restores cleanly, but the restored checkout still lacks the
current issue #3 helper surface from the live branch. It turns that stale state
into exact sync and follow-up commands instead of forcing the next run to
reconstruct them by hand.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shlex
import sys
import tempfile
import unittest


DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
REQUIRED_REPO_ROOT_FILE = "build.zig.zon"


def shell_quote(value: Path | str) -> str:
    return shlex.quote(str(value))


def resolve_workspace_companion_path(root: Path, name: str) -> Path:
    child_path = root / name
    sibling_path = root.parent / name
    if child_path.exists() or root.name == "workspace":
        return child_path.resolve()
    return sibling_path.resolve()


def path_has_live_helper_surface(path: Path) -> bool:
    return (
        path.is_dir()
        and (path / REQUIRED_REPO_ROOT_FILE).is_file()
        and (path / "scripts/linux/restore_saved_browser_snapshot.sh").is_file()
        and (path / "scripts/check_issue3_restored_checkout.py").is_file()
    )


def resolve_default_helper_root(repo_root: Path) -> Path:
    repo_root = repo_root.resolve()
    cwd = Path.cwd().resolve()
    if (
        repo_root.name == DEFAULT_RESTORED_CHECKOUT_NAME
        and cwd != repo_root
        and path_has_live_helper_surface(cwd)
    ):
        return cwd
    return repo_root


def build_restore_command(
    *,
    helper_root: Path,
    memory_root: Path,
    repo_root: Path,
    sync_mode: str,
) -> str:
    restore_script = helper_root / "scripts/linux/restore_saved_browser_snapshot.sh"
    archive_path = memory_root / "repo_archives/browser" / DEFAULT_ARCHIVE_NAME
    base = (
        f"bash {shell_quote(restore_script)}"
        f" --browser-root {shell_quote(helper_root)}"
        f" --helper-root {shell_quote(helper_root)}"
        f" --memory-root {shell_quote(memory_root)}"
        f" --archive {shell_quote(archive_path)}"
        f" --destination {shell_quote(repo_root)}"
    )
    if sync_mode == "sync-only":
        return base + " --sync-only"
    if sync_mode == "sync-helper-surface":
        return base + " --sync-helper-surface"
    raise ValueError(f"Unsupported sync mode: {sync_mode}")


def resolve_follow_up_script(repo_root: Path, helper_root: Path, relative_path: str) -> Path:
    restored_candidate = repo_root / relative_path
    if restored_candidate.is_file():
        return restored_candidate
    return helper_root / relative_path


def build_follow_up_commands(
    *,
    repo_root: Path,
    helper_root: Path,
    memory_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, str]:
    restored_checkout_checker = resolve_follow_up_script(
        repo_root, helper_root, "scripts/check_issue3_restored_checkout.py"
    )
    saved_memory_preflight = resolve_follow_up_script(
        repo_root, helper_root, "scripts/check_issue3_saved_memory_inputs.py"
    )
    linux_build_route = resolve_follow_up_script(
        repo_root, helper_root, "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    )
    runtime_route = resolve_follow_up_script(
        repo_root,
        helper_root,
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
    )

    commands = {
        "restored_checkout_check": (
            f"python {shell_quote(restored_checkout_checker)}"
            f" --repo-root {shell_quote(repo_root)}"
            f" --helper-root {shell_quote(helper_root)}"
            " --expect-helper-surface"
        ),
        "saved_memory_preflight": (
            f"python {shell_quote(saved_memory_preflight)}"
            f" --repo-root {shell_quote(repo_root)}"
            f" --helper-root {shell_quote(helper_root)}"
            f" --memory-root {shell_quote(memory_root)}"
        ),
        "linux_build_route": (
            f"bash {shell_quote(linux_build_route)}"
            f" --repo-root {shell_quote(repo_root)}"
        ),
        "runtime_route": (
            f"bash {shell_quote(runtime_route)}"
            f" --repo-root {shell_quote(repo_root)}"
        ),
    }

    if fallback_zig_archive is not None:
        commands["saved_memory_preflight"] += (
            f" --fallback-zig-archive {shell_quote(fallback_zig_archive)}"
        )
        commands["linux_build_route"] += (
            f" --fallback-zig-archive {shell_quote(fallback_zig_archive)}"
        )
        commands["runtime_route"] += (
            f" --fallback-zig-archive {shell_quote(fallback_zig_archive)}"
        )

    return commands


def collect_results(
    *,
    repo_root: Path,
    helper_root: Path,
    memory_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    repo_root = repo_root.resolve()
    helper_root = helper_root.resolve()
    memory_root = memory_root.resolve()
    repo_exists = repo_root.is_dir()
    has_build_manifest = (repo_root / REQUIRED_REPO_ROOT_FILE).is_file()
    recommended_mode = "sync-only" if repo_exists and has_build_manifest else "sync-helper-surface"

    sync_only_refresh = build_restore_command(
        helper_root=helper_root,
        memory_root=memory_root,
        repo_root=repo_root,
        sync_mode="sync-only",
    )
    sync_helper_surface_refresh = build_restore_command(
        helper_root=helper_root,
        memory_root=memory_root,
        repo_root=repo_root,
        sync_mode="sync-helper-surface",
    )

    commands = {
        "sync_only_refresh": sync_only_refresh,
        "sync_only_check": sync_only_refresh + " --check-only",
        "sync_helper_surface_refresh": sync_helper_surface_refresh,
        "sync_helper_surface_check": sync_helper_surface_refresh + " --check-only",
    }
    commands.update(
        build_follow_up_commands(
            repo_root=repo_root,
            helper_root=helper_root,
            memory_root=memory_root,
            fallback_zig_archive=fallback_zig_archive,
        )
    )

    notes = [
        "Use sync-only when the restored checkout already exists and only the helper surface needs to be refreshed in place.",
        "Use sync-helper-surface when the saved snapshot needs to be restored or rebuilt as a self-contained follow-up checkout.",
        "Run restored_checkout_check immediately after the sync step so helper drift fails fast before broader Linux or WSL replay.",
        "Run saved_memory_preflight after the restored-checkout check and before the wider build-readiness route.",
        "Use runtime_route only after the restored checkout carries the current helper surface and the build-readiness gate stops being the blocker.",
    ]

    return {
        "profile": "issue3-restored-checkout-sync-recovery",
        "repo_root": str(repo_root),
        "helper_root": str(helper_root),
        "memory_root": str(memory_root),
        "fallback_zig_archive": None if fallback_zig_archive is None else str(fallback_zig_archive),
        "repo_exists": repo_exists,
        "has_build_manifest": has_build_manifest,
        "recommended_mode": recommended_mode,
        "recommended_command": commands[
            "sync_only_refresh"
            if recommended_mode == "sync-only"
            else "sync_helper_surface_refresh"
        ],
        "commands": commands,
        "notes": notes,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Google issue #3 restored-checkout sync recovery")
    print("")
    print(f"Restored checkout: {result['repo_root']}")
    print(f"Helper root:       {result['helper_root']}")
    print(f"Memory root:       {result['memory_root']}")
    print(
        "Recommended mode: "
        f"{result['recommended_mode']} "
        f"({'existing checkout detected' if result['recommended_mode'] == 'sync-only' else 'restore or rebuild checkout first'})"
    )
    print("")
    print("Commands:")
    for key, value in result["commands"].items():
        print(f"  {key}:")
        print(f"    {value}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Print exact recovery commands for refreshing the issue #3 helper "
            "surface inside a restored browser snapshot checkout."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the restored browser checkout (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Path to the live helper checkout that owns restore_saved_browser_snapshot.sh "
            "and the current issue #3 helper surface"
        ),
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: beside the helper root)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the fallback Zig archive",
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


class RestoredCheckoutSyncRecoveryTests(unittest.TestCase):
    def test_recommends_sync_only_for_existing_restored_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            memory_root = root / "memory"
            repo_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            memory_root.mkdir()
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            (helper_root / "scripts/linux").mkdir(parents=True, exist_ok=True)
            (helper_root / "scripts").mkdir(parents=True, exist_ok=True)
            (helper_root / "scripts/linux/restore_saved_browser_snapshot.sh").write_text(
                "#!/usr/bin/env bash\n", encoding="utf-8"
            )
            (helper_root / "scripts/check_issue3_restored_checkout.py").write_text(
                "pass\n", encoding="utf-8"
            )
            (helper_root / "scripts/check_issue3_saved_memory_inputs.py").write_text(
                "pass\n", encoding="utf-8"
            )
            (helper_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh").write_text(
                "#!/usr/bin/env bash\n", encoding="utf-8"
            )
            (
                helper_root
                / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
            ).write_text("#!/usr/bin/env bash\n", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=helper_root,
                memory_root=memory_root,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_mode"], "sync-only")
            self.assertIn("--sync-only", result["recommended_command"])
            self.assertEqual(
                result["commands"]["restored_checkout_check"].split()[1],
                str(helper_root / "scripts/check_issue3_restored_checkout.py"),
            )

    def test_recommends_sync_helper_surface_when_checkout_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            memory_root = root / "memory"
            repo_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            memory_root.mkdir()
            (helper_root / "scripts/linux").mkdir(parents=True, exist_ok=True)
            (helper_root / "scripts").mkdir(parents=True, exist_ok=True)
            (helper_root / "scripts/linux/restore_saved_browser_snapshot.sh").write_text(
                "#!/usr/bin/env bash\n", encoding="utf-8"
            )
            (helper_root / "scripts/check_issue3_restored_checkout.py").write_text(
                "pass\n", encoding="utf-8"
            )
            (helper_root / "scripts/check_issue3_saved_memory_inputs.py").write_text(
                "pass\n", encoding="utf-8"
            )
            (helper_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh").write_text(
                "#!/usr/bin/env bash\n", encoding="utf-8"
            )
            (
                helper_root
                / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
            ).write_text("#!/usr/bin/env bash\n", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=helper_root,
                memory_root=memory_root,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_mode"], "sync-helper-surface")
            self.assertIn("--sync-helper-surface", result["recommended_command"])

    def test_default_helper_root_prefers_live_cwd_for_restored_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            repo_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            repo_root.mkdir()
            (helper_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            (helper_root / "scripts/linux").mkdir(parents=True, exist_ok=True)
            (helper_root / "scripts").mkdir(parents=True, exist_ok=True)
            (helper_root / "scripts/linux/restore_saved_browser_snapshot.sh").write_text(
                "#!/usr/bin/env bash\n", encoding="utf-8"
            )
            (helper_root / "scripts/check_issue3_restored_checkout.py").write_text(
                "pass\n", encoding="utf-8"
            )

            original_cwd = Path.cwd()
            try:
                os.chdir(helper_root)
                self.assertEqual(resolve_default_helper_root(repo_root), helper_root.resolve())
            finally:
                os.chdir(original_cwd)

    def test_fallback_zig_archive_is_forwarded_to_follow_up_commands(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            memory_root = root / "memory"
            repo_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            zig_archive = root / DEFAULT_FALLBACK_ZIG_ARCHIVE
            helper_root.mkdir()
            memory_root.mkdir()
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            zig_archive.write_text("zig", encoding="utf-8")
            (helper_root / "scripts/linux").mkdir(parents=True, exist_ok=True)
            (helper_root / "scripts").mkdir(parents=True, exist_ok=True)
            (helper_root / "scripts/linux/restore_saved_browser_snapshot.sh").write_text(
                "#!/usr/bin/env bash\n", encoding="utf-8"
            )
            (helper_root / "scripts/check_issue3_restored_checkout.py").write_text(
                "pass\n", encoding="utf-8"
            )
            (helper_root / "scripts/check_issue3_saved_memory_inputs.py").write_text(
                "pass\n", encoding="utf-8"
            )
            (helper_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh").write_text(
                "#!/usr/bin/env bash\n", encoding="utf-8"
            )
            (
                helper_root
                / "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
            ).write_text("#!/usr/bin/env bash\n", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=helper_root,
                memory_root=memory_root,
                fallback_zig_archive=zig_archive,
            )

            self.assertIn("--fallback-zig-archive", result["commands"]["saved_memory_preflight"])
            self.assertIn("--fallback-zig-archive", result["commands"]["linux_build_route"])
            self.assertIn("--fallback-zig-archive", result["commands"]["runtime_route"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoredCheckoutSyncRecoveryTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = (
        Path(args.helper_root).resolve()
        if args.helper_root
        else resolve_default_helper_root(repo_root)
    )
    memory_root = (
        Path(args.memory_root).resolve()
        if args.memory_root
        else resolve_workspace_companion_path(helper_root, "memory")
    )
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else None
    )

    result = collect_results(
        repo_root=repo_root,
        helper_root=helper_root,
        memory_root=memory_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
