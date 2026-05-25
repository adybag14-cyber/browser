from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md": """
    # Issue #3 Zig Toolchain Archive Restore Route

    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/check_issue3_saved_zig_archive_candidates.py`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `--saved-archives-root /path/to/memory/repo_archives/browser/dependencies`
    - Print The Route
    - Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet
    - `python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
    - `show_issue3_zig_toolchain_recovery_route.sh`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `check_issue3_zig_toolchain_match.sh`
    - `check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `show_issue3_zig_toolchain_archive_restore_route.sh`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    """,
    "scripts/check_issue3_saved_zig_archive_candidates.py": """
    class SavedZigArchiveHelperTests(unittest.TestCase):
        pass

    def build_report():
        return {
            "saved_archives_search_roots": [],
            "commands": {
                "restore_check": "bash restore_zig_toolchain_archive.sh --check-only",
                "restore": "bash restore_zig_toolchain_archive.sh",
                "fallback_restore_check": "bash restore_issue3_fallback_zig_toolchain.sh --check-only",
                "fallback_restore": "bash restore_issue3_fallback_zig_toolchain.sh",
            },
        }

    print("Saved archive search:")
    print("Preferred restore commands:")
    print("Fallback restore commands:")
    """,
    "scripts/check_linux_build_readiness.py": """
    parser.add_argument("--toolchains-root")
    parser.add_argument("--saved-archives-root")
    parser.add_argument("--offline-deps-root")
    parser.add_argument("--expect-saved-archives")
    parser.add_argument("--expect-offline-deps")
    parser.add_argument("--require-prebuilt-v8")
    parser.add_argument("--zig")
    """,
    "scripts/linux/check_issue3_zig_toolchain_match.sh": """
    #!/usr/bin/env bash
    echo check_issue3_zig_toolchain_match.sh
    """,
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": """
    #!/usr/bin/env bash
    declare -a REFERENCE_PATHS=(
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Read-first route note for staging a real Zig archive under ../toolchains."
        "scripts/check_issue3_saved_zig_archive_candidates.py|file|Saved Zig archive discovery helper that should surface matching 0.15.x archive candidates before restore."
        "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|file|Route printer that should keep the archive-restore, recovery, and readiness commands on one compact surface."
        "scripts/linux/restore_zig_toolchain_archive.sh|file|Archive restore helper that stages a Zig archive into ../toolchains."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Recovery route printer that should surface the archive-restore checker and restore commands."
        "scripts/check_linux_build_readiness.py|file|Readiness helper that should consume the restored Zig candidate once it is staged."
        "build.zig.zon|file|Manifest surface that defines the minimum Zig line this route must target."
    )
    declare -a CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|The archive-restore note keeps the route printer named explicitly."
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .|The archive-restore note prints the exact saved-archive discovery command."
        "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|saved_archive_candidates|The route printer keeps a dedicated saved-archive discovery command in structured output."
        "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|Archive restore commands|The route printer keeps the archive-restore command section visible in text output."
        "scripts/linux/restore_zig_toolchain_archive.sh|\\"saved_archives_root\\"|The restore helper JSON output keeps the saved-archives root visible."
        "scripts/linux/restore_zig_toolchain_archive.sh|\\"offline_deps_root\\"|The restore helper JSON output keeps the offline-deps root visible."
        "scripts/linux/restore_zig_toolchain_archive.sh|\\"fallback_zig_archive\\"|The restore helper JSON output keeps the fallback Zig archive visible."
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|archive_restore_surface_check|The recovery route printer keeps a dedicated archive-restore surface-check command in structured output."
    )
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": """
    #!/usr/bin/env bash
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \
        [--repo-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-0.15.2.tar.xz] \
        [--offline-deps-root /path/to/offline-deps] \
        [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
        [--json]
    result = {
        "commands": {
            "surface_check": "bash scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "saved_archive_candidates": "python scripts/check_issue3_saved_zig_archive_candidates.py",
            "restore_check_only": "bash scripts/linux/restore_zig_toolchain_archive.sh --check-only",
            "restore": "bash scripts/linux/restore_zig_toolchain_archive.sh",
            "full_readiness": "python scripts/check_linux_build_readiness.py --zig <restored-zig-path>",
            "recovery_route": "bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        },
    }
    print("Saved archive discovery")
    print("Archive restore commands")
    print("Suggested follow-up")
    print("restore_zig_toolchain_archive.sh")
    print("show_issue3_zig_toolchain_recovery_route.sh")
    print("--saved-archives-root")
    print("--offline-deps-root")
    print("check_issue3_zig_toolchain_archive_restore_route_surface.sh")
    print("check_issue3_saved_zig_archive_candidates.py")
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": """
    #!/usr/bin/env bash
    result = {
        "commands": {
            "archive_restore_surface_check": "bash scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        },
    }
    print("Archive restore surface check")
    print("check_issue3_zig_toolchain_archive_restore_route_surface.sh")
    print("show_issue3_zig_toolchain_archive_restore_route.sh")
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": """
    #!/usr/bin/env bash
    Usage:
      scripts/linux/restore_zig_toolchain_archive.sh \
        [--browser-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-archive.tar.xz] \
        [--destination /path/to/toolchains/zig-0.15.2] \
        [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
        [--offline-deps-root /path/to/offline-deps] \
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
        [--check-only] \
        [--json] \
        [--force]
    normalize_saved_archives_root() {
        return 0
    }
    printf '  "saved_archives_root": %s,\\n' "value"
    printf '  "offline_deps_root": %s,\\n' "value"
    printf '  "fallback_zig_archive": %s,\\n' "value"
    printf '  "destination_exists": %s\\n' "false"
    echo "Saved Zig toolchain restore surface check passed."
    echo "Suggested follow-up commands:"
    echo "--expect-saved-archives"
    echo "--expect-offline-deps"
    echo "--require-prebuilt-v8"
    """,
    "build.zig.zon": """
    .minimum_zig_version = "0.15.2",
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-restore-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigToolchainArchiveRestoreRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.archive_restore_route = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.recovery_route = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.build_readiness_route = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates = read_text(cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")
        cls.surface_script = read_text(
            cls.repo_root / "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
        )
        cls.route_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.restore_script = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )
        cls.saved_archive_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_zig_archive_candidates.py"
        )
        cls.readiness_helper = read_text(cls.repo_root / "scripts/check_linux_build_readiness.py")
        cls.recovery_script = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )

    def test_archive_restore_route_keeps_surface_route_and_saved_archive_discovery_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "Print The Route",
            "Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "show_issue3_zig_toolchain_recovery_route.sh",
        ):
            self.assertIn(fragment, self.archive_restore_route)

    def test_route_printer_keeps_surface_discovery_restore_and_followup_commands_visible(self) -> None:
        for fragment in (
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "--offline-deps-root /path/to/offline-deps",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "check_issue3_saved_zig_archive_candidates.py",
            "saved_archive_candidates",
            "Saved archive discovery",
            "Archive restore commands",
            "restore_zig_toolchain_archive.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "Suggested follow-up",
            "<restored-zig-path>",
        ):
            self.assertIn(fragment, self.route_script)

        saved_archive_index = self.route_script.index("Saved archive discovery")
        restore_index = self.route_script.index("Archive restore commands")
        followup_index = self.route_script.index("Suggested follow-up")
        self.assertLess(saved_archive_index, restore_index)
        self.assertLess(restore_index, followup_index)

    def test_surface_checker_keeps_archive_restore_contract_markers_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|file|Read-first route note",
            "scripts/check_issue3_saved_zig_archive_candidates.py|file|Saved Zig archive discovery helper",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|file|Route printer",
            "scripts/linux/restore_zig_toolchain_archive.sh|file|Archive restore helper",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Recovery route printer",
            "scripts/check_linux_build_readiness.py|file|Readiness helper",
            "build.zig.zon|file|Manifest surface",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md|python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh|saved_archive_candidates",
            'scripts/linux/restore_zig_toolchain_archive.sh|\\"saved_archives_root\\"',
            'scripts/linux/restore_zig_toolchain_archive.sh|\\"offline_deps_root\\"',
            'scripts/linux/restore_zig_toolchain_archive.sh|\\"fallback_zig_archive\\"',
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|archive_restore_surface_check",
        ):
            self.assertIn(fragment, self.surface_script)

    def test_restore_helper_keeps_saved_archive_offline_deps_and_followup_contract_visible(self) -> None:
        for fragment in (
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--offline-deps-root /path/to/offline-deps",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "normalize_saved_archives_root()",
            '"saved_archives_root"',
            '"offline_deps_root"',
            '"fallback_zig_archive"',
            '"destination_exists"',
            "Saved Zig toolchain restore surface check passed.",
            "Suggested follow-up commands:",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
        ):
            self.assertIn(fragment, self.restore_script)

    def test_recovery_and_readiness_helpers_keep_archive_restore_followup_visible(self) -> None:
        for fragment in (
            "check_issue3_zig_toolchain_match.sh",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "show_issue3_zig_toolchain_archive_restore_route.sh",
        ):
            self.assertIn(fragment, self.recovery_route)

        for fragment in (
            '"archive_restore_surface_check"',
            "Archive restore surface check",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "show_issue3_zig_toolchain_archive_restore_route.sh",
        ):
            self.assertIn(fragment, self.recovery_script)

        for fragment in (
            "--toolchains-root",
            "--saved-archives-root",
            "--offline-deps-root",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "--zig",
        ):
            self.assertIn(fragment, self.readiness_helper)

        for fragment in (
            "Saved archive search:",
            "Preferred restore commands:",
            "Fallback restore commands:",
            '"saved_archives_search_roots"',
            '"restore_check"',
            '"restore"',
            '"fallback_restore_check"',
            '"fallback_restore"',
        ):
            self.assertIn(fragment, self.saved_archive_helper)

    def test_build_readiness_and_runtime_gates_keep_archive_restore_route_visible(self) -> None:
        self.assertIn("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", self.build_readiness_route)
        self.assertIn("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", self.build_readiness_route)
        self.assertIn("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", self.runtime_gates)
        self.assertIn("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", self.runtime_gates)


if __name__ == "__main__":
    unittest.main()
