from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/check_issue3_saved_archives_workspace_root.py": """
    #!/usr/bin/env python3
    from __future__ import annotations
    import pathlib
    import unittest
    SAVED_ARCHIVE_GLOBS = {
        "rust_toolchain": "01-rust-*.tar.xz",
        "html5ever": "02-litefetch-html5ever-*.zip",
        "boringssl": "03-boringssl-zig-main.zip",
        "browser_deps": "04-zig-browser-depo.tar.zip",
    }
    SAVED_ARCHIVE_LABELS = {
        "rust_toolchain": "saved Rust toolchain archive",
        "html5ever": "saved html5ever dependency archive",
        "boringssl": "saved BoringSSL archive",
        "browser_deps": "saved browser dependency archive",
    }
    REQUIRED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
    OPTIONAL_ARCHIVE_KEYS = ("html5ever",)
    def ancestor_chain(start: pathlib.Path) -> list[pathlib.Path]:
        return []
    def locate_first_existing(start: pathlib.Path, relative_path: str) -> pathlib.Path | None:
        return None
    def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
        located = locate_first_existing(repo_root, "memory/repo_archives/browser")
        return located
    def normalize_saved_archives_root(saved_archives_root: pathlib.Path) -> pathlib.Path:
        dependencies_root = saved_archives_root / "dependencies"
        return dependencies_root.resolve()
    def discover_saved_archives(saved_archives_root): return {}
    def check_saved_archives_root(saved_archives_root): return [], {}
    class SavedArchivesWorkspaceRootTests(unittest.TestCase):
        def test_default_root_uses_repo_parent_when_workspace_is_flat(self) -> None: pass
        def test_default_root_discovers_ancestor_memory_workspace(self) -> None: pass
        def test_normalization_prefers_dependencies_subdirectory(self) -> None: pass
        def test_check_saved_archives_root_accepts_dependencies_layout(self) -> None: pass
    report = {
        "status": "failed" if failures else "passed",
        "repo_root": repo_root,
        "requested_saved_archives_root": requested_root,
        "discovered_saved_archives_root": discovered_root,
        "normalized_saved_archives_root": normalized_root,
        "saved_archives": discovered_archives,
        "failures": failures,
        "suggested_next_step": next_step,
    }
    print(f"Discovered saved archive root: {discovered_root}")
    print(f"Normalized saved archive root: {normalized_root}")
    print("\\nSaved archive discovery passed.")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-archives-root-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedArchivesWorkspaceRootContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archives_workspace_root.py"
        )

    def test_helper_keeps_workspace_discovery_and_normalization_visible(self) -> None:
        for fragment in (
            'def ancestor_chain(start: pathlib.Path) -> list[pathlib.Path]:',
            'def locate_first_existing(start: pathlib.Path, relative_path: str) -> pathlib.Path | None:',
            'def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:',
            '"memory/repo_archives/browser"',
            'def normalize_saved_archives_root(saved_archives_root: pathlib.Path) -> pathlib.Path:',
            '"dependencies"',
        ):
            self.assertIn(fragment, self.helper)

    def test_helper_keeps_saved_archive_contract_and_required_keys_visible(self) -> None:
        for fragment in (
            '"rust_toolchain": "01-rust-*.tar.xz"',
            '"html5ever": "02-litefetch-html5ever-*.zip"',
            '"boringssl": "03-boringssl-zig-main.zip"',
            '"browser_deps": "04-zig-browser-depo.tar.zip"',
            '"saved Rust toolchain archive"',
            '"saved html5ever dependency archive"',
            '"saved BoringSSL archive"',
            '"saved browser dependency archive"',
            'REQUIRED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")',
            'OPTIONAL_ARCHIVE_KEYS = ("html5ever",)',
        ):
            self.assertIn(fragment, self.helper)

    def test_helper_keeps_self_test_surface_visible(self) -> None:
        for fragment in (
            "class SavedArchivesWorkspaceRootTests(unittest.TestCase):",
            "def test_default_root_uses_repo_parent_when_workspace_is_flat(self) -> None:",
            "def test_default_root_discovers_ancestor_memory_workspace(self) -> None:",
            "def test_normalization_prefers_dependencies_subdirectory(self) -> None:",
            "def test_check_saved_archives_root_accepts_dependencies_layout(self) -> None:",
        ):
            self.assertIn(fragment, self.helper)

    def test_helper_keeps_report_fields_and_console_output_visible(self) -> None:
        for fragment in (
            '"status": "failed" if failures else "passed"',
            '"requested_saved_archives_root": requested_root',
            '"discovered_saved_archives_root": discovered_root',
            '"normalized_saved_archives_root": normalized_root',
            '"saved_archives": discovered_archives',
            '"failures": failures',
            '"suggested_next_step": next_step',
            'print(f"Discovered saved archive root: {discovered_root}")',
            'print(f"Normalized saved archive root: {normalized_root}")',
            'print("\\nSaved archive discovery passed.")',
        ):
            self.assertIn(fragment, self.helper)


if __name__ == "__main__":
    unittest.main()
