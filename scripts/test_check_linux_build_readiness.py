import contextlib
import importlib.util
import io
import pathlib
import tempfile
import unittest
from types import SimpleNamespace
from unittest import mock


MODULE_PATH = pathlib.Path(__file__).with_name("check_linux_build_readiness.py")
SPEC = importlib.util.spec_from_file_location("check_linux_build_readiness", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


SAMPLE_BUILD_ZIG_ZON = """
.{
    .name = "browser",
    .version = "0.0.0",
    .minimum_zig_version = "0.15.2",
    .dependencies = .{
        .@"zig-v8" = .{ .path = "../zig-v8-fork" },
        .boringssl = .{ .path = "../boringssl-zig" },
        .@"html5ever" = .{ .url = "https://example.test/html5ever.tar.gz" },
    },
}
"""


class CheckLinuxBuildReadinessTest(unittest.TestCase):
    def write_repo(self, root: pathlib.Path) -> pathlib.Path:
        repo_root = root / "browser"
        repo_root.mkdir()
        (repo_root / "build.zig.zon").write_text(SAMPLE_BUILD_ZIG_ZON, encoding="utf-8")
        return repo_root

    def test_load_build_metadata_collects_minimum_path_and_url_dependencies(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.write_repo(pathlib.Path(tmpdir))
            minimum_zig, path_deps, url_deps = MODULE.load_build_metadata(repo_root)

        self.assertEqual(minimum_zig, "0.15.2")
        self.assertEqual(
            [(name, path.name) for name, path in path_deps],
            [("zig-v8", "zig-v8-fork"), ("boringssl", "boringssl-zig")],
        )
        self.assertEqual(url_deps, ["html5ever"])

    def test_check_zig_version_reports_missing_binary(self) -> None:
        with mock.patch.object(MODULE.subprocess, "run", side_effect=FileNotFoundError):
            failures = MODULE.check_zig_version(pathlib.Path("."), "0.15.2", "zig")
        self.assertEqual(
            failures,
            ["zig not found on PATH (expected a 0.15.2 toolchain or an explicit --zig path)"],
        )

    def test_check_zig_version_reports_mismatched_line(self) -> None:
        completed = SimpleNamespace(stdout="0.17.0-dev.299+a76ce7710\n")
        with mock.patch.object(MODULE.subprocess, "run", return_value=completed):
            failures = MODULE.check_zig_version(pathlib.Path("."), "0.15.2", "zig")
        self.assertEqual(
            failures,
            ["zig 0.17.0-dev.299+a76ce7710 does not match the branch's expected 0.15.x line"],
        )

    def test_check_path_dependencies_reports_missing_siblings(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            present = root / "present"
            present.mkdir()
            missing = root / "missing"
            failures = MODULE.check_path_dependencies(
                [("present-dep", present), ("missing-dep", missing)]
            )

        self.assertEqual(
            failures,
            [f"missing sibling dependency missing-dep: expected {missing}"],
        )

    def test_main_skip_zig_check_passes_with_staged_siblings(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            repo_root = self.write_repo(root)
            (root / "zig-v8-fork").mkdir()
            (root / "boringssl-zig").mkdir()

            stdout = io.StringIO()
            stderr = io.StringIO()
            argv = [
                "check_linux_build_readiness.py",
                "--repo-root",
                str(repo_root),
                "--skip-zig-check",
            ]
            with mock.patch("sys.argv", argv), contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = MODULE.main()

        self.assertEqual(exit_code, 0)
        self.assertIn("Minimum Zig from build.zig.zon: 0.15.2", stdout.getvalue())
        self.assertIn("  - zig-v8", stdout.getvalue())
        self.assertIn("  - boringssl", stdout.getvalue())
        self.assertIn("  - html5ever", stdout.getvalue())
        self.assertIn("Readiness check passed.", stdout.getvalue())
        self.assertEqual(stderr.getvalue(), "")

    def test_main_skip_zig_check_fails_when_sibling_dependency_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            repo_root = self.write_repo(root)
            (root / "zig-v8-fork").mkdir()

            stdout = io.StringIO()
            stderr = io.StringIO()
            argv = [
                "check_linux_build_readiness.py",
                "--repo-root",
                str(repo_root),
                "--skip-zig-check",
            ]
            with mock.patch("sys.argv", argv), contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = MODULE.main()

        self.assertEqual(exit_code, 1)
        self.assertIn("missing sibling dependency boringssl", stderr.getvalue())
        self.assertIn("Suggested next step", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
