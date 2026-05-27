import pathlib
import tempfile
import unittest


SCRIPT_NAME = "scripts/linux/show_issue11_toolchains_root_audit_route.sh"
SURFACE_NAME = "scripts/check_issue11_toolchains_root_audit_surface.py"
PREFERENCE_NAME = "scripts/check_issue11_toolchains_root_preference.py"
CONSISTENCY_NAME = "scripts/check_issue11_toolchains_root_consistency.py"
CANDIDATE_NAME = "scripts/check_issue11_toolchains_root_candidates.py"


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


class Issue11ToolchainsRootAuditRouteSurfaceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.repo_root = pathlib.Path(__file__).resolve().parents[2]
        self.route_path = self.repo_root / SCRIPT_NAME
        self.surface_path = self.repo_root / SURFACE_NAME

    def test_route_mentions_all_issue11_toolchains_audit_steps(self) -> None:
        route_text = read_text(self.route_path)
        self.assertIn("Issue #11 toolchains-root audit route", route_text)
        self.assertIn(SURFACE_NAME, route_text)
        self.assertIn(PREFERENCE_NAME, route_text)
        self.assertIn(CONSISTENCY_NAME, route_text)
        self.assertIn(CANDIDATE_NAME, route_text)

    def test_surface_checker_tracks_required_audit_files(self) -> None:
        surface_text = read_text(self.surface_path)
        self.assertIn(PREFERENCE_NAME, surface_text)
        self.assertIn(CONSISTENCY_NAME, surface_text)
        self.assertIn(CANDIDATE_NAME, surface_text)
        self.assertIn(SCRIPT_NAME, surface_text)

    def test_surface_checker_self_test_fails_when_route_printer_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = pathlib.Path(tmpdir)
            for relative in (
                SURFACE_NAME,
                PREFERENCE_NAME,
                CONSISTENCY_NAME,
                CANDIDATE_NAME,
            ):
                target = repo_root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("# placeholder\n", encoding="utf-8")
            module_globals: dict[str, object] = {}
            exec(compile(surface_text := read_text(self.surface_path), str(self.surface_path), "exec"), module_globals)
            report = module_globals["collect_report"](repo_root)
            self.assertEqual(report["status"], "failed")
            self.assertEqual(len(report["failures"]), 1)
            self.assertIn(SCRIPT_NAME, report["failures"][0])


if __name__ == "__main__":
    unittest.main()