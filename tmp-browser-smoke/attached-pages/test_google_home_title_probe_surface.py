from __future__ import annotations

import unittest
from pathlib import Path


class GoogleHomeTitleProbeSurfaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        cls.probe_path = repo_root / "src/browser/tests/page/google_home_title_probe.html"
        cls.text = cls.probe_path.read_text(encoding="utf-8")

    def assertContains(self, snippet: str) -> None:
        self.assertIn(snippet, self.text)

    def test_probe_keeps_early_event_and_message_buckets(self) -> None:
        self.assertContains("window.__lpEarlyEvents=[];")
        self.assertContains("window.__lpPostMessages=[];")
        self.assertContains("window.__lpMessageEvents=[];")
        self.assertContains("window.__lpListenerAdds=[];")
        self.assertContains("window.__lpAcCalls=[];")

    def test_probe_keeps_listener_registration_capture_filter(self) -> None:
        self.assertContains("type==='keydown'||type==='keypress'||type==='keyup'||type==='focus'||type==='blur'||type==='input'||type==='beforeinput'||type==='submit'||type==='message'")
        self.assertContains("window.__lpListenerAdds.push(type+'@'+target);")

    def test_probe_keeps_title_summary_fields(self) -> None:
        self.assertContains("var summary = lastMark + '|A=' + describeElement(document.activeElement) + '|Q=' + describeElement(currentQ) + '|V=' + value + '|S=' + selection + '|E=' + early;")
        self.assertContains("document.title = summary;")
        self.assertContains("badge.textContent = summary;")

    def test_probe_keeps_query_input_focus_and_text_markers(self) -> None:
        self.assertContains("q.addEventListener('focus', function(){ mark('FOCUSED'); });")
        self.assertContains("q.addEventListener('input', function(){ mark('TYPED:' + q.value); });")
        self.assertContains("mark('BEFOREINPUT:' + (e.data || '') + ':' + q.value);")
        self.assertContains("mark('KEYPRESS:' + (e.key || '') + ':' + q.value);")
        self.assertContains("mark('KEYDOWN:' + q.value + ':' + e.keyCode + ':' + e.which);")
        self.assertContains("mark('KEYDOWN:' + e.key + ':' + q.value);")

    def test_probe_keeps_submit_interception_visible(self) -> None:
        self.assertContains("q.form.addEventListener('submit', function(e){")
        self.assertContains("e.preventDefault();")
        self.assertContains("mark('SUBMIT:' + q.value);")

    def test_probe_keeps_document_level_key_and_focus_traces(self) -> None:
        self.assertContains("mark('DOC-KD:' + describeElement(e.target) + ':' + (e.key || '') + ':' + e.keyCode + ':' + e.which);")
        self.assertContains("mark('DOC-KP:' + describeElement(e.target) + ':' + (e.key || '') + ':' + e.keyCode + ':' + e.which);")
        self.assertContains("mark('DOC-BI:' + describeElement(e.target) + ':' + (e.data || ''));")
        self.assertContains("mark('SEL:' + describeElement(document.activeElement));")
        self.assertContains("mark('FOCUSIN:' + describeElement(e.target));")
        self.assertContains("mark('FOCUSOUT:' + describeElement(e.target));")

    def test_probe_keeps_sync_loop_and_binding_ladder(self) -> None:
        self.assertContains("currentQ = next;")
        self.assertContains("bindQueryInput(currentQ);")
        self.assertContains("mark(currentQ ? 'BOUND' : 'NOQ');")
        self.assertContains("window.setInterval(syncQueryInput, 250);")


if __name__ == "__main__":
    unittest.main()
