from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
Usage:
  bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh \\
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \\
normalize_saved_archives_root() {
SAVED_ARCHIVES_ROOT=\"$(cd \"${REPO_ROOT}/..\" && pwd)/memory/repo_archives/browser\"
SAVED_ARCHIVES_ROOT=\"$(normalize_saved_archives_root \"${SAVED_ARCHIVES_ROOT}\")\"
repo_archives/browser/dependencies and is normalized before discovery runs.
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-root-normalization-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigSavedArchivesRootNormalizationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = build_fixture_repo()

        cls.route_script = (
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        ).read_text(encoding="utf-8")

    def test_usage_accepts_browser_root_or_dependencies_subdirectory(self) -> None:
        self.assertIn(
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            self.route_script,
        )

    def test_route_normalizes_saved_archives_root_before_discovery(self) -> None:
        for fragment in (
            "normalize_saved_archives_root() {",
            'SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"',
            'SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"',
            "repo_archives/browser/dependencies and is normalized before discovery runs.",
        ):
            self.assertIn(fragment, self.route_script)


if __name__ == "__main__":
    unittest.main()
