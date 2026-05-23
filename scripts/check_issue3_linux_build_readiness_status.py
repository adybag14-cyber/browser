#!/usr/bin/env python3

"""Summarize the current Linux/WSL build-readiness state for issue #3.

This helper gives headed-mode recovery work one factual status snapshot of the
saved Memory inputs, default Zig, staged Zig candidates, saved Rust toolchain,
and offline dependency staging. It is intentionally read-only and points the
next run at the most relevant branch-local recovery helper based on what is
actually present.
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
PREBUILT_V8_GLOB = "libc_v8_*.a"
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)

REQUIRED_MEMORY_FILES: tuple[tuple[str, str], ...] = (
    ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("repo_archives/browser/README.md", "saved repo notes"),
    ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    (
        "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
        "saved Rust toolchain archive",
    ),
    (
        "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
        "saved html5ever dependency archive",
    ),
    (
        "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
        "saved BoringSSL archive",
    ),
    (
        "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
        "saved browser dependency archive",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize the current Linux/WSL build-readiness state for the "
            "blocked issue #3 Enter-submit runtime lane."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: ../memory beside the repo)",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the staged Zig toolchains root (default: ../toolchains beside the repo)",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Path to the offline dependency root (default: ../offline-deps beside the repo)",
    )
    parser.add_argument(
        "--rust-toolchain-dir",
        default=None,
        help="Path to the restored Rust 1.79.0 toolchain root (default: ../toolchains/rust-1.79.0)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the fallback Zig archive",
    )
    parser.add_argument("--json", action="store_true", help="Emit structured JSON")
    parser.add_argument("--self-test", action="store_true", help="Run focused helper tests")
    return parser


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_rust_toolchain_dir(repo_root: Path) -> Path:
    return resolve_default_toolchains_root(repo_root) / "rust-1.79.0"


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(text)
    if match is None:
        raise ValueError(text)
    return tuple(int(part) for part in match.groups())


def classify_zig_version(minimum_zig: str, actual_version: str) -> str:
    minimum = parse_semver(minimum_zig)
    actual = parse_semver(actual_version)
    if actual < minimum:
        return "older-than-minimum"
    if actual[:2] == minimum[:2]:
        return "matches-expected-line"
    return "mismatched-line"


def load_minimum_zig(repo_root: Path) -> str:
    text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError("Could not find minimum_zig_version in build.zig.zon")
    return match.group(1)


def probe_version(command: list[str]) -> tuple[bool, str]:
    try:
        completed = subprocess.run(command, check=True, capture_output=True, text=True)
    except FileNotFoundError:
        return False, "not found"
    except subprocess.CalledProcessError as exc:
        return False, f"probe failed with exit code {exc.returncode}"
    output = completed.stdout.strip() or completed.stderr.strip()
    return True, output or "no version output"


def collect_memory_status(memory_root: Path) -> dict[str, object]:
    entries = []
    missing = []
    for relative_path, label in REQUIRED_MEMORY_FILES:
        path = memory_root / relative_path
        exists = path.is_file()
        entry = {"label": label, "path": str(path), "exists": exists}
        entries.append(entry)
        if not exists:
            missing.append(label)
    return {"ok": not missing, "entries": entries, "missing_labels": missing}


def resolve_fallback_zig(repo_root: Path, fallback_zig_archive: Path | None) -> Path:
    if fallback_zig_archive is not None:
        return fallback_zig_archive
    return (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG).resolve()


def collect_default_zig_status(minimum_zig: str) -> dict[str, object]:
    zig_path = shutil.which("zig")
    if zig_path is None:
        return {"found": False, "path": "", "version": "", "status": "not-found"}
    ok, version = probe_version([zig_path, "version"])
    if not ok:
        return {"found": True, "path": zig_path, "version": version, "status": "probe-failed"}
    return {
        "found": True,
        "path": zig_path,
        "version": version,
        "status": classify_zig_version(minimum_zig, version),
    }


def collect_zig_candidates(minimum_zig: str, toolchains_root: Path) -> list[dict[str, str]]:
    if not toolchains_root.is_dir():
        return []

    candidates: list[dict[str, str]] = []
    seen: set[Path] = set()
    for pattern in DEFAULT_ZIG_TOOLCHAIN_GLOBS:
        for path in sorted(toolchains_root.glob(pattern)):
            resolved = path.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            ok, version = probe_version([str(resolved), "version"])
            status = "probe-failed"
            if ok:
                status = classify_zig_version(minimum_zig, version)
            candidates.append({"path": str(resolved), "version": version, "status": status})
    return candidates


def collect_rust_status(rust_toolchain_dir: Path) -> dict[str, object]:
    cargo_path = rust_toolchain_dir / "cargo" / "bin" / "cargo"
    rustc_path = rust_toolchain_dir / "rustc" / "bin" / "rustc"
    cargo_ok, cargo_version = probe_version([str(cargo_path), "--version"])
    rustc_ok, rustc_version = probe_version([str(rustc_path), "--version"])
    return {
        "toolchain_dir": str(rust_toolchain_dir),
        "cargo_path": str(cargo_path),
        "cargo_ready": cargo_ok,
        "cargo_version": cargo_version,
        "rustc_path": str(rustc_path),
        "rustc_ready": rustc_ok,
        "rustc_version": rustc_version,
        "ready": cargo_ok and rustc_ok,
    }


def collect_offline_deps_status(offline_deps_root: Path) -> dict[str, object]:
    entries = []
    for dep_name in OFFLINE_DEP_NAMES:
        dep_path = offline_deps_root / dep_name
        entries.append(
            {
                "name": dep_name,
                "path": str(dep_path),
                "exists": dep_path.is_dir(),
                "non_empty": dep_path.is_dir() and any(dep_path.iterdir()),
            }
        )
    prebuilt_v8 = sorted(offline_deps_root.glob(PREBUILT_V8_GLOB)) if offline_deps_root.is_dir() else []
    ready = offline_deps_root.is_dir() and all(entry["exists"] and entry["non_empty"] for entry in entries) and bool(prebuilt_v8)
    return {
        "root": str(offline_deps_root),
        "entries": entries,
        "prebuilt_v8": [str(path) for path in prebuilt_v8],
        "ready": ready,
    }


def build_next_step(
    *,
    repo_root: Path,
    memory_status: dict[str, object],
    default_zig: dict[str, object],
    zig_candidates: list[dict[str, str]],
    rust_status: dict[str, object],
    offline_status: dict[str, object],
    fallback_zig_path: Path,
) -> dict[str, str]:
    if not memory_status["ok"]:
        return {
            "reason": "saved-memory-inputs-missing",
            "command": f"python scripts/check_issue3_saved_memory_inputs.py --repo-root {repo_root}",
        }

    matching_candidate = next(
        (candidate for candidate in zig_candidates if candidate["status"] == "matches-expected-line"),
        None,
    )
    if default_zig["status"] != "matches-expected-line" and matching_candidate is None:
        command = f"bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root {repo_root}"
        if fallback_zig_path.is_file():
            command += f" --fallback-zig-archive {fallback_zig_path}"
        return {"reason": "no-branch-compatible-zig", "command": command}

    if not rust_status["ready"]:
        return {
            "reason": "saved-rust-toolchain-not-restored",
            "command": f"bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh --browser-root {repo_root}",
        }

    if not offline_status["ready"]:
        return {
            "reason": "offline-deps-not-staged",
            "command": (
                "bash scripts/linux/show_issue3_linux_build_readiness_route.sh "
                f"--repo-root {repo_root}"
            ),
        }

    selected_zig = default_zig["path"] if default_zig["status"] == "matches-expected-line" else matching_candidate["path"]
    return {
        "reason": "ready-for-full-readiness-check",
        "command": (
            "python scripts/check_linux_build_readiness.py "
            f"--repo-root {repo_root} --zig {selected_zig} "
            "--expect-saved-archives --expect-offline-deps --require-prebuilt-v8"
        ),
    }


def collect_status(
    *,
    repo_root: Path,
    memory_root: Path,
    toolchains_root: Path,
    offline_deps_root: Path,
    rust_toolchain_dir: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    minimum_zig = load_minimum_zig(repo_root)
    memory_status = collect_memory_status(memory_root)
    fallback_zig_path = resolve_fallback_zig(repo_root, fallback_zig_archive)
    default_zig = collect_default_zig_status(minimum_zig)
    zig_candidates = collect_zig_candidates(minimum_zig, toolchains_root)
    rust_status = collect_rust_status(rust_toolchain_dir)
    offline_status = collect_offline_deps_status(offline_deps_root)
    next_step = build_next_step(
        repo_root=repo_root,
        memory_status=memory_status,
        default_zig=default_zig,
        zig_candidates=zig_candidates,
        rust_status=rust_status,
        offline_status=offline_status,
        fallback_zig_path=fallback_zig_path,
    )
    return {
        "profile": "issue3-linux-build-readiness-status",
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "toolchains_root": str(toolchains_root),
        "offline_deps_root": str(offline_deps_root),
        "rust_toolchain_dir": str(rust_toolchain_dir),
        "minimum_zig": minimum_zig,
        "memory_status": memory_status,
        "fallback_zig_archive": {
            "path": str(fallback_zig_path),
            "exists": fallback_zig_path.is_file(),
        },
        "default_zig": default_zig,
        "zig_candidates": zig_candidates,
        "rust_status": rust_status,
        "offline_status": offline_status,
        "next_step": next_step,
        "ready_for_full_readiness": next_step["reason"] == "ready-for-full-readiness-check",
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 Linux build-readiness status")
    print()
    print(f"Repo root:           {result['repo_root']}")
    print(f"Memory root:         {result['memory_root']}")
    print(f"Toolchains root:     {result['toolchains_root']}")
    print(f"Offline deps root:   {result['offline_deps_root']}")
    print(f"Rust toolchain dir:  {result['rust_toolchain_dir']}")
    print(f"Minimum Zig line:    {result['minimum_zig']}")
    print(
        "Fallback Zig archive:"
        f" {'present' if result['fallback_zig_archive']['exists'] else 'missing'}"
        f" ({result['fallback_zig_archive']['path']})"
    )
    print()

    memory_status = result["memory_status"]
    print("Saved Memory inputs")
    print("===================")
    for entry in memory_status["entries"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['path']}")

    default_zig = result["default_zig"]
    print()
    print("Default Zig")
    print("===========")
    if default_zig["found"]:
        print(f"  Path:    {default_zig['path']}")
        print(f"  Version: {default_zig['version']}")
        print(f"  Status:  {default_zig['status']}")
    else:
        print("  zig is not on PATH")

    print()
    print("Staged Zig candidates")
    print("=====================")
    if result["zig_candidates"]:
        for candidate in result["zig_candidates"]:
            print(f"  - {candidate['path']} [{candidate['version']}; {candidate['status']}]")
    else:
        print("  none")

    rust_status = result["rust_status"]
    print()
    print("Saved Rust toolchain")
    print("====================")
    print(f"  Cargo: {'PASS' if rust_status['cargo_ready'] else 'FAIL'} {rust_status['cargo_version']}")
    print(f"  Rustc: {'PASS' if rust_status['rustc_ready'] else 'FAIL'} {rust_status['rustc_version']}")

    offline_status = result["offline_status"]
    print()
    print("Offline dependencies")
    print("====================")
    for entry in offline_status["entries"]:
        status = "PASS" if entry["exists"] and entry["non_empty"] else "FAIL"
        print(f"  [{status}] {entry['name']}: {entry['path']}")
    if offline_status["prebuilt_v8"]:
        print(f"  [PASS] prebuilt V8: {offline_status['prebuilt_v8'][0]}")
    else:
        print("  [FAIL] prebuilt V8: missing")

    print()
    print("Next step")
    print("=========")
    print(f"  Reason:  {result['next_step']['reason']}")
    print(f"  Command: {result['next_step']['command']}")

    print()
    if result["ready_for_full_readiness"]:
        print("Ready for the full Linux/WSL readiness check.")
    else:
        print("Not ready for the full Linux/WSL readiness check yet.")


class BuildReadinessStatusTests(unittest.TestCase):
    def _write_repo(self, root: Path) -> Path:
        repo_root = root / "browser"
        repo_root.mkdir()
        (repo_root / "build.zig.zon").write_text(
            '.minimum_zig_version = "0.15.2";\n',
            encoding="utf-8",
        )
        return repo_root

    def _write_memory(self, root: Path) -> Path:
        memory_root = root / "memory"
        for relative_path, _label in REQUIRED_MEMORY_FILES:
            target = memory_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("x", encoding="utf-8")
        return memory_root

    def test_next_step_prefers_memory_preflight_when_inputs_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self._write_repo(root)
            result = collect_status(
                repo_root=repo_root,
                memory_root=root / "memory",
                toolchains_root=root / "toolchains",
                offline_deps_root=root / "offline-deps",
                rust_toolchain_dir=root / "toolchains" / "rust-1.79.0",
                fallback_zig_archive=None,
            )
            self.assertEqual(result["next_step"]["reason"], "saved-memory-inputs-missing")

    def test_next_step_prefers_zig_route_when_only_mismatched_zig_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self._write_repo(root)
            memory_root = self._write_memory(root)
            toolchains_root = root / "toolchains"
            zig_dir = toolchains_root / "zig-0.17.0" / "bin"
            zig_dir.mkdir(parents=True)
            zig = zig_dir / "zig"
            zig.write_text("#!/usr/bin/env bash\necho 0.17.0-dev.1\n", encoding="utf-8")
            zig.chmod(0o755)
            result = collect_status(
                repo_root=repo_root,
                memory_root=memory_root,
                toolchains_root=toolchains_root,
                offline_deps_root=root / "offline-deps",
                rust_toolchain_dir=root / "toolchains" / "rust-1.79.0",
                fallback_zig_archive=None,
            )
            self.assertEqual(result["next_step"]["reason"], "no-branch-compatible-zig")

    def test_ready_route_when_matching_zig_rust_and_offline_inputs_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self._write_repo(root)
            memory_root = self._write_memory(root)
            toolchains_root = root / "toolchains"
            zig_dir = toolchains_root / "zig-0.15.2" / "bin"
            zig_dir.mkdir(parents=True)
            zig = zig_dir / "zig"
            zig.write_text("#!/usr/bin/env bash\necho 0.15.2\n", encoding="utf-8")
            zig.chmod(0o755)

            rust_toolchain_dir = toolchains_root / "rust-1.79.0"
            cargo = rust_toolchain_dir / "cargo" / "bin" / "cargo"
            cargo.parent.mkdir(parents=True)
            cargo.write_text("#!/usr/bin/env bash\necho cargo 1.79.0\n", encoding="utf-8")
            cargo.chmod(0o755)
            rustc = rust_toolchain_dir / "rustc" / "bin" / "rustc"
            rustc.parent.mkdir(parents=True)
            rustc.write_text("#!/usr/bin/env bash\necho rustc 1.79.0\n", encoding="utf-8")
            rustc.chmod(0o755)

            offline_root = root / "offline-deps"
            for name in OFFLINE_DEP_NAMES:
                dep_dir = offline_root / name
                dep_dir.mkdir(parents=True)
                (dep_dir / "marker.txt").write_text("x", encoding="utf-8")
            (offline_root / "libc_v8_stub.a").write_text("x", encoding="utf-8")

            result = collect_status(
                repo_root=repo_root,
                memory_root=memory_root,
                toolchains_root=toolchains_root,
                offline_deps_root=offline_root,
                rust_toolchain_dir=rust_toolchain_dir,
                fallback_zig_archive=None,
            )
            self.assertEqual(result["next_step"]["reason"], "ready-for-full-readiness-check")
            self.assertTrue(result["ready_for_full_readiness"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(BuildReadinessStatusTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    offline_deps_root = (
        Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else resolve_default_offline_deps_root(repo_root)
    )
    rust_toolchain_dir = (
        Path(args.rust_toolchain_dir).resolve()
        if args.rust_toolchain_dir
        else resolve_default_rust_toolchain_dir(repo_root)
    )
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    result = collect_status(
        repo_root=repo_root,
        memory_root=memory_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        rust_toolchain_dir=rust_toolchain_dir,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ready_for_full_readiness"] else 1


if __name__ == "__main__":
    sys.exit(main())
