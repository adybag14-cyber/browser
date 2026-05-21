from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from issue3_trace_target_catalog import missing_trace_hints, normalize_trace_text


TRACE_GATE_SOURCES: dict[str, str] = {
    "src/display/win32_backend.zig": "googleInputTraceEnabled",
    "src/lightpanda.zig": "googleRenderTraceEnabled",
}


@dataclass(frozen=True)
class TraceGateSourceAudit:
    relative_path: str
    expected_function: str
    function_present: bool
    missing_hints: tuple[str, ...]


def source_declares_trace_function(path: str | Path, function_name: str) -> bool:
    source_text = Path(path).read_text(encoding="utf-8")
    return normalize_trace_text(f"fn {function_name}(") in normalize_trace_text(source_text)


def audit_trace_gate_source(
    path: str | Path,
    expected_function: str,
    relative_path: str | None = None,
) -> TraceGateSourceAudit:
    source_path = Path(path)
    lines = source_path.read_text(encoding="utf-8").splitlines()
    return TraceGateSourceAudit(
        relative_path=relative_path or source_path.as_posix(),
        expected_function=expected_function,
        function_present=source_declares_trace_function(source_path, expected_function),
        missing_hints=tuple(missing_trace_hints(lines)),
    )


def audit_trace_gate_sources(repo_root: str | Path) -> list[TraceGateSourceAudit]:
    root = Path(repo_root)
    return [
        audit_trace_gate_source(root / relative_path, expected_function, relative_path)
        for relative_path, expected_function in TRACE_GATE_SOURCES.items()
    ]


def failing_trace_gate_sources(repo_root: str | Path) -> list[TraceGateSourceAudit]:
    return [
        audit
        for audit in audit_trace_gate_sources(repo_root)
        if (not audit.function_present) or audit.missing_hints
    ]
