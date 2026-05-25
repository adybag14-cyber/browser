# Issue #3 Workspace-Context Route

Use this note when a restored checkout does not sit in the default sibling
layout expected by the Linux or WSL issue `#3` recovery helpers.

This route exists to surface the practical paths for:

- the shared `toolchains` directory
- the saved Memory browser archives
- the attached fallback Zig archive under `agent_files`

without rebuilding those paths by hand every time a checkout is restored deeper
than `/workspace/browser`.

## Run The Helper

From the browser repo root:

```bash
python scripts/check_issue3_workspace_context.py --repo-root .
```

Use `--json` when another helper or a scheduled run wants the resolved paths as
structured output.

If the fallback Zig archive is not sitting under the nearest discovered
`agent_files` directory, provide it explicitly:

```bash
python scripts/check_issue3_workspace_context.py \
  --repo-root . \
  --fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
```

## What The Helper Surfaces

The helper prints:

1. the current repo root
2. whether `build.zig.zon` is present
3. the nearest shared `toolchains` root it can find while walking up the
   workspace tree
4. the nearest saved browser-archives root under `memory/repo_archives/browser`
5. the nearest `agent_files` root
6. the fallback Zig archive path it resolved, if one exists
7. a ready-to-rerun `scripts/check_linux_build_readiness.py` command that uses
   the resolved roots

## Working Rules

- Run this helper first when a restored checkout sits deeper than the default
  sibling layout and the next Linux or WSL readiness command would otherwise
  guess the wrong `toolchains`, `memory`, or `agent_files` root.
- Treat the surfaced readiness command as the shortest honest handoff back to
  `scripts/check_linux_build_readiness.py`.
- Keep using explicit overrides when the desired roots are outside the current
  workspace ancestry.