from __future__ import annotations

import importlib.util
import os
import pathlib
import tempfile
import unittest


FIXTURE_HELPER = """
from __future__ import annotations

from pathlib import Path

DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


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


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        root = located
    else:
        root = (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()
    dependencies_root = root / "dependencies"
    return dependencies_root if dependencies_root.is_dir() else root


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "offline-deps")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "offline-deps").resolve()


def resolve_fallback_zig_archive(repo_root: Path, explicit_archive: Path | None) -> Path | None:
    if explicit_archive is not None:
        return explicit_archive.resolve()
    located = locate_first_existing(repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}")
    if located is not None and located.is_file():
        return located
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.exists() else None


def build_readiness_rerun_command(
    repo_root: Path,
    zig_path: Path,
    toolchains_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
) -> list[str]:
    command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--zig",
        str(zig_path),
        "--toolchains-root",
        str(toolchains_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-saved-archives",
        "--offline-deps-root",
        str(offline_deps_root),
        "--expect-offline-deps",
        "--require-prebuilt-v8",
    ]
    if fallback_zig_archive is not None:
        command.extend(["--fallback-zig-archive", str(fallback_zig_archive)])
    return command
"""


def load_helper_module(repo_root: pathlib.Path):
    helper_path = repo_root / "scripts" / "check_issue3_build_readiness_rerun.py"
    spec = importlib.util.spec_from_file_location("issue3_build_readiness_rerun", helper_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load helper module from {helper_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def build_fixture_repo() -> pathlib.Path:
    workspace_root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-build-rerun-roots-"))
    repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
    repo_root.mkdir(parents=True)
    (repo_root / "scripts").mkdir(parents=True, exist_ok=True)
    (repo_root / "scripts" / "check_issue3_build_readiness_rerun.py").write_text(
        FIXTURE_HELPER,
        encoding="utf-8",
    )
    (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")
    return repo_root


class Issue3BuildReadinessRerunWorkspaceRootsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]
        cls.helper = load_helper_module(cls.repo_root)

    def test_nested_workspace_defaults_resolve_shared_roots(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = pathlib.Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            toolchains_root = workspace_root / "toolchains"
            toolchains_root.mkdir()
            saved_archives_root = workspace_root / "memory" / "repo_archives" / "browser" / "dependencies"
            saved_archives_root.mkdir(parents=True)
            offline_deps_root = workspace_root / "offline-deps"
            offline_deps_root.mkdir()
            agent_files_root = workspace_root / "agent_files"
            agent_files_root.mkdir()
            fallback_archive = agent_files_root / self.helper.DEFAULT_FALLBACK_ZIG_ARCHIVE
            fallback_archive.write_text("zig", encoding="utf-8")

            self.assertEqual(
                self.helper.resolve_default_toolchains_root(repo_root),
                toolchains_root.resolve(),
            )
            self.assertEqual(
                self.helper.resolve_default_saved_archives_root(repo_root),
                saved_archives_root.resolve(),
            )
            self.assertEqual(
                self.helper.resolve_default_offline_deps_root(repo_root),
                offline_deps_root.resolve(),
            )
            self.assertEqual(
                self.helper.resolve_fallback_zig_archive(repo_root, None),
                fallback_archive.resolve(),
            )

    def test_saved_archives_root_prefers_dependencies_subdirectory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = pathlib.Path(tmpdir)
            repo_root = workspace_root / "browser"
            repo_root.mkdir()
            browser_root = workspace_root / "memory" / "repo_archives" / "browser"
            dependencies_root = browser_root / "dependencies"
            dependencies_root.mkdir(parents=True)

            self.assertEqual(
                self.helper.resolve_default_saved_archives_root(repo_root),
                dependencies_root.resolve(),
            )

    def test_rerun_command_keeps_resolved_root_overrides_visible(self) -> None:
        repo_root = pathlib.Path("/tmp/restored/browser-memory-snapshot/browser")
        zig_path = pathlib.Path("/tmp/toolchains/zig-0.15.7/zig")
        toolchains_root = pathlib.Path("/tmp/toolchains")
        saved_archives_root = pathlib.Path("/tmp/memory/repo_archives/browser/dependencies")
        offline_deps_root = pathlib.Path("/tmp/offline-deps")
        fallback_archive = pathlib.Path("/tmp/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz")

        command = self.helper.build_readiness_rerun_command(
            repo_root,
            zig_path,
            toolchains_root,
            saved_archives_root,
            offline_deps_root,
            fallback_archive,
        )

        self.assertIn("--toolchains-root", command)
        self.assertIn(str(toolchains_root), command)
        self.assertIn("--saved-archives-root", command)
        self.assertIn(str(saved_archives_root), command)
        self.assertIn("--offline-deps-root", command)
        self.assertIn(str(offline_deps_root), command)
        self.assertIn("--fallback-zig-archive", command)
        self.assertIn(str(fallback_archive), command)


if __name__ == "__main__":
    unittest.main()
