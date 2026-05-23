from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
    - `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
    - `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    """,
    "docs/HEADED_MODE_ROADMAP.md": """
    # Headed Mode Roadmap

    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1
    bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
    bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
    """,
    "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md": """
    # Headed Mode Production Execution Guide

    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - start with `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
    - then run `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1`
    - if Linux or WSL dependency or toolchain staging is the blocker, start with `bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
    - then run `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`
    """,
    "docs/WINDOWS_FULL_USE.md": """
    # Windows Full Use

    - `google-form-controls-enter-order`
    - `google-shared-enter-order`
    - `check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
    - `show_google_issue3_enter_submit_runtime_revalidation.ps1`
    """,
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": r"""
    (New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file" -Purpose "Branch-local gate note for deciding whether the direct issue #3 runtime patch can be reopened honestly."),
    (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Branch-local runtime-first note for the issue #3 Enter-submit revalidation slice."),
    (New-ValidationReference -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Kind "file" -Purpose "Saved-browser-snapshot route note that should stay visible when no reusable checkout exists yet."),
    (New-ValidationReference -Path "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md" -Kind "file" -Purpose "Linux or WSL build-readiness companion that should stay nearby when the runtime route is still gated on environment recovery."),
    (New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "Top-level execution guide that should stay aligned with the runtime revalidation route."),
    (New-ValidationReference -Path "docs/HEADED_MODE_ROADMAP.md" -Kind "file" -Purpose "Top-level roadmap that should keep the direct runtime re-entry helper visible from the validation quick routes."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows runbook that should stay nearby when replay widens back out from the runtime-only route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "Helper that prints the gated Windows-first Enter-submit runtime route."),
    (New-ValidationReference -Path "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh" -Kind "file" -Purpose "Fail-fast surface checker for the saved-browser-snapshot restore route used before helper replay moves into a restored checkout."),
    (New-ValidationReference -Path "scripts/linux/show_issue3_saved_browser_snapshot_route.sh" -Kind "file" -Purpose "Compact saved-browser-snapshot route printer used when no reusable checkout exists yet."),
    (New-ValidationReference -Path "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh" -Kind "file" -Purpose "Fail-fast Linux or WSL surface checker for the direct issue #3 runtime route."),
    (New-ValidationReference -Path "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" -Kind "file" -Purpose "Compact Linux or WSL route printer for the direct issue #3 runtime lane."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "Source-based checker for the direct Page.zig and win32_backend.zig runtime bridge markers."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Purpose "The gate note keeps the runtime revalidation note in the required re-entry order."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py" -Purpose "The gate note keeps the source-based runtime contract checker visible before replay widens."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "The production guide keeps the fail-fast runtime surface checker visible from the direct issue #3 re-entry route."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "The production guide keeps the compact runtime revalidation helper visible from the direct issue #3 re-entry route."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "The roadmap quick routes keep the fail-fast runtime surface checker visible before the direct issue #3 route widens."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "The roadmap quick routes keep the compact runtime revalidation helper visible before the direct issue #3 route widens."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet "google-form-controls-enter-order" -Purpose "Windows guide still surfaces the Google-shaped Enter-order route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"' -Purpose "The helper points directly at the runtime re-entry gates note."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand' -Purpose "The helper prints the saved-browser-snapshot surface checker before replay depends on a restored checkout."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_build_readiness = $linuxBuildReadinessFullCommand' -Purpose "The helper prints the full build-readiness command for the re-entry gate."),
    Write-Host "Google issue #3 Enter-submit runtime revalidation surface check"
    Write-Host "All runtime revalidation surfaces are present."
    """,
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand
    linux_build_readiness = $linuxBuildReadinessFullCommand
    """,
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": "snapshot surface",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": "snapshot route",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh": "linux runtime surface",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": "linux runtime route",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": "contract checker",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-runtime-surface-checker-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3EnterSubmitRuntimeSurfaceCheckerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runtime_gates = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.roadmap = read_text(cls.repo_root / "docs/HEADED_MODE_ROADMAP.md")
        cls.production_guide = read_text(
            cls.repo_root / "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"
        )
        cls.windows_guide = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )

    def test_runtime_gates_keep_the_windows_surface_checker_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_top_level_docs_keep_the_runtime_surface_checker_on_the_reentry_route(self) -> None:
        for fragment in (
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
        ):
            self.assertIn(fragment, self.roadmap)
            self.assertIn(fragment, self.production_guide)

        for fragment in (
            "google-form-controls-enter-order",
            "google-shared-enter-order",
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
        ):
            self.assertIn(fragment, self.windows_guide)

    def test_surface_checker_keeps_reference_paths_for_docs_and_followup_helpers(self) -> None:
        for fragment in (
            'New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            'New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            'New-ValidationReference -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            'New-ValidationReference -Path "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"',
            'New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"',
            'New-ValidationReference -Path "docs/HEADED_MODE_ROADMAP.md"',
            'New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            'New-ValidationReference -Path "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"',
            'New-ValidationReference -Path "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"',
            'New-ValidationReference -Path "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"',
            'New-ValidationReference -Path "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"',
            'New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_surface_checker_keeps_content_expectations_for_runtime_reentry_docs(self) -> None:
        for fragment in (
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py"',
            'New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            'New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            'New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet "google-form-controls-enter-order"',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet \'"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"\'',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet \'saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand\'',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet \'linux_build_readiness = $linuxBuildReadinessFullCommand\'',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_surface_checker_keeps_human_readable_pass_output(self) -> None:
        for fragment in (
            'Write-Host "Google issue #3 Enter-submit runtime revalidation surface check"',
            'Write-Host "All runtime revalidation surfaces are present."',
        ):
            self.assertIn(fragment, self.surface_checker)


if __name__ == "__main__":
    unittest.main()
