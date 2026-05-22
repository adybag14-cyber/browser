# Zig 0.17 Dependency Port Queue

Use this note when the headed fork is back on the **Build and dependency readiness** lane and the next goal is to keep the already-landed root `build.zig` port moving instead of rediscovering the same external blockers.

Keep these nearby:

- `build.zig`
- `build.zig.zon`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- saved dependency archive `repo_archives/browser/dependencies/03-boringssl-zig-main.zip`
- saved dependency archive `repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip`

## What is already landed on the branch

The fork already carries the root build-script port toward Zig 0.17:

- Commit: `6aff01c86843a11ac09d0921df72dfbb675e9a71`
- Message: `build: port root build script toward zig 0.17`

That branch change moved the top-level build away from the older `std.zon.parse.fromSlice(...)` and compile-step C-source helpers that blocked the first Zig 0.17 replay.

## Current remaining blockers

The next blockers are not in the fork root anymore. They live in the saved dependency worktrees that the branch expects through `build.zig.zon`:

- `zig-v8-fork-0.3.1/build.zig`
- `boringssl-zig-main/build.zig`

The branch still declares:

- `.minimum_zig_version = "0.15.2"`
- `.dependencies.v8.path = "../zig-v8-fork"`
- `.dependencies.@"boringssl-zig".path = "../boringssl-zig"`

That means a future Zig 0.17 replay still depends on porting the external build scripts before the whole headed fork can build cleanly under that toolchain.

## Verified dependency surfaces

### `zig-v8-fork-0.3.1/build.zig`

The saved `zig-v8-fork` build script still performs cache and marker-file work through direct `std.fs.cwd()` access patterns around the depot-tools and V8 bootstrap paths, including:

- `std.fs.cwd().access(cache_root, .{})`
- `std.fs.cwd().makeDir(cache_root)`
- later marker checks under `bootstrapDepotTools(...)` and `bootstrapV8(...)`

Use that file as the next replay surface for the Zig 0.17 cache/bootstrap port.

### `boringssl-zig-main/build.zig`

The saved `boringssl-zig` build script still defines its outputs through the older compile-step pattern:

- `b.addStaticLibrary(...)` for `fipsmodule`, `crypto`, `ssl`, `decrepit`, and `pki`
- `b.addExecutable(...)` for `bssl`
- per-target source attachment through repeated `addCSourceFile(...)`
- header installation through `installHeadersDirectory(...)`

Use that file as the next replay surface for the Zig 0.17 library/executable build-graph port.

## Practical replay order

1. Restore the saved dependency worktrees from Memory next to a writable checkout of `fork/headed-mode-foundation`.
2. Reopen `zig-v8-fork-0.3.1/build.zig` first and port the cache/bootstrap file handling so the depot-tools and V8 preparation path compiles under Zig 0.17.
3. Reopen `boringssl-zig-main/build.zig` next and port the static-library and executable setup onto the Zig 0.17 build APIs.
4. Re-run the top-level replay from the headed fork root with the same command family used for the original root build port:

```sh
zig build --summary all -Dprebuilt_v8_path='<path to libc_v8 archive>'
```

5. Only after both dependency build scripts are green should the branch `build.zig.zon` minimum-version discussion be reopened.

## Working rule

Treat this as a branch-local handoff note, not proof that the dependency ports are already done.

What is proven here is narrower:

- the root fork build script already moved forward
- the next Zig 0.17 failures are expected in the external dependency build scripts
- the saved Memory archives contain the exact files that should be reopened next

If a future run has a writable checkout plus the dependency worktrees, resume from this note before re-deriving the same blocker chain from scratch.
