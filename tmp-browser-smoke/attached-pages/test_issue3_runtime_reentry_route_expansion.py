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
    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
    - `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_linux_build_readiness.py`
    - `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
    - `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
    - `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
    - `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
    - `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
    - `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface`
    - `show_issue3_windows_runtime_handoff_route.sh`
    7. If the current run does not yet have a reusable checkout beside the
       workspace, print the saved-browser-snapshot route first.
    8. If the restore route is creating or reusing `../browser-memory-snapshot`,
       run the restored-checkout route surface first.
    9. If the run depends on the saved Memory repo and dependency bundles,
       surface the saved-memory route first.
    10. If the run still depends on the saved Memory repo snapshot or dependency
        bundles after the presence preflight, verify the saved-archive route surface.
    12. When the route still only sees the attached Zig `0.17` fallback or needs a
        branch-compatible `0.15.x` decision, run the Zig recovery surface first.
    15. When the run is using Linux or WSL staging, start with the direct runtime
        Linux or WSL surface and then print the compact re-entry route.
    16. Re-check Linux or WSL build readiness before trusting file-level Zig output:
    `python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check`
    """,
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": """
    $route = [ordered]@{
        read_first = @(
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        commands = [ordered]@{
            surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
            saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand
            saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand
            saved_browser_snapshot_route_synced = $savedBrowserSnapshotSyncedRouteCommand
            restored_checkout_surface = $restoredCheckoutRouteSurfaceCommand
            restored_checkout_route = $restoredCheckoutRouteCommand
            restored_checkout_readiness = $restoredCheckoutReadinessCommand
            restored_checkout_synced_readiness = $restoredCheckoutSyncedReadinessCommand
            windows_runtime_handoff = $windowsRuntimeHandoffRouteCommand
            saved_archive_integrity_surface = $savedArchiveIntegritySurfaceCommand
            saved_archive_integrity_route = $savedArchiveIntegrityRouteCommand
            saved_archive_integrity = $savedArchiveIntegrityCommand
            contract_check = $runtimeContractCheckCommand
            contract_self_test = $runtimeContractSelfTestCommand
            saved_memory_preflight = $savedMemoryPreflightCommand
            linux_runtime_surface = $linuxRuntimeSurfaceCommand
            linux_runtime_route = $linuxRuntimeRouteCommand
            linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
            linux_build_readiness = $linuxBuildReadinessFullCommand
            shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"
            reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
            reduced_google_fixture = "& ``\"$resolvedBrowserExe``\" browse --headed --window_width 1366 --window_height 900 ``\"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1``\""
        }
        notes = @(
            "Run saved_browser_snapshot_surface and then saved_browser_snapshot_route before trusting Linux or WSL follow-up helpers against a restored checkout.",
            "Run restored_checkout_surface and then restored_checkout_route when the reusable checkout now exists but the next run still needs a compact, restored-checkout-first follow-up path.",
            "Run saved_archive_integrity_surface, saved_archive_integrity_route, and then saved_archive_integrity before saved_memory_preflight when the route still depends on the saved repo snapshot or dependency bundles.",
            "Run linux_runtime_surface and then linux_runtime_route when the direct issue #3 runtime patch is still blocked earlier on Linux or WSL saved-checkout staging or helper drift.",
            "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging and you need to confirm the saved inputs before trusting focused Zig output."
        )
    }
    Write-Host "Saved snapshot route:"
    Write-Host "Saved snapshot route (sync helper surface):"
    Write-Host "Restored-checkout surface:"
    Write-Host "Restored-checkout route:"
    Write-Host "Restored-checkout readiness:"
    Write-Host "Restored-checkout synced-helper-surface readiness:"
    Write-Host "Saved archive route:"
    Write-Host "Saved archive verification:"
    Write-Host "Shared click-first route:"
    """,
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": """
    $references = @(
        (New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file" -Purpose "gate note"),
        (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "runtime note"),
        (New-ValidationReference -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Kind "file" -Purpose "saved snapshot note"),
        (New-ValidationReference -Path "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md" -Kind "file" -Purpose "restored-checkout note"),
        (New-ValidationReference -Path "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md" -Kind "file" -Purpose "saved-archive note"),
        (New-ValidationReference -Path "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md" -Kind "file" -Purpose "Linux build-readiness note"),
        (New-ValidationReference -Path "scripts/check_issue3_saved_memory_inputs.py" -Kind "file" -Purpose "saved-memory helper"),
        (New-ValidationReference -Path "scripts/check_issue3_saved_archive_integrity.py" -Kind "file" -Purpose "saved-archive helper"),
        (New-ValidationReference -Path "scripts/check_issue3_restored_checkout.py" -Kind "file" -Purpose "restored-checkout helper"),
        (New-ValidationReference -Path "scripts/check_linux_build_readiness.py" -Kind "file" -Purpose "build-readiness helper"),
        (New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "runtime helper"),
        (New-ValidationReference -Path "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh" -Kind "file" -Purpose "saved snapshot surface"),
        (New-ValidationReference -Path "scripts/linux/show_issue3_saved_browser_snapshot_route.sh" -Kind "file" -Purpose "saved snapshot route"),
        (New-ValidationReference -Path "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh" -Kind "file" -Purpose "restored checkout surface"),
        (New-ValidationReference -Path "scripts/linux/show_issue3_restored_checkout_reentry_route.sh" -Kind "file" -Purpose "restored checkout route"),
        (New-ValidationReference -Path "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh" -Kind "file" -Purpose "saved archive surface"),
        (New-ValidationReference -Path "scripts/linux/show_issue3_saved_archive_integrity_route.sh" -Kind "file" -Purpose "saved archive route"),
        (New-ValidationReference -Path "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh" -Kind "file" -Purpose "linux runtime surface"),
        (New-ValidationReference -Path "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" -Kind "file" -Purpose "linux runtime route"),
        (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "runtime contract checker"),
        (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1" -Kind "file" -Purpose "reduced Google probe"),
        (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "reduced Google fixture")
    )
    $contentExpectations = @(
        (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/check_issue3_saved_memory_inputs.py" -Purpose "gate note keeps saved-memory preflight visible"),
        (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_saved_archive_integrity_route.sh" -Purpose "gate note keeps saved-archive route visible"),
        (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" -Purpose "gate note keeps runtime route visible"),
        (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "guide keeps runtime surface checker visible"),
        (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "roadmap keeps runtime helper visible"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand' -Purpose "helper prints saved snapshot route"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'restored_checkout_route = $restoredCheckoutRouteCommand' -Purpose "helper prints restored checkout route"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_archive_integrity = $savedArchiveIntegrityCommand' -Purpose "helper prints saved archive verification"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"' -Purpose "helper keeps click-first route visible"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "helper keeps reduced Google fixture visible"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved snapshot route:" -Purpose "helper output prints saved snapshot route label"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Restored-checkout synced-helper-surface readiness:" -Purpose "helper output prints synced restored-checkout label"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved archive verification:" -Purpose "helper output prints saved archive verification label"),
        (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Shared click-first route:" -Purpose "helper output prints shared click-first label")
    )
    """,
    "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md": """
    - `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
    - `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
    """,
    "docs/HEADED_MODE_ROADMAP.md": """
    - `scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
    - `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-runtime-route-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RuntimeReentryRouteExpansionTest(unittest.TestCase):
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
        cls.runtime_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.production_guide = read_text(
            cls.repo_root / "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"
        )
        cls.roadmap = read_text(cls.repo_root / "docs/HEADED_MODE_ROADMAP.md")

    def test_runtime_gates_keep_restore_archive_and_runtime_handoff_steps_in_order(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_linux_build_readiness.py",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface",
            "show_issue3_windows_runtime_handoff_route.sh",
            "python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check",
        ):
            self.assertIn(fragment, self.runtime_gates)

        saved_snapshot_index = self.runtime_gates.index("7. If the current run does not yet have a reusable checkout beside the")
        restored_checkout_index = self.runtime_gates.index("8. If the restore route is creating or reusing `../browser-memory-snapshot`,")
        saved_memory_index = self.runtime_gates.index("9. If the run depends on the saved Memory repo and dependency bundles,")
        saved_archive_index = self.runtime_gates.index("10. If the run still depends on the saved Memory repo snapshot or dependency")
        zig_recovery_index = self.runtime_gates.index("12. When the route still only sees the attached Zig `0.17` fallback or needs a")
        runtime_index = self.runtime_gates.index("15. When the run is using Linux or WSL staging, start with the direct runtime")
        build_index = self.runtime_gates.index("16. Re-check Linux or WSL build readiness before trusting file-level Zig output:")
        self.assertLess(saved_snapshot_index, restored_checkout_index)
        self.assertLess(restored_checkout_index, saved_memory_index)
        self.assertLess(saved_memory_index, saved_archive_index)
        self.assertLess(saved_archive_index, zig_recovery_index)
        self.assertLess(zig_recovery_index, runtime_index)
        self.assertLess(runtime_index, build_index)

    def test_runtime_helper_keeps_saved_snapshot_restore_archive_and_google_probe_commands_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            '"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"',
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"',
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            "saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand",
            "saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand",
            "saved_browser_snapshot_route_synced = $savedBrowserSnapshotSyncedRouteCommand",
            "restored_checkout_surface = $restoredCheckoutRouteSurfaceCommand",
            "restored_checkout_route = $restoredCheckoutRouteCommand",
            "restored_checkout_readiness = $restoredCheckoutReadinessCommand",
            "restored_checkout_synced_readiness = $restoredCheckoutSyncedReadinessCommand",
            "windows_runtime_handoff = $windowsRuntimeHandoffRouteCommand",
            "saved_archive_integrity_surface = $savedArchiveIntegritySurfaceCommand",
            "saved_archive_integrity_route = $savedArchiveIntegrityRouteCommand",
            "saved_archive_integrity = $savedArchiveIntegrityCommand",
            "contract_check = $runtimeContractCheckCommand",
            "contract_self_test = $runtimeContractSelfTestCommand",
            "saved_memory_preflight = $savedMemoryPreflightCommand",
            "linux_runtime_surface = $linuxRuntimeSurfaceCommand",
            "linux_runtime_route = $linuxRuntimeRouteCommand",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            "google_home_title_probe.html?google-home-probe=1",
            "Run saved_browser_snapshot_surface and then saved_browser_snapshot_route before trusting Linux or WSL follow-up helpers against a restored checkout.",
            "Run restored_checkout_surface and then restored_checkout_route when the reusable checkout now exists but the next run still needs a compact, restored-checkout-first follow-up path.",
            "Run saved_archive_integrity_surface, saved_archive_integrity_route, and then saved_archive_integrity before saved_memory_preflight when the route still depends on the saved repo snapshot or dependency bundles.",
            "Run linux_runtime_surface and then linux_runtime_route when the direct issue #3 runtime patch is still blocked earlier on Linux or WSL saved-checkout staging or helper drift.",
            "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging and you need to confirm the saved inputs before trusting focused Zig output.",
            'Write-Host "Saved snapshot route:"',
            'Write-Host "Saved snapshot route (sync helper surface):"',
            'Write-Host "Restored-checkout surface:"',
            'Write-Host "Restored-checkout route:"',
            'Write-Host "Restored-checkout readiness:"',
            'Write-Host "Restored-checkout synced-helper-surface readiness:"',
            'Write-Host "Saved archive route:"',
            'Write-Host "Saved archive verification:"',
            'Write-Host "Shared click-first route:"',
        ):
            self.assertIn(fragment, self.runtime_helper)

    def test_surface_checker_keeps_helper_reference_and_content_contracts_visible(self) -> None:
        for fragment in (
            'New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            'New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            'New-ValidationReference -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            'New-ValidationReference -Path "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"',
            'New-ValidationReference -Path "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"',
            'New-ValidationReference -Path "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"',
            'New-ValidationReference -Path "scripts/check_issue3_saved_memory_inputs.py"',
            'New-ValidationReference -Path "scripts/check_issue3_saved_archive_integrity.py"',
            'New-ValidationReference -Path "scripts/check_issue3_restored_checkout.py"',
            'New-ValidationReference -Path "scripts/check_linux_build_readiness.py"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            'New-ValidationReference -Path "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"',
            'New-ValidationReference -Path "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"',
            'New-ValidationReference -Path "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh"',
            'New-ValidationReference -Path "scripts/linux/show_issue3_restored_checkout_reentry_route.sh"',
            'New-ValidationReference -Path "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"',
            'New-ValidationReference -Path "scripts/linux/show_issue3_saved_archive_integrity_route.sh"',
            'New-ValidationReference -Path "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"',
            'New-ValidationReference -Path "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"',
            'New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py"',
            'New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"',
            'New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/check_issue3_saved_memory_inputs.py"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_saved_archive_integrity_route.sh"',
            'New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"',
            'New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1"',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet \'saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand\'',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet \'restored_checkout_route = $restoredCheckoutRouteCommand\'',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet \'saved_archive_integrity = $savedArchiveIntegrityCommand\'',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet \'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"\'',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "google_home_title_probe.html?google-home-probe=1"',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved snapshot route:"',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Restored-checkout synced-helper-surface readiness:"',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved archive verification:"',
            'New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Shared click-first route:"',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_guide_and_roadmap_keep_runtime_surface_and_helper_visible(self) -> None:
        for content in (self.production_guide, self.roadmap):
            self.assertIn("check_google_issue3_enter_submit_runtime_revalidation_surface.ps1", content)
            self.assertIn("show_google_issue3_enter_submit_runtime_revalidation.ps1", content)


if __name__ == "__main__":
    unittest.main()
