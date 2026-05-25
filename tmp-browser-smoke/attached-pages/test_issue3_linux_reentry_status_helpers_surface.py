from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "scripts/check_issue3_linux_reentry_status.py": """
def extract_workspace_overrides(workspace_context):
    for key in (
        "memory_root",
        "agent_files_root",
        "restored_checkout_root",
        "saved_archives_root",
        "toolchains_root",
        "offline_deps_root",
    ):
        pass
    fallback_archive = workspace_context.get("fallback_zig_archive")
    fallback_found = workspace_context.get("fallback_zig_archive_found")

def build_component_commands(repo_root, python_executable, workspace_context=None):
    commands = {
        "workspace_context": [
            python_executable,
            str(repo_root / "scripts" / "check_issue3_workspace_context.py"),
            "--repo-root",
            str(repo_root),
            "--json",
        ]
    }
    saved_memory = [
        python_executable,
        str(repo_root / "scripts" / "check_issue3_saved_memory_inputs.py"),
        "--repo-root",
        str(repo_root),
        "--json",
    ]
    saved_memory.extend(("--memory-root", "/tmp/memory"))
    saved_memory.extend(("--agent-files-root", "/tmp/agent_files"))
    saved_memory.extend(("--restored-checkout-root", "/tmp/restored"))
    saved_memory.extend(("--fallback-zig-archive", "/tmp/agent_files/zig.tar.xz"))
    zig_match = [
        "bash",
        str(repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"),
        "--repo-root",
        str(repo_root),
        "--json",
    ]
    zig_match.extend(("--toolchains-root", "/tmp/toolchains"))
    zig_match.extend(("--saved-archives-root", "/tmp/memory/repo_archives/browser"))
    zig_match.extend(("--fallback-zig-archive", "/tmp/agent_files/zig.tar.xz"))
    build_readiness = [
        python_executable,
        str(repo_root / "scripts" / "check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--expect-saved-archives",
        "--expect-offline-deps",
        "--require-prebuilt-v8",
        "--json",
    ]
    build_readiness.extend(("--toolchains-root", "/tmp/toolchains"))
    build_readiness.extend(("--saved-archives-root", "/tmp/memory/repo_archives/browser"))
    build_readiness.extend(("--offline-deps-root", "/tmp/offline-deps"))
    build_readiness.extend(("--fallback-zig-archive", "/tmp/agent_files/zig.tar.xz"))

def choose_next_step(results, repo_root):
    return route_command(repo_root, "scripts/linux/show_issue3_workspace_context_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_saved_memory_inputs_route.sh")
    preferred_restore = zig_json.get("preferred_saved_archive_restore_check")
    return route_command(repo_root, "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh")
    suggested = readiness_json.get("suggested_next_step")
    return route_command(repo_root, "scripts/linux/show_issue3_linux_build_readiness_route.sh")
    return route_command(repo_root, "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh")
""",
    "scripts/check_issue3_matching_zig_toolchain.py": """
DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

def resolve_default_toolchains_root(repo_root):
    return (repo_root.parent / "toolchains").resolve()

def resolve_default_offline_deps_root(repo_root):
    return (repo_root.parent / "offline-deps").resolve()

def resolve_default_saved_archives_root(repo_root):
    browser_root = (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()
    dependencies_root = browser_root / "dependencies"
    return dependencies_root if dependencies_root.is_dir() else browser_root

def resolve_default_fallback_archive(repo_root):
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.is_file() else None

def build_readiness_command():
    command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        "/tmp/browser",
        "--zig",
        "/tmp/toolchains/zig-0.15.2/zig",
        "--toolchains-root",
        "/tmp/toolchains",
        "--expect-offline-deps",
        "--offline-deps-root",
        "/tmp/offline-deps",
        "--expect-saved-archives",
        "--saved-archives-root",
        "/tmp/memory/repo_archives/browser/dependencies",
        "--require-prebuilt-v8",
        "--skip-rust-check",
        "--fallback-zig-archive",
        "/tmp/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
    ]
    return command
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-linux-reentry-status-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LinuxReentryStatusHelpersSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = build_fixture_repo()

        cls.status_helper = (
            cls.repo_root / "scripts/check_issue3_linux_reentry_status.py"
        ).read_text(encoding="utf-8")
        cls.matching_helper = (
            cls.repo_root / "scripts/check_issue3_matching_zig_toolchain.py"
        ).read_text(encoding="utf-8")

    def test_status_helper_threads_workspace_roots_into_follow_up_commands(self) -> None:
        for fragment in (
            '"memory_root",',
            '"agent_files_root",',
            '"restored_checkout_root",',
            '"saved_archives_root",',
            '"toolchains_root",',
            '"offline_deps_root",',
            'fallback_archive = workspace_context.get("fallback_zig_archive")',
            'fallback_found = workspace_context.get("fallback_zig_archive_found")',
            'str(repo_root / "scripts" / "check_issue3_workspace_context.py")',
            'str(repo_root / "scripts" / "check_issue3_saved_memory_inputs.py")',
            'str(repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh")',
            'str(repo_root / "scripts" / "check_linux_build_readiness.py")',
            '"--memory-root"',
            '"--agent-files-root"',
            '"--restored-checkout-root"',
            '"--saved-archives-root"',
            '"--toolchains-root"',
            '"--offline-deps-root"',
            '"--fallback-zig-archive"',
            '"--expect-saved-archives"',
            '"--expect-offline-deps"',
            '"--require-prebuilt-v8"',
        ):
            self.assertIn(fragment, self.status_helper)

    def test_status_helper_keeps_route_priority_order_visible(self) -> None:
        for fragment in (
            'route_command(repo_root, "scripts/linux/show_issue3_workspace_context_route.sh")',
            'route_command(repo_root, "scripts/linux/show_issue3_saved_memory_inputs_route.sh")',
            'preferred_restore = zig_json.get("preferred_saved_archive_restore_check")',
            'route_command(repo_root, "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh")',
            'suggested = readiness_json.get("suggested_next_step")',
            'route_command(repo_root, "scripts/linux/show_issue3_linux_build_readiness_route.sh")',
            'route_command(repo_root, "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh")',
        ):
            self.assertIn(fragment, self.status_helper)

    def test_matching_helper_keeps_default_workspace_roots_visible(self) -> None:
        for fragment in (
            'return (repo_root.parent / "toolchains").resolve()',
            'return (repo_root.parent / "offline-deps").resolve()',
            'browser_root = (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()',
            'dependencies_root = browser_root / "dependencies"',
            'candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()',
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            '"zig*/zig"',
            '"zig*/bin/zig"',
            '"*/zig"',
            '"*/bin/zig"',
            '"zig"',
        ):
            self.assertIn(fragment, self.matching_helper)

    def test_matching_helper_keeps_readiness_rerun_contract_visible(self) -> None:
        for fragment in (
            '"scripts/check_linux_build_readiness.py"',
            '"--repo-root"',
            '"--zig"',
            '"--toolchains-root"',
            '"--expect-offline-deps"',
            '"--offline-deps-root"',
            '"--expect-saved-archives"',
            '"--saved-archives-root"',
            '"--require-prebuilt-v8"',
            '"--skip-rust-check"',
            '"--fallback-zig-archive"',
            '"/tmp/memory/repo_archives/browser/dependencies"',
            '"/tmp/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
        ):
            self.assertIn(fragment, self.matching_helper)


if __name__ == "__main__":
    unittest.main()
