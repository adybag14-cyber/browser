from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_FILES = {
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \\
      --repo-root /path/to/browser \\
      --toolchains-root /path/to/toolchains \\
      --archive /path/to/zig-0.15.2.tar.xz \\
      --saved-archives-root /path/to/memory/repo_archives/browser/dependencies \\
      --offline-deps-root /path/to/offline-deps \\
      --fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz

    Use `--fallback-zig-archive` when the run still needs to keep the attached
    `0.17` archive visible as a surfaced stopgap input while the route restores
    or discovers a real `0.15.x` Zig candidate.
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": """
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
    if fallback_zig_archive:
        saved_archive_candidate_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
        restore_check_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
        restore_run_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
        readiness_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
    recovery_parts.extend(("--fallback-zig-archive", fallback_zig_archive))
    "fallback_zig_archive": fallback_zig_archive,
    Keep the fallback Zig archive override on this route so saved-archive discovery,
    restore, recovery, and readiness commands stay aligned on one helper surface.
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-fallback-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigArchiveRestoreFallbackRouteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        else:
            cls.repo_root = build_fixture_repo()

        cls.route_note = (
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        ).read_text(encoding="utf-8")
        cls.route_script = (
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        ).read_text(encoding="utf-8")

    def test_route_note_keeps_fallback_override_visible(self) -> None:
        for fragment in (
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Use `--fallback-zig-archive` when the run still needs to keep the attached",
            "surfaced stopgap input",
        ):
            self.assertIn(fragment, self.route_note)

    def test_route_printer_threads_fallback_override_through_all_followups(self) -> None:
        for fragment in (
            "[--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz]",
            'saved_archive_candidate_parts.extend(("--fallback-zig-archive", fallback_zig_archive))',
            'restore_check_parts.extend(("--fallback-zig-archive", fallback_zig_archive))',
            'restore_run_parts.extend(("--fallback-zig-archive", fallback_zig_archive))',
            'readiness_parts.extend(("--fallback-zig-archive", fallback_zig_archive))',
            'recovery_parts.extend(("--fallback-zig-archive", fallback_zig_archive))',
            '"fallback_zig_archive": fallback_zig_archive,',
            "Keep the fallback Zig archive override on this route so saved-archive discovery,",
        ):
            self.assertIn(fragment, self.route_script)


if __name__ == "__main__":
    unittest.main()
