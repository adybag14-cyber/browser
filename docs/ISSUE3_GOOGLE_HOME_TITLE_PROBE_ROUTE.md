# Issue 3 Google Home Title Probe Route

Use this note when issue `#3` is already narrowed past the shared
`tmp-browser-smoke/form-controls/enter-submit-probe.ps1` ladder but is not yet
ready to jump back to the full live `https://www.google.com/` replay.

This route keeps the replay on the branch-local reduced Google fixture:

- `src/browser/tests/page/google_home_title_probe.html`

That fixture is the smallest branch-owned page that still preserves the
Google-shaped focus, type, and Enter-submit path. It also stamps the active
runtime state into the document title so headed runs can be triaged without
guessing.

## When To Use This Route

Use this route when one of these is true:

- the shared Enter-submit ladder is green but live Google still drops typed
  text or submit behavior
- a change touched `src/browser/Page.zig` or `src/display/win32_backend.zig`
  and you need a smaller Google-shaped checkpoint before widening out
- a headed replay needs to prove whether the failure boundary is focus,
  keyboard text insertion, or Enter dispatch

Do not start here when the simpler shared form-controls ladder is still red.
Re-open `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` first in that case.

## Fast Re-entry Order

Run the replay in this order:

1. Reconfirm the shared baseline first:
   - `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1`
   - `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder`
   - `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus`
2. Re-open the reduced Google fixture path:
   - `zig test src/browser/Page.zig --test-filter "Page reduced Google fixture accepts focused keyboard text and Enter submit"`
3. Only widen back out after the reduced fixture gives a stable answer:
   - first to the attached-page replay ladder under `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
   - then to the live Google homepage headed replay

If Linux or WSL toolchain staging is the blocker before the filtered Zig test
can run, reopen `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md` before treating
the issue as a new runtime regression.

## What The Fixture Proves

The reduced fixture is intentionally small, but it still checks the core
issue `#3` event chain:

- the Google-shaped query field is focused on load
- a printable key reaches `keydown`, `keypress`, `beforeinput`, and `input`
- the query value changes after text insertion
- Enter reaches the same form and produces a title that begins with `SUBMIT:`

The corresponding branch test already lives in `src/browser/Page.zig` as:

- `test "Page reduced Google fixture accepts focused keyboard text and Enter submit"`

Treat that test as the smallest owned checkpoint before the replay widens back
out to localhost bundles or the live homepage.

## Title And Badge Readout

`src/browser/tests/page/google_home_title_probe.html` mirrors the current
runtime state into both the document title and the on-page badge. The summary
format is:

- `<MARK>|A=<active-element>|Q=<query-element>|V=<query-value>|S=<selection>|E=<last-early-event>`

The most useful marks are:

- `BOUND`: the probe found the current `document.forms.f.q` field
- `FOCUSIN:...` or `FOCUSED`: focus reached the query field
- `KEYDOWN:<key>:<value>`: the keydown path reached the field
- `BEFOREINPUT:<data>:<value>`: editable text insertion is about to land
- `TYPED:<value>`: the query field accepted text
- `SUBMIT:<value>`: the form submit handler ran on the reduced fixture
- `ERR:...` or `REJ:...`: the page hit a script error or unhandled rejection

The early-event suffix is the fastest way to tell which DOM event was last seen
by the reduced page:

- `KD:` means the last captured early event was `keydown`
- `KP:` means the last captured early event was `keypress`
- `BI:` means the last captured early event was `beforeinput`
- `IN:` means the last captured early event was `input`

## How To Read Failures Quickly

Use this table when the reduced probe stops short of `SUBMIT:`:

- `BOUND` never appears:
  The page never rebound the Google-shaped `q` field. Check whether the fixture
  script ran and whether the query control moved or was replaced unexpectedly.
- `FOCUSIN` is missing or `A=` never points at the query field:
  The failure is still on the focus or activation boundary. Re-check the
  click-focus path before blaming text insertion.
- `KD:` or `KP:` appears but `V=` stays empty:
  Keyboard dispatch reached the page, but text insertion did not commit into
  the field. Re-check the text-input path in `src/display/win32_backend.zig`.
- `BI:` appears without a matching `IN:`:
  `beforeinput` fired but the DOM value update or input event path still broke.
  Re-check the edit command path in `src/browser/Page.zig`.
- `TYPED:` appears but `SUBMIT:` never follows after Enter:
  Text insertion worked, but the Enter-submit path is still broken. Re-open the
  deferred or Google-order submit path before widening out.
- `ERR:` or `REJ:` appears first:
  Treat the page script failure as the first regression boundary, not the later
  input symptom.

## Widen-Back Rule

Keep the replay on this reduced fixture until it can answer one of these
questions cleanly:

- focus fails before any typed text reaches the field
- typed text fails before the field value changes
- the field value changes but Enter still does not submit
- the reduced fixture is green and the remaining failure only reproduces on the
  attached-page or live Google routes

Only after one of those answers is stable should the run widen back out to the
attached HTML bundle or the live homepage.
