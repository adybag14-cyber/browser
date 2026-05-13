# Issue #3 Replay Context Rules

Use this note when an issue `#3` Windows replay is running against a non-default checkout, binary path, or saved summary artifact.

The goal is simple: once a replay starts with explicit context, every follow-up command should keep that same context instead of silently drifting back to default lookup paths.

## Context that must stay pinned

Preserve these values whenever the current replay already set them:

- `-RepoRoot`
- `-BrowserExe`
- `-SummaryPath`

Treat a missing passthrough for any of these as replay drift, not as harmless convenience.

## Why it matters

Issue `#3` now relies on wrapper chains that reopen saved artifacts repeatedly:

- safe-summary routes
- safe-route runner-patch wrappers
- patch-target repair wrappers
- patch-handoff helpers
- safe and raw runner-output wiring checks

If one emitted follow-up command drops the active repo root, browser path, or summary path, the next Windows replay can reopen the wrong checkout or stale artifacts and produce misleading guidance.

## Practical rule

When a wrapper emits a follow-up command, keep the current replay context in that command unless the helper is intentionally switching to a new artifact.

That means:

- preserve `-RepoRoot` when the replay is intentionally pinned to a specific checkout
- preserve `-BrowserExe` when the replay is intentionally pinned to a specific binary
- preserve `-SummaryPath` whenever later helpers are meant to keep inspecting the same saved summary instead of the default headed-probe path

## Recommended review check

Before trusting a newly added issue `#3` wrapper or helper chain, scan the emitted commands and confirm that they do not discard explicit replay context.

A wrapper is only context-safe when its follow-up commands stay aligned with the same:

- checkout
- binary
- saved summary artifact

## Related notes

Pair this note with:

- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`

Use those notes for route selection, direct runner patch rules, and replay-state branching. Use this note as the compact rule for keeping a chosen replay context intact across the next helper hop.
