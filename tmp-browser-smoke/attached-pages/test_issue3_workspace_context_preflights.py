from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_workspace_context_preflights.py": """
    #!/usr/bin/env python3

    \"\"\"Surface saved-memory and archive-integrity preflights for issue #3 re-entry.

    This helper complements the broader workspace-context and build-readiness
    helpers. Its job is to answer one practical question for issue #11 reruns:
    given the current checkout location, what are the exact saved-memory and saved-
    archive commands that should run before Linux/WSL runtime re-entry is trusted?
    \"\"\"

    DEFAULT_FALLBACK_ZIG_ARCHIVE = \"zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz\"
    DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = \"browser-memory-snapshot\"

    def build_parser():
        parser.add_argument(\"--repo-root\")
        parser.add_argument(\"--helper-root\")
        parser.add_argument(\"--memory-root\")
        parser.add_argument(\"--agent-files-root\")
        parser.add_argument(\"--restored-checkout-root\")
        parser.add_argument(\"--fallback-zig-archive\")
        parser.add_argument(\"--json\")
        parser.add_argument(\"--self-test\")

    def locate_first_existing(start, relative_path):
        return None

    def resolve_default_memory_root(repo_root):
        located = locate_first_existing(repo_root, \"memory\")
        return (repo_root.parent / \"memory\").resolve()

    def resolve_default_agent_files_root(repo_root):
        located = locate_first_existing(repo_root, \"agent_files\")
        return (repo_root.parent / \"agent_files\").resolve()

    def resolve_default_restored_checkout_root(repo_root):
        located = locate_first_existing(repo_root, DEFAULT_RESTORED_CHECKOUT_ROOT_NAME)
        return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME).resolve()

    def resolve_default_fallback_archive(repo_root):
        located = locate_first_existing(repo_root, f\"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}\")
        candidate = (repo_root.parent / \"agent_files\" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
        return candidate if candidate.is_file() else None

    def collect_context(repo_root, helper_root, memory_root, agent_files_root, restored_checkout_root, fallback_zig_archive):
        build_zon = repo_root / \"build.zig.zon\"
        helper_root = helper_root.resolve() if helper_root is not None else repo_root
        memory_root = memory_root.resolve() if memory_root is not None else resolve_default_memory_root(repo_root)
        agent_files_root = agent_files_root.resolve() if agent_files_root is not None else resolve_default_agent_files_root(repo_root)
        restored_checkout_root = restored_checkout_root.resolve() if restored_checkout_root is not None else resolve_default_restored_checkout_root(repo_root)
        fallback_zig_archive = fallback_zig_archive.resolve() if fallback_zig_archive is not None else resolve_default_fallback_archive(repo_root)

        saved_memory_command = [
            \"python\",
            \"scripts/check_issue3_saved_memory_inputs.py\",
            \"--repo-root\",
            str(repo_root),
            \"--helper-root\",
            str(helper_root),
            \"--memory-root\",
            str(memory_root),
            \"--agent-files-root\",
            str(agent_files_root),
            \"--restored-checkout-root\",
            str(restored_checkout_root),
        ]
        saved_archive_integrity_command = [
            \"python\",
            \"scripts/check_issue3_saved_archive_integrity.py\",
            \"--repo-root\",
            str(repo_root),
            \"--memory-root\",
            str(memory_root),
            \"--agent-files-root\",
            str(agent_files_root),
        ]
        restored_checkout_command = [
            \"python\",
            \"scripts/check_issue3_restored_checkout.py\",
            \"--repo-root\",
            str(restored_checkout_root),
            \"--helper-root\",
            str(helper_root),
        ]

        if fallback_zig_archive is not None:
            saved_memory_command.extend((\"--fallback-zig-archive\", str(fallback_zig_archive)))
            saved_archive_integrity_command.extend((\"--fallback-zig-archive\", str(fallback_zig_archive)))

        return {
            \"status\": \"failed\" if not build_zon.is_file() else \"passed\",
            \"saved_memory_command\": saved_memory_command,
            \"saved_archive_integrity_command\": saved_archive_integrity_command,
            \"restored_checkout_command\": restored_checkout_command,
        }

    class WorkspaceContextPreflightsTests(unittest.TestCase):
        pass

    def build_fixture_repo():
        return None

    env_root = os.environ.get(\"LIGHTPANDA_REPO_ROOT\", \"\").strip()
    if os.environ.get(\"LIGHTPANDA_FIXTURE_REPO\") == \"1\":
        pass
    unittest.TextTestRunner(verbosity=2)
    """,
    "scripts/check_issue3_workspace_context.py": """
    #!/usr/bin/env python3

    \"\"\"Surface the practical workspace roots for issue #3 Linux/WSL recovery.\"\"\"

    - where the nearest shared toolchains directory lives
    - where the saved Memory browser archives live
    - where the attached fallback Zig archive is visible from this checkout
    - where the nearest shared offline dependency root and Memory root live
    - which saved-snapshot, saved-Rust, build-readiness, and issue #11 progress-
      tracker route commands already match those roots
    """,
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md": """
    # Issue #3 Workspace-Context Route

    - `scripts/check_issue3_workspace_context.py`
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
    - `scripts/check_issue3_saved_rust_archive_candidates.py`
    - `scripts/check_issue3_staged_rust_toolchain_candidates.py`
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-workspace-context-preflights-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3WorkspaceContextPreflightsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.preflights_helper = read_text(
            cls.repo_root / "scripts/check_issue3_workspace_context_preflights.py"
        )
        cls.workspace_context_helper = read_text(
            cls.repo_root / "scripts/check_issue3_workspace_context.py"
        )
        cls.workspace_context_route = read_text(
            cls.repo_root / "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md"
        )

    def test_helper_docstring_keeps_issue11_preflight_goal_visible(self) -> None:
        for fragment in (
            "Surface saved-memory and archive-integrity preflights for issue #3 re-entry.",
            "This helper complements the broader workspace-context and build-readiness",
            "issue #11 reruns",
            "saved-memory and saved-",
            "archive commands that should run before Linux/WSL runtime re-entry is trusted",
        ):
            self.assertIn(fragment, self.preflights_helper)

    def test_parser_and_default_root_helpers_remain_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"',
            '--repo-root',
            '--helper-root',
            '--memory-root',
            '--agent-files-root',
            '--restored-checkout-root',
            '--fallback-zig-archive',
            '--json',
            '--self-test',
            'locate_first_existing(repo_root, "memory")',
            'locate_first_existing(repo_root, "agent_files")',
            'locate_first_existing(repo_root, DEFAULT_RESTORED_CHECKOUT_ROOT_NAME)',
            'locate_first_existing(repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}")',
            '(repo_root.parent / "memory").resolve()',
            '(repo_root.parent / "agent_files").resolve()',
            '(repo_root.parent / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME).resolve()',
        ):
            self.assertIn(fragment, self.preflights_helper)

    def test_collect_context_keeps_saved_memory_archive_and_restored_commands_aligned(self) -> None:
        for fragment in (
            'build_zon = repo_root / "build.zig.zon"',
            '"scripts/check_issue3_saved_memory_inputs.py"',
            '"scripts/check_issue3_saved_archive_integrity.py"',
            '"scripts/check_issue3_restored_checkout.py"',
            '"--helper-root"',
            '"--memory-root"',
            '"--agent-files-root"',
            '"--restored-checkout-root"',
            'str(restored_checkout_root)',
            'str(agent_files_root)',
            'str(memory_root)',
            'saved_memory_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))',
            'saved_archive_integrity_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))',
            '"saved_memory_command": saved_memory_command',
            '"saved_archive_integrity_command": saved_archive_integrity_command',
            '"restored_checkout_command": restored_checkout_command',
        ):
            self.assertIn(fragment, self.preflights_helper)

    def test_helper_keeps_fixture_mode_and_self_tests_visible(self) -> None:
        for fragment in (
            'class WorkspaceContextPreflightsTests(unittest.TestCase):',
            'build_fixture_repo(',
            'LIGHTPANDA_FIXTURE_REPO',
            'LIGHTPANDA_REPO_ROOT',
            'unittest.TextTestRunner',
        ):
            self.assertIn(fragment, self.preflights_helper)

    def test_helper_stays_positioned_as_companion_to_broader_workspace_context_route(self) -> None:
        for fragment in (
            "Surface the practical workspace roots for issue #3 Linux/WSL recovery.",
            "saved Memory browser archives",
            "fallback Zig archive",
            "offline dependency root and Memory root live",
            "issue #11 progress-",
            "tracker route commands already match those roots",
        ):
            self.assertIn(fragment, self.workspace_context_helper)

        for fragment in (
            "`scripts/check_issue3_workspace_context.py`",
            "`docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`",
            "`docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`",
            "`docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`",
            "`docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`",
            "`docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`",
            "`docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`",
            "`scripts/check_issue3_saved_rust_archive_candidates.py`",
            "`scripts/check_issue3_staged_rust_toolchain_candidates.py`",
        ):
            self.assertIn(fragment, self.workspace_context_route)


if __name__ == "__main__":
    unittest.main()
