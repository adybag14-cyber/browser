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

    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - `scripts/check_linux_build_readiness.py`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
    - a matching Zig `0.15.x` archive is available
    - `bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only`
    """,
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
    # Issue #3 Zig Toolchain Recovery Route

    - `scripts/linux/restore_zig_toolchain_archive.sh`
    - `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
    - Prefer a Zig `0.15.2` or other `0.15.x` archive
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
    - `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
    - checks an installed Zig version unless told to skip it
    """,
    "scripts/linux/restore_zig_toolchain_archive.sh": r"""
    Usage:
      scripts/linux/restore_zig_toolchain_archive.sh \
        [--browser-root /path/to/browser-repo] \
        [--toolchains-root /path/to/toolchains] \
        [--archive /path/to/zig-archive.tar.xz] \
        [--destination /path/to/toolchains/zig-0.15.2] \
        [--check-only] \
        [--json] \
        [--force]
    Supported archive types:
      .tar, .tar.gz, .tgz, .tar.xz, .zip
    DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    ARCHIVE_TOP_LEVEL="$(python3 - "${ARCHIVE_PATH}" <<'PY'"
    FOLLOW_UP_DISCOVERY="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root '${BROWSER_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}'"
    FOLLOW_UP_BUILD_READINESS_TEMPLATE="python scripts/check_linux_build_readiness.py --repo-root '${BROWSER_ROOT}' --toolchains-root '${TOOLCHAINS_ROOT}' --zig <restored-zig-path>"
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
    printf "  python scripts/check_linux_build_readiness.py --repo-root '%s' --toolchains-root '%s' --zig '%s'\n" \
        "${BROWSER_ROOT}" "${TOOLCHAINS_ROOT}" "${ZIG_BIN}"
    """,
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
    build_zon = repo_root / "build.zig.zon"
    fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    fallback_restore_check
    fallback_restore
    """,
    "scripts/check_linux_build_readiness.py": """
    def build_parser():
        parser.add_argument("--toolchains-root")
        parser.add_argument("--zig")
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
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "a matching Zig `0.15.x` archive is available",
            "bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only",
        ):
            self.assertIn(fragment, self.route_note)

    def test_recovery_and_build_readiness_notes_keep_pointing_at_the_archive_route(self) -> None:
        for fragment in (
            "scripts/linux/restore_zig_toolchain_archive.sh",
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            "Prefer a Zig `0.15.2` or other `0.15.x` archive",
        ):
            self.assertIn(fragment, self.recovery_note)

        for fragment in (
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        ):
            self.assertIn(fragment, self.build_readiness_note)

    def test_restore_helper_keeps_archive_discovery_and_followup_contract_visible(self) -> None:
        for fragment in (
            "--archive /path/to/zig-archive.tar.xz",
            "--destination /path/to/toolchains/zig-0.15.2",
            "--check-only",
            "--json",
            "--force",
            "Supported archive types:",
            ".tar, .tar.gz, .tgz, .tar.xz, .zip",
            'DEFAULT_FALLBACK_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'ARCHIVE_TOP_LEVEL="$(python3 - "${ARCHIVE_PATH}" <<\'PY\'"',
            'FOLLOW_UP_DISCOVERY="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh',
            'FOLLOW_UP_BUILD_READINESS_TEMPLATE="python scripts/check_linux_build_readiness.py',
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
            "--zig '%s'",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_companion_helpers_keep_toolchain_root_and_fallback_surface_visible(self) -> None:
        for fragment in (
            'build_zon = repo_root / "build.zig.zon"',
            'fallback_zig_archive = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "fallback_restore_check",
            "fallback_restore",
        ):
            self.assertIn(fragment, self.recovery_helper)

        for fragment in (
            '--toolchains-root',
            '--zig',
        ):
            self.assertIn(fragment, self.readiness_helper)


if __name__ == "__main__":
    unittest.main()
