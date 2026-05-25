from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/linux/show_issue3_saved_zig_archive_candidates.sh": """
    Usage:
      bash scripts/linux/show_issue3_saved_zig_archive_candidates.sh \
        [--repo-root /path/to/browser-repo] \
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
        [--toolchains-root /path/to/toolchains] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--json]
    normalize_saved_archives_root() {
        if [[ -d "${raw_root}/dependencies" ]]; then
            raw_root="${raw_root}/dependencies"
        fi
    }
    DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    COMMAND=(
        python3
        "${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py"
        --repo-root "${REPO_ROOT}"
        --saved-archives-root "${SAVED_ARCHIVES_ROOT}"
        --toolchains-root "${TOOLCHAINS_ROOT}"
    )
    COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
    COMMAND+=(--json)
    "${COMMAND[@]}"
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    def build_saved_archive_search_roots(saved_archives_root):
        dependencies_root = normalized_root / "dependencies"
    def resolve_default_saved_archives_root(repo_root):
        return normalize_saved_archives_root(repo_root.parent / "memory" / "repo_archives" / "browser")
    def resolve_default_toolchains_root(repo_root):
        return (repo_root.parent / "toolchains").resolve()
    def resolve_default_fallback_archive(repo_root):
        candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    def build_report(
    "saved_archives_search_roots": [str(root) for root in saved_archives_search_roots]
    "toolchains_root": str(toolchains_root)
    "fallback_archive": str(fallback_archive) if fallback_archive is not None else ""
    "commands": commands
    "failures": failures
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
    saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"
    saved_archive_candidate_discovery_command = format_command(
    "saved_archive_candidate_discovery"
    "Saved archive candidate discovery"
    "The saved-archives-root override accepts either repo_archives/browser or repo_archives/browser/dependencies"
    """,
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": """
    scripts/check_issue3_saved_zig_archive_candidates.py
    Saved Zig archive candidate discovery when the exact 0.15.x archive path is not known yet
    bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    scripts/check_issue3_saved_zig_archive_candidates.py
    --saved-archives-root
    ../memory/repo_archives/browser/dependencies
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-zig-wrapper-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedZigArchiveCandidatesWrapperSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.wrapper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_zig_archive_candidates.sh"
        )
        cls.helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.build_readiness_route = read_text(
            cls.repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )

    def test_wrapper_keeps_cli_and_default_sibling_paths_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/show_issue3_saved_zig_archive_candidates.sh",
            "--repo-root /path/to/browser-repo",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--toolchains-root /path/to/toolchains",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--json",
            'DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"',
            'memory/repo_archives/browser',
            'TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"',
            'agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz',
            'normalize_saved_archives_root() {',
            'raw_root="${raw_root}/dependencies"',
        ):
            self.assertIn(fragment, self.wrapper)

    def test_wrapper_keeps_helper_delegation_and_optional_flags_visible(self) -> None:
        for fragment in (
            'python3',
            '"${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py"',
            '--repo-root "${REPO_ROOT}"',
            '--saved-archives-root "${SAVED_ARCHIVES_ROOT}"',
            '--toolchains-root "${TOOLCHAINS_ROOT}"',
            'COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")',
            'COMMAND+=(--json)',
            '"${COMMAND[@]}"',
        ):
            self.assertIn(fragment, self.wrapper)

    def test_helper_keeps_matching_override_and_report_fields_visible(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'dependencies_root = normalized_root / "dependencies"',
            'repo_root.parent / "memory" / "repo_archives" / "browser"',
            'return (repo_root.parent / "toolchains").resolve()',
            'repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE',
            '"saved_archives_search_roots": [str(root) for root in saved_archives_search_roots]',
            '"toolchains_root": str(toolchains_root)',
            '"fallback_archive": str(fallback_archive) if fallback_archive is not None else ""',
            '"commands": commands',
            '"failures": failures',
        ):
            self.assertIn(fragment, self.helper)

    def test_route_helpers_keep_wrapper_and_saved_archive_discovery_surface_visible(self) -> None:
        for fragment in (
            'saved_archive_candidates_script = repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"',
            'saved_archive_candidate_discovery_command = format_command(',
            '"saved_archive_candidate_discovery"',
            '"Saved archive candidate discovery"',
            "The saved-archives-root override accepts either repo_archives/browser or repo_archives/browser/dependencies",
        ):
            self.assertIn(fragment, self.recovery_route)

        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "Saved Zig archive candidate discovery when the exact 0.15.x archive path is not known yet",
            "bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        ):
            self.assertIn(fragment, self.build_readiness_route)

        for fragment in (
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "--saved-archives-root",
            "../memory/repo_archives/browser/dependencies",
        ):
            self.assertIn(fragment, self.recovery_note)


if __name__ == "__main__":
    unittest.main()
