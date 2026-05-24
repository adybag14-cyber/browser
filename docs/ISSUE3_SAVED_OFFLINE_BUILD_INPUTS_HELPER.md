# Issue #3 Saved Offline Build Inputs Helper

Use this note when the Linux or WSL recovery path for issue `#3` still needs
the saved dependency archives staged, but the next run should not have to rebuild
the archive arguments for `prepare_offline_build_inputs.sh` by hand.

The helper added here keeps the saved-archive defaults on one small branch-local
surface:

- `scripts/linux/restore_issue3_saved_offline_build_inputs.sh`
- `scripts/linux/prepare_offline_build_inputs.sh`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`

## What It Does

The helper wraps `prepare_offline_build_inputs.sh` and fills in the default
saved-archive paths from Memory:

- `../memory/repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip`
- `../memory/repo_archives/browser/dependencies/03-boringssl-zig-main.zip`
- `../memory/repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip` when present

It still lets a run override:

- `--saved-archives-root`
- `--offline-deps-root`
- `--browser-deps-archive`
- `--boringssl-archive`
- `--html5ever-archive`

## Typical Usage

From the browser repo root:

```bash
bash ./scripts/linux/restore_issue3_saved_offline_build_inputs.sh --check-only
bash ./scripts/linux/restore_issue3_saved_offline_build_inputs.sh
```

Use `--check-only` first to print the resolved archive locations and the offline
dependency root before the helper mutates the sibling workspace layout.

Use `--json` when another helper wants the resolved command surface as
structured output.

## Why This Exists

The broader route note already documents the offline-input recovery flow, but it
still leaves runs carrying long archive arguments into the raw restore helper.
This smaller wrapper makes the common saved-Memory path easier to replay
correctly when the next Linux or WSL retry just needs the expected dependency
layout staged again.

## Working Rule

Use this helper when the saved dependency archives already exist in Memory and
the next step is simply to replay the standard offline-input staging flow. Move
back to `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md` when the run also needs the
full route context, the saved-Memory preflight, or the follow-up Rust and Zig
toolchain recovery steps on one longer checklist.
