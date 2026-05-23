#!/usr/bin/env python3

"""Summarize whether issue #3 runtime re-entry is ready or still blocked."""

from __future__ import annotations

import argparse
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
ZIG_VERSION_IN_NAME_RE = re.compile(r"(\d+\.\d+\.\d+)")

DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)

REQUIRED_MEMORY_FILES: tuple[str, ...] = (
    "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
    "repo_archives/browser/README.md",
    "repo_archives/browser/blocker_intelligence.yaml",
    "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
    "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
    "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
    "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
)

PAGE_MARKERS: tuple[str, ...] = (
    "_defer_native_text_input_enter_submit: bool = false",
    "_pending_native_enter_submit: ?*Element.Html.Input = null",
    "pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {",
    "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
    'test "Page reduced Google fixture defers native Enter submit until keypress" {',
)

WIN32_MARKERS: tuple[str, ...] = (
    "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
    'const defer_enter_submit = std.mem.eql(u8, key, "Enter");',
    "try page.applyDeferredNativeTextInputEnterSubmit();",
    "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
    'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
)


def parse_semver(version_text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(version_text)
    if not match:
        raise ValueError(f"Could not parse semantic version from {version_text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected_version: str, actual_version: str) -> bool:
    expected_parts = parse_semver(expected_version)
    actual_parts = parse_semver(actual_version)
    return actual_parts[:2] == expected_parts[:2]


def infer_archive_semver(path: Path) -> str | None:
    match = ZIG_VERSION_IN_NAME_RE.search(path.name)
    if match is None:
        return None
    return match.group(1)


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains").resolve()


def load_minimum_zig(repo_root: Path) -> str:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


def discover_toolchain_zig_candidates(toolchains_root: Path) -> list[Path]:
    if not toolchains_root.exists() or not toolchains_root.is_dir():
        return []

    candidates: list[Path] = []
    seen: set[Path] = set()
    for pattern in DEFAULT_ZIG_TOOLCHAIN_GLOBS:
        for path in sorted(toolchains_root.glob(pattern)):
            if not path.is_file():
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def describe_zig_candidate(minimum_zig: str, path: Path) -> dict[str, object]:
    version = infer_archive_semver(path.parent if path.name == "zig" else path)
    if version is None:
        version = infer_archive_semver(path)
    if version is None:
        status = "unknown version"
    elif same_version_line(minimum_zig, version):
        status = "matches expected line"
    elif parse_semver(version) < parse_semver(minimum_zig):
        status = "older than minimum"
    else:
        status = "mismatched line"
    return {
        "path": str(path),
        "version": version,
        "status": status,
        "matches_expected_line": status == "matches expected line",
    }


def collect_memory_status(memory_root: Path) -> dict[str, object]:
    required_files = []
    missing = []
    for relative_path in REQUIRED_MEMORY_FILES:
        path = memory_root / relative_path
        exists = path.is_file()
        required_files.append({"path": str(path), "exists": exists})
        if not exists:
            missing.append(relative_path)
    return {
        "ok": not missing,
        "root": str(memory_root),
        "missing_required_files": missing,
        "required_files": required_files,
    }


def evaluate_runtime_contract(repo_root: Path) -> dict[str, object]:
    page_path = repo_root / "src/browser/Page.zig"
    win32_path = repo_root / "src/display/win32_backend.zig"
    if not page_path.is_file() or not win32_path.is_file():
        return {
            "ok": False,
            "reason": "runtime target files are missing",
            "page_missing_markers": PAGE_MARKERS,
            "win32_missing_markers": WIN32_MARKERS,
        }

    page_source = page_path.read_text(encoding="utf-8")
    win32_source = win32_path.read_text(encoding="utf-8")
    page_missing = [marker for marker in PAGE_MARKERS if marker not in page_source]
    win32_missing = [marker for marker in WIN32_MARKERS if marker not in win32_source]
    ok = not page_missing and not win32_missing
    if ok:
        reason = "runtime bridge markers are present"
    else:
        reason = "runtime bridge markers are still missing"
    return {
        "ok": ok,
        "reason": reason,
        "page_missing_markers": page_missing,
        "win32_missing_markers": win32_missing,
    }


def summarize_status(
    *,
    repo_root: Path,
    memory_root: Path,
    agent_files_root: Path,
    toolchains_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    repo_has_manifest = (repo_root / "build.zig.zon").is_file()
    git_checkout_present = (repo_root / ".git").exists()
    target_files_present = (
        (repo_root / "src/browser/Page.zig").is_file()
        and (repo_root / "src/display/win32_backend.zig").is_file()
    )

    memory_status = collect_memory_status(memory_root)
    minimum_zig = load_minimum_zig(repo_root) if repo_has_manifest else None

    zig_candidates: list[dict[str, object]] = []
    matching_candidates: list[dict[str, object]] = []
    if minimum_zig is not None:
        for candidate in discover_toolchain_zig_candidates(toolchains_root):
            report = describe_zig_candidate(minimum_zig, candidate)
            zig_candidates.append(report)
            if report["matches_expected_line"]:
                matching_candidates.append(report)

    fallback_status = None
    if fallback_zig_archive is None:
        candidate = agent_files_root / DEFAULT_FALLBACK_ZIG
        fallback_zig_archive = candidate if candidate.exists() else candidate
    if minimum_zig is not None:
        fallback_version = infer_archive_semver(fallback_zig_archive) if fallback_zig_archive else None
        fallback_status = {
            "path": str(fallback_zig_archive),
            "exists": bool(fallback_zig_archive and fallback_zig_archive.is_file()),
            "version": fallback_version,
            "matches_expected_line": bool(
                fallback_version is not None and same_version_line(minimum_zig, fallback_version)
            ),
        }

    runtime_contract = evaluate_runtime_contract(repo_root) if target_files_present else {
        "ok": False,
        "reason": "runtime target files are missing",
        "page_missing_markers": list(PAGE_MARKERS),
        "win32_missing_markers": list(WIN32_MARKERS),
    }

    publication_gate_open = git_checkout_present and target_files_present
    toolchain_gate_open = bool(matching_candidates)

    if not repo_has_manifest or not target_files_present:
        recommended_lane = "Build and dependency readiness"
        recommendation_reason = "Restore or point at a usable checkout before reopening runtime work."
    elif not memory_status["ok"]:
        recommended_lane = "Build and dependency readiness"
        recommendation_reason = "Saved Memory inputs are incomplete, so replay recovery should start there."
    elif not publication_gate_open:
        recommended_lane = "Build and dependency readiness"
        recommendation_reason = "The direct runtime patch still lacks a writable checkout surface."
    elif not toolchain_gate_open:
        recommended_lane = "Build and dependency readiness"
        recommendation_reason = "A branch-compatible Zig 0.15.x line is not staged yet."
    elif runtime_contract["ok"]:
        recommended_lane = "Validation and regression control"
        recommendation_reason = "The narrowed runtime bridge is already present, so the next honest step is replay validation."
    else:
        recommended_lane = "Headed runtime bring-up"
        recommendation_reason = "The checkout and toolchain gates are open, so the runtime bridge can be edited directly."

    next_steps = []
    if not repo_has_manifest or not publication_gate_open:
        next_steps.append("bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh")
    if not memory_status["ok"]:
        next_steps.append("python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .")
    if repo_has_manifest and not toolchain_gate_open:
        next_steps.append("bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh")
        next_steps.append("bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh")
    if repo_has_manifest and toolchain_gate_open and not runtime_contract["ok"]:
        next_steps.append("bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh")
    if repo_has_manifest and toolchain_gate_open and runtime_contract["ok"]:
        next_steps.append(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )

    return {
        "profile": "issue3-runtime-reentry-gate-status",
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "agent_files_root": str(agent_files_root),
        "toolchains_root": str(toolchains_root),
        "minimum_zig": minimum_zig,
        "git_checkout_present": git_checkout_present,
        "target_files_present": target_files_present,
        "memory_status": memory_status,
        "zig_candidates": zig_candidates,
        "fallback_zig_archive": fallback_status,
        "runtime_contract": runtime_contract,
        "publication_gate": {
            "open": publication_gate_open,
            "reason": "writable checkout present" if publication_gate_open else "no writable checkout detected",
        },
        "toolchain_gate": {
            "open": toolchain_gate_open,
            "reason": "matching Zig candidate discovered"
            if toolchain_gate_open
            else "no staged Zig candidate matches the branch line",
        },
        "recommended_lane": recommended_lane,
        "recommendation_reason": recommendation_reason,
        "next_steps": next_steps,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Recommended lane: {result['recommended_lane']}")
    print(f"Why: {result['recommendation_reason']}")
    print(f"Publication gate: {'open' if result['publication_gate']['open'] else 'closed'}")
    print(f"Toolchain gate: {'open' if result['toolchain_gate']['open'] else 'closed'}")
    print(f"Runtime contract: {'ready' if result['runtime_contract']['ok'] else 'missing markers'}")
    if result["minimum_zig"] is not None:
        print(f"Minimum Zig: {result['minimum_zig']}")
    print("Next steps:")
    for step in result["next_steps"]:
        print(f"  - {step}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize whether issue #3 should reopen the direct runtime lane "
            "or stay on build-readiness recovery."
        )
    )
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--memory-root", default=None)
    parser.add_argument("--agent-files-root", default=None)
    parser.add_argument("--toolchains-root", default=None)
    parser.add_argument("--fallback-zig-archive", default=None)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    return parser


class RuntimeGateStatusTests(unittest.TestCase):
    def test_prefers_build_readiness_without_git_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            toolchains_root = root / "toolchains"
            agent_files_root = root / "agent_files"
            (repo_root / "src/browser").mkdir(parents=True)
            (repo_root / "src/display").mkdir(parents=True)
            memory_root.mkdir()
            toolchains_root.mkdir()
            agent_files_root.mkdir()

            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"\n', encoding="utf-8")
            (repo_root / "src/browser/Page.zig").write_text("\n".join(PAGE_MARKERS), encoding="utf-8")
            (repo_root / "src/display/win32_backend.zig").write_text("\n".join(WIN32_MARKERS), encoding="utf-8")
            for relative_path in REQUIRED_MEMORY_FILES:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            zig = toolchains_root / "zig-0.15.7" / "zig"
            zig.parent.mkdir(parents=True, exist_ok=True)
            zig.write_text("", encoding="utf-8")

            result = summarize_status(
                repo_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                toolchains_root=toolchains_root,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_lane"], "Build and dependency readiness")
            self.assertFalse(result["publication_gate"]["open"])

    def test_prefers_validation_when_runtime_markers_and_toolchain_are_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            toolchains_root = root / "toolchains"
            agent_files_root = root / "agent_files"
            (repo_root / ".git").mkdir(parents=True)
            (repo_root / "src/browser").mkdir(parents=True)
            (repo_root / "src/display").mkdir(parents=True)
            memory_root.mkdir()
            toolchains_root.mkdir()
            agent_files_root.mkdir()

            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"\n', encoding="utf-8")
            (repo_root / "src/browser/Page.zig").write_text("\n".join(PAGE_MARKERS), encoding="utf-8")
            (repo_root / "src/display/win32_backend.zig").write_text("\n".join(WIN32_MARKERS), encoding="utf-8")
            for relative_path in REQUIRED_MEMORY_FILES:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            zig = toolchains_root / "zig-0.15.7" / "zig"
            zig.parent.mkdir(parents=True, exist_ok=True)
            zig.write_text("", encoding="utf-8")

            result = summarize_status(
                repo_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                toolchains_root=toolchains_root,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_lane"], "Validation and regression control")
            self.assertTrue(result["publication_gate"]["open"])
            self.assertTrue(result["toolchain_gate"]["open"])
            self.assertTrue(result["runtime_contract"]["ok"])

    def test_prefers_runtime_when_checkout_is_ready_but_markers_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            toolchains_root = root / "toolchains"
            agent_files_root = root / "agent_files"
            (repo_root / ".git").mkdir(parents=True)
            (repo_root / "src/browser").mkdir(parents=True)
            (repo_root / "src/display").mkdir(parents=True)
            memory_root.mkdir()
            toolchains_root.mkdir()
            agent_files_root.mkdir()

            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"\n', encoding="utf-8")
            (repo_root / "src/browser/Page.zig").write_text("placeholder", encoding="utf-8")
            (repo_root / "src/display/win32_backend.zig").write_text("placeholder", encoding="utf-8")
            for relative_path in REQUIRED_MEMORY_FILES:
                target = memory_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            zig = toolchains_root / "zig-0.15.7" / "zig"
            zig.parent.mkdir(parents=True, exist_ok=True)
            zig.write_text("", encoding="utf-8")

            result = summarize_status(
                repo_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                toolchains_root=toolchains_root,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_lane"], "Headed runtime bring-up")
            self.assertFalse(result["runtime_contract"]["ok"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RuntimeGateStatusTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    agent_files_root = (
        Path(args.agent_files_root).resolve()
        if args.agent_files_root
        else resolve_default_agent_files_root(repo_root)
    )
    toolchains_root = (
        Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_default_toolchains_root(repo_root)
    )
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    result = summarize_status(
        repo_root=repo_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        toolchains_root=toolchains_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
