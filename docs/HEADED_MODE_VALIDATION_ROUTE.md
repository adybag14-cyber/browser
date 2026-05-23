# Headed Mode Validation Route Helper

Use `scripts/show_headed_validation_route.py` when a headed-mode change is
small enough that the next question is "which probe families do I run now?"

Examples:

```bash
python scripts/show_headed_validation_route.py --list-areas
python scripts/show_headed_validation_route.py --area text-input-ime
python scripts/show_headed_validation_route.py --path src/display/win32_backend.zig
python scripts/show_headed_validation_route.py --path src/browser/Page.zig --path src/http/Client.zig
```

What the helper does:

- maps common headed subsystems to the bounded `tmp-browser-smoke/` suites that
  should run next
- recognizes representative ownership paths such as `src/display/`,
  `src/render/`, `src/browser/Page.zig`, `src/http/`, and storage/file
  handling surfaces
- prints the release-build route for changes that affect packaging, build-cache
  recovery, or packaged binary validation

What it does not do:

- replace the production execution guide
- prove that the selected suites are green
- choose Windows-only manual steps for you when the change needs a real headed
  session

Use this helper as the fast entry point, then open
`docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md` for the deeper gate or
acceptance context.
