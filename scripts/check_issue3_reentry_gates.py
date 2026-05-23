#!/usr/bin/env python3

"""Summarize whether the direct issue #3 runtime patch can be reopened honestly.

This helper checks the two hard gates from docs/ISSUE3_RUNTIME_REENTRY_GATES.md:
1. A writable local publication surface for src/browser/Page.zig and
   src/display/win32_backend.zig.
2. A branch-compatible validation surface with saved archives, offline deps, and
   at least one Zig toolchain on the branch's expected major/minor line.

It is intentionally read-only. The goal is to help scheduled or manual reruns
choose the next lane quickly instead of re-deriving the same gate status by
hand.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
ARCHIVE_VERSION_RE = re.compile(r"(\d+\.\d+\.\d+)")
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
PREBUILT_V8_GLOB = "libc_v8_*.a"
SAVED_ARCHIVE_GLOBS: dict[str, str] = {
    "rust_toolchain": "01-rust-*.tar.xz",
    "html5ever": "02-litefetch-html5ever-*.zip",
    "boringssl": "03-boringssl-zig-main.zip",
    "browser_deps": "04-zig-browser-depo.tar.zip",
}
REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)
RUNTIME_TARGETS = (
    "src/browser/Page.zig",
    "src/display/win32_backend.zig",
)
HELPER_SURFACE_PATHS = (
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/check_linux_build_readiness.py",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "scripts/linux/show_issue3_offline_build_inputs_route.sh",
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
)
DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(text)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected_version: str, actual_version: str) -> bool:
    expected_parts = parse_semver(expected_version)
    actual_parts = parse_semver(actual_version)
    return actual_parts[:2] == expected_parts[:2]


def infer_archive_version(path: Path) -> str | None:
    match = ARCHIVE_VERSION_RE.search(path.name)
    return None if match is None else match.group(1)


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory" / "repo_archives" / "browser" / "dependencies").resolve()


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_fallback_zig(repo_root: Path) -> Path | None:
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG).resolve()
    return candidate if candidate.is_file() else None


def load_minimum_zig(repo_root: Path) -> str:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


def probe_version(command: list[str]) -> tuple[bool, str]:
    try:
        completed = subprocess.run(command, check=True, capture_output=True, text=True)
    except FileNotFoundError:
        return False, "not found"
    except subprocess.CalledProcessError as exc:
        return False, f"probe failed with exit code {exc.returncode}"
    output = completed.stdout.strip() or completed.stderr.strip()
    return True, output or "unknown"


def collect_runtime_target_status(repo_root: Path) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    for relative_path in RUNTIME_TARGETS:
        path = repo_root / relative_path
        exists = path.is_file()
        writable = exists and path.stat().st_mode & 0o200 != 0
        results.append(
            {
                "path": str(path),
                "exists": exists,
                "writable": bool(writable),
            }
        )
    return results


def collect_helper_surface_status(repo_root: Path) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    for relative_path in HELPER_SURFACE_PATHS:
        path = repo_root / relative_path
        results.append(
            {
                "path": str(path),
                "exists": path.is_file(),
            }
        )
    return results


def collect_saved_archive_status(saved_archives_root: Path) -> dict[str, object]:
    results: dict[str, object] = {
        "root": str(saved_archives_root),
        "exists": saved_archives_root.is_dir(),
        "archives": {},
    }
    for key, pattern in SAVED_ARCHIVE_GLOBS.items():
        matches = sorted(saved_archives_root.glob(pattern)) if saved_archives_root.is_dir() else []
        results["archives"][key] = {
            "path": str(matches[0]) if matches else "",
            "exists": bool(matches),
            "required": key in REQUIRED_SAVED_ARCHIVE_KEYS,
        }
    return results


def collect_offline_dep_status(offline_deps_root: Path) -> dict[str, object]:
    staged_dirs: list[dict[str, object]] = []
    for name in OFFLINE_DEP_NAMES:
        path = offline_deps_root / name
        staged_dirs.append(
            {
                "name": name,
                "path": str(path),
                "exists": path.is_dir(),
                "nonempty": path.is_dir() and any(path.iterdir()),
            }
        )
    prebuilt_archives = sorted(offline_deps_root.glob(PREBUILT_V8_GLOB)) if offline_deps_root.is_dir() else []
    return {
        "root": str(offline_deps_root),
        "exists": offline_deps_root.is_dir(),
        "dirs": staged_dirs,
        "prebuilt_v8": [str(path) for path in prebuilt_archives],
    }


def discover_zig_candidates(toolchains_root: Path) -> list[Path]:
    if not toolchains_root.is_dir():
        return []
    candidates: list[Path] = []
    seen: set[Path] = set()
    for pattern in DEFAULT_ZIG_TOOLCHAIN_GLOBS:
        for candidate in sorted(toolchains_root.glob(pattern)):
            resolved = candidate.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def collect_zig_status(
    *,
    repo_root: Path,
    minimum_zig: str,
    toolchains_root: Path,
    zig_cmd: str,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    current_ok, current_output = probe_version([zig_cmd, "version"])
    current_matches = current_ok and same_version_line(minimum_zig, current_output)

    candidates: list[dict[str, object]] = []
    matching_candidates: list[str] = []
    for candidate in discover_zig_candidates(toolchains_root):
        ok, output = probe_version([str(candidate), "version"])
        matches = ok and same_version_line(minimum_zig, output)
        if matches:
            matching_candidates.append(str(candidate))
        candidates.append(
            {
                "path": str(candidate),
                "ok": ok,
                "version": output,
                "matches_expected_line": matches,
            }
        )

    fallback_status: dict[str, object] | None = None
    if fallback_zig_archive is not None:
        inferred_version = infer_archive_version(fallback_zig_archive)
        fallback_status = {
            "path": str(fallback_zig_archive),
            "exists": fallback_zig_archive.is_file(),
            "inferred_version": inferred_version,
            "matches_expected_line": bool(
                inferred_version is not None and same_version_line(minimum_zig, inferred_version)
            ),
        }

    return {
        "minimum_zig": minimum_zig,
        "current": {
            "command": zig_cmd,
            "ok": current_ok,
            "version": current_output,
            "matches_expected_line": current_matches,
        },
        "toolchains_root": str(toolchains_root),
        "candidates": candidates,
        "matching_candidates": matching_candidates,
        "fallback_archive": fallback_status,
        "has_matching_toolchain": current_matches or bool(matching_candidates),
    }


def build_summary(
    *,
    repo_root: Path,
    minimum_zig: str,
    runtime_targets: list[dict[str, object]],
    helper_surface: list[dict[str, object]],
    saved_archives: dict[str, object],
    offline_deps: dict[str, object],
    zig_status: dict[str, object],
) -> dict[str, object]:
    publication_blockers: list[str] = []
    for target in runtime_targets:
        if not target["exists"]:
            publication_blockers.append(f"missing runtime target {target['path']}")
        elif not target["writable"]:
            publication_blockers.append(f"runtime target is not writable: {target['path']}")

    helper_blockers = [entry["path"] for entry in helper_surface if not entry["exists"]]

    archive_entries = saved_archives["archives"]
    saved_archive_blockers = [
        key for key in REQUIRED_SAVED_ARCHIVE_KEYS if not archive_entries[key]["exists"]
    ]

    offline_dir_blockers = [
        entry["name"]
        for entry in offline_deps["dirs"]
        if not entry["exists"] or not entry["nonempty"]
    ]
    missing_prebuilt_v8 = not offline_deps["prebuilt_v8"]

    validation_blockers: list[str] = []
    if not zig_status["has_matching_toolchain"]:
        validation_blockers.append(
            f"no Zig toolchain on the expected {parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x line is staged"
        )
    if saved_archive_blockers:
        validation_blockers.append(
            "missing required saved archives: " + ", ".join(saved_archive_blockers)
        )
    if offline_dir_blockers:
        validation_blockers.append(
            "offline dependency staging is incomplete: " + ", ".join(offline_dir_blockers)
        )
    if missing_prebuilt_v8:
        validation_blockers.append("no prebuilt V8 archive is staged under offline-deps")

    publication_gate_open = not publication_blockers
    validation_gate_open = not validation_blockers
    helper_surface_ready = not helper_blockers

    repo_root_str = str(repo_root)
    saved_archives_root = str(Path(saved_archives["root"]))
    offline_deps_root = str(Path(offline_deps["root"]))
    toolchains_root = zig_status["toolchains_root"]
    rust_toolchain_dir = str(Path(toolchains_root) / "rust-1.79.0")

    next_commands: list[str] = []
    if not publication_gate_open:
        next_commands.append(
            f"bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root {repo_root_str}"
        )
    if saved_archive_blockers:
        next_commands.append(
            f"python scripts/check_issue3_saved_memory_inputs.py --repo-root {repo_root_str}"
        )
    if offline_dir_blockers or missing_prebuilt_v8:
        next_commands.append(
            f"bash scripts/linux/show_issue3_offline_build_inputs_route.sh --repo-root {repo_root_str} --saved-archives-root {saved_archives_root}"
        )
    if not zig_status["has_matching_toolchain"]:
        next_commands.append(
            f"bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root {repo_root_str} --toolchains-root {toolchains_root} --saved-archives-root {saved_archives_root} --offline-deps-root {offline_deps_root}"
        )
    if publication_gate_open and validation_gate_open:
        next_commands.append(
            f"bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root {repo_root_str} --saved-archives-root {Path(saved_archives_root).parent} --rust-toolchain-dir {rust_toolchain_dir}"
        )
        next_commands.append(
            r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        )
        next_commands.append(
            r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )

    return {
        "publication_gate": {
            "open": publication_gate_open,
            "blockers": publication_blockers,
        },
        "validation_gate": {
            "open": validation_gate_open,
            "blockers": validation_blockers,
        },
        "helper_surface": {
            "ready": helper_surface_ready,
            "missing_paths": helper_blockers,
        },
        "direct_runtime_reentry_ready": publication_gate_open and validation_gate_open,
        "next_commands": next_commands,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check whether the issue #3 direct runtime patch is ready to reopen."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser checkout root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to the saved dependency archives root (default: ../memory/repo_archives/browser/dependencies)",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the staged toolchains root (default: ../toolchains)",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Path to the staged offline dependency root (default: ../offline-deps)",
    )
    parser.add_argument("--zig", default="zig", help="Zig executable to probe on PATH")
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional path to the surfaced fallback Zig archive",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of line-oriented text")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class ReentryGateTests(unittest.TestCase):
    def test_same_version_line_only_needs_major_minor_match(self) -> None:
        self.assertTrue(same_version_line("0.15.2", "0.15.7"))
        self.assertFalse(same_version_line("0.15.2", "0.17.0-dev.299+a76ce7710"))

    def test_infer_archive_version_from_filename(self) -> None:
        archive = Path("/tmp/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz")
        self.assertEqual(infer_archive_version(archive), "0.17.0")

    def test_build_summary_reports_ready_layout(self) -> None:
        runtime_targets = [
            {"path": "/tmp/Page.zig", "exists": True, "writable": True},
            {"path": "/tmp/win32_backend.zig", "exists": True, "writable": True},
        ]
        helper_surface = [{"path": "/tmp/helper", "exists": True}]
        saved_archives = {
            "root": "/tmp/memory/repo_archives/browser/dependencies",
            "archives": {
                "rust_toolchain": {"exists": True},
                "html5ever": {"exists": True},
                "boringssl": {"exists": True},
                "browser_deps": {"exists": True},
            },
        }
        offline_deps = {
            "root": "/tmp/offline-deps",
            "dirs": [
                {"name": name, "exists": True, "nonempty": True}
                for name in OFFLINE_DEP_NAMES
            ],
            "prebuilt_v8": ["/tmp/offline-deps/libc_v8_test.a"],
        }
        zig_status = {
            "toolchains_root": "/tmp/toolchains",
            "has_matching_toolchain": True,
        }

        summary = build_summary(
            repo_root=Path("/tmp/browser"),
            minimum_zig="0.15.2",
            runtime_targets=runtime_targets,
            helper_surface=helper_surface,
            saved_archives=saved_archives,
            offline_deps=offline_deps,
            zig_status=zig_status,
        )

        self.assertTrue(summary["publication_gate"]["open"])
        self.assertTrue(summary["validation_gate"]["open"])
        self.assertTrue(summary["direct_runtime_reentry_ready"])

    def test_build_summary_reports_missing_offline_inputs(self) -> None:
        runtime_targets = [
            {"path": "/tmp/Page.zig", "exists": True, "writable": True},
            {"path": "/tmp/win32_backend.zig", "exists": True, "writable": True},
        ]
        helper_surface = [{"path": "/tmp/helper", "exists": True}]
        saved_archives = {
            "root": "/tmp/memory/repo_archives/browser/dependencies",
            "archives": {
                "rust_toolchain": {"exists": True},
                "html5ever": {"exists": False},
                "boringssl": {"exists": True},
                "browser_deps": {"exists": True},
            },
        }
        offline_deps = {
            "root": "/tmp/offline-deps",
            "dirs": [
                {"name": "brotli", "exists": False, "nonempty": False},
                {"name": "zlib", "exists": True, "nonempty": True},
                {"name": "nghttp2", "exists": True, "nonempty": True},
                {"name": "curl", "exists": True, "nonempty": True},
            ],
            "prebuilt_v8": [],
        }
        zig_status = {
            "toolchains_root": "/tmp/toolchains",
            "has_matching_toolchain": False,
        }

        summary = build_summary(
            repo_root=Path("/tmp/browser"),
            minimum_zig="0.15.2",
            runtime_targets=runtime_targets,
            helper_surface=helper_surface,
            saved_archives=saved_archives,
            offline_deps=offline_deps,
            zig_status=zig_status,
        )

        self.assertFalse(summary["validation_gate"]["open"])
        self.assertIn("offline dependency staging is incomplete", summary["validation_gate"]["blockers"][1])
        self.assertFalse(summary["direct_runtime_reentry_ready"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReentryGateTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    saved_archives_root = (
        Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )
    toolchains_root = (
        Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_default_toolchains_root(repo_root)
    )
    offline_deps_root = (
        Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else resolve_default_offline_deps_root(repo_root)
    )
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else resolve_default_fallback_zig(repo_root)
    )

    try:
        minimum_zig = load_minimum_zig(repo_root)
    except (FileNotFoundError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    runtime_targets = collect_runtime_target_status(repo_root)
    helper_surface = collect_helper_surface_status(repo_root)
    saved_archives = collect_saved_archive_status(saved_archives_root)
    offline_deps = collect_offline_dep_status(offline_deps_root)
    zig_status = collect_zig_status(
        repo_root=repo_root,
        minimum_zig=minimum_zig,
        toolchains_root=toolchains_root,
        zig_cmd=args.zig,
        fallback_zig_archive=fallback_zig_archive,
    )
    summary = build_summary(
        repo_root=repo_root,
        minimum_zig=minimum_zig,
        runtime_targets=runtime_targets,
        helper_surface=helper_surface,
        saved_archives=saved_archives,
        offline_deps=offline_deps,
        zig_status=zig_status,
    )

    result = {
        "repo_root": str(repo_root),
        "minimum_zig": minimum_zig,
        "runtime_targets": runtime_targets,
        "helper_surface": helper_surface,
        "saved_archives": saved_archives,
        "offline_deps": offline_deps,
        "zig_status": zig_status,
        "summary": summary,
    }

    if args.json:
        print(json.dumps(result, indent=2))
        return 0 if summary["direct_runtime_reentry_ready"] else 1

    print("Issue #3 reentry gate status")
    print()
    print(f"Repo root: {repo_root}")
    print(f"Minimum Zig line: {minimum_zig}")
    print()
    print(
        "Publication gate: "
        + ("OPEN" if summary["publication_gate"]["open"] else "CLOSED")
    )
    for target in runtime_targets:
        state = "ok"
        if not target["exists"]:
            state = "missing"
        elif not target["writable"]:
            state = "not writable"
        print(f"  - {target['path']} [{state}]")
    if summary["publication_gate"]["blockers"]:
        print("  Blockers:")
        for blocker in summary["publication_gate"]["blockers"]:
            print(f"    - {blocker}")

    print()
    print(
        "Validation gate: "
        + ("OPEN" if summary["validation_gate"]["open"] else "CLOSED")
    )
    current = zig_status["current"]
    current_state = "ok" if current["ok"] else "missing"
    if current["ok"] and not current["matches_expected_line"]:
        current_state = "mismatched line"
    print(f"  - current zig ({current['command']}): {current['version']} [{current_state}]")
    if zig_status["candidates"]:
        print("  - staged Zig candidates:")
        for candidate in zig_status["candidates"]:
            state = "ok" if candidate["matches_expected_line"] else "not usable"
            print(f"    - {candidate['path']} [{candidate['version']}; {state}]")
    else:
        print("  - staged Zig candidates: none")
    if zig_status["fallback_archive"] is not None:
        fallback = zig_status["fallback_archive"]
        state = "ok" if fallback["matches_expected_line"] else "fallback only"
        print(
            "  - fallback Zig archive: "
            f"{fallback['path']} [{fallback['inferred_version'] or 'unknown'}; {state}]"
        )
    archive_entries = saved_archives["archives"]
    print(f"  - saved archives root: {saved_archives['root']}")
    for key in (*REQUIRED_SAVED_ARCHIVE_KEYS, *OPTIONAL_SAVED_ARCHIVE_KEYS):
        entry = archive_entries[key]
        state = "ok" if entry["exists"] else "missing"
        requirement = "required" if entry["required"] else "optional"
        location = entry["path"] or SAVED_ARCHIVE_GLOBS[key]
        print(f"    - {key}: {location} [{requirement}; {state}]")
    print(f"  - offline deps root: {offline_deps['root']}")
    for entry in offline_deps["dirs"]:
        state = "ok" if entry["exists"] and entry["nonempty"] else "missing"
        print(f"    - {entry['name']}: {entry['path']} [{state}]")
    prebuilt_count = len(offline_deps["prebuilt_v8"])
    print(f"    - prebuilt V8 archives: {prebuilt_count}")
    if summary["validation_gate"]["blockers"]:
        print("  Blockers:")
        for blocker in summary["validation_gate"]["blockers"]:
            print(f"    - {blocker}")

    print()
    print(
        "Helper surface: "
        + ("READY" if summary["helper_surface"]["ready"] else "INCOMPLETE")
    )
    if summary["helper_surface"]["missing_paths"]:
        for path in summary["helper_surface"]["missing_paths"]:
            print(f"  - missing {path}")

    print()
    overall = "READY" if summary["direct_runtime_reentry_ready"] else "BLOCKED"
    print(f"Direct runtime reentry: {overall}")
    if summary["next_commands"]:
        print("Next commands:")
        for command in summary["next_commands"]:
            print(f"  - {command}")

    return 0 if summary["direct_runtime_reentry_ready"] else 1


if __name__ == "__main__":
    sys.exit(main())
