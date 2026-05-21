from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re


HEADED_MODE_PATTERN = re.compile(r'''["\']--browser_mode["\']\s*,\s*["\']headed["\']''')


@dataclass(frozen=True)
class HelperAuditEntry:
    name: str
    relative_path: str


@dataclass(frozen=True)
class HelperAuditResult:
    name: str
    relative_path: str
    explicit_headed: bool


HELPER_AUDIT_TARGETS = (
    HelperAuditEntry(
        name="attachment_downloads_common",
        relative_path="tmp-browser-smoke/attachment-downloads/AttachmentProbeCommon.ps1",
    ),
    HelperAuditEntry(
        name="cookie_persistence_common",
        relative_path="tmp-browser-smoke/cookie-persistence/CookieProbeCommon.ps1",
    ),
    HelperAuditEntry(
        name="fetch_credentials_common",
        relative_path="tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1",
    ),
    HelperAuditEntry(
        name="indexeddb_persistence_common",
        relative_path="tmp-browser-smoke/indexeddb-persistence/IndexedDbProbeCommon.ps1",
    ),
    HelperAuditEntry(
        name="localstorage_persistence_common",
        relative_path="tmp-browser-smoke/localstorage-persistence/StorageProbeCommon.ps1",
    ),
    HelperAuditEntry(
        name="sessionstorage_scope_common",
        relative_path="tmp-browser-smoke/sessionstorage-scope/SessionStorageProbeCommon.ps1",
    ),
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def helper_text(root: Path, relative_path: str) -> str:
    return (root / relative_path).read_text(encoding="utf-8")


def audit_shared_probe_helpers(root: Path | None = None) -> list[HelperAuditResult]:
    resolved_root = root or repo_root()
    results: list[HelperAuditResult] = []
    for entry in HELPER_AUDIT_TARGETS:
        text = helper_text(resolved_root, entry.relative_path)
        results.append(
            HelperAuditResult(
                name=entry.name,
                relative_path=entry.relative_path,
                explicit_headed=HEADED_MODE_PATTERN.search(text) is not None,
            )
        )
    return results


def missing_explicit_headed_helpers(root: Path | None = None) -> list[HelperAuditResult]:
    return [result for result in audit_shared_probe_helpers(root) if not result.explicit_headed]
