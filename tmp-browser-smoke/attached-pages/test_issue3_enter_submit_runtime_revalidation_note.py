import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md": """# Issue #3 Enter-Submit Runtime Revalidation

Keep these nearby:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `src/browser/tests/page/google_home_title_probe.html`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

## Target `Page.zig` slice

- add a small deferred-submit state on `Page`
  - `_defer_native_text_input_enter_submit: bool`
  - `_pending_native_enter_submit: ?*Element.Html.Input`
- add three focused helpers
  - `beginDeferredNativeTextInputEnterSubmit()`
  - `endDeferredNativeTextInputEnterSubmit()`
  - `applyDeferredNativeTextInputEnterSubmit()`
- in the Enter activation path for text-like inputs, queue the focused input when deferred native Enter submit is active instead of calling `submitForm(...)` immediately
- when the deferred submit is later applied, confirm the same input is still focused before submitting its form

## Target `win32_backend.zig` slice

- replace the scalar `pending_text_input_suppressions` counter with a queued `std.ArrayListUnmanaged(TextInputEvent)`
- start deferred native Enter submit before the synthetic keypress phase for Enter and end it afterward
- when Enter was allowed, apply the deferred submit after the keypress phase completes
- queue printable-key suppression by exact text bytes instead of by count only
- suppress later `text_input` only when the queued bytes match
- clear stale queued suppressions when later text does not match, so real text is not dropped by an old entry

## Windows replay route

Use the normal Windows headed build and then prefer the smaller Google title probe before jumping straight back to the live homepage:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1
```

If the reduced Google fixture is already the chosen replay surface, keep this nearby too:

```powershell
.\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

Only jump to the real homepage after the reduced probe shows the keydown, typing, and submit boundary behaving in the right order.

## Expected signals

- printable keydown and keypress land text in the focused query input
- Enter keydown alone does not force an early submit title transition
- the later Enter keypress phase is what allows the submit transition
- later `text_input` remains available when stale suppression bytes do not match

## Practical rule

Prefer landing this exact runtime slice from a writable checkout of `fork/headed-mode-foundation`.
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runtime-note-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return root


class Issue3EnterSubmitRuntimeRevalidationNoteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.note = read_text(
            cls.repo_root / "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        )

    def test_note_keeps_core_runtime_targets_and_probe_inputs(self) -> None:
        expected_fragments = (
            "`src/browser/Page.zig`",
            "`src/display/win32_backend.zig`",
            "`tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`",
            "`src/browser/tests/page/google_home_title_probe.html`",
            "`docs/WINDOWS_FULL_USE.md`",
            "`docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.note)

    def test_note_keeps_deferred_submit_page_slice(self) -> None:
        expected_fragments = (
            "_defer_native_text_input_enter_submit: bool",
            "_pending_native_enter_submit: ?*Element.Html.Input",
            "beginDeferredNativeTextInputEnterSubmit()",
            "endDeferredNativeTextInputEnterSubmit()",
            "applyDeferredNativeTextInputEnterSubmit()",
            "queue the focused input when deferred native Enter submit is active",
            "confirm the same input is still focused before submitting its form",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.note)

    def test_note_keeps_win32_byte_matched_suppression_slice(self) -> None:
        expected_fragments = (
            "std.ArrayListUnmanaged(TextInputEvent)",
            "start deferred native Enter submit before the synthetic keypress phase for Enter and end it afterward",
            "apply the deferred submit after the keypress phase completes",
            "queue printable-key suppression by exact text bytes instead of by count only",
            "suppress later `text_input` only when the queued bytes match",
            "clear stale queued suppressions when later text does not match",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.note)

    def test_note_keeps_reduced_probe_before_real_homepage_rule(self) -> None:
        expected_fragments = (
            "prefer the smaller Google title probe before jumping straight back to the live homepage",
            "zig build -Dtarget=x86_64-windows-msvc --summary all",
            "chrome-google-home-title-probe.ps1",
            "lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1",
            "Only jump to the real homepage after the reduced probe shows the keydown, typing, and submit boundary behaving in the right order.",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.note)

    def test_note_keeps_expected_signals_and_practical_rule(self) -> None:
        expected_fragments = (
            "printable keydown and keypress land text in the focused query input",
            "Enter keydown alone does not force an early submit title transition",
            "the later Enter keypress phase is what allows the submit transition",
            "later `text_input` remains available when stale suppression bytes do not match",
            "Prefer landing this exact runtime slice from a writable checkout of `fork/headed-mode-foundation`.",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.note)


if __name__ == "__main__":
    unittest.main()
