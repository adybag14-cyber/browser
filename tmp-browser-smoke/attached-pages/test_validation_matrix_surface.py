import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/HEADED_MODE_VALIDATION_MATRIX.md": """# Headed Mode Validation Matrix

Use this guide when a headed-mode change is ready for Windows validation and you
need the smallest bounded probe family before widening into manual replay.

- Prefer `scripts\\windows\\show_headed_validation_suites.ps1` first for the change areas it already routes directly: `navigation`, `stop-loading`, `input`, `google-form-controls-enter-order`, `google-shared-enter-order`, `rendering`, `network`, `browser-shell`, `popup`, `attached-html`, `attached-html-target-bundle`, `google-input`, and `google-attached-html`.

| Change area | First bounded check | Good follow-up | Notes |
| --- | --- | --- | --- |
| Shared Google-shaped Enter submit timing before the issue #3-specific gate | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order` | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order` | Use this when the replay is already narrowed to Google-like keypress-before-submit behavior, but you still want the reusable shared ladder before the tighter issue #3 gate. |
| Google form-controls Enter submit timing on the real headed surface | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order` | `& ".\\zig-out\\bin\\lightpanda.exe" browse --headed "https://www.google.com/"` | Use this only after the broader `google-shared-enter-order` route is already green and you want the tightest issue #3 checkpoint before manual Google or saved-page follow-up. |
| Shared layout, paint, screenshot timing, or visible headed surface behavior | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea rendering` | `powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\layout-smoke\\chrome-screenshot-load-complete-probe.ps1` | Start here before widening into attached-page replay for rendering or screenshot issues. |
| Shared subresource loading, authenticated asset fetches, or browser-managed request credentials | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea network` | `powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\fetch-credentials\\chrome-fetch-credentials-probe.ps1` | Start here before widening into attached-page replay for network, credential, or asset-loading changes. |
| Browser shell tabs, settings, and related chrome behavior | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea browser-shell` | `powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\tabs\\chrome-tabs-probe.ps1` | Use this for tab strip, duplicate/reopen, settings persistence, and shell keyboard-shortcut changes before widening into older deeper helpers. |
| Popup creation, named-target flows, or popup policy | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea popup` | `powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\popup\\chrome-popup-anchor-probe.ps1` | Start here for the checkout-portable first popup proof, then use the direct popup probes below if you need deeper form-submit or script-open coverage. |
| Pinned three-page compatibility bundle | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"` | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath "<bundle-html-or-folder>"` | Use this when the replay should stay on the known three-page compatibility set and you want the compact bundle-specific helper chain surfaced immediately. |

## Pinned Bundle Fast Path

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_bundle_first_bridge.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -InputPath "<bundle-html-or-folder>" -Wait
```

## Google Issue #3 Narrowing Ladder

1. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea input`
2. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input`
3. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order`
4. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order`
5. `& ".\\zig-out\\bin\\lightpanda.exe" browse --headed "https://www.google.com/"`
6. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-attached-html -InputPath "<saved-html-or-folder>"`
7. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"`
""",
    "docs/WINDOWS_FULL_USE.md": """# Lightpanda Full Use on Windows (Fork)

For the broader subsystem-to-probe map across the existing `tmp-browser-smoke`
families, read `docs/HEADED_MODE_VALIDATION_MATRIX.md` after the router output.

- a broader shared Enter-order ladder surfaced through `scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order`
- checkout-portable first-line rendering probes surfaced through `scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea rendering`
- checkout-portable first-line network probes surfaced through `scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea network`
- checkout-portable first-line browser-shell probes under `tmp-browser-smoke\\tabs\\` and `tmp-browser-smoke\\settings\\`, surfaced through `scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea browser-shell`
- a checkout-portable first-line popup probe under `tmp-browser-smoke\\popup\\`, surfaced through `scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea popup`
""",
    "scripts/windows/show_headed_validation_suites.ps1": """[CmdletBinding()]
param(
    [ValidateSet("", "attached-html-target-bundle", "google-attached-html", "google-form-controls-enter-order", "google-recommended", "google-shared-enter-order")]
    [string]$SuiteName = "",
    [ValidateSet("", "attached-html", "attached-html-target-bundle", "browser-shell", "google-attached-html", "google-form-controls-enter-order", "google-input", "google-shared-enter-order", "input", "manual-html", "navigation", "network", "popup", "rendering", "stop-loading")]
    [string]$ChangeArea = ""
)

function Get-RenderingRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\layout-smoke\\chrome-layout-flex-center-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\layout-smoke\\chrome-screenshot-load-complete-probe.ps1"
    )
}

function Get-NetworkRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\stylesheet-smoke\\chrome-stylesheet-auth-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\fetch-credentials\\chrome-fetch-credentials-probe.ps1"
    )
}

function Get-BrowserShellRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\tabs\\chrome-tabs-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\settings\\chrome-settings-home-probe.ps1"
    )
}

function Get-PopupRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\popup\\chrome-popup-anchor-probe.ps1"
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-validation-matrix-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return root


class ValidationMatrixSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.matrix = read_text(cls.repo_root / "docs/HEADED_MODE_VALIDATION_MATRIX.md")
        cls.windows_full_use = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")
        cls.router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")

    def test_matrix_keeps_product_weighted_change_areas(self) -> None:
        expected_fragments = (
            "show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order",
            "show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
            "show_headed_validation_suites.ps1 -ChangeArea rendering",
            "show_headed_validation_suites.ps1 -ChangeArea network",
            "show_headed_validation_suites.ps1 -ChangeArea browser-shell",
            "show_headed_validation_suites.ps1 -ChangeArea popup",
            "chrome-screenshot-load-complete-probe.ps1",
            "chrome-fetch-credentials-probe.ps1",
            "chrome-tabs-probe.ps1",
            "chrome-popup-anchor-probe.ps1",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.matrix)

    def test_matrix_keeps_bundle_fast_path(self) -> None:
        expected_fragments = (
            "## Pinned Bundle Fast Path",
            "show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_replay_route_bundle_first_bridge.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
            "run_attached_html_target_bundle_validation.ps1",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.matrix)

    def test_matrix_keeps_google_narrowing_ladder_in_order(self) -> None:
        ladder = (
            "1. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea input`",
            "2. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input`",
            "3. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order`",
            "4. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order`",
            '5. `& ".\\zig-out\\bin\\lightpanda.exe" browse --headed "https://www.google.com/"`',
            '6. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-attached-html -InputPath "<saved-html-or-folder>"`',
            '7. `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"`',
        )
        last_index = -1
        for fragment in ladder:
            index = self.matrix.find(fragment)
            self.assertGreater(index, last_index, f"expected ladder fragment in order: {fragment}")
            last_index = index

    def test_windows_full_use_still_points_back_to_matrix(self) -> None:
        expected_fragments = (
            "docs/HEADED_MODE_VALIDATION_MATRIX.md",
            "google-shared-enter-order",
            "-ChangeArea rendering",
            "-ChangeArea network",
            "-ChangeArea browser-shell",
            "-ChangeArea popup",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.windows_full_use)

    def test_router_keeps_matrix_backed_route_commands(self) -> None:
        expected_fragments = (
            '[ValidateSet("", "attached-html", "attached-html-target-bundle", "browser-shell", "google-attached-html", "google-form-controls-enter-order", "google-input", "google-shared-enter-order", "input", "manual-html", "navigation", "network", "popup", "rendering", "stop-loading")]',
            "function Get-RenderingRouteCommands",
            "chrome-layout-flex-center-probe.ps1",
            "chrome-screenshot-load-complete-probe.ps1",
            "function Get-NetworkRouteCommands",
            "chrome-stylesheet-auth-probe.ps1",
            "chrome-fetch-credentials-probe.ps1",
            "function Get-BrowserShellRouteCommands",
            "chrome-tabs-probe.ps1",
            "chrome-settings-home-probe.ps1",
            "function Get-PopupRouteCommands",
            "chrome-popup-anchor-probe.ps1",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.router)


if __name__ == "__main__":
    unittest.main()
