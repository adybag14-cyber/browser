#!/usr/bin/env python3

"""Surface paired staged Rust and Zig toolchain readiness for issue #11."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest


def run_json_helper(helper_path: Path, *, repo_root: Path, toolchains_root: Path | None) -> dict[str, object]:
    command = [sys.executable, str(helper_path), "--repo-root", str(repo_root), "--json"]
    if toolchains_root is not None:
        command.extend(["--toolchains-root", str(toolchains_root)])

    completed = subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=False,
    )

    output = completed.stdout.strip()
    if not output:
        stderr = completed.stderr.strip()
        raise RuntimeError(
            f"{helper_path.name} produced no JSON output (exit {completed.returncode})"
            + (f": {stderr}" if stderr else "")
        )

    try:
        report = json.loads(output)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{helper_path.name} emitted invalid JSON") from exc

    if not isinstance(report, dict):
        raise RuntimeError(f"{helper_path.name} JSON output was not an object")

    report["exit_code"] = completed.returncode
    return report


def build_combined_exports(rust_report: dict[str, object], zig_report: dict[str, object]) -> list[str]:
    rust_candidate = rust_report.get("preferred_candidate") or {}
    zig_candidate = zig_report.get("preferred_candidate") or {}

    exports: list[str] = []
    rust_path = rust_candidate.get("path_export")
    rust_cargo = rust_candidate.get("cargo_export")
    rust_rustc = rust_candidate.get("rustc_export")
    zig_path = zig_candidate.get("path_export")
    zig_export = zig_candidate.get("zig_export")

    if isinstance(rust_path, str):
        exports.append(rust_path)
    if isinstance(zig_path, str):
        exports.append(zig_path)
    if isinstance(rust_cargo, str):
        exports.append(rust_cargo)
    if isinstance(rust_rustc, str):
        exports.append(rust_rustc)
    if isinstance(zig_export, str):
        exports.append(zig_export)
    return exports


def summarize_pairing(
    *,
    repo_root: Path,
    toolchains_root: Path | None,
    rust_report: dict[str, object],
    zig_report: dict[str, object],
) -> dict[str, object]:
    rust_ready = rust_report.get("status") == "passed" and rust_report.get("preferred_candidate") is not None
    zig_ready = zig_report.get("status") == "passed" and zig_report.get("preferred_candidate") is not None
    paired_ready = rust_ready and zig_ready

    failures: list[str] = []
    if not rust_ready:
        failures.append("No staged Rust 1.79.x candidate is ready yet.")
    if not zig_ready:
        failures.append("No staged Zig candidate matches the branch minimum line yet.")

    next_steps: list[str] = []
    rust_next = rust_report.get("suggested_next_step")
    zig_next = zig_report.get("suggested_next_step")
    if not rust_ready and isinstance(rust_next, str) and rust_next:
        next_steps.append(rust_next)
    if not zig_ready and isinstance(zig_next, str) and zig_next:
        next_steps.append(zig_next)
    if paired_ready:
        next_steps.append(
            "Use the surfaced exports and rerun scripts/check_linux_build_readiness.py with the same repo and toolchains roots."
        )

    return {
        "status": "passed" if paired_ready else "failed",
        "repo_root": str(repo_root),
        "toolchains_root": str(toolchains_root) if toolchains_root is not None else None,
        "rust": rust_report,
        "zig": zig_report,
        "paired_ready": paired_ready,
        "exports": build_combined_exports(rust_report, zig_report) if paired_ready else [],
        "failures": failures,
        "suggested_next_steps": next_steps,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check whether both the staged Rust and Zig toolchain lanes are ready for issue #11 Linux/WSL re-entry."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Optional shared toolchains directory override passed through to the staged Rust and Zig helper scripts",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class StagedToolchainPairTests(unittest.TestCase):
    def test_summarize_pairing_passes_when_both_candidates_are_ready(self) -> None:
        rust_report = {
            "status": "passed",
            "preferred_candidate": {
                "path_export": 'export PATH="/tmp/toolchains/rust-1.79.0/cargo/bin:/tmp/toolchains/rust-1.79.0/rustc/bin:$PATH"',
                "cargo_export": 'export CARGO="/tmp/toolchains/rust-1.79.0/cargo/bin/cargo"',
                "rustc_export": 'export RUSTC="/tmp/toolchains/rust-1.79.0/rustc/bin/rustc"',
            },
        }
        zig_report = {
            "status": "passed",
            "preferred_candidate": {
                "path_export": 'export PATH="/tmp/toolchains/zig-linux-x86_64-0.15.2:$PATH"',
                "zig_export": 'export ZIG="/tmp/toolchains/zig-linux-x86_64-0.15.2/zig"',
            },
        }

        result = summarize_pairing(
            repo_root=Path("/tmp/browser"),
            toolchains_root=Path("/tmp/toolchains"),
            rust_report=rust_report,
            zig_report=zig_report,
        )

        self.assertEqual(result["status"], "passed")
        self.assertTrue(result["paired_ready"])
        self.assertEqual(len(result["exports"]), 5)

    def test_summarize_pairing_reports_missing_rust_candidate(self) -> None:
        rust_report = {
            "status": "failed",
            "preferred_candidate": None,
            "suggested_next_step": "restore Rust first",
        }
        zig_report = {
            "status": "passed",
            "preferred_candidate": {"zig_export": "export ZIG=/tmp/zig"},
        }

        result = summarize_pairing(
            repo_root=Path("/tmp/browser"),
            toolchains_root=None,
            rust_report=rust_report,
            zig_report=zig_report,
        )

        self.assertEqual(result["status"], "failed")
        self.assertFalse(result["paired_ready"])
        self.assertIn("Rust", result["failures"][0])
        self.assertIn("restore Rust first", result["suggested_next_steps"][0])

    def test_run_json_helper_accepts_nonzero_exit_with_json(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper = Path(tmpdir) / "helper.py"
            helper.write_text(
                textwrap.dedent(
                    """\
                    #!/usr/bin/env python3
                    import json
                    import sys
                    print(json.dumps({"status": "failed", "preferred_candidate": None}))
                    raise SystemExit(1)
                    """
                ),
                encoding="utf-8",
            )

            report = run_json_helper(helper, repo_root=Path(tmpdir), toolchains_root=None)

            self.assertEqual(report["status"], "failed")
            self.assertEqual(report["exit_code"], 1)

    def test_run_json_helper_rejects_empty_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper = Path(tmpdir) / "helper.py"
            helper.write_text("#!/usr/bin/env python3\n", encoding="utf-8")

            with self.assertRaises(RuntimeError):
                run_json_helper(helper, repo_root=Path(tmpdir), toolchains_root=None)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(StagedToolchainPairTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else None
    scripts_root = repo_root / "scripts"

    rust_helper = scripts_root / "check_issue3_staged_rust_toolchain_candidates.py"
    zig_helper = scripts_root / "check_issue3_staged_zig_toolchain_candidates.py"
    for helper in (rust_helper, zig_helper):
        if not helper.is_file():
            print(f"ERROR: required helper not found: {helper}", file=sys.stderr)
            return 2

    rust_report = run_json_helper(rust_helper, repo_root=repo_root, toolchains_root=toolchains_root)
    zig_report = run_json_helper(zig_helper, repo_root=repo_root, toolchains_root=toolchains_root)
    result = summarize_pairing(
        repo_root=repo_root,
        toolchains_root=toolchains_root,
        rust_report=rust_report,
        zig_report=zig_report,
    )

    if args.json:
        print(json.dumps(result, indent=2))
        return 0 if result["paired_ready"] else 1

    print(f"Repo root: {repo_root}")
    print(f"Toolchains root: {toolchains_root or 'default helper discovery'}")
    print(f"Rust staged status: {rust_report.get('status')}")
    print(f"Zig staged status: {zig_report.get('status')}")

    if result["paired_ready"]:
        print("\nPaired staged toolchain check passed.")
        print("Combined exports:")
        for export in result["exports"]:
            print(f"  {export}")
        return 0

    print("\nPaired staged toolchain check failed.", file=sys.stderr)
    for failure in result["failures"]:
        print(f"  - {failure}", file=sys.stderr)
    if result["suggested_next_steps"]:
        print("Suggested next steps:", file=sys.stderr)
        for step in result["suggested_next_steps"]:
            print(f"  - {step}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())