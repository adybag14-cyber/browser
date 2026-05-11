# Google Homepage Input Probe

This probe family gives issue `#3` a bounded localhost reproduction that
matches the real headed Google path more closely than the generic form-control
checks.

What it covers:
- click-to-focus on a Google-style search field
- legacy named form/control access through `document.f` and `form.q`
- visible typed-text confirmation before submit
- Enter submit with captured `keydown`, `keypress`, and final submitted value

Files:
- `google_home_input_server.py`: localhost harness that serves the Google-like
  page and logs the submitted query plus key/input state
- `google-homepage-input-probe.ps1`: headed Win32 probe that clicks the search
  field, types `Q`, presses Enter, and expects the typed query to survive into
  the final navigation

Suggested usage:
- run this after changing headed text input, focus, Enter submit ordering, or
  Google-specific regressions in the Win32 path
- pair it with `tmp-browser-smoke/form-controls/` because the simpler form
  probes still catch baseline regressions earlier
