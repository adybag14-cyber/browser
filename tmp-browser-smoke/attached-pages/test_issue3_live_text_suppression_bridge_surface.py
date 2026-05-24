from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "src/browser/Page.zig": """
    _keyboard_text_suppression_depth: u32 = 0,

    pub fn triggerKeyboardKeyDownNoTextWithCodeAndRepeat(
        self: *Page,
        key: []const u8,
        code: ?[]const u8,
        modifiers: Event.KeyboardModifierSet,
        repeat: bool,
    ) !bool {
        self._keyboard_text_suppression_depth += 1;
        defer self._keyboard_text_suppression_depth -= 1;
    }

    pub fn triggerKeyboardKeyPressWithCode(
        self: *Page,
        key: []const u8,
        code: ?[]const u8,
        modifiers: Event.KeyboardModifierSet,
        repeat: bool,
    ) !bool {}

    const suppress_text = self._keyboard_text_suppression_depth > 0;

    // Handle printable characters
    if (!suppress_text and key.isPrintable() and !blocksTextInsertion(keyboard_event)) {
        try input.innerInsert(key.asString(), self);
    }
    """,
    "src/display/win32_backend.zig": """
    pending_text_input_suppressions: u32 = 0,

    if (emitsTextInput(key, key_down.modifiers)) {
        if (allow_text_input) {
            try page.insertText(key);
        }
        self.pending_text_input_suppressions +|= 1;
    }

    if (self.pending_text_input_suppressions > 0) {
        self.pending_text_input_suppressions -= 1;
        continue;
    }

    self.pending_text_input_suppressions = 0;

    test \"win32 dispatchInput suppresses later text_input after printable keydown across batches\" {
        try std.testing.expectEqual(@as(u32, 1), backend.pending_text_input_suppressions);
        queueTextFromUtf16Unit(&backend, 'a');
        try std.testing.expect(try backend.dispatchInput(page));
        try testing.expectString(\"a\", input.getValue());
        try std.testing.expectEqual(@as(u32, 0), backend.pending_text_input_suppressions);
    }
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-live-text-suppression-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3LiveTextSuppressionBridgeSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.page_source = read_text(cls.repo_root / "src/browser/Page.zig")
        cls.win32_source = read_text(cls.repo_root / "src/display/win32_backend.zig")

    def test_page_source_keeps_keyboard_text_suppression_depth_bridge(self) -> None:
        for fragment in (
            "_keyboard_text_suppression_depth: u32 = 0,",
            "self._keyboard_text_suppression_depth += 1;",
            "defer self._keyboard_text_suppression_depth -= 1;",
            "const suppress_text = self._keyboard_text_suppression_depth > 0;",
            "// Handle printable characters",
            "if (!suppress_text and key.isPrintable() and !blocksTextInsertion(keyboard_event)) {",
            "try input.innerInsert(key.asString(), self);",
        ):
            self.assertIn(fragment, self.page_source)

    def test_win32_source_keeps_counter_based_text_suppression_bridge(self) -> None:
        for fragment in (
            "pending_text_input_suppressions: u32 = 0,",
            "self.pending_text_input_suppressions +|= 1;",
            "if (self.pending_text_input_suppressions > 0) {",
            "self.pending_text_input_suppressions -= 1;",
            "self.pending_text_input_suppressions = 0;",
        ):
            self.assertIn(fragment, self.win32_source)

    def test_win32_source_keeps_the_cross_batch_regression_probe(self) -> None:
        for fragment in (
            'test "win32 dispatchInput suppresses later text_input after printable keydown across batches" {',
            "try std.testing.expectEqual(@as(u32, 1), backend.pending_text_input_suppressions);",
            "queueTextFromUtf16Unit(&backend, 'a');",
            "try std.testing.expect(try backend.dispatchInput(page));",
            'try testing.expectString("a", input.getValue());',
            "try std.testing.expectEqual(@as(u32, 0), backend.pending_text_input_suppressions);",
        ):
            self.assertIn(fragment, self.win32_source)


if __name__ == "__main__":
    unittest.main()
