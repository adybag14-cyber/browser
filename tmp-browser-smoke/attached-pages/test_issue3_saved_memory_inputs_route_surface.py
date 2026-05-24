from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md": """
    # Issue #3 Saved Memory Inputs Route

    - `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
    - `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .`
    - `--skip-archive-integrity-check`
    - `--restored-checkout-root /path/to/browser-memory-snapshot`
    - `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
    """,
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh": """
    declare -a REFERENCE_PATHS=(
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|file|Read-first saved-Memory-inputs route note for the blocked issue #3 recovery path."
        "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh|file|Fail-fast surface checker for the saved-Memory-inputs route."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|file|Compact route printer for the saved-Memory-inputs preflight."
        "scripts/check_issue3_saved_memory_inputs.py|file|Saved Memory input preflight helper that checks the repo snapshot, notes, blocker file, dependency bundles, and fallback Zig surface."
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file|Follow-up route printer when the saved inputs are green but no restored checkout exists yet."
        "scripts/linux/show_issue3_linux_build_readiness_route.sh|file|Follow-up route printer when toolchain or offline dependency staging is still the blocker."
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file|Follow-up route printer when the narrowed runtime lane is ready to reopen."
    )
    declare -a CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|check_issue3_saved_memory_inputs_route_surface.sh|The saved-Memory-inputs note keeps the dedicated route surface checker visible."
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_saved_memory_inputs_route.sh|The saved-Memory-inputs note keeps the compact route printer visible."
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .|The saved-Memory-inputs note keeps the main preflight command visible."
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|--skip-archive-integrity-check|The saved-Memory-inputs note keeps the quick presence-only mode visible."
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|--restored-checkout-root ../browser-memory-snapshot|The saved-Memory-inputs note keeps the restored-checkout override visible."
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh|The saved-Memory-inputs note keeps the saved-browser-snapshot follow-up route visible."
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_linux_build_readiness_route.sh|The saved-Memory-inputs note keeps the Linux or WSL build-readiness follow-up route visible."
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh|The saved-Memory-inputs note keeps the direct runtime follow-up route visible."
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|The saved-Memory-inputs note still names the fallback Zig bundle."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|check_issue3_saved_memory_inputs_route_surface.sh|The route printer points back to the dedicated route surface checker."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|check_issue3_saved_memory_inputs.py|The route printer still prints the saved-input preflight command."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|--skip-archive-integrity-check|The route printer still supports the quick presence-only mode."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|--restored-checkout-root|The route printer still supports the restored-checkout override."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|show_issue3_saved_browser_snapshot_route.sh|The route printer still exposes the saved-browser-snapshot follow-up."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|show_issue3_linux_build_readiness_route.sh|The route printer still exposes the Linux or WSL build-readiness follow-up."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh|The route printer still exposes the direct runtime follow-up."
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh|restored_checkout_saved_input_preflight|The route printer JSON output still exposes the restored-checkout preflight command."
        "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip|The saved-input preflight still checks for the saved repo snapshot."
        "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml|The saved-input preflight still checks for blocker intelligence."
        "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed.|The saved-input preflight still reports a clear pass surface."
    )
    echo "All saved-Memory-input route surfaces are present."
    """,
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh": """
    ROUTE_SURFACE_COMMAND="bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh --repo-root ."
    SAVED_INPUT_COMMAND="python ./scripts/check_issue3_saved_memory_inputs.py --repo-root ."
    QUICK_SAVED_INPUT_COMMAND="${SAVED_INPUT_COMMAND} --skip-archive-integrity-check"
    RESTORED_SAVED_INPUT_COMMAND="${SAVED_INPUT_COMMAND} --restored-checkout-root ../browser-memory-snapshot"
    SNAPSHOT_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    BUILD_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh"
    RUNTIME_ROUTE_COMMAND="bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    print("restored_checkout_saved_input_preflight")
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_MEMORY_FILES = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
        ("repo_archives/browser/README.md", "saved repo notes"),
        ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    )
    REQUIRED_RESTORED_HELPER_FILES = (
        ("docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md", "saved-Memory-inputs route guide"),
        ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide"),
        ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry guide"),
        ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness guide"),
        ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery guide"),
        ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
        ("scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh", "saved-Memory-inputs route surface checker"),
        ("scripts/linux/show_issue3_saved_memory_inputs_route.sh", "saved-Memory-inputs route helper"),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route helper"),
        ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route helper"),
        ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime re-entry route helper"),
    )
    print("Saved Memory input check passed.")
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-memory-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedMemoryInputsRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_note = read_text(cls.repo_root / "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md")
        cls.surface_script = read_text(
            cls.repo_root / "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh"
        )
        cls.route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_memory_inputs_route.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )

    def test_route_note_keeps_surface_preflight_and_followup_routes_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .",
            "--skip-archive-integrity-check",
            "--restored-checkout-root /path/to/browser-memory-snapshot",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.route_note)

    def test_surface_checker_keeps_note_route_and_helper_contract_markers(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--skip-archive-integrity-check",
            "--restored-checkout-root ../browser-memory-snapshot",
            "restored_checkout_saved_input_preflight",
            "Saved Memory input check passed.",
            "All saved-Memory-input route surfaces are present.",
        ):
            self.assertIn(fragment, self.surface_script)

    def test_route_script_keeps_surface_preflight_and_followup_order(self) -> None:
        for fragment in (
            "check_issue3_saved_memory_inputs_route_surface.sh",
            "check_issue3_saved_memory_inputs.py",
            "--skip-archive-integrity-check",
            "--restored-checkout-root ../browser-memory-snapshot",
            "show_issue3_saved_browser_snapshot_route.sh",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "restored_checkout_saved_input_preflight",
        ):
            self.assertIn(fragment, self.route_script)

        surface_index = self.route_script.index("ROUTE_SURFACE_COMMAND")
        saved_input_index = self.route_script.index("SAVED_INPUT_COMMAND")
        quick_index = self.route_script.index("QUICK_SAVED_INPUT_COMMAND")
        restored_index = self.route_script.index("RESTORED_SAVED_INPUT_COMMAND")
        snapshot_index = self.route_script.index("SNAPSHOT_ROUTE_COMMAND")
        build_index = self.route_script.index("BUILD_ROUTE_COMMAND")
        runtime_index = self.route_script.index("RUNTIME_ROUTE_COMMAND")
        self.assertLess(surface_index, saved_input_index)
        self.assertLess(saved_input_index, quick_index)
        self.assertLess(quick_index, restored_index)
        self.assertLess(restored_index, snapshot_index)
        self.assertLess(snapshot_index, build_index)
        self.assertLess(build_index, runtime_index)

    def test_saved_memory_helper_keeps_memory_and_restored_helper_surface_scope(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/README.md",
            "repo_archives/browser/blocker_intelligence.yaml",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)


if __name__ == "__main__":
    unittest.main()
