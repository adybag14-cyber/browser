from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1": r"""
New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file" -Purpose "gate note"
New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "runtime note"
New-ValidationReference -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Kind "file" -Purpose "saved snapshot note"
New-ValidationReference -Path "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md" -Kind "file" -Purpose "restored checkout note"
New-ValidationReference -Path "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md" -Kind "file" -Purpose "saved archive note"
New-ValidationReference -Path "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md" -Kind "file" -Purpose "linux readiness note"
New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "production guide"
New-ValidationReference -Path "docs/HEADED_MODE_ROADMAP.md" -Kind "file" -Purpose "roadmap"
New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "windows guide"
New-ValidationReference -Path "src/browser/Page.zig" -Kind "file" -Purpose "page target"
New-ValidationReference -Path "src/display/win32_backend.zig" -Kind "file" -Purpose "win32 target"
New-ValidationReference -Path "scripts/check_issue3_saved_memory_inputs.py" -Kind "file" -Purpose "saved-memory preflight"
New-ValidationReference -Path "scripts/check_issue3_saved_archive_integrity.py" -Kind "file" -Purpose "saved-archive verifier"
New-ValidationReference -Path "scripts/check_issue3_restored_checkout.py" -Kind "file" -Purpose "restored checkout readiness"
New-ValidationReference -Path "scripts/check_linux_build_readiness.py" -Kind "file" -Purpose "linux readiness"
New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "helpers"
New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "show helper"
New-ValidationReference -Path "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh" -Kind "file" -Purpose "saved snapshot surface"
New-ValidationReference -Path "scripts/linux/show_issue3_saved_browser_snapshot_route.sh" -Kind "file" -Purpose "saved snapshot route"
New-ValidationReference -Path "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh" -Kind "file" -Purpose "restored checkout surface"
New-ValidationReference -Path "scripts/linux/show_issue3_restored_checkout_reentry_route.sh" -Kind "file" -Purpose "restored checkout route"
New-ValidationReference -Path "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh" -Kind "file" -Purpose "saved archive surface"
New-ValidationReference -Path "scripts/linux/show_issue3_saved_archive_integrity_route.sh" -Kind "file" -Purpose "saved archive route"
New-ValidationReference -Path "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh" -Kind "file" -Purpose "linux runtime surface"
New-ValidationReference -Path "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" -Kind "file" -Purpose "linux runtime route"
New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "probe"
New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "contract checker"
New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1" -Kind "file" -Purpose "title probe"
New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "fixture"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Purpose "gate note order"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py" -Purpose "gate note checker"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Purpose "gate note saved snapshot note"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md" -Purpose "gate note restored checkout note"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_restored_checkout.py" -Purpose "gate note restored checkout helper"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_saved_archive_integrity.py" -Purpose "gate note saved archive helper"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/check_issue3_saved_memory_inputs.py" -Purpose "gate note saved memory helper"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh" -Purpose "gate note linux runtime surface"
New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" -Purpose "gate note linux runtime route"
New-ValidationContentExpectation -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Snippet "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md" -Purpose "saved snapshot route handoff"
New-ValidationContentExpectation -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Snippet "scripts/check_issue3_restored_checkout.py" -Purpose "saved snapshot route helper"
New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "guide surface check"
New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "guide show helper"
New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "roadmap surface check"
New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "roadmap show helper"
New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `Page.zig` slice" -Purpose "runtime page slice"
New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `win32_backend.zig` slice" -Purpose "runtime win32 slice"
New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Focused regression coverage" -Purpose "runtime coverage"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"' -Purpose "show helper gate note"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"' -Purpose "show helper runtime note"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"' -Purpose "show helper saved snapshot note"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"' -Purpose "show helper restored checkout note"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"' -Purpose "show helper saved archive note"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"' -Purpose "show helper linux readiness note"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand' -Purpose "show helper saved snapshot surface"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand' -Purpose "show helper saved snapshot route"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_browser_snapshot_route_synced = $savedBrowserSnapshotSyncedRouteCommand' -Purpose "show helper synced saved snapshot route"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'restored_checkout_surface = $restoredCheckoutRouteSurfaceCommand' -Purpose "show helper restored checkout surface"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'restored_checkout_route = $restoredCheckoutRouteCommand' -Purpose "show helper restored checkout route"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'restored_checkout_readiness = $restoredCheckoutReadinessCommand' -Purpose "show helper restored checkout readiness"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'restored_checkout_synced_readiness = $restoredCheckoutSyncedReadinessCommand' -Purpose "show helper synced restored checkout readiness"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_archive_integrity_surface = $savedArchiveIntegritySurfaceCommand' -Purpose "show helper saved archive surface"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_archive_integrity_route = $savedArchiveIntegrityRouteCommand' -Purpose "show helper saved archive route"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_archive_integrity = $savedArchiveIntegrityCommand' -Purpose "show helper saved archive verification"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_memory_preflight = $savedMemoryPreflightCommand' -Purpose "show helper saved memory preflight"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_runtime_surface = $linuxRuntimeSurfaceCommand' -Purpose "show helper linux runtime surface"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_runtime_route = $linuxRuntimeRouteCommand' -Purpose "show helper linux runtime route"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand' -Purpose "show helper skip-zig"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_build_readiness = $linuxBuildReadinessFullCommand' -Purpose "show helper full readiness"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"' -Purpose "show helper surface route"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"' -Purpose "show helper click-first"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"' -Purpose "show helper title probe"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "show helper reduced fixture"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Stale queued suppression entries do not drop real later text_input bytes." -Purpose "show helper stale text signal"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved snapshot route:" -Purpose "show helper saved snapshot output"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved snapshot route (sync helper surface):" -Purpose "show helper synced saved snapshot output"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Restored-checkout surface:" -Purpose "show helper restored checkout surface output"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Restored-checkout route:" -Purpose "show helper restored checkout route output"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Restored-checkout readiness:" -Purpose "show helper restored checkout readiness output"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Restored-checkout synced-helper-surface readiness:" -Purpose "show helper synced restored checkout readiness output"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved archive route:" -Purpose "show helper saved archive route output"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved archive verification:" -Purpose "show helper saved archive verification output"
New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Shared click-first route:" -Purpose "show helper output route"
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
check_issue3_enter_submit_runtime_contract.py
docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
check_issue3_restored_checkout.py
check_issue3_saved_archive_integrity.py
scripts/check_issue3_saved_memory_inputs.py
scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
""",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
scripts/check_issue3_restored_checkout.py
""",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """
Target `Page.zig` slice
Target `win32_backend.zig` slice
Focused regression coverage
chrome-google-home-title-probe.ps1
google_home_title_probe.html?google-home-probe=1
""",
    "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md": """
check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
show_google_issue3_enter_submit_runtime_revalidation.ps1
""",
    "docs/HEADED_MODE_ROADMAP.md": """
check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
show_google_issue3_enter_submit_runtime_revalidation.ps1
""",
    "docs/WINDOWS_FULL_USE.md": "google-form-controls-enter-order",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1": r"""
"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"
"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand
saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand
saved_browser_snapshot_route_synced = $savedBrowserSnapshotSyncedRouteCommand
restored_checkout_surface = $restoredCheckoutRouteSurfaceCommand
restored_checkout_route = $restoredCheckoutRouteCommand
restored_checkout_readiness = $restoredCheckoutReadinessCommand
restored_checkout_synced_readiness = $restoredCheckoutSyncedReadinessCommand
saved_archive_integrity_surface = $savedArchiveIntegritySurfaceCommand
saved_archive_integrity_route = $savedArchiveIntegrityRouteCommand
saved_archive_integrity = $savedArchiveIntegrityCommand
saved_memory_preflight = $savedMemoryPreflightCommand
linux_runtime_surface = $linuxRuntimeSurfaceCommand
linux_runtime_route = $linuxRuntimeRouteCommand
linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
linux_build_readiness = $linuxBuildReadinessFullCommand
surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"
reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"
google_home_title_probe.html?google-home-probe=1
Stale queued suppression entries do not drop real later text_input bytes.
Saved snapshot route:
Saved snapshot route (sync helper surface):
Restored-checkout surface:
Restored-checkout route:
Restored-checkout readiness:
Restored-checkout synced-helper-surface readiness:
Saved archive route:
Saved archive verification:
Shared click-first route:
""",
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md": "route",
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md": "route",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": "route",
    "scripts/check_issue3_saved_memory_inputs.py": "def main(): pass",
    "scripts/check_issue3_saved_archive_integrity.py": "def main(): pass",
    "scripts/check_issue3_restored_checkout.py": "def main(): pass",
    "scripts/check_linux_build_readiness.py": "def main(): pass",
    "scripts/windows/HeadedValidationHelpers.ps1": "function Resolve-LightpandaRepoRoot {}",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": "echo ok",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": "echo ok",
    "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh": "echo ok",
    "scripts/linux/show_issue3_restored_checkout_reentry_route.sh": "echo ok",
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh": "echo ok",
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh": "echo ok",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh": "echo ok",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": "echo ok",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": "Write-Host 'probe'",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py": "print('ok')",
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1": "Write-Host 'probe'",
    "src/browser/tests/page/google_home_title_probe.html": "<title>probe</title>",
    "src/browser/Page.zig": "test",
    "src/display/win32_backend.zig": "test",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runtime-reentry-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3RuntimeRevalidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.surface_checker = read_text(
            cls.repo_root / "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        cls.gate_note = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.saved_snapshot_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.runtime_note = read_text(cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")
        cls.production_guide = read_text(
            cls.repo_root / "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"
        )
        cls.roadmap = read_text(cls.repo_root / "docs/HEADED_MODE_ROADMAP.md")
        cls.windows_full_use = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")
        cls.revalidation_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )

    def test_surface_checker_keeps_reference_paths_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
            "docs/HEADED_MODE_ROADMAP.md",
            "docs/WINDOWS_FULL_USE.md",
            "src/browser/Page.zig",
            "src/display/win32_backend.zig",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
            "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
            "src/browser/tests/page/google_home_title_probe.html",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_surface_checker_keeps_key_content_expectations_in_scope(self) -> None:
        for fragment in (
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_restored_checkout.py',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_saved_archive_integrity.py',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/check_issue3_saved_memory_inputs.py',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh',
            'docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh',
            'docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Snippet "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md',
            'docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Snippet "scripts/check_issue3_restored_checkout.py',
            'docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1',
            'docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1',
            'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `Page.zig` slice"',
            'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `win32_backend.zig` slice"',
            'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Focused regression coverage"',
            "saved_browser_snapshot_route_synced = $savedBrowserSnapshotSyncedRouteCommand",
            "restored_checkout_synced_readiness = $restoredCheckoutSyncedReadinessCommand",
            "saved_archive_integrity_surface = $savedArchiveIntegritySurfaceCommand",
            "saved_archive_integrity_route = $savedArchiveIntegrityRouteCommand",
            "saved_archive_integrity = $savedArchiveIntegrityCommand",
            "saved_memory_preflight = $savedMemoryPreflightCommand",
            "linux_runtime_surface = $linuxRuntimeSurfaceCommand",
            "linux_runtime_route = $linuxRuntimeRouteCommand",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            "Stale queued suppression entries do not drop real later text_input bytes.",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_gate_note_keeps_runtime_checker_and_linux_reentry_routes_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "check_issue3_enter_submit_runtime_contract.py",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "check_issue3_restored_checkout.py",
            "check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.gate_note)

    def test_saved_snapshot_route_keeps_restored_checkout_handoff_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "scripts/check_issue3_restored_checkout.py",
        ):
            self.assertIn(fragment, self.saved_snapshot_note)

    def test_companion_docs_keep_reentry_helpers_visible(self) -> None:
        for fragment in (
            "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
            "show_google_issue3_enter_submit_runtime_revalidation.ps1",
        ):
            self.assertIn(fragment, self.production_guide)
            self.assertIn(fragment, self.roadmap)

        self.assertIn("google-form-controls-enter-order", self.windows_full_use)

    def test_runtime_note_keeps_direct_slice_and_focused_fixture_visible(self) -> None:
        for fragment in (
            "Target `Page.zig` slice",
            "Target `win32_backend.zig` slice",
            "Focused regression coverage",
            "chrome-google-home-title-probe.ps1",
            "google_home_title_probe.html?google-home-probe=1",
        ):
            self.assertIn(fragment, self.runtime_note)

    def test_revalidation_helper_keeps_gated_commands_and_success_signals_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            '"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"',
            '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"',
            "saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand",
            "saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand",
            "saved_browser_snapshot_route_synced = $savedBrowserSnapshotSyncedRouteCommand",
            "restored_checkout_surface = $restoredCheckoutRouteSurfaceCommand",
            "restored_checkout_route = $restoredCheckoutRouteCommand",
            "restored_checkout_readiness = $restoredCheckoutReadinessCommand",
            "restored_checkout_synced_readiness = $restoredCheckoutSyncedReadinessCommand",
            "saved_archive_integrity_surface = $savedArchiveIntegritySurfaceCommand",
            "saved_archive_integrity_route = $savedArchiveIntegrityRouteCommand",
            "saved_archive_integrity = $savedArchiveIntegrityCommand",
            "saved_memory_preflight = $savedMemoryPreflightCommand",
            "linux_runtime_surface = $linuxRuntimeSurfaceCommand",
            "linux_runtime_route = $linuxRuntimeRouteCommand",
            "linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand",
            "linux_build_readiness = $linuxBuildReadinessFullCommand",
            'surface_check = Format-RepoRootCommand -ScriptPath "scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"',
            'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1"',
            'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"',
            "google_home_title_probe.html?google-home-probe=1",
            "Stale queued suppression entries do not drop real later text_input bytes.",
            "Saved snapshot route:",
            "Saved snapshot route (sync helper surface):",
            "Restored-checkout surface:",
            "Restored-checkout route:",
            "Restored-checkout readiness:",
            "Restored-checkout synced-helper-surface readiness:",
            "Saved archive route:",
            "Saved archive verification:",
            "Shared click-first route:",
        ):
            self.assertIn(fragment, self.revalidation_helper)


if __name__ == "__main__":
    unittest.main()
