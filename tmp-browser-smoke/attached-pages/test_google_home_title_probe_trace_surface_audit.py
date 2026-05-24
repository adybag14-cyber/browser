#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import os
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("google_home_title_probe_trace_surface_audit.py")
SPEC = importlib.util.spec_from_file_location("google_home_title_probe_trace_surface_audit", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


def resolve_repo_root() -> Path:
    env_root = os.environ.get("LIGHTPANDA_FIXTURE_REPO")
    if env_root and env_root != "1":
        root = Path(env_root).resolve()
        if (root / "src/browser/tests/page/google_home_title_probe.html").exists():
            return root

    for candidate in (
        Path(__file__).resolve().parent,
        Path.cwd(),
        Path("/workspace/tmp-browser-snapshot/browser-fork-headed-mode-foundation"),
    ):
        current = candidate.resolve()
        while True:
            probe = current / "src/browser/tests/page/google_home_title_probe.html"
            if probe.exists():
                return current
            if current.parent == current:
                break
            current = current.parent
    raise FileNotFoundError("could not find repo root with google_home_title_probe.html")


class GoogleHomeTitleProbeTraceSurfaceAuditTests(unittest.TestCase):
    def test_self_test_distinguishes_guarded_and_vulnerable_samples(self) -> None:
        self.assertEqual(MODULE.run_self_test(json_output=False), 0)

    def test_live_probe_source_passes_audit(self) -> None:
        repo_root = resolve_repo_root()
        html_path = repo_root / "src/browser/tests/page/google_home_title_probe.html"
        result = MODULE.evaluate_path(html_path)
        self.assertTrue(result["ok"], result["detail"])
        self.assertEqual(result["matched_marker_count"], result["required_marker_count"])

    def test_missing_message_trace_markers_fail(self) -> None:
        html = Path("/workspace/tmp-browser-snapshot/browser-fork-headed-mode-foundation/src/browser/tests/page/google_home_title_probe.html").read_text(encoding="utf-8")
        broken = html.replace("window.__lpPostMessages.push(String(message));", "")
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".html", delete=False) as handle:
            handle.write(broken)
            broken_path = Path(handle.name)
        try:
            result = MODULE.evaluate_path(broken_path)
        finally:
            broken_path.unlink(missing_ok=True)
        self.assertFalse(result["ok"])
        self.assertIn("window.__lpPostMessages.push(String(message));", result["missing_markers"])


if __name__ == "__main__":
    unittest.main()
