from __future__ import annotations

from pathlib import Path


EXPECTED_LAUNCH_SNIPPETS = {
    "tmp-browser-smoke/sessionstorage-scope/SessionStorageProbeCommon.ps1": (
        '"browse"',
        '"--browser_mode"',
        '"headed"',
    ),
    "tmp-browser-smoke/fetch-abort/FetchAbortProbeCommon.ps1": (
        '"browse"',
        '"--browser_mode"',
        '"headed"',
    ),
    "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1": (
        '"browse"',
        '"--browser_mode"',
        '"headed"',
    ),
    "tmp-browser-smoke/file-upload/FileUploadProbeCommon.ps1": (
        "'browse'",
        "'--browser_mode'",
        "'headed'",
    ),
    "tmp-browser-smoke/localstorage-persistence/StorageProbeCommon.ps1": (
        '"browse"',
        '"--browser_mode"',
        '"headed"',
    ),
    "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1": (
        '"browse"',
        '"--browser_mode"',
        '"headed"',
    ),
    "tmp-browser-smoke/settings/chrome-settings-restore-off-probe.ps1": (
        '"browse"',
        '"--browser_mode"',
        '"headed"',
    ),
    "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1": (
        '"browse"',
        '"--browser_mode"',
        '"headed"',
    ),
    "tmp-browser-smoke/font-smoke/chrome-font-auth-probe.ps1": (
        "'browse'",
        "'--browser_mode'",
        "'headed'",
    ),
    "tmp-browser-smoke/font-smoke/chrome-font-anonymous-probe.ps1": (
        "'browse'",
        "'--browser_mode'",
        "'headed'",
    ),
}


def resolve_repo_root(start: Path | None = None) -> Path:
    cursor = (start or Path(__file__)).resolve()
    for candidate in (cursor, *cursor.parents):
        if (candidate / "build.zig").exists():
            return candidate
    raise FileNotFoundError("Could not resolve the Lightpanda repo root")


def collect_headed_launch_gaps(repo_root: Path) -> list[dict[str, object]]:
    gaps: list[dict[str, object]] = []
    for relative_path, snippets in EXPECTED_LAUNCH_SNIPPETS.items():
        target = repo_root / relative_path
        if not target.exists():
            gaps.append(
                {
                    "path": relative_path,
                    "missing_file": True,
                    "missing_snippets": list(snippets),
                }
            )
            continue

        content = target.read_text(encoding="utf-8")
        missing_snippets = [snippet for snippet in snippets if snippet not in content]
        if missing_snippets:
            gaps.append(
                {
                    "path": relative_path,
                    "missing_file": False,
                    "missing_snippets": missing_snippets,
                }
            )
    return gaps


def audit_summary(repo_root: Path | None = None) -> dict[str, object]:
    resolved_repo_root = resolve_repo_root(repo_root)
    gaps = collect_headed_launch_gaps(resolved_repo_root)
    return {
        "repo_root": str(resolved_repo_root),
        "expected_file_count": len(EXPECTED_LAUNCH_SNIPPETS),
        "gaps": gaps,
    }


if __name__ == "__main__":
    import json

    print(json.dumps(audit_summary(), indent=2))
