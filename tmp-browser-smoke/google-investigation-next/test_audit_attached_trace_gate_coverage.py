#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


MODULE_PATH = pathlib.Path(__file__).with_name("audit_attached_trace_gate_coverage.py")
SPEC = importlib.util.spec_from_file_location("audit_attached_trace_gate_coverage", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class AttachedTraceGateAuditTests(unittest.TestCase):
    def test_extract_function_body_returns_nested_body(self) -> None:
        source = """
fn sample() bool {
    if (true) {
        return true;
    }
    return false;
}
"""
        body = MODULE.extract_function_body(source, "sample")
        self.assertIn("return true;", body)
        self.assertIn("return false;", body)

    def test_extract_string_literals_returns_unique_literals(self) -> None:
        body = 'return helper("alpha") or helper("beta") or helper("alpha");'
        self.assertEqual(
            MODULE.extract_string_literals(body),
            {"alpha", "beta"},
        )


if __name__ == "__main__":
    unittest.main()
