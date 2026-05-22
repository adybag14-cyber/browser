#!/usr/bin/env python3
"""Verify and optionally dry-run the issue #3 Enter-submit runtime patch base.

This helper keeps the current live blob expectations next to the repo so a
writable checkout can confirm it is replaying the saved runtime patch against
the exact `fork/headed-mode-foundation` base that was revalidated for the
Google headed Enter-submit work.
"""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys


EXPECTED_PAGE_SHA = "4baba018ca1dd351f3313c498545d71d6478a28d"
EXPECTED_WIN32_SHA = "af5afd2ab02dad63812185a4ae5cb43dd7f55eea"
DEFAULT_PAGE_PATCH = (
    "tmp-browser-smoke/google-investigation-next/patches/"
    "issue3-enter-submit-page-revalidated.patch"
)
DEFAULT_WIN32_PATCH = (
    "tmp-browser-smoke/google-investigation-next/patches/"
    "issue3-enter-submit-win32-revalidated.patch"
)
PAGE_PATH = pathlib.Path("src/browser/Page.zig")
WIN32_PATH = pathlib.Path("src/display/win32_backend.zig")


def git_blob_sha(repo_root: pathlib.Path, relative_path: pathlib.Path) -> str:
    target = repo_root / relative_path
    if not target.is_file():
        raise FileNotFoundError(f"missing target file: {relative_path}")
    result = subprocess.run(
        ["git", "hash-object", str(target)],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def resolve_patch_path(repo_root: pathlib.Path, patch_value: str) -> pathlib.Path:
    patch_path = pathlib.Path(patch_value)
    if patch_path.is_absolute():
        return patch_path
    return repo_root / patch_path


def patch_dry_run(repo_root: pathlib.Path, patch_path: pathlib.Path) -> tuple[bool, str]:
    if not patch_path.is_file():
        return False, f"missing patch file: {patch_path}"

    result = subprocess.run(
        ["patch", "-p4", "--dry-run", "-d", str(repo_root), "-i", str(patch_path)],
        check=False,
        capture_output=True,
        text=True,
    )
    combined = (result.stdout + result.stderr).strip()
    return result.returncode == 0, combined


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Verify that a checkout still matches the revalidated issue #3 "
            "Enter-submit runtime base, and optionally dry-run the saved patches."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout that should match fork/headed-mode-foundation.",
    )
    parser.add_argument(
        "--page-patch",
        default=DEFAULT_PAGE_PATCH,
        help="Patch path to dry-run for src/browser/Page.zig.",
    )
    parser.add_argument(
        "--win32-patch",
        default=DEFAULT_WIN32_PATCH,
        help="Patch path to dry-run for src/display/win32_backend.zig.",
    )
    parser.add_argument(
        "--skip-patch-check",
        action="store_true",
        help="Only verify blob SHAs without running patch --dry-run.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_argument_parser()
    args = parser.parse_args(argv)
    repo_root = pathlib.Path(args.repo_root).resolve()

    page_sha = git_blob_sha(repo_root, PAGE_PATH)
    win32_sha = git_blob_sha(repo_root, WIN32_PATH)

    page_matches = page_sha == EXPECTED_PAGE_SHA
    win32_matches = win32_sha == EXPECTED_WIN32_SHA

    print(f"repo_root={repo_root}")
    print(
        f"{PAGE_PATH} sha={page_sha} expected={EXPECTED_PAGE_SHA} "
        f"match={'yes' if page_matches else 'no'}"
    )
    print(
        f"{WIN32_PATH} sha={win32_sha} expected={EXPECTED_WIN32_SHA} "
        f"match={'yes' if win32_matches else 'no'}"
    )

    if not (page_matches and win32_matches):
        print("base_match=no")
        print("Next: refresh the checkout to the exact revalidated branch base before replaying the runtime patches.")
        return 1

    print("base_match=yes")

    if args.skip_patch_check:
        print("patch_check=skipped")
        return 0

    page_patch = resolve_patch_path(repo_root, args.page_patch)
    win32_patch = resolve_patch_path(repo_root, args.win32_patch)

    page_ok, page_output = patch_dry_run(repo_root, page_patch)
    win32_ok, win32_output = patch_dry_run(repo_root, win32_patch)

    print(f"page_patch={page_patch}")
    print(f"page_patch_dry_run={'ok' if page_ok else 'failed'}")
    if page_output:
        print(page_output)

    print(f"win32_patch={win32_patch}")
    print(f"win32_patch_dry_run={'ok' if win32_ok else 'failed'}")
    if win32_output:
        print(win32_output)

    return 0 if page_ok and win32_ok else 1


if __name__ == "__main__":
    sys.exit(main())
