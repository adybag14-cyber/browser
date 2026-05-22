# Build Dependency Readiness Handoff

Updated: 2026-05-22 UTC

Use this note when the next headed-mode run needs to unblock local build validation before reopening the direct runtime fix for issue `#3`.

## Why this note exists

The current branch already declares its expected Zig floor in `build.zig.zon`:

- `minimum_zig_version = "0.15.2"`

That matters because the attached Zig `0.17.0-dev.299` fallback toolchain is useful for quick drift checks, but it is not yet a branch-compatible validation toolchain for this fork. The root `build.zig` was already moved partway toward Zig 0.17, but the next failures now live in the saved dependency build scripts rather than in the browser repo's root build file.

## Current validated state

The root browser build script already includes the earlier compatibility work:

- allocator-backed `std.zon.parse.fromSliceAlloc(...)` manifest parsing
- `root_module.addCSourceFiles(...)` usage for zlib, brotli, nghttp2, and curl
- `root_module.addConfigHeader(...)` usage for curl config wiring

Those changes moved the failure boundary forward. The next blockers are now in dependency build surfaces.

## Remaining dependency blockers

### 1. `zig-v8-fork/build.zig`

Current blocker shape:

- the saved dependency build script still uses `std.fs.cwd()` for cache-root and bootstrap marker access
- the failing surface sits in the V8 bootstrap/cache preparation path, not in the browser's root build file

Concrete next target:

- reopen `zig-v8-fork/build.zig`
- port the `std.fs.cwd()` access and directory-manipulation calls onto the Zig `0.17`-compatible build/path APIs used by the newer toolchain
- keep the existing cache-root behavior and marker-file semantics intact while moving the API surface

### 2. `boringssl-zig/build.zig`

Current blocker shape:

- the saved dependency build script still uses the older `b.addStaticLibrary(...)` style for:
  - `fipsmodule`
  - `crypto`
  - `ssl`
  - `decrepit`
  - `pki`
- the same file still uses the older `b.addExecutable(...)` surface for `bssl`

Concrete next target:

- reopen `boringssl-zig/build.zig`
- port those library and executable declarations onto the current Zig `0.17` build-step API while preserving:
  - the same artifact names
  - the existing include-path wiring
  - the same C and C++ link behavior
  - the existing generated-source registration order

## Why this is the best next build lane

Issue `#3` still narrows to the two runtime files below:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

But the attached Zig `0.17` fallback still fails in untouched dependency build surfaces before the focused runtime validation path can be trusted. That makes build and dependency readiness the highest-value unblocked lane whenever the direct runtime publication path is still sensitive.

## Practical replay path

When a writable checkout and local dependency worktrees are available:

1. Start from the branch root and confirm `build.zig.zon` still declares `minimum_zig_version = "0.15.2"`.
2. If the run must keep using Zig `0.17`, port these dependency files first:
   - `../zig-v8-fork/build.zig`
   - `../boringssl-zig/build.zig`
3. Re-run the normal browser build validation only after those dependency ports land.
4. Resume the direct issue `#3` runtime slice from `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`.

## Validation focus after the dependency ports

Prefer rechecking this sequence in order:

1. the root browser build no longer fails in dependency build scripts under the chosen toolchain
2. focused runtime checks for `src/browser/Page.zig` and `src/display/win32_backend.zig`
3. the reduced Google probe before the real Google homepage replay

## Rule for future runs

Treat the attached Zig `0.17.0-dev.299` toolchain as a fallback reference until the dependency scripts above are ported or a confirmed Zig `0.15.2` validation path is available again.
