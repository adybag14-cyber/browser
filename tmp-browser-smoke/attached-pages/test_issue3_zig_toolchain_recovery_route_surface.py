from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "build.zig.zon": """
.{
    .name = "browser",
    .version = "0.0.0",
    .minimum_zig_version = "0.15.2",
    .dependencies = .{
        .v8 = .{ .path = "../zig-v8-fork" },
        .@"boringssl-zig" = .{ .path = "../boringssl-zig" },
        .curl = .{ .url = "https://example.invalid/curl.tar.gz" },
    },
}
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
# Issue #3 Runtime Re-entry Gates

- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
""",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
# Issue #3 Linux Build-Readiness Route

- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/check_linux_build_readiness.py`
- Prefer a Zig `0.15.2` toolchain
""",
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": """
# Issue #3 Zig Toolchain Recovery Route

- `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
- Prefer a Zig `0.15.2` toolchain
""",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": r"""
Usage:
  bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

build_zon = repo_root / "build.zig.zon"
match = re.search(
    r'\.minimum_zig_version\s*=\s*"([^"]+)"',
    build_zon.read_text(encoding="utf-8"),
)
discovery_parts = [
    "python",
    "scripts/check_linux_build_readiness.py",
    "--repo-root",
    str(repo_root),
    "--skip-zig-check",
    "--skip-rust-check",
    "--expect-saved-archives",
    "--saved-archives-root",
    str(saved_archives_root),
    "--toolchains-root",
    str(toolchains_root),
]

print("Surface check")
print("Candidate discovery")
print("Suggested matching readiness command")
print("No branch-compatible Zig candidate is staged yet.")
print("Fallback Zig archive:")
print("Treat the attached Zig 0.17 dev bundle as a surfaced fallback only; it is not branch-compatible validation evidence for this checkout.")
""",
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh": r"""
REFERENCE_PATHS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|Read-first Zig line recovery note"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|Linux build-readiness companion"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|Gate note"
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh|file|Fail-fast surface checker"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|Compact Zig line recovery route printer"
    "scripts/check_linux_build_readiness.py|file|Readiness helper"
    "build.zig.zon|file|Manifest surface that defines the branch minimum Zig line."
)
CONTENT_EXPECTATIONS=(
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|Route helper stays linked."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|Fallback Zig bundle stays named."
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|Expected line stays named."
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|Linux route still points back here."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|Route still reads build.zig.zon."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|Route still points back to readiness helper."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|Explicit toolchains override remains."
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|Fallback archive remains surfaced."
)
echo "All Zig toolchain recovery surfaces are present."
""",
    "scripts/check_linux_build_readiness.py": """
MINIMUM_ZIG_RE = re.compile(r'\\.minimum_zig_version\\s*=\\s*"([^"]+)"')
PATH_VALUE_RE = re.compile(r'\\.path\\s*=\\s*"([^"]+)"')
URL_VALUE_RE = re.compile(r'\\.url\\s*=\\s*"([^"]+)"')
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

def build_parser():
    parser.add_argument("--skip-zig-check")
    parser.add_argument("--skip-rust-check")
    parser.add_argument("--expect-saved-archives")
    parser.add_argument("--saved-archives-root")
    parser.add_argument("--toolchains-root")
    parser.add_argument("--fallback-zig-archive")
    parser.add_argument("--self-test")

def discover_toolchain_zig_candidates(toolchains_root): ...
def describe_zig_toolchain_candidate(minimum_zig, zig_path): ...
def resolve_fallback_zig_archive(repo_root, fallback_zig_archive): ...

class ReadinessHelperTests(unittest.TestCase):
    def test_same_version_line_matches_major_minor_only(self): ...
    def test_describe_fallback_zig_archive_reports_mismatched_line(self): ...
    def test_describe_fallback_zig_archive_reports_matching_line(self): ...
    def test_discover_toolchain_zig_candidates_and_describe_versions(self): ...
    def test_parser_accepts_fallback_zig_archive(self): ...
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-zig-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ZigToolchainRecoveryRouteSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
        )
        cls.linux_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
        )
        cls.readiness_helper = read_text(
            cls.repo_root / "scripts/check_linux_build_readiness.py"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_route_note_keeps_fallback_and_matching_line_guidance_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            "scripts/check_linux_build_readiness.py",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "0.15.2",
        ):
            self.assertIn(fragment, self.route_note)

    def test_linux_note_and_runtime_gates_still_point_back_to_zig_route(self) -> None:
        self.assertIn("show_issue3_zig_toolchain_recovery_route.sh", self.linux_note)
        for fragment in (
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            "scripts/check_linux_build_readiness.py",
        ):
            self.assertIn(fragment, self.runtime_gates)

    def test_route_helper_keeps_discovery_fallback_and_readiness_commands(self) -> None:
        for fragment in (
            "build.zig.zon",
            "check_linux_build_readiness.py",
            "--skip-zig-check",
            "--skip-rust-check",
            "--expect-saved-archives",
            "--saved-archives-root",
            "--toolchains-root",
            "--fallback-zig-archive",
            "Surface check",
            "Candidate discovery",
            "Suggested matching readiness command",
            "No branch-compatible Zig candidate is staged yet.",
            "Fallback Zig archive:",
            "Treat the attached Zig 0.17 dev bundle as a surfaced fallback only",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_surface_checker_keeps_reference_and_content_expectations(self) -> None:
        for fragment in (
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|file|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file|',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|file|',
            '"scripts/check_linux_build_readiness.py|file|',
            '"build.zig.zon|file|Manifest surface',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|',
            '"docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md|0.15.2|',
            '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|show_issue3_zig_toolchain_recovery_route.sh|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|build.zig.zon|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|check_linux_build_readiness.py|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|--toolchains-root|',
            '"scripts/linux/show_issue3_zig_toolchain_recovery_route.sh|zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz|',
            "All Zig toolchain recovery surfaces are present.",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_readiness_helper_keeps_toolchain_discovery_and_fallback_coverage(self) -> None:
        for fragment in (
            'DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            "--skip-zig-check",
            "--skip-rust-check",
            "--expect-saved-archives",
            "--saved-archives-root",
            "--toolchains-root",
            "--fallback-zig-archive",
            "--self-test",
            "discover_toolchain_zig_candidates",
            "describe_zig_toolchain_candidate",
            "resolve_fallback_zig_archive",
            "def test_same_version_line_matches_major_minor_only",
            "def test_describe_fallback_zig_archive_reports_mismatched_line",
            "def test_describe_fallback_zig_archive_reports_matching_line",
            "def test_discover_toolchain_zig_candidates_and_describe_versions",
            "def test_parser_accepts_fallback_zig_archive",
        ):
            self.assertIn(fragment, self.readiness_helper)

    def test_manifest_keeps_branch_minimum_line_and_path_dependencies(self) -> None:
        for fragment in (
            '.minimum_zig_version = "0.15.2"',
            '.v8 = .{ .path = "../zig-v8-fork" }',
            '.@"boringssl-zig" = .{ .path = "../boringssl-zig" }',
            '.curl = .{ .url = "https://example.invalid/curl.tar.gz" }',
        ):
            self.assertIn(fragment, self.build_manifest)


if __name__ == "__main__":
    unittest.main()
