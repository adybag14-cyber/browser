#!/usr/bin/env python3

"""Check whether the saved Rust 1.79.0 toolchain is restored and usable.

This helper narrows one recurring Linux/WSL issue #3 blocker: we often know the
saved Rust archive exists, but we still need a quick check that a restored Rust
1.79.0 toolchain is present under the shared toolchains root and that its cargo
and rustc binaries are the expected version line before reopening broader build
readiness work.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest


EXPECTED_RUST_VERSION_PREFIX = "1.79."
DEFAULT_RUST_ARCHIVE_GLOB = "01-rust-1.79.0-*.tar.xz"
DEFAULT_TOOLCHAIN_DIRNAME = "rust-1.79.0"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved Rust 1.79.0 archive is present and whether "
            "a restored toolchain under ../toolchains is ready for Linux/WSL "
            "issue #3 build-readiness follow-up work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--dependencies-root",
        default=None,
        help=(
            "Path to the saved dependency archive root "
            "(default: ../memory/repo_archives/browser/dependencies beside the repo workspace)"
        ),
    )
    parser.add_argument(
        "--toolchain-root",
        default=None,
        help=(
            "Path to the restored Rust toolchain root "
            "(default: ../toolchains/rust-1.79.0 beside the repo workspace)"
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def resolve_default_dependencies_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory" / "repo_archives" / "browser" / "dependencies").resolve()


def resolve_default_toolchain_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains" / DEFAULT_TOOLCHAIN_DIRNAME).resolve()


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def probe_version(command: Path, label: str) -> tuple[str | None, str | None]:
    if not command.is_file():
        return None, f"{label} does not exist: {command}"

    try:
        completed = subprocess.run(
            [str(command), "--version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return None, f"{label} version probe failed: {exc}"
    except subprocess.CalledProcessError as exc:
        return None, f"{label} version probe failed with exit code {exc.returncode}"

    version_output = completed.stdout.strip() or completed.stderr.strip()
    if not version_output:
        return None, f"{label} version probe returned no output"
    return version_output, None


def version_matches_expected(version_output: str) -> bool:
    return EXPECTED_RUST_VERSION_PREFIX in version_output


def collect_results(
    *,
    repo_root: Path,
    dependencies_root: Path,
    toolchain_root: Path,
) -> dict[str, object]:
    archive_matches = sorted(dependencies_root.glob(DEFAULT_RUST_ARCHIVE_GLOB)) if dependencies_root.is_dir() else []
    archive_path = archive_matches[0] if archive_matches else dependencies_root / DEFAULT_RUST_ARCHIVE_GLOB

    cargo_path = toolchain_root / "bin" / "cargo"
    rustc_path = toolchain_root / "bin" / "rustc"

    cargo_version, cargo_error = probe_version(cargo_path, "cargo")
    rustc_version, rustc_error = probe_version(rustc_path, "rustc")

    exports = {
        "PATH": f"{toolchain_root / 'bin'}:$PATH",
        "CARGO": str(cargo_path),
        "RUSTC": str(rustc_path),
    }

    readiness_command = shell_join(
        [
            "python",
            str(repo_root / "scripts" / "check_linux_build_readiness.py"),
            "--repo-root",
            str(repo_root),
            "--cargo",
            str(cargo_path),
            "--rustc",
            str(rustc_path),
        ]
    )

    failures: list[str] = []
    if not dependencies_root.is_dir():
        failures.append(f"saved dependency archive root is missing: {dependencies_root}")
    elif not archive_matches:
        failures.append(
            "saved Rust toolchain archive is missing under "
            f"{dependencies_root} (expected {DEFAULT_RUST_ARCHIVE_GLOB})"
        )

    if not toolchain_root.is_dir():
        failures.append(f"restored Rust toolchain root is missing: {toolchain_root}")
    if cargo_error is not None:
        failures.append(cargo_error)
    elif cargo_version is not None and not version_matches_expected(cargo_version):
        failures.append(
            f"cargo version does not match the expected Rust {EXPECTED_RUST_VERSION_PREFIX}x line: {cargo_version}"
        )

    if rustc_error is not None:
        failures.append(rustc_error)
    elif rustc_version is not None and not version_matches_expected(rustc_version):
        failures.append(
            f"rustc version does not match the expected Rust {EXPECTED_RUST_VERSION_PREFIX}x line: {rustc_version}"
        )

    return {
        "ok": not failures,
        "repo_root": str(repo_root),
        "dependencies_root": str(dependencies_root),
        "toolchain_root": str(toolchain_root),
        "expected_rust_version_prefix": EXPECTED_RUST_VERSION_PREFIX,
        "archive": {
            "path": str(archive_path),
            "exists": bool(archive_matches),
        },
        "cargo": {
            "path": str(cargo_path),
            "version": cargo_version,
            "error": cargo_error,
            "matches_expected": cargo_version is not None and version_matches_expected(cargo_version),
        },
        "rustc": {
            "path": str(rustc_path),
            "version": rustc_version,
            "error": rustc_error,
            "matches_expected": rustc_version is not None and version_matches_expected(rustc_version),
        },
        "exports": exports,
        "readiness_command": readiness_command,
        "failures": failures,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Saved dependencies root: {result['dependencies_root']}")
    print(f"Restored Rust toolchain root: {result['toolchain_root']}")
    print(f"Expected Rust line: {result['expected_rust_version_prefix']}x")

    archive = result["archive"]
    archive_status = "PASS" if archive["exists"] else "FAIL"
    print(f"Saved Rust archive: [{archive_status}] {archive['path']}")

    for label in ("cargo", "rustc"):
        entry = result[label]
        status = "PASS" if entry["matches_expected"] else "FAIL"
        print(f"{label}: [{status}] {entry['path']}")
        if entry["version"] is not None:
            print(f"         version: {entry['version']}")
        if entry["error"] is not None:
            print(f"         error:   {entry['error']}")

    print("Suggested environment:")
    print(f"  export PATH={shlex.quote(result['exports']['PATH'])}")
    print(f"  export CARGO={shlex.quote(result['exports']['CARGO'])}")
    print(f"  export RUSTC={shlex.quote(result['exports']['RUSTC'])}")
    print("Suggested readiness command:")
    print(f"  {result['readiness_command']}")

    if result["ok"]:
        print("\nSaved Rust toolchain readiness check passed.")
    else:
        print("\nSaved Rust toolchain readiness check failed.", file=sys.stderr)
        print(
            "Suggested next step: restore the saved Rust 1.79.0 archive into "
            "../toolchains/rust-1.79.0 and rerun this helper before reopening "
            "the broader Linux build-readiness path.",
            file=sys.stderr,
        )


class SavedRustToolchainReadinessTests(unittest.TestCase):
    def write_probe(self, path: Path, output: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"#!/usr/bin/env bash\necho {shlex.quote(output)}\n", encoding="utf-8")
        path.chmod(0o755)

    def test_collect_results_passes_with_saved_archive_and_matching_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            deps_root = root / "memory" / "repo_archives" / "browser" / "dependencies"
            toolchain_root = root / "toolchains" / DEFAULT_TOOLCHAIN_DIRNAME
            repo_root.mkdir(parents=True)
            deps_root.mkdir(parents=True)
            (deps_root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
            self.write_probe(toolchain_root / "bin" / "cargo", "cargo 1.79.0 (demo)")
            self.write_probe(toolchain_root / "bin" / "rustc", "rustc 1.79.1 (demo)")

            result = collect_results(
                repo_root=repo_root,
                dependencies_root=deps_root,
                toolchain_root=toolchain_root,
            )

            self.assertTrue(result["ok"])
            self.assertTrue(result["archive"]["exists"])
            self.assertTrue(result["cargo"]["matches_expected"])
            self.assertTrue(result["rustc"]["matches_expected"])

    def test_collect_results_fails_when_archive_and_toolchain_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            deps_root = root / "memory" / "repo_archives" / "browser" / "dependencies"
            toolchain_root = root / "toolchains" / DEFAULT_TOOLCHAIN_DIRNAME
            repo_root.mkdir(parents=True)

            result = collect_results(
                repo_root=repo_root,
                dependencies_root=deps_root,
                toolchain_root=toolchain_root,
            )

            self.assertFalse(result["ok"])
            self.assertIn("saved dependency archive root is missing", result["failures"][0])
            self.assertIn("restored Rust toolchain root is missing", "\n".join(result["failures"]))

    def test_collect_results_fails_when_versions_do_not_match_expected_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            deps_root = root / "memory" / "repo_archives" / "browser" / "dependencies"
            toolchain_root = root / "toolchains" / DEFAULT_TOOLCHAIN_DIRNAME
            repo_root.mkdir(parents=True)
            deps_root.mkdir(parents=True)
            (deps_root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
            self.write_probe(toolchain_root / "bin" / "cargo", "cargo 1.81.0 (demo)")
            self.write_probe(toolchain_root / "bin" / "rustc", "rustc 1.81.0 (demo)")

            result = collect_results(
                repo_root=repo_root,
                dependencies_root=deps_root,
                toolchain_root=toolchain_root,
            )

            self.assertFalse(result["ok"])
            self.assertIn("cargo version does not match", "\n".join(result["failures"]))
            self.assertIn("rustc version does not match", "\n".join(result["failures"]))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedRustToolchainReadinessTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    dependencies_root = (
        Path(args.dependencies_root).resolve()
        if args.dependencies_root
        else resolve_default_dependencies_root(repo_root)
    )
    toolchain_root = (
        Path(args.toolchain_root).resolve()
        if args.toolchain_root
        else resolve_default_toolchain_root(repo_root)
    )

    result = collect_results(
        repo_root=repo_root,
        dependencies_root=dependencies_root,
        toolchain_root=toolchain_root,
    )
    if args.json:
        print(json.dumps({"profile": "issue3-saved-rust-toolchain-readiness", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
