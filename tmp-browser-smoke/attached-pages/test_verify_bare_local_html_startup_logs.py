from __future__ import annotations

import pathlib
import sys
import tempfile
import textwrap
import unittest

HERE = pathlib.Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from verify_bare_local_html_startup_logs import (
    DEFAULT_EXPECTATIONS,
    extract_startup_records,
    load_records_from_path,
    validate_records,
)


class VerifyBareLocalHtmlStartupLogsTest(unittest.TestCase):
    def test_extract_startup_records_keeps_target_fields(self) -> None:
        text = textwrap.dedent(
            """
            level=DEBUG msg=startup mode=browse url=attached-page.html target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=INFO msg="browse headed runtime" url=localhost:8123/attached-page.html target_scheme=implicit_http target_scope=loopback target_host=localhost target_port=8123
            level=INFO msg="browse finished" url=example.com/attached-page.html target_scheme=implicit_http target_scope=remote target_host=example.com target_port="(default)"
            """
        ).strip()

        records = extract_startup_records(text, "<memory>")

        self.assertEqual(
            [
                ("attached-page.html", "path", "local_path"),
                ("localhost:8123/attached-page.html", "implicit_http", "loopback"),
                ("example.com/attached-page.html", "implicit_http", "remote"),
            ],
            [(record.url, record.target_scheme, record.target_scope) for record in records],
        )

    def test_validate_records_reports_misclassified_bare_local_html(self) -> None:
        text = textwrap.dedent(
            """
            level=DEBUG msg=startup mode=browse url=attached-page.html target_scheme=implicit_http target_scope=remote target_host=attached-page.html target_port="(default)"
            level=DEBUG msg=startup mode=browse url=attached-page.html?case=1 target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=attached-page.xhtml#focus-probe target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=report.v1.html target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=report.v1.xhtml#focus-probe target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=localhost:8123/attached-page.html target_scheme=implicit_http target_scope=loopback target_host=localhost target_port=8123
            level=DEBUG msg=startup mode=browse url=example.com/attached-page.html target_scheme=implicit_http target_scope=remote target_host=example.com target_port="(default)"
            """
        ).strip()

        failures = validate_records(extract_startup_records(text, "<memory>"), DEFAULT_EXPECTATIONS)

        self.assertEqual(1, len(failures))
        self.assertIn("attached-page.html expected path/local_path", failures[0])

    def test_load_records_from_path_supports_file_inputs(self) -> None:
        text = textwrap.dedent(
            """
            level=DEBUG msg=startup mode=browse url=attached-page.html target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=attached-page.html?case=1 target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=attached-page.xhtml#focus-probe target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=report.v1.html target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=report.v1.xhtml#focus-probe target_scheme=path target_scope=local_path target_host="(none)" target_port="(none)"
            level=DEBUG msg=startup mode=browse url=localhost:8123/attached-page.html target_scheme=implicit_http target_scope=loopback target_host=localhost target_port=8123
            level=DEBUG msg=startup mode=browse url=example.com/attached-page.html target_scheme=implicit_http target_scope=remote target_host=example.com target_port="(default)"
            """
        ).strip()

        with tempfile.TemporaryDirectory() as temp_dir:
            path = pathlib.Path(temp_dir) / "startup.log"
            path.write_text(text, encoding="utf-8")
            records = load_records_from_path(path)

        self.assertEqual(7, len(records))
        self.assertEqual([], validate_records(records))


if __name__ == "__main__":
    unittest.main()
