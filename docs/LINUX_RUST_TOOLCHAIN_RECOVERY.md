# Linux Saved Rust Toolchain Recovery

Use this when the headed-mode browser fork's offline Linux validation needs the
saved Rust 1.79.0 toolchain archive from Memory instead of a system Rust
install.

## Goal

Restore the saved `cargo` and `rustc` binaries into a repeatable sibling
workspace path so the existing offline preflight and build helpers can reuse
them without guessing.

## Saved Archive

The default archive path for scheduled runs is:

```text
/workspace/memory/repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz
```

The helper restores it to:

```text
../rust-1.79.0-x86_64-unknown-linux-gnu
```

relative to the browser repo root, unless `--toolchain-parent` is provided.

## Restore Helper

From the browser checkout, run:

```bash
bash scripts/linux/restore_saved_rust_toolchain.sh
```

What it does:

1. locates the saved Rust archive under the standard Memory dependency path
2. extracts the toolchain beside the browser repo
3. confirms the restored `cargo` and `rustc` binaries exist
4. prints exact `PATH`, `CARGO`, and `RUSTC` commands for later steps

If the archive lives somewhere else, point the helper at it explicitly:

```bash
bash scripts/linux/restore_saved_rust_toolchain.sh \
  --dependencies-root /path/to/dependencies
```

or:

```bash
bash scripts/linux/restore_saved_rust_toolchain.sh \
  --archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz
```

Use `--force` when you want to replace an existing extracted copy.

## Preflight And Build

After the restore helper prints the paths, reuse them with the existing offline
preflight:

```bash
ZIG=/absolute/path/to/zig \
CARGO=/absolute/path/to/rust-1.79.0-x86_64-unknown-linux-gnu/cargo/bin/cargo \
RUSTC=/absolute/path/to/rust-1.79.0-x86_64-unknown-linux-gnu/rustc/bin/rustc \
scripts/linux/check_offline_build_prereqs.sh
```

Then run the offline build with the same Rust environment:

```bash
ZIG=/absolute/path/to/zig \
CARGO=/absolute/path/to/rust-1.79.0-x86_64-unknown-linux-gnu/cargo/bin/cargo \
RUSTC=/absolute/path/to/rust-1.79.0-x86_64-unknown-linux-gnu/rustc/bin/rustc \
zig build --summary all -Dprebuilt_v8_path='../offline-deps/libc_v8_14.0.365.4_linux_x86_64 (1).a'
```

## Notes

- This helper is for Linux offline validation only. It does not install Rust
  system-wide.
- The extracted toolchain is intentionally kept beside the repo so future runs
  can discover and reuse it.
- Use this together with `docs/LINUX_OFFLINE_BUILD_RECOVERY.md` when both the
  Zig-side dependency layout and the Rust toolchain need to be restored from
  Memory.
