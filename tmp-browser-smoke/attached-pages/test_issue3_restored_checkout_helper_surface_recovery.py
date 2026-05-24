from __future__ import annotations

import contextlib
import importlib.util
import io
import os
import pathlib
import tempfile
import textwrap
import unittest


FIXTURE_CHECKER = textwrap.dedent(
    """\
    #!/usr/bin/env python3
    from __future__ import annotations

    import hashlib
    from pathlib import Path
    import sys

    RESTORED_CHECKOUT_PATHS = (
        ("build.zig", "top-level build entrypoint"),
        ("build.zig.zon", "dependency manifest"),
        ("src/browser/Page.zig", "page runtime surface"),
        ("src/display/win32_backend.zig", "Win32 backend runtime surface"),
    )

    HELPER_SURFACE_PATHS = (
        ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
        ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
        ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer"),
    )

    def file_sha256(path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(65536), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def check_required_paths(repo_root: Path) -> list[dict[str, object]]:
        results = []
        for relative_path, label in RESTORED_CHECKOUT_PATHS:
            path = repo_root / relative_path
            results.append({"path": relative_path, "label": label, "exists": path.is_file()})
        return results

    def check_helper_surface(repo_root: Path, helper_root: Path | None, *, expect_helper_surface: bool) -> list[dict[str, object]]:
        results = []
        for relative_path, label in HELPER_SURFACE_PATHS:
            restored_path = repo_root / relative_path
            entry = {
                "path": relative_path,
                "label": label,
                "exists": restored_path.is_file(),
                "required": expect_helper_surface,
                "matches_helper_root": None,
                "restored_sha256": None,
                "helper_root_sha256": None,
            }
            if restored_path.is_file():
                entry["restored_sha256"] = file_sha256(restored_path)
            if helper_root is not None:
                helper_path = helper_root / relative_path
                entry["helper_root_exists"] = helper_path.is_file()
                if helper_path.is_file():
                    entry["helper_root_sha256"] = file_sha256(helper_path)
                    if restored_path.is_file():
                        entry["matches_helper_root"] = entry["restored_sha256"] == entry["helper_root_sha256"]
                else:
                    entry["matches_helper_root"] = False if restored_path.is_file() else None
            results.append(entry)
        return results

    def diagnose_result(*, missing_required, missing_helper_surface, drifted_helper_surface, expect_helper_surface: bool) -> str:
        if not missing_required and not missing_helper_surface and not drifted_helper_surface:
            return "ready"
        if missing_required:
            if expect_helper_surface and missing_helper_surface and not drifted_helper_surface:
                return "missing-required-and-stale-helper-surface"
            return "missing-required-paths"
        if expect_helper_surface and missing_helper_surface and not drifted_helper_surface:
            return "stale-helper-surface"
        if drifted_helper_surface and not missing_helper_surface:
            return "helper-surface-drift"
        if missing_helper_surface and drifted_helper_surface:
            return "partial-helper-surface-and-drift"
        if missing_helper_surface:
            return "missing-helper-surface"
        return "mixed"

    def collect_results(*, repo_root: Path, helper_root: Path | None, expect_helper_surface: bool) -> dict[str, object]:
        required_paths = check_required_paths(repo_root)
        helper_surface = check_helper_surface(repo_root, helper_root, expect_helper_surface=expect_helper_surface)
        missing_required = [entry for entry in required_paths if not entry["exists"]]
        missing_helper_surface = [entry for entry in helper_surface if expect_helper_surface and not entry["exists"]]
        drifted_helper_surface = [entry for entry in helper_surface if entry["exists"] and entry.get("matches_helper_root") is False]
        diagnosis = diagnose_result(
            missing_required=missing_required,
            missing_helper_surface=missing_helper_surface,
            drifted_helper_surface=drifted_helper_surface,
            expect_helper_surface=expect_helper_surface,
        )
        ok = not missing_required and not missing_helper_surface and not drifted_helper_surface
        return {
            "ok": ok,
            "diagnosis": diagnosis,
            "repo_root": str(repo_root),
            "helper_root": str(helper_root) if helper_root is not None else None,
            "expect_helper_surface": expect_helper_surface,
            "required_paths": required_paths,
            "helper_surface": helper_surface,
            "missing_required_paths": [entry["path"] for entry in missing_required],
            "missing_helper_surface_paths": [entry["path"] for entry in missing_helper_surface],
            "drifted_helper_surface_paths": [entry["path"] for entry in drifted_helper_surface],
        }

    def emit_text(result: dict[str, object]) -> None:
        print(f"Restored checkout: {result['repo_root']}")
        print(f"Helper root: {result['helper_root'] or 'not provided'}")
        print(f"Expect helper surface: {'yes' if result['expect_helper_surface'] else 'no'}")
        if result["ok"]:
            print("\\nRestored checkout check passed.")
            return
        print("\\nRestored checkout check failed.", file=sys.stderr)
        print(f"Diagnosis: {result['diagnosis']}", file=sys.stderr)
        if result["diagnosis"] == "stale-helper-surface":
            print(
                "Suggested next step: this restored checkout looks like the historical saved snapshot without the synced issue #3 helper surface. From a live helper checkout, rerun restore_saved_browser_snapshot.sh with --sync-only if this destination already exists, or rerun the restore with --sync-helper-surface for a fresh self-contained checkout.",
                file=sys.stderr,
            )
            print(
                "Alternative: keep using the live helper root for follow-up commands if the restored checkout should stay as a clean historical snapshot.",
                file=sys.stderr,
            )
        elif result["diagnosis"] == "helper-surface-drift":
            print(
                "Suggested next step: refresh the restored helper surface from the live helper checkout with restore_saved_browser_snapshot.sh --sync-only, then rerun this helper with --helper-root.",
                file=sys.stderr,
            )
        elif result["expect_helper_surface"]:
            print(
                "Suggested next step: rerun restore_saved_browser_snapshot.sh with --sync-helper-surface or keep using the live helper root for follow-up commands.",
                file=sys.stderr,
            )
    """
)


def load_module(module_path: pathlib.Path):
    spec = importlib.util.spec_from_file_location("issue3_restored_checkout_helper", module_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def write_file(path: pathlib.Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def populate_repo(root: pathlib.Path, module, *, helper_body: str = "helper", include_helpers: bool = True) -> None:
    for relative_path, _label in module.RESTORED_CHECKOUT_PATHS:
        write_file(root / relative_path, "required")
    if include_helpers:
        for relative_path, _label in module.HELPER_SURFACE_PATHS:
            body = FIXTURE_CHECKER if relative_path == "scripts/check_issue3_restored_checkout.py" else helper_body
            write_file(root / relative_path, body)


class Issue3RestoredCheckoutHelperSurfaceRecoveryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
            cls.module = load_module(cls.repo_root / "scripts/check_issue3_restored_checkout.py")
            cls.fixture_mode = False
            return

        cls.fixture_dir = tempfile.TemporaryDirectory(prefix="lightpanda-restored-checkout-helper-")
        cls.repo_root = pathlib.Path(cls.fixture_dir.name) / "browser"
        write_file(cls.repo_root / "scripts/check_issue3_restored_checkout.py", FIXTURE_CHECKER)
        cls.module = load_module(cls.repo_root / "scripts/check_issue3_restored_checkout.py")
        populate_repo(cls.repo_root, cls.module, helper_body="live-helper", include_helpers=True)
        cls.fixture_mode = True

    @classmethod
    def tearDownClass(cls) -> None:
        fixture_dir = getattr(cls, "fixture_dir", None)
        if fixture_dir is not None:
            fixture_dir.cleanup()

    def create_restored_checkout(self) -> tuple[pathlib.Path, pathlib.Path]:
        tempdir = tempfile.TemporaryDirectory(prefix="lightpanda-restored-checkout-case-")
        self.addCleanup(tempdir.cleanup)
        root = pathlib.Path(tempdir.name)
        restored = root / "browser-memory-snapshot"
        helper_root = root / "live-helper-root"
        populate_repo(restored, self.module, helper_body="shared-helper", include_helpers=True)
        populate_repo(helper_root, self.module, helper_body="shared-helper", include_helpers=True)
        return restored, helper_root

    def test_stale_helper_surface_reports_sync_only_recovery(self) -> None:
        restored, helper_root = self.create_restored_checkout()
        stale_helper_path = restored / self.module.HELPER_SURFACE_PATHS[0][0]
        stale_helper_path.unlink()

        result = self.module.collect_results(
            repo_root=restored,
            helper_root=helper_root,
            expect_helper_surface=True,
        )

        self.assertFalse(result["ok"])
        self.assertEqual(result["diagnosis"], "stale-helper-surface")
        self.assertIn(self.module.HELPER_SURFACE_PATHS[0][0], result["missing_helper_surface_paths"])

        stdout = io.StringIO()
        stderr = io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            self.module.emit_text(result)

        error_text = stderr.getvalue()
        self.assertIn("--sync-only", error_text)
        self.assertIn("--sync-helper-surface", error_text)
        self.assertIn("clean historical snapshot", error_text)

    def test_helper_surface_drift_reports_sync_only_refresh(self) -> None:
        restored, helper_root = self.create_restored_checkout()
        drift_path = restored / self.module.HELPER_SURFACE_PATHS[1][0]
        drift_path.write_text("drifted-helper", encoding="utf-8")

        result = self.module.collect_results(
            repo_root=restored,
            helper_root=helper_root,
            expect_helper_surface=True,
        )

        self.assertFalse(result["ok"])
        self.assertEqual(result["diagnosis"], "helper-surface-drift")
        self.assertIn(self.module.HELPER_SURFACE_PATHS[1][0], result["drifted_helper_surface_paths"])

        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            self.module.emit_text(result)
        self.assertIn("--sync-only", stderr.getvalue())
        self.assertIn("--helper-root", stderr.getvalue())

    def test_synced_helper_surface_passes(self) -> None:
        restored, helper_root = self.create_restored_checkout()

        result = self.module.collect_results(
            repo_root=restored,
            helper_root=helper_root,
            expect_helper_surface=True,
        )

        self.assertTrue(result["ok"])
        self.assertEqual(result["diagnosis"], "ready")


if __name__ == "__main__":
    unittest.main()
