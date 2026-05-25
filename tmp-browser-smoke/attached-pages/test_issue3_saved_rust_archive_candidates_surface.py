from __future__ import annotations

import os
from pathlib import Path
import tempfile
import unittest


REQUIRED_FILES: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "Saved Rust toolchain route note for the Linux or WSL re-entry lane.",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "Fail-fast route surface checker for the saved Rust toolchain lane.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "Saved Rust archive candidate selector.",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "Wrapper that surfaces the saved Rust route with repo-local defaults.",
    ),
)

SNIPPET_EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "The saved Rust route note keeps the archive selector visible.",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "1.79.0",
        "The saved Rust route note keeps the expected branch companion Rust line visible.",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "../toolchains/rust-1.79.0",
        "The saved Rust route note keeps the aligned restore destination visible.",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "The route surface checker keeps the saved Rust archive selector visible.",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "show_issue3_saved_rust_toolchain_route.sh|Saved archive candidate discovery:",
        "The route surface checker keeps the saved archive discovery step visible.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "--saved-archives-root",
        "The saved Rust archive selector still supports an explicit saved-archives root.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "--toolchains-root",
        "The saved Rust archive selector still supports an explicit toolchains root.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "normalize_saved_archives_root",
        "The saved Rust archive selector still normalizes repo_archives/browser to dependencies.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "Issue #11 saved Rust archive candidates",
        "The saved Rust archive selector still prints the issue #11 summary header.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "Preferred restore commands:",
        "The saved Rust archive selector still prints preferred restore commands when a match exists.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "no saved Rust archive under",
        "The saved Rust archive selector still reports a clear mismatch failure.",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "saved_archive_candidates",
        "The saved Rust route wrapper still exposes the archive candidate discovery command in JSON output.",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "check_issue3_saved_rust_archive_candidates.py",
        "The saved Rust route wrapper still delegates to the archive candidate selector.",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "Saved archive candidate discovery:",
        "The saved Rust route wrapper still prints the archive discovery step in text output.",
    ),
)


def collect_surface_state(repo_root: Path) -> dict[str, object]:
    missing_files: list[str] = []
    missing_snippets: list[dict[str, str]] = []

    for relative_path, _purpose in REQUIRED_FILES:
        if not (repo_root / relative_path).is_file():
            missing_files.append(relative_path)

    for relative_path, snippet, purpose in SNIPPET_EXPECTATIONS:
        target = repo_root / relative_path
        if not target.is_file() or snippet not in target.read_text(encoding="utf-8"):
            missing_snippets.append(
                {
                    "path": relative_path,
                    "snippet": snippet,
                    "purpose": purpose,
                }
            )

    return {
        "repo_root": str(repo_root),
        "missing_files": missing_files,
        "missing_snippets": missing_snippets,
    }


def build_fixture_repo(root: Path) -> None:
    file_snippets: dict[str, list[str]] = {}
    for relative_path, _purpose in REQUIRED_FILES:
        file_snippets.setdefault(relative_path, [])
    for relative_path, snippet, _purpose in SNIPPET_EXPECTATIONS:
        file_snippets.setdefault(relative_path, []).append(snippet)

    for relative_path, snippets in file_snippets.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("\n".join(["fixture"] + snippets), encoding="utf-8")


class SavedRustArchiveCandidatesSurfaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._tmpdir: tempfile.TemporaryDirectory[str] | None = None
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls._tmpdir = tempfile.TemporaryDirectory()
            cls.repo_root = Path(cls._tmpdir.name)
            build_fixture_repo(cls.repo_root)
        else:
            cls.repo_root = Path(__file__).resolve().parents[2]

    @classmethod
    def tearDownClass(cls) -> None:
        if cls._tmpdir is not None:
            cls._tmpdir.cleanup()

    def test_surface_files_and_snippets_are_present(self) -> None:
        result = collect_surface_state(self.repo_root)
        self.assertEqual(result["missing_files"], [])
        self.assertEqual(result["missing_snippets"], [])

    def test_missing_route_wrapper_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            build_fixture_repo(repo_root)
            (repo_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh").unlink()

            result = collect_surface_state(repo_root)

            self.assertIn(
                "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
                result["missing_files"],
            )

    def test_missing_saved_archives_override_snippet_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            build_fixture_repo(repo_root)
            target = repo_root / "scripts/check_issue3_saved_rust_archive_candidates.py"
            target.write_text("fixture\nnormalize_saved_archives_root\n", encoding="utf-8")

            result = collect_surface_state(repo_root)

            missing = {
                (entry["path"], entry["snippet"])
                for entry in result["missing_snippets"]
            }
            self.assertIn(
                (
                    "scripts/check_issue3_saved_rust_archive_candidates.py",
                    "--saved-archives-root",
                ),
                missing,
            )


if __name__ == "__main__":
    unittest.main()
