#!/usr/bin/env python3

"""Surface the next Rust toolchain re-entry step for issue #11 follow-up work."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shlex
import subprocess
import tempfile
import unittest


EXPECTED_RUST = "1.79.0"
ARCHIVE_RE = re.compile(r"01-rust-(\d+\.\d+\.\d+)-([^.]+(?:\.[^.]+)*)\.tar\.xz$")
VERSION_RE = re.compile(r"\b(\d+\.\d+\.\d+)\b")
PATH_GLOB = ("rust-*/cargo/bin/cargo", "*/cargo/bin/cargo")


def parse_version(text: str) -> tuple[int, int, int]:
    match = VERSION_RE.search(text)
    if match is None:
        raise ValueError(f"could not parse version from {text!r}")
    return tuple(int(part) for part in match.group(1).split("."))


def version_text(text: str) -> str | None:
    match = VERSION_RE.search(text)
    return match.group(1) if match else None


def same_line(expected: str, actual: str) -> bool:
    return parse_version(expected)[:2] == parse_version(actual)[:2]


def ancestor_chain(start: Path) -> list[Path]:
    chain: list[Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: Path, relative_path: str) -> Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def resolve_toolchains_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def resolve_saved_archives_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


def build_saved_archive_roots(saved_archives_root: Path) -> list[Path]:
    browser_root = saved_archives_root.resolve()
    if browser_root.name == "dependencies" and browser_root.parent.is_dir():
        browser_root = browser_root.parent.resolve()
    roots = [browser_root]
    dependencies_root = browser_root / "dependencies"
    if dependencies_root.is_dir():
        roots.append(dependencies_root.resolve())
    return roots


def discover_saved_archives(saved_archives_roots: list[Path]) -> list[Path]:
    discovered: list[Path] = []
    seen: set[Path] = set()
    for root in saved_archives_roots:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("01-rust-*.tar.xz")):
            resolved = path.resolve()
            if not path.is_file() or resolved in seen:
                continue
            seen.add(resolved)
            discovered.append(resolved)
    return discovered


def classify_saved_archive(expected: str, path: Path) -> dict[str, str]:
    match = ARCHIVE_RE.match(path.name)
    version = match.group(1) if match else ""
    triple = match.group(2) if match else ""
    if not version:
        status = "unknown-version"
    elif same_line(expected, version):
        status = "matches-expected-line"
    elif parse_version(version) < parse_version(expected):
        status = "older-than-expected"
    else:
        status = "mismatched-line"
    return {
        "path": str(path),
        "version": version,
        "target_triple": triple,
        "status": status,
    }


def choose_saved_archive(expected: str, archives: list[dict[str, str]]) -> dict[str, str] | None:
    exact = next(
        (
            archive
            for archive in archives
            if archive["status"] == "matches-expected-line" and archive["version"] == expected
        ),
        None,
    )
    if exact is not None:
        return exact
    matching = [
        archive
        for archive in archives
        if archive["status"] == "matches-expected-line" and archive["version"]
    ]
    if not matching:
        return None
    return max(matching, key=lambda archive: parse_version(archive["version"]))


def discover_staged_toolchains(toolchains_root: Path) -> list[Path]:
    if not toolchains_root.is_dir():
        return []
    candidates: list[Path] = []
    seen: set[Path] = set()
    for pattern in PATH_GLOB:
        for cargo_bin in sorted(toolchains_root.glob(pattern)):
            resolved = cargo_bin.resolve()
            if not cargo_bin.is_file() or resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def run_version(binary: Path) -> tuple[list[str], str | None]:
    try:
        completed = subprocess.run(
            [str(binary), "--version"],
            capture_output=True,
            check=True,
            text=True,
        )
    except FileNotFoundError:
        return [f"missing binary: {binary}"], None
    except subprocess.CalledProcessError as exc:
        return [f"version probe failed with exit code {exc.returncode}: {binary}"], None
    output = completed.stdout.strip() or completed.stderr.strip()
    return [], output or None


def classify_staged_toolchain(expected: str, cargo_bin: Path) -> dict[str, object]:
    cargo_failures, cargo_output = run_version(cargo_bin)
    rustc_bin = cargo_bin.parent.parent.parent / "rustc" / "bin" / "rustc"
    rustc_failures, rustc_output = run_version(rustc_bin) if rustc_bin.is_file() else ([f"missing rustc beside cargo: {rustc_bin}"], None)
    cargo_version = version_text(cargo_output or "")
    rustc_version = version_text(rustc_output or "")
    status = "unknown"
    if cargo_version == expected and rustc_version == expected:
        status = "matches-expected"
    elif cargo_version == expected and rustc_version is None:
        status = "cargo-matches-rustc-missing"
    elif cargo_version and same_line(expected, cargo_version):
        status = "matching-line"
    elif cargo_version:
        status = "mismatched-line"
    toolchain_root = cargo_bin.parent.parent.parent
    return {
        "toolchain_root": str(toolchain_root),
        "cargo_bin": str(cargo_bin),
        "rustc_bin": str(rustc_bin),
        "cargo_version": cargo_version,
        "rustc_version": rustc_version,
        "status": status,
        "failures": cargo_failures + rustc_failures,
        "path_export": f'export PATH="{toolchain_root / "cargo" / "bin"}:{toolchain_root / "rustc" / "bin"}:$PATH"',
        "cargo_export": f'export CARGO="{cargo_bin}"',
        "rustc_export": f'export RUSTC="{rustc_bin}"',
    }


def choose_staged_toolchain(candidates: list[dict[str, object]]) -> dict[str, object] | None:
    exact = next((candidate for candidate in candidates if candidate["status"] == "matches-expected"), None)
    if exact is not None:
        return exact
    return next((candidate for candidate in candidates if candidate["status"] == "matching-line"), None)


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def build_restore_command(repo_root: Path, saved_archives_root: Path, archive: Path, toolchains_root: Path, *, check_only: bool) -> list[str]:
    version = classify_saved_archive(EXPECTED_RUST, archive)["version"] or "unknown"
    command = [
        "bash",
        str(repo_root / "scripts" / "linux" / "restore_saved_rust_toolchain.sh"),
        "--browser-root",
        str(repo_root),
        "--dependencies-root",
        str(saved_archives_root),
        "--toolchain-root",
        str(toolchains_root / f"rust-{version}"),
        "--archive",
        str(archive),
    ]
    if check_only:
        command.append("--check-only")
    return command


def build_readiness_command(repo_root: Path, staged_candidate: dict[str, object] | None) -> str:
    command = [
        "python3",
        str(repo_root / "scripts" / "check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--expect-saved-archives",
    ]
    if staged_candidate is not None:
        command.extend(
            [
                "--cargo",
                str(staged_candidate["cargo_bin"]),
                "--rustc",
                str(staged_candidate["rustc_bin"]),
            ]
        )
    return format_command(command)


def collect_results(repo_root: Path, saved_archives_root: Path, toolchains_root: Path) -> dict[str, object]:
    saved_archive_roots = build_saved_archive_roots(saved_archives_root)
    saved_archive_reports = [
        classify_saved_archive(EXPECTED_RUST, archive)
        for archive in discover_saved_archives(saved_archive_roots)
    ]
    preferred_saved_archive = choose_saved_archive(EXPECTED_RUST, saved_archive_reports)

    staged_reports = [
        classify_staged_toolchain(EXPECTED_RUST, cargo_bin)
        for cargo_bin in discover_staged_toolchains(toolchains_root)
    ]
    preferred_staged = choose_staged_toolchain(staged_reports)

    next_action = "blocked"
    if preferred_staged is not None and preferred_staged["status"] == "matches-expected":
        next_action = "reuse-staged-toolchain"
    elif preferred_saved_archive is not None:
        next_action = "restore-from-saved-archive"
    elif preferred_staged is not None:
        next_action = "review-staged-mismatch"

    commands: dict[str, str] = {
        "saved_archive_candidates": format_command(
            [
                "python3",
                str(repo_root / "scripts" / "check_issue3_saved_rust_archive_candidates.py"),
                "--repo-root",
                str(repo_root),
            ]
        ),
        "staged_toolchain_candidates": format_command(
            [
                "python3",
                str(repo_root / "scripts" / "check_issue3_staged_rust_toolchain_candidates.py"),
                "--repo-root",
                str(repo_root),
            ]
        ),
        "build_readiness": build_readiness_command(repo_root, preferred_staged),
    }
    if preferred_saved_archive is not None:
        archive_path = Path(preferred_saved_archive["path"])
        commands["restore_check"] = format_command(
            build_restore_command(
                repo_root,
                saved_archives_root,
                archive_path,
                toolchains_root,
                check_only=True,
            )
        )
        commands["restore"] = format_command(
            build_restore_command(
                repo_root,
                saved_archives_root,
                archive_path,
                toolchains_root,
                check_only=False,
            )
        )

    failures: list[str] = []
    if preferred_staged is None and preferred_saved_archive is None:
        failures.append(
            "no reusable staged Rust toolchain and no saved Rust archive on the expected 1.79.x line were discovered"
        )

    suggested_next_step = None
    if next_action == "reuse-staged-toolchain" and preferred_staged is not None:
        suggested_next_step = (
            "reuse the staged Rust exports and rerun the Linux build-readiness helper before reopening the direct runtime patch"
        )
    elif next_action == "restore-from-saved-archive":
        suggested_next_step = (
            "run the saved Rust restore check, restore the preferred archive, and then rerun the Linux build-readiness helper"
        )
    elif next_action == "review-staged-mismatch":
        suggested_next_step = (
            "the toolchains folder has a same-line Rust candidate but it is not a full 1.79.0 match; inspect its surfaced versions before trusting it"
        )

    return {
        "status": "passed" if next_action == "reuse-staged-toolchain" else "needs-action" if preferred_saved_archive is not None or preferred_staged is not None else "failed",
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "saved_archive_roots": [str(root) for root in saved_archive_roots],
        "toolchains_root": str(toolchains_root),
        "expected_rust": EXPECTED_RUST,
        "next_action": next_action,
        "saved_archives": saved_archive_reports,
        "preferred_saved_archive": preferred_saved_archive,
        "staged_toolchains": staged_reports,
        "preferred_staged_toolchain": preferred_staged,
        "commands": commands,
        "suggested_next_step": suggested_next_step,
        "failures": failures,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Decide whether issue #11 Linux/WSL follow-up should reuse or restore Rust tooling."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument("--saved-archives-root", default=None, help="Path to repo_archives/browser or its dependencies directory")
    parser.add_argument("--toolchains-root", default=None, help="Path to the shared toolchains directory")
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class RustToolchainReentryTests(unittest.TestCase):
    def make_archive(self, root: Path, name: str) -> Path:
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("archive", encoding="utf-8")
        return path

    def make_toolchain(self, root: Path, name: str, cargo_version: str, rustc_version: str | None) -> Path:
        cargo_bin = root / name / "cargo" / "bin" / "cargo"
        cargo_bin.parent.mkdir(parents=True, exist_ok=True)
        cargo_bin.write_text(f"#!/usr/bin/env bash\necho cargo {cargo_version}\n", encoding="utf-8")
        cargo_bin.chmod(0o755)
        if rustc_version is not None:
            rustc_bin = root / name / "rustc" / "bin" / "rustc"
            rustc_bin.parent.mkdir(parents=True, exist_ok=True)
            rustc_bin.write_text(f"#!/usr/bin/env bash\necho rustc {rustc_version}\n", encoding="utf-8")
            rustc_bin.chmod(0o755)
        return cargo_bin

    def test_saved_archive_roots_accept_browser_root_and_dependencies(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            browser_root = Path(tmpdir) / "repo_archives" / "browser"
            dependencies_root = browser_root / "dependencies"
            dependencies_root.mkdir(parents=True)
            roots = build_saved_archive_roots(dependencies_root)
            self.assertEqual(roots, [browser_root.resolve(), dependencies_root.resolve()])

    def test_choose_saved_archive_prefers_exact_version(self) -> None:
        reports = [
            {"path": "/tmp/01-rust-1.79.1-x86_64-unknown-linux-gnu.tar.xz", "version": "1.79.1", "target_triple": "x86_64-unknown-linux-gnu", "status": "matches-expected-line"},
            {"path": "/tmp/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "version": "1.79.0", "target_triple": "x86_64-unknown-linux-gnu", "status": "matches-expected-line"},
        ]
        preferred = choose_saved_archive(EXPECTED_RUST, reports)
        assert preferred is not None
        self.assertEqual(preferred["version"], EXPECTED_RUST)

    def test_collect_results_prefers_reusing_matching_staged_toolchain(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            toolchains_root = root / "toolchains"
            saved_root = root / "memory" / "repo_archives" / "browser" / "dependencies"
            saved_root.mkdir(parents=True)
            self.make_archive(saved_root, "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz")
            self.make_toolchain(toolchains_root, "rust-1.79.0", "1.79.0", "1.79.0")

            result = collect_results(repo_root, saved_root, toolchains_root)

            self.assertEqual(result["next_action"], "reuse-staged-toolchain")
            self.assertEqual(result["status"], "passed")
            self.assertEqual(result["preferred_staged_toolchain"]["status"], "matches-expected")

    def test_collect_results_falls_back_to_saved_archive_restore(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            toolchains_root = root / "toolchains"
            saved_root = root / "memory" / "repo_archives" / "browser" / "dependencies"
            saved_root.mkdir(parents=True)
            self.make_archive(saved_root, "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz")

            result = collect_results(repo_root, saved_root, toolchains_root)

            self.assertEqual(result["next_action"], "restore-from-saved-archive")
            self.assertIn("restore", result["commands"])

    def test_collect_results_reports_failure_without_saved_or_staged_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            result = collect_results(
                repo_root,
                root / "memory" / "repo_archives" / "browser",
                root / "toolchains",
            )
            self.assertEqual(result["status"], "failed")
            self.assertTrue(result["failures"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RustToolchainReentryTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    saved_archives_root = (
        Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_saved_archives_root(repo_root)
    )
    toolchains_root = (
        Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_toolchains_root(repo_root)
    )
    results = collect_results(repo_root, saved_archives_root, toolchains_root)

    if args.json:
        print(json.dumps(results, indent=2))
        return 0 if results["status"] != "failed" else 1

    print("Issue #11 Rust toolchain re-entry")
    print()
    print(f"Repo root:            {results['repo_root']}")
    print(f"Saved archives root:  {results['saved_archives_root']}")
    print(f"Saved archive search: {', '.join(results['saved_archive_roots'])}")
    print(f"Toolchains root:      {results['toolchains_root']}")
    print(f"Expected Rust:        {results['expected_rust']}")
    print(f"Next action:          {results['next_action']}")
    print()
    if results["staged_toolchains"]:
        print("Staged toolchains:")
        for candidate in results["staged_toolchains"]:
            print(
                "  - "
                f"{candidate['toolchain_root']} "
                f"[cargo={candidate['cargo_version'] or 'unknown'}, "
                f"rustc={candidate['rustc_version'] or 'unknown'}; "
                f"{candidate['status']}]"
            )
    else:
        print("Staged toolchains: none")
    print()
    if results["saved_archives"]:
        print("Saved Rust archives:")
        for archive in results["saved_archives"]:
            version = archive["version"] or "unknown"
            triple = archive["target_triple"] or "unknown"
            print(f"  - {archive['path']} [{triple}; {version}; {archive['status']}]")
    else:
        print("Saved Rust archives: none")
    print()
    for label, command in results["commands"].items():
        print(f"{label}:")
        print(f"  {command}")
    if results["preferred_staged_toolchain"] is not None:
        preferred = results["preferred_staged_toolchain"]
        print()
        print("Preferred staged exports:")
        print(f"  {preferred['path_export']}")
        print(f"  {preferred['cargo_export']}")
        print(f"  {preferred['rustc_export']}")
    if results["suggested_next_step"] is not None:
        print()
        print(f"Suggested next step: {results['suggested_next_step']}")
    if results["failures"]:
        print()
        print("Failures:")
        for failure in results["failures"]:
            print(f"  - {failure}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
