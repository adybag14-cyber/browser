import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_NOTE = """# Google Form-Controls Enter-Order Validation

Use this note when issue `#3` has already been narrowed to the smallest shared
Enter-order checkpoint and you want one read-first guide for the dedicated
form-controls gate before widening back out to the broader shared ladder.

## Read the trace guide first

Use the quick diagnosis helper after the surface check when you want the
dedicated marker meanings printed before or after a rerun:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1
```

## Fastest bounded runner

When you want the narrowest reusable shared gate in one command, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1
```

## Raw probe fallback

When you need the exact underlying probe surface without the wrapper layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\google-enter-order-probe.ps1
```

Prefer the wrapper unless you specifically need the raw script entrypoint.

## Exact evidence to keep

- `clicked_worked = true` and `typed_worked = true`
- `keydown_held_without_submit = true`
- `submit_phase = keypress`
- `submit_after_keydown = true`
- `submit_after_keypress = true`
- `submit_record` includes `phase=keypress`
- `event_log` contains `FOCUS`, `KD:Enter:<text>`, `KP:Enter:<text>`, and `SUBMIT:<text>` in that order

## When to widen again

- use `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1` when you want the wider shared Enter-order ladder printed again
- use `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_shared_enter_order_validation.ps1` when you want the reduced homepage, localhost wrapper, and shared Enter-order phases back on one command surface
- use `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1` when the next question is the later saved-homepage-fixture and submit-timing handoff
- use `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1` only after the shared Enter-order stack is green again and the current run already has Google-like HTML snapshots
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-form-controls-note-"))
    note_path = root / "docs" / "GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md"
    note_path.parent.mkdir(parents=True, exist_ok=True)
    note_path.write_text(FIXTURE_NOTE, encoding="utf-8")
    return root


class GoogleFormControlsEnterOrderValidationNoteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]
        cls.note = read_text(cls.repo_root / "docs" / "GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md")

    def test_note_keeps_issue3_narrowing_and_trace_guide(self) -> None:
        self.assertIn("issue `#3`", self.note)
        self.assertIn("smallest shared", self.note)
        self.assertIn(
            ".\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1",
            self.note,
        )

    def test_note_keeps_wrapper_and_raw_probe_guidance(self) -> None:
        self.assertIn(
            ".\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1",
            self.note,
        )
        self.assertIn(
            ".\\tmp-browser-smoke\\form-controls\\google-enter-order-probe.ps1",
            self.note,
        )
        self.assertIn("Prefer the wrapper unless you specifically need the raw script entrypoint.", self.note)

    def test_note_keeps_exact_enter_order_evidence_markers(self) -> None:
        expected_markers = (
            "clicked_worked = true",
            "typed_worked = true",
            "keydown_held_without_submit = true",
            "submit_phase = keypress",
            "submit_after_keydown = true",
            "submit_after_keypress = true",
            "phase=keypress",
            "FOCUS",
            "KD:Enter:<text>",
            "KP:Enter:<text>",
            "SUBMIT:<text>",
        )
        for marker in expected_markers:
            self.assertIn(marker, self.note)

    def test_note_keeps_widening_commands(self) -> None:
        expected_commands = (
            ".\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1",
            ".\\scripts\\windows\\run_google_shared_enter_order_validation.ps1",
            ".\\scripts\\windows\\show_google_submit_path_validation_flow.ps1",
            ".\\scripts\\windows\\show_google_attached_html_validation_flow.ps1",
        )
        for command in expected_commands:
            self.assertIn(command, self.note)


if __name__ == "__main__":
    unittest.main()
