from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/linux/restore_saved_browser_repo_snapshot.sh": r"""
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
infer_archive_top_level() {
    python3 - "$1" <<'PY'
import zipfile
PY
}
ZIP_LIST_COMMAND="unzip -l '${ARCHIVE_PATH}' | sed -n '1,40p'"
MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root '${CHECKOUT_DIR}'"
BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root '${CHECKOUT_DIR}' --skip-zig-check --expect-saved-archives --saved-archives-root '${SAVED_ARCHIVES_ROOT}/dependencies'"
if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved browser repo snapshot restore surface check passed."
    echo "Archive top-level:"
    echo "Suggested archive listing:"
    echo "Suggested next steps after extraction:"
fi
if [[ -d "${CHECKOUT_DIR}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${CHECKOUT_DIR}"
    fi
fi
unzip -q "${ARCHIVE_PATH}" -d "${EXTRACT_ROOT}"
if [[ ! -f "${CHECKOUT_DIR}/build.zig" ]]; then
    exit 1
fi
echo "Saved browser repo snapshot is ready."
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-restore-snapshot-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class RestoreSavedBrowserRepoSnapshotSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_repo_snapshot.sh"
        )

    def test_restore_helper_keeps_saved_archive_surface_and_preflight_commands(self) -> None:
        for fragment in (
            'DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"',
            "infer_archive_top_level()",
            "zipfile",
            'ZIP_LIST_COMMAND="unzip -l',
            'MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py',
            'BUILD_READINESS_COMMAND="python scripts/check_linux_build_readiness.py',
            "--skip-zig-check --expect-saved-archives",
            "Saved browser repo snapshot restore surface check passed.",
            "Archive top-level:",
            "Suggested archive listing:",
            "Suggested next steps after extraction:",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_restore_helper_keeps_force_replace_and_extract_guards(self) -> None:
        for fragment in (
            'if [[ -d "${CHECKOUT_DIR}" ]]; then',
            'if [[ "${FORCE_RESTORE}" == "true" ]]; then',
            'rm -rf "${CHECKOUT_DIR}"',
            'unzip -q "${ARCHIVE_PATH}" -d "${EXTRACT_ROOT}"',
            'if [[ ! -f "${CHECKOUT_DIR}/build.zig" ]]; then',
            "Saved browser repo snapshot is ready.",
        ):
            self.assertIn(fragment, self.restore_helper)


if __name__ == "__main__":
    unittest.main()
