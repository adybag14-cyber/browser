# Linux Localhost Validation Guide

This guide is for Linux or WSL2 restore work on the headed fork.

It does not claim that Linux currently has a native headed window backend. On
non-Windows targets, `browse --browser_mode headed` still falls back safely to
headless mode. The point of this guide is to make Linux useful for dependency
restore, toolchain diagnosis, localhost page serving, and preflight validation
before a real Windows headed run.

Read this together with:
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/WINDOWS_FULL_USE.md`
- `scripts/linux/check_lightpanda_linux_prereqs.sh`

## What This Covers

- verifying the basic Linux toolchain shape for this repo
- confirming localhost smoke assets can be served consistently
- distinguishing a real source failure from a toolchain mismatch
- staging the same localhost targets that the Windows headed path should use

## Quick Preflight

From the repo root:

```bash
bash scripts/linux/check_lightpanda_linux_prereqs.sh
```

Expected result:
- `python3` is available
- `zig` is available through `PATH`, `ZIG=/path/to/zig`, `./zig/zig`, or
  `./toolchains/zig/zig`
- `tmp-browser-smoke/` is present
- the isolated `zig build --help` probe succeeds

If `zig build --help` fails even with isolated cache directories, treat that as
a local toolchain problem before assuming the source tree is broken.

## Known Toolchain Trap

The saved Zig `0.17.0-dev.299+a76ce7710` toolchain is useful for quick probing,
but it is not automatically proof that this branch can run focused Zig tests on
Linux unchanged.

If you see failures like these in untouched files:
- `import of file outside module path`
- API or syntax errors before your target test code is reached

Treat that as a toolchain or invocation mismatch first.

Do not immediately edit headed runtime code in response to those failures.
Instead:
1. capture the exact command and stderr
2. confirm `zig build --help` still works with isolated caches
3. retry through the branch's normal `zig build` entrypoint before narrowing to
   source edits
4. move the final headed interaction validation back to a Windows/MSVC run

## Localhost Smoke Serving

Serve the local pages from the repo root with Python:

```bash
python3 -m http.server 8000 --directory tmp-browser-smoke
```

Then use `http://127.0.0.1:8000/` URLs for smoke targets.

If you are validating attached or external HTML pages outside the repo tree,
serve their containing directory the same way and keep the URLs loopback-based.

## Linux-Side Sanity Checks

These checks are safe on Linux even though the real headed backend is
Windows-first:

1. `zig build --help`
2. `zig build test`
3. start a localhost server for smoke pages
4. run `browse --browser_mode headed` against a loopback URL and confirm the
   process stays stable even if it falls back to headless mode

Example:

```bash
zig build
./zig-out/bin/lightpanda browse --browser_mode headed http://127.0.0.1:8000/
```

The Linux pass condition is not "a native window opened." The Linux pass
condition is:
- the toolchain and smoke assets are in place
- localhost navigation can be staged cleanly
- the fallback path does not crash immediately

## Windows Hand-off

Once Linux preflight is green, move real headed validation to Windows with the
same localhost targets:

1. serve the chosen pages over loopback
2. build the Windows/MSVC binary
3. run `browse --browser_mode headed <loopback-url>`
4. validate the visible browser surface, focus, typing, and navigation there

Use `docs/WINDOWS_FULL_USE.md` for the Windows-specific build and run steps.
