import unittest

from check_issue3_enter_submit_runtime_contract import analyze_runtime_contract


class EnterSubmitRuntimeContractTests(unittest.TestCase):
    def test_vulnerable_samples_fail(self) -> None:
        page = """
_keyboard_text_suppression_depth: u32 = 0,
else => return self.submitForm(input.asElement(), input.getForm(self), .{}),
"""
        win32 = """
pending_text_input_suppressions: u32 = 0,
self.pending_text_input_suppressions +|= 1;
if (self.pending_text_input_suppressions > 0) {
"""
        failures = analyze_runtime_contract(page, win32)
        self.assertTrue(failures)
        self.assertTrue(any("Page.zig" in failure for failure in failures))
        self.assertTrue(any("win32_backend.zig" in failure for failure in failures))

    def test_fixed_samples_pass(self) -> None:
        page = """
_keyboard_text_suppression_depth: u32 = 0,
_defer_native_text_input_enter_submit: bool = false,
_pending_native_enter_submit: ?*Element.Html.Input = null,
pub fn beginDeferredNativeTextInputEnterSubmit(self: *Page) void {
}
pub fn endDeferredNativeTextInputEnterSubmit(self: *Page) void {
}
pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {
}
if (self._defer_native_text_input_enter_submit) {
    self._pending_native_enter_submit = input;
    return;
}
"""
        win32 = """
pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},
self.pending_text_input_suppressions.deinit(self.allocator);
const defer_enter_submit = std.mem.eql(u8, key, "Enter");
page.beginDeferredNativeTextInputEnterSubmit();
page.endDeferredNativeTextInputEnterSubmit();
if (defer_enter_submit and allow_text_input) {
    try page.applyDeferredNativeTextInputEnterSubmit();
}
queuePendingTextInputSuppression(self, key);
if (shouldSuppressPendingTextInput(self, text_input.bytes[0..text_input.len])) {
    continue;
}
fn queuePendingTextInputSuppression(self: *Win32Backend, bytes: []const u8) void {
}
fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {
    return true;
}
"""
        self.assertEqual([], analyze_runtime_contract(page, win32))


if __name__ == "__main__":
    unittest.main()
