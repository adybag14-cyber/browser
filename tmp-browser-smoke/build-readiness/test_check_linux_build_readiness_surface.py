from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


def write_text(path: pathlib.Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def stage_path_dependencies(base_dir: pathlib.Path) -> None:
    v8_root = base_dir / "zig-v8-fork"
    boringssl_root = base_dir / "boringssl-zig"

    write_text(v8_root / "build.zig", "")
    write_text(v8_root / "build.zig.zon", "")
    write_text(v8_root / "src" / "v8.zig", "")

    write_text(boringssl_root / "build.zig", "")
    write_text(boringssl_root / "README.md", "")
    (boringssl_root / "generated").mkdir(parents=True, exist_ok=True)


def stage_offline_deps(base_dir: pathlib.Path, *, include_prebuilt_v8: bool) -> pathlib.Path:
    offline_root = base_dir / "offline-deps"
    for dep_name in ("brotli", "zlib", "nghttp2", "curl"):
        write_text(offline_root / dep_name / "marker.txt", dep_name)
    if include_prebuilt_v8:
        write_text(offline_root / "libc_v8_14.0.365.4_linux_x86_64.a", "archive")
    return offline_root


def stage_saved_archives(base_dir: pathlib.Path, *, include_html5ever: bool) -> pathlib.Path:
    archive_root = base_dir / "memory" / "repo_archives" / "browser"
    write_text(
        archive_root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
        "rust",
    )
    if include_html5ever:
        write_text(
            archive_root / "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
            "html5ever",
        )
    write_text(archive_root / "03-boringssl-zig-main.zip", "boringssl")
    write_text(archive_root / "04-zig-browser-depo.tar.zip", "browser-deps")
    return archive_root


def build_fixture_repo(
    source_repo_root: pathlib.Path,
    *,
    stage_offline: bool,
    stage_saved: bool,
    include_prebuilt_v8: bool = False,
    include_html5ever: bool = True,
) -> pathlib.Path:
    fixture_root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-build-readiness-")) / "browser-fork-headed-mode-foundation"
    fixture_root.mkdir(parents=True, exist_ok=True)

    helper_source = source_repo_root / "scripts" / "check_linux_build_readiness.py"
    helper_target = fixture_root / "scripts" / "check_linux_build_readiness.py"
    helper_target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(helper_source, helper_target)

    write_text(
        fixture_root / "scripts" / "linux" / "prepare_offline_build_inputs.sh",
        "#!/usr/bin/env bash\nexit 0\n",
    )
    write_text(
        fixture_root / "build.zig.zon",
        """
.{
    .name = "browser",
    .version = "0.0.0",
    .minimum_zig_version = "0.15.2",
    .dependencies = .{
        .v8 = .{
            .path = "../zig-v8-fork",
        },
        .@"boringssl-zig" = .{
            .path = "../boringssl-zig",
        },
        .curl = .{
            .url = "https://example.invalid/curl.tar.gz",
        },
    },
}
""".lstrip(),
    )

    base_dir = fixture_root.parent
    stage_path_dependencies(base_dir)

    if stage_offline:
        stage_offline_deps(base_dir, include_prebuilt_v8=include_prebuilt_v8)
    if stage_saved:
        stage_saved_archives(base_dir, include_html5ever=include_html5ever)

    return fixture_root


class CheckLinuxBuildReadinessSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source_repo_root = pathlib.Path(__file__).resolve().parents[2]

    def run_helper(self, repo_root: pathlib.Path, *args: str) -> subprocess.CompletedProcess[str]:
        helper_path = repo_root / "scripts" / "check_linux_build_readiness.py"
        return subprocess.run(
            [sys.executable, str(helper_path), "--repo-root", str(repo_root), *args],
            check=False,
            capture_output=True,
            text=True,
        )

    def test_cli_failure_reports_missing_offline_staging_and_saved_archive_next_step(self) -> None:
        repo_root = build_fixture_repo(
            self.source_repo_root,
            stage_offline=False,
            stage_saved=True,
        )

        completed = self.run_helper(
            repo_root,
            "--skip-zig-check",
            "--skip-rust-check",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "--expect-saved-archives",
        )

        self.assertEqual(completed.returncode, 1)
        self.assertIn("offline dependency root is missing", completed.stderr)
        self.assertIn("Suggested next step: run the saved-archive restore command above", completed.stderr)
        self.assertIn("Saved archive root:", completed.stdout)
        self.assertIn("saved Rust toolchain archive", completed.stdout)
        self.assertIn("Suggested offline staging command:", completed.stdout)
        self.assertIn("--browser-deps-archive", completed.stdout)
        self.assertIn("--boringssl-archive", completed.stdout)
        self.assertIn("--html5ever-archive", completed.stdout)
        self.assertIn("--check-only", completed.stdout)

    def test_cli_success_reports_staged_dependencies_prebuilt_v8_and_saved_archives(self) -> None:
        repo_root = build_fixture_repo(
            self.source_repo_root,
            stage_offline=True,
            stage_saved=True,
            include_prebuilt_v8=True,
        )

        completed = self.run_helper(
            repo_root,
            "--skip-zig-check",
            "--skip-rust-check",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "--expect-saved-archives",
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("Repo root:", completed.stdout)
        self.assertIn("Minimum Zig from build.zig.zon: 0.15.2", completed.stdout)
        self.assertIn("Sibling path dependencies:", completed.stdout)
        self.assertIn("[ok]", completed.stdout)
        self.assertIn("Offline dependency root:", completed.stdout)
        self.assertIn("Prebuilt V8 archives:", completed.stdout)
        self.assertIn("libc_v8_14.0.365.4_linux_x86_64.a", completed.stdout)
        self.assertIn("Saved archive root:", completed.stdout)
        self.assertIn("saved browser dependency archive", completed.stdout)
        self.assertIn("URL-backed dependencies still need network access or an offline cache:", completed.stdout)
        self.assertIn("Readiness check passed.", completed.stdout)


if __name__ == "__main__":
    unittest.main()
