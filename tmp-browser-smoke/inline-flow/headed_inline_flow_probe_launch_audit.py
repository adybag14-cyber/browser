from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ProbeExpectation:
    filename: str
    expected_url: str


PROBE_EXPECTATIONS = (
    ProbeExpectation(
        filename="chrome-inline-checkbox-button-link-probe.ps1",
        expected_url='"http://127.0.0.1:$port/checkbox-button-link.html"',
    ),
    ProbeExpectation(
        filename="chrome-inline-radio-button-link-probe.ps1",
        expected_url='"http://127.0.0.1:$port/radio-button-link.html"',
    ),
    ProbeExpectation(
        filename="chrome-inline-checkbox-pair-button-link-probe.ps1",
        expected_url='"http://127.0.0.1:$port/checkbox-pair-button-link.html"',
    ),
)

EXPLICIT_HEADED_LAUNCH_SNIPPET = '"browse","--browser_mode","headed",'


@dataclass(frozen=True)
class ProbeAuditResult:
    filename: str
    has_explicit_headed_launch: bool
    has_expected_url: bool


def audit_inline_flow_probe_launches(root: Path) -> list[ProbeAuditResult]:
    results: list[ProbeAuditResult] = []
    for expectation in PROBE_EXPECTATIONS:
        script = (root / expectation.filename).read_text(encoding="utf-8")
        results.append(
            ProbeAuditResult(
                filename=expectation.filename,
                has_explicit_headed_launch=EXPLICIT_HEADED_LAUNCH_SNIPPET in script,
                has_expected_url=expectation.expected_url in script,
            )
        )
    return results


def summarize_missing_contracts(root: Path) -> list[str]:
    missing: list[str] = []
    for result in audit_inline_flow_probe_launches(root):
        if not result.has_explicit_headed_launch:
            missing.append(f"{result.filename}: missing explicit headed browse launch")
        if not result.has_expected_url:
            missing.append(f"{result.filename}: missing expected localhost page target")
    return missing
