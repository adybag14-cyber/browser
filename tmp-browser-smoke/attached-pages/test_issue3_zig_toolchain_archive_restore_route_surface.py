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
    - a matching Zig `0.15.x` archive is available
    - Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet
    - `python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
    - Print The Route
    - `bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
    - `--saved-archives-root /path/to/memory/repo_archives/browser/dependencies`
    - `bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - Prefer a Zig `0.15.2` or other `0.15.x` archive
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/linux/check_issue3_zig_toolchain_match.sh`
    - checks an installed Zig version unless told to skip it
    """,
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": r"""
    Usage:
      bash scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh \
        [--repo-root /path/to/browser-repo] \
        [--json]
    docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
    docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md
    scripts/check_issue3_saved_zig_archive_candidates.py
    scripts/linux/check_issue3_zig_toolchain_match.sh
    scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh
    scripts/linux/restore_zig_toolchain_archive.sh
    scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
    scripts/check_linux_build_readiness.py
    build.zig.zon
    Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet
    python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
    Print The Route
    bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh
    --saved-archives-root /path/to/memory/repo_archives/browser/dependencies
    show_issue3_zig_toolchain_recovery_route.sh
    saved_archive_candidates
    Saved archive discovery
    Archive restore commands
    --offline-deps-root
    archive_restore_surface_check
    --check-only
    --saved-archives-root
    --fallback-zig-archive
    normalize_saved_archives_root()
    "saved_archives_root"
    "offline_deps_root"
    "fallback_zig_archive"
    "destination_exists"
    Saved Zig toolchain restore surface check passed.
    Suggested follow-up commands:
    --expect-saved-archives
    --expect-offline-deps
    --require-prebuilt-v8
    """,
    "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh": r"""
    Usage:
      bash scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh \
        [--repo-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-0.15.2.tar.xz] \
        [--offline-deps-root /path/to/offline-deps] \
        [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
        [--json]
    SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
    SAVED_ARCHIVE_CANDIDATES_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_zig_archive_candidates.py"
    RESTORE_SCRIPT="${REPO_ROOT}/scripts/linux/restore_zig_toolchain_archive.sh"
    RECOVERY_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    READINESS_SCRIPT="${REPO_ROOT}/scripts/check_linux_build_readiness.py"
    "saved_archive_candidates"
    "restore_check_only"
    "full_readiness"
    "Saved archive discovery"
    "Archive restore commands"
    "Suggested follow-up"
    "--saved-archives-root"
    "--offline-deps-root"
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": r"""
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
    Supported archive types:
      .tar, .tar.gz, .tgz, .tar.xz, .zip
    DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    normalize_saved_archives_root() {
    ARCHIVE_TOP_LEVEL="$(python3 - "${ARCHIVE_PATH}" <<'PY'"
    FOLLOW_UP_DISCOVERY="bash '${FOLLOW_UP_DISCOVERY_SCRIPT}' --repo-root '${BROWSER_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}' --saved-archives-root '${SAVED_ARCHIVES_ROOT}' --offline-deps-root '${OFFLINE_DEPS_ROOT}'"
    FOLLOW_UP_BUILD_READINESS_TEMPLATE="python '${FOLLOW_UP_BUILD_READINESS_SCRIPT}' --repo-root '${BROWSER_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}' --saved-archives-root '${SAVED_ARCHIVES_ROOT}' --offline-deps-root '${OFFLINE_DEPS_ROOT}' --expect-saved-archives --expect-offline-deps --require-prebuilt-v8 --zig <restored-zig-path>"
    "saved_archives_root"
    "offline_deps_root"
    "fallback_zig_archive"
    "destination_exists"
    if [[ "${CHECK_ONLY}" == "true" ]]; then
        echo "Saved Zig toolchain restore surface check passed."
        echo "Archive top level:   ${ARCHIVE_TOP_LEVEL}"
        echo "Suggested follow-up commands:"
    fi
    if [[ -e "${DESTINATION}" ]]; then
        if [[ "${FORCE_RESTORE}" == "true" ]]; then
            rm -rf "${DESTINATION}"
        fi
    fi
    if python3 - "${ARCHIVE_PATH}" <<'PY'
    then
        unzip -q "${ARCHIVE_PATH}" -d "${TMP_DIR}"
    else
        tar -xf "${ARCHIVE_PATH}" -C "${TMP_DIR}"
    fi
    if [[ -x "${DESTINATION}/zig" ]]; then
        ZIG_BIN="${DESTINATION}/zig"
    elif [[ -x "${DESTINATION}/bin/zig" ]]; then
        ZIG_BIN="${DESTINATION}/bin/zig"
    else
        echo "Restored toolchain is missing a zig executable under ${DESTINATION}" >&2
        exit 1
    fi
    echo "Saved Zig toolchain is ready."
    --expect-saved-archives
    --expect-offline-deps
    --require-prebuilt-v8
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    build_zon = repo_root / "build.zig.zon"
    fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    archive_restore_surface_check
    fallback_restore_check
    fallback_restore
    """,
    "scripts/check_linux_build_readiness.py": """
    def build_parser():
        parser.add_argument("--toolchains-root")
        parser.add_argument("--saved-archives-root")
        parser.add_argument("--offline-deps-root")
        parser.add_argument("--fallback-zig-archive")
        parser.add_argument("--zig")
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
    """,
    "build.zig.zon": """
    .{
        .name = "browser",
        .version = "0.0.0",
        .minimum_zig_version = "0.15.2",
    }
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-archive-route-"))
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

        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
        )
        cls.recovery_note = read_text(
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.surface_helper = read_text(
            cls.repo_root / "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_zig_toolchain_archive.sh"
        )
        cls.recovery_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )

    def test_route_note_keeps_archive_restore_surface_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "a matching Zig `0.15.x` archive is available",
            "Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "Print The Route",
            "bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only",
        ):
            self.assertIn(fragment, self.route_note)

    def test_paired_notes_keep_pointing_back_to_archive_restore_route(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "Prefer a Zig `0.15.2` or other `0.15.x` archive",
        ):
            self.assertIn(fragment, self.recovery_note)

        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        ):
            self.assertIn(fragment, self.runtime_gates_note)

    def test_surface_helper_keeps_archive_restore_contract_checks_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/linux/check_issue3_zig_toolchain_match.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "build.zig.zon",
            "Surface Saved Archive Candidates When The Exact Archive Path Is Not Known Yet",
            "python scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .",
            "Print The Route",
            "bash ./scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "saved_archive_candidates",
            "Saved archive discovery",
            "Archive restore commands",
            "--offline-deps-root",
            "archive_restore_surface_check",
            "--check-only",
            "--saved-archives-root",
            "--fallback-zig-archive",
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
            self.assertIn(fragment, self.surface_helper)

    def test_route_printer_keeps_saved_archive_and_followup_surfaces_visible(self) -> None:
        for fragment in (
            "--archive /path/to/zig-0.15.2.tar.xz",
            "--offline-deps-root /path/to/offline-deps",
            "--saved-archives-root /path/to/memory/repo_archives/browser/dependencies",
            "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "check_issue3_saved_zig_archive_candidates.py",
            "restore_zig_toolchain_archive.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "check_linux_build_readiness.py",
            '"saved_archive_candidates"',
            '"restore_check_only"',
            '"full_readiness"',
            "Saved archive discovery",
            "Archive restore commands",
            "Suggested follow-up",
            "--saved-archives-root",
            "--offline-deps-root",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_restore_helper_keeps_archive_discovery_and_followup_contract_visible(self) -> None:
        for fragment in (
            "--archive /path/to/zig-archive.tar.xz",
            "--destination /path/to/toolchains/zig-0.15.2",
            "--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]",
            "--offline-deps-root /path/to/offline-deps",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--check-only",
            "--json",
            "--force",
            "Supported archive types:",
            ".tar, .tar.gz, .tgz, .tar.xz, .zip",
            'DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "normalize_saved_archives_root()",
            'ARCHIVE_TOP_LEVEL="$(python3 - "${ARCHIVE_PATH}" <<\'PY\'"',
            "--saved-archives-root '${SAVED_ARCHIVES_ROOT}' --offline-deps-root '${OFFLINE_DEPS_ROOT}'",
            "--saved-archives-root '${SAVED_ARCHIVES_ROOT}' --offline-deps-root '${OFFLINE_DEPS_ROOT}' --expect-saved-archives --expect-offline-deps --require-prebuilt-v8 --zig <restored-zig-path>",
            '"saved_archives_root"',
            '"offline_deps_root"',
            '"fallback_zig_archive"',
            '"destination_exists"',
            "Saved Zig toolchain restore surface check passed.",
            "Archive top level:",
            "Suggested follow-up commands:",
            'if [[ "${FORCE_RESTORE}" == "true" ]]',
            'unzip -q "${ARCHIVE_PATH}" -d "${TMP_DIR}"',
            'tar -xf "${ARCHIVE_PATH}" -C "${TMP_DIR}"',
            'if [[ -x "${DESTINATION}/zig" ]]',
            'elif [[ -x "${DESTINATION}/bin/zig" ]]',
            "Restored toolchain is missing a zig executable under ${DESTINATION}",
            "Saved Zig toolchain is ready.",
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_companion_helpers_keep_toolchain_root_and_fallback_surface_visible(self) -> None:
        for fragment in (
            'build_zon = repo_root / "build.zig.zon"',
            'fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "archive_restore_surface_check",
            "fallback_restore_check",
            "fallback_restore",
        ):
            self.assertIn(fragment, self.recovery_helper)

        for fragment in (
            "--toolchains-root",
            "--saved-archives-root",
            "--offline-deps-root",
            "--fallback-zig-archive",
            "--zig",
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
