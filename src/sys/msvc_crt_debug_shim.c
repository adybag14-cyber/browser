// Debug-MSVC compatibility for prebuilt V8.
//
// V8's Win32 debug platform configures the MSVC CRT report destinations with
// _CrtSetReportMode/_CrtSetReportFile. Zig's MSVC Debug executable otherwise
// links the release UCRT, and linking the whole debug UCRT causes duplicate
// runtime symbols. These calls only configure diagnostic routing; V8 ignores
// their return values. Keeping tiny local definitions avoids mixing CRTs while
// preserving the intended no-op-safe debug behavior.

#if defined(_MSC_VER)
int _CrtSetReportMode(int report_type, int report_mode) {
    (void)report_type;
    return report_mode;
}

void *_CrtSetReportFile(int report_type, void *report_file) {
    (void)report_type;
    return report_file;
}
#endif
