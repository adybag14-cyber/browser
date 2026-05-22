# Zig 0.17 Build Readiness: `src/Config.zig` Arg Iterator Audit

Updated: 2026-05-22 UTC

## Scope

- Repository: `adybag14-cyber/browser`
- Branch: `fork/headed-mode-foundation`
- Lane: `Build and dependency readiness`
- Live target file: `src/Config.zig`

## What was verified

The live branch still types several parser helpers against `std.process.ArgIterator` in `src/Config.zig`.

A direct Zig 0.17.0-dev.299 probe confirmed that this type no longer exists:

```zig
fn takesArgIterator(args: *std.process.ArgIterator) void {
    _ = args;
}
```

Validation result:

```text
/tmp/argiter_probe.zig:5:39: error: root source file struct 'process' has no member named 'ArgIterator'
```

A follow-up probe confirmed the compatible replacement type:

```zig
fn takesArgsIterator(args: *std.process.Args.Iterator) void {
    _ = args;
}
```

Validation result:

```text
1/1 argsiter_probe.test.args iterator type exists...OK
All 1 tests passed.
```

## Suggested branch edit

Replace the `std.process.ArgIterator` type references in `src/Config.zig` with `std.process.Args.Iterator`.

The current live `src/Config.zig` surfaces that need this rename are the parser entrypoints and shared option helpers that still accept the older iterator type.

## Why this matters

This is a branch-local Zig 0.17 compatibility blocker that sits on the headed browser startup/configuration path.
Clearing it removes one of the saved build-readiness failures before the runtime-specific headed-mode tests can even run.

## Next recommended step

Apply the narrow type-name update directly in `src/Config.zig`, then rerun the focused Zig build/test path with the saved Zig 0.17 toolchain to expose the next real branch-local blocker.
