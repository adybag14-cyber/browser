#!/usr/bin/env python3
"""Print the Linux/WSL build re-entry route for the direct issue #3 runtime fix."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shlex
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SAVED_ARCHIVE_GLOBS: dict[str, str] = {
    "rust_toolchain": "01-rust-*.tar.xz",
    "html5ever": "02-litefetch-html5ever-*.zip",
    "boringssl": "03-boringssl-zig-main.zip",
    "browser_deps": "04-zig-browser-depo.tar.zip",
}


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def find_first(root: pathlib.Path, pattern: str) -> pathlib.Path | None:
    matches = sorted(root.glob(pattern))
    return matches[0] if matches else None


def discover_saved_archives(root: pathlib.Path) -> dict[str, pathlib.Path]:
    search_roots = [root, root / "dependencies"]
    discovered: dict[str, pathlib.Path] = {}
    for key, pattern in SAVED_ARCHIVE_GLOBS.items():
        for candidate_root in search_roots:
            path = find_first(candidate_root, pattern)
            if path is not None:
                discovered[key] = path
                break
    return discovered


def load_minimum_zig(repo_root: pathlib.Path) -> str | None:
    zon_path = repo_root / "build.zig.zon"
    if not zon_path.is_file():
        return None
    match = MINIMUM_ZIG_RE.search(zon_path.read_text(encoding="utf-8"))
    return match.group(1) if match else None


def build_route(repo_root: pathlib.Path, saved_archives_root: pathlib.Path, offline_deps_root: pathlib.Path) -> dict[str, object]:
    discovered_archives = discover_saved_archives(saved_archives_root)
    minimum_zig = load_minimum_zig(repo_root)

    readiness_helper = repo_root / "scripts" / "check_linux_build_readiness.py"
    prepare_helper = repo_root / "scripts" / "linux" / "prepare_offline_build_inputs.sh"
    runtime_checker = (
        repo_root
        / "tmp-browser-smoke"
        / "google-investigation-next"
        / "check_issue3_enter_submit_runtime_contract.py"
    )

    browser_deps_archive = discovered_archives.get("browser_deps")
    boringssl_archive = discovered_archives.get("boringssl")
    html5ever_archive = discovered_archives.get("html5ever")
    prebuilt_v8_path = offline_deps_root / "libc_v8_14.0.365.4_linux_x86_64.a"

    commands: dict[str, str] = {}
    commands["saved_archive_preflight"] = shell_join(
        [
            "python",
            str(readiness_helper),
            "--repo-root",
            str(repo_root),
            "--skip-zig-check",
            "--expect-saved-archives",
            "--saved-archives-root",
            str(saved_archives_root),
        ]
    )
    commands["runtime_contract_self_test"] = shell_join(
        ["python", str(runtime_checker), "--self-test"]
    )
    commands["runtime_contract_check"] = shell_join(
        [
            "python",
            str(runtime_checker),
            "--page",
            str(repo_root / "src" / "browser" / "Page.zig"),
            "--win32",
            str(repo_root / "src" / "display" / "win32_backend.zig"),
        ]
    )

    if browser_deps_archive is not None and boringssl_archive is not None:
        prepare_parts = [
            "bash",
            str(prepare_helper),
            "--browser-root",
            str(repo_root),
            "--browser-deps-archive",
            str(browser_deps_archive),
            "--boringssl-archive",
            str(boringssl_archive),
        ]
        if html5ever_archive is not None:
            prepare_parts.extend(["--html5ever-archive", str(html5ever_archive)])
        commands["offline_restore_preflight"] = shell_join([*prepare_parts, "--check-only"])
        commands["offline_restore"] = shell_join(prepare_parts)

    commands["post_restore_readiness"] = shell_join(
        [
            "python",
            str(readiness_helper),
            "--repo-root",
            str(repo_root),
            "--expect-saved-archives",
            "--saved-archives-root",
            str(saved_archives_root),
            "--expect-offline-deps",
            "--offline-deps-root",
            str(offline_deps_root),
            "--require-prebuilt-v8",
        ]
    )
    commands["suggested_build"] = shell_join(
        [
            "zig",
            "build",
            "--summary",
            "all",
            f"-Dprebuilt_v8_path={prebuilt_v8_path}",
        ]
    )

    required_surfaces = {
        "gate_note": repo_root / "docs" / "ISSUE3_RUNTIME_REENTRY_GATES.md",
        "runtime_note": repo_root / "docs" / "ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "readiness_helper": readiness_helper,
        "prepare_helper": prepare_helper,
        "runtime_checker": runtime_checker,
    }

    archive_status = {
        key: {
            "path": str(saved_archives_root / SAVED_ARCHIVE_GLOBS[key]) if key not in discovered_archives else str(discovered_archives[key]),
            "exists": key in discovered_archives,
        }
        for key in SAVED_ARCHIVE_GLOBS
    }

    return {
        "issue": "Issue #3 Linux/WSL build re-entry",
        "purpose": (
            "Keep the saved-archive checks, offline restore command, runtime contract "
            "checker, and post-restore build gate on one branch-local surface before "
            "reopening the direct Page.zig and win32_backend.zig patch."
        ),
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "offline_deps_root": str(offline_deps_root),
        "minimum_zig": minimum_zig,
        "read_first": [
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/prepare_offline_build_inputs.sh",
        ],
        "required_surfaces": {
            key: {"path": str(path), "exists": path.exists()}
            for key, path in required_surfaces.items()
        },
        "saved_archives": archive_status,
        "commands": commands,
        "notes": [
            "Run the saved-archive preflight before trusting any Linux or WSL Zig failure as a source regression.",
            "Use the offline restore preflight before mutating the checkout when you only want to prove the bundle layout.",
            (
                f"Treat a Zig line other than {minimum_zig} as suspect for this branch"
                if minimum_zig
                else "Read build.zig.zon first and use the branch minimum Zig line before trusting focused validation."
            ),
            "Run the runtime contract checker before and after restore work so the direct runtime bridge stays narrowed to Page.zig plus win32_backend.zig.",
            "Only reopen the direct runtime patch after the post-restore readiness step and a normal zig build agree that the environment is usable.",
        ],
    }


def format_text(route: dict[str, object]) -> str:
    lines = [
        "Issue #3 Linux/WSL build re-entry",
        "",
        f"Repo root:           {route['repo_root']}",
        f"Saved archives root: {route['saved_archives_root']}",
        f"Offline deps root:   {route['offline_deps_root']}",
        f"Minimum Zig:         {route['minimum_zig'] or 'unknown'}",
        "",
        "Read first",
        "==========",
    ]
    for path in route["read_first"]:
        lines.append(f"  {path}")

    lines.extend(["", "Required surfaces", "================="])
    for key, item in route["required_surfaces"].items():
        status = "PASS" if item["exists"] else "FAIL"
        lines.append(f"  [{status}] {key}: {item['path']}")

    lines.extend(["", "Saved archives", "=============="])
    for key, item in route["saved_archives"].items():
        status = "PASS" if item["exists"] else "MISS"
        lines.append(f"  [{status}] {key}: {item['path']}")

    lines.extend(["", "Commands", "========"])
    for key, command in route["commands"].items():
        lines.append(f"  {key}: {command}")

    lines.extend(["", "Notes", "====="])
    for note in route["notes"]:
        lines.append(f"  - {note}")
    return "\n".join(lines)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Print the Linux/WSL re-entry route for the direct issue #3 runtime patch."
    )
    parser.add_argument("--repo-root", default=None, help="Path to the browser checkout root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to the saved browser archive root (default: ../memory/repo_archives/browser beside the repo)",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Path to the offline dependency root (default: ../offline-deps beside the repo)",
    )
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit nonzero if required surfaces or required saved archives are missing",
    )
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class RouteHelperTests(unittest.TestCase):
    def test_discovers_saved_archives(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            deps = root / "dependencies"
            deps.mkdir()
            (deps / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
            (deps / "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip").write_text("html5ever", encoding="utf-8")
            (deps / "03-boringssl-zig-main.zip").write_text("boringssl", encoding="utf-8")
            (deps / "04-zig-browser-depo.tar.zip").write_text("browser-deps", encoding="utf-8")
            discovered = discover_saved_archives(root)
            self.assertEqual(set(discovered), {"rust_toolchain", "html5ever", "boringssl", "browser_deps"})

    def test_loads_minimum_zig(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            (root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"\n', encoding="utf-8")
            self.assertEqual(load_minimum_zig(root), "0.15.2")


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RouteHelperTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    script_path = pathlib.Path(__file__).resolve()
    repo_root = pathlib.Path(args.repo_root).resolve() if args.repo_root else script_path.parents[2]
    saved_archives_root = (
        pathlib.Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()
    )
    offline_deps_root = (
        pathlib.Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else (repo_root.parent / "offline-deps").resolve()
    )

    route = build_route(repo_root, saved_archives_root, offline_deps_root)
    if args.json:
        json.dump(route, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        print(format_text(route))

    if args.check:
        missing_surfaces = [
            key for key, item in route["required_surfaces"].items() if not item["exists"]
        ]
        missing_archives = [
            key
            for key in ("rust_toolchain", "boringssl", "browser_deps")
            if not route["saved_archives"][key]["exists"]
        ]
        if missing_surfaces or missing_archives:
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
