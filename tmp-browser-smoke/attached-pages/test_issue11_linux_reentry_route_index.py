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
}
""",
    "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md": """
# Issue #11 Linux Re-entry Route Index

This index is for the lower-volume tracker in issue `#11`:

- https://github.com/adybag14-cyber/browser/issues/11

Do not use the saturated issue `#2` or issue `#3` threads for routine start or
completion updates while the work is still in the saved-input, archive,
toolchain, or offline-dependency lane.

## Goal

1. issue `#11` progress updates
2. saved-archive trust checks
3. restored-checkout and saved-input checks
4. saved Rust and Zig toolchain recovery
5. Linux or WSL build-readiness reruns
6. the narrower Windows runtime re-entry route once the environment gates turn green

## Expected Shared Roots

- Memory archive root: `../memory/repo_archives/browser`
- Toolchains root: `../toolchains`
- Offline dependency root: `../offline-deps`
- Attached fallback Zig archive: `../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`

```bash
bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh
bash ./scripts/linux/show_issue3_workspace_context_route.sh
python ./scripts/check_issue3_workspace_context.py --repo-root .
```

## Start With The Progress Tracker Route

```bash
bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh
bash ./scripts/linux/show_issue3_progress_tracker_route.sh
```

## Prove The Saved Inputs Before Restore Or Staging

```bash
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

Use `--fallback-zig-archive ../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
when the attached Zig archive is present but not in the default sibling
location expected by the helper.

```bash
bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

## Reopen Rust Before Trusting Host Tooling

```bash
bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

## Reopen Zig In Two Steps

```bash
bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
```

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
bash ./scripts/linux/check_issue3_zig_toolchain_match.sh
```

Treat the attached Zig `0.17` dev archive as a surfaced fallback only. Do not
count it as honest branch-compatible validation evidence for a checkout that
still expects a `0.15.x` line.

## Re-run Linux Build Readiness Only After The Gates Above

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
python ./scripts/check_linux_build_readiness.py --repo-root .
```

```bash
python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .
```

## Hand Control Back To The Runtime Route Only When Ready

```bash
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```

Keep `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` and
`docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` open when the route crosses
back from environment recovery into the real runtime patch lane.
""",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": "# gates\n",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": "# runtime\n",
    "scripts/check_issue3_workspace_context.py": "\"\"\"workspace context\"\"\"\n",
    "scripts/check_issue3_saved_archive_integrity.py": "\"\"\"archive integrity\"\"\"\n",
    "scripts/check_issue3_saved_memory_inputs.py": "\"\"\"saved memory\"\"\"\n",
    "scripts/check_issue3_saved_rust_archive_candidates.py": "\"\"\"saved rust\"\"\"\n",
    "scripts/check_issue3_staged_rust_toolchain_candidates.py": "\"\"\"staged rust\"\"\"\n",
    "scripts/check_issue3_saved_zig_archive_candidates.py": "\"\"\"saved zig\"\"\"\n",
    "scripts/check_linux_build_readiness.py": "\"\"\"build readiness\"\"\"\n",
    "scripts/check_issue3_build_readiness_rerun.py": "\"\"\"rerun\"\"\"\n",
    "scripts/linux/check_issue3_workspace_context_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_workspace_context_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_progress_tracker_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_zig_toolchain_match.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh": "#!/usr/bin/env bash\n",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": "#!/usr/bin/env bash\n",
}


REQUIRED_ROUTE_PATHS = (
    "scripts/linux/check_issue3_workspace_context_route_surface.sh",
    "scripts/linux/show_issue3_workspace_context_route.sh",
    "scripts/check_issue3_workspace_context.py",
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
    "scripts/linux/show_issue3_progress_tracker_route.sh",
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
    "scripts/check_issue3_saved_archive_integrity.py",
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
    "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
    "scripts/check_issue3_saved_rust_archive_candidates.py",
    "scripts/check_issue3_staged_rust_toolchain_candidates.py",
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
    "scripts/check_issue3_saved_zig_archive_candidates.py",
    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
    "scripts/linux/check_issue3_zig_toolchain_match.sh",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh",
    "scripts/check_linux_build_readiness.py",
    "scripts/check_issue3_build_readiness_rerun.py",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
)


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue11-route-index-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11LinuxReentryRouteIndexTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_index = read_text(
            cls.repo_root / "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md"
        )
        cls.build_manifest = read_text(cls.repo_root / "build.zig.zon")

    def test_note_keeps_issue11_tracker_and_saturated_thread_warning_visible(self) -> None:
        for fragment in (
            "# Issue #11 Linux Re-entry Route Index",
            "https://github.com/adybag14-cyber/browser/issues/11",
            "Do not use the saturated issue `#2` or issue `#3` threads",
            "saved-input, archive,",
            "toolchain, or offline-dependency lane.",
        ):
            self.assertIn(fragment, self.route_index)

    def test_note_keeps_the_ordered_reentry_ladder_visible(self) -> None:
        for fragment in (
            "1. issue `#11` progress updates",
            "2. saved-archive trust checks",
            "3. restored-checkout and saved-input checks",
            "4. saved Rust and Zig toolchain recovery",
            "5. Linux or WSL build-readiness reruns",
            "6. the narrower Windows runtime re-entry route once the environment gates turn green",
        ):
            self.assertIn(fragment, self.route_index)

    def test_note_keeps_shared_roots_and_fallback_archive_visible(self) -> None:
        for fragment in (
            "Memory archive root: `../memory/repo_archives/browser`",
            "Toolchains root: `../toolchains`",
            "Offline dependency root: `../offline-deps`",
            "Attached fallback Zig archive: `../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`",
            "Use `--fallback-zig-archive ../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`",
            "Treat the attached Zig `0.17` dev archive as a surfaced fallback only.",
            "still expects a `0.15.x` line.",
        ):
            self.assertIn(fragment, self.route_index)

    def test_note_keeps_all_major_route_commands_visible(self) -> None:
        for fragment in (
            "bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh",
            "bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh",
            "bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
            "bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            "bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
            "bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
            "bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
            "bash ./scripts/linux/check_issue3_zig_toolchain_match.sh",
            "bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
            "python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .",
            "bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh",
            "`docs/ISSUE3_RUNTIME_REENTRY_GATES.md`",
            "`docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`",
        ):
            self.assertIn(fragment, self.route_index)

    def test_every_advertised_route_path_exists(self) -> None:
        for relative_path in REQUIRED_ROUTE_PATHS:
            with self.subTest(relative_path=relative_path):
                self.assertTrue(
                    (self.repo_root / relative_path).is_file(),
                    msg=f"Missing route surface: {relative_path}",
                )

    def test_build_manifest_keeps_expected_zig_line_visible(self) -> None:
        self.assertIn('.minimum_zig_version = "0.15.2"', self.build_manifest)


if __name__ == "__main__":
    unittest.main()
