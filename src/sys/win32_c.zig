pub const BYTE = u8;
pub const WORD = c_ushort;
pub const SHORT = c_short;
pub const LONG = c_long;
pub const BOOL = c_int;
pub const WINBOOL = c_int;
pub const DWORD = c_ulong;
pub const UINT = c_uint;
pub const UINT32 = c_uint;
pub const UINT64 = c_ulonglong;
pub const INT = c_int;
pub const ULONG = c_ulong;
pub const ULONG_PTR = c_ulonglong;
pub const UINT_PTR = c_ulonglong;
pub const LONG_PTR = c_longlong;
pub const SIZE_T = usize;
pub const HRESULT = LONG;
pub const WPARAM = UINT_PTR;
pub const LPARAM = LONG_PTR;
pub const LRESULT = LONG_PTR;
pub const COLORREF = DWORD;

pub const HANDLE = ?*anyopaque;
pub const PVOID = ?*anyopaque;
pub const LPVOID = ?*anyopaque;
pub const LPUNKNOWN = ?*anyopaque;
pub const LPBINDSTATUSCALLBACK = ?*anyopaque;
pub const WCHAR = u16;
pub const LPCWSTR = [*c]const WCHAR;
pub const LPWSTR = [*c]WCHAR;

pub const struct_HWND__ = opaque {};
pub const struct_HINSTANCE__ = opaque {};
pub const struct_HBITMAP__ = opaque {};
pub const struct_HBRUSH__ = opaque {};
pub const struct_HDC__ = opaque {};
pub const struct_HICON__ = opaque {};
pub const struct_HMENU__ = opaque {};
pub const struct_HFONT__ = opaque {};
pub const struct_HRGN__ = opaque {};

pub const HWND = ?*anyopaque;
pub const HINSTANCE = ?*anyopaque;
pub const HMODULE = HINSTANCE;
pub const HBITMAP = ?*anyopaque;
pub const HBRUSH = ?*anyopaque;
pub const HDC = ?*anyopaque;
pub const HGDIOBJ = ?*anyopaque;
pub const HICON = ?*anyopaque;
pub const HCURSOR = HICON;
pub const HMENU = ?*anyopaque;
pub const HFONT = ?*anyopaque;
pub const HRGN = ?*anyopaque;
pub const HGLOBAL = HANDLE;
pub const HIMC = HANDLE;

pub const GUID = extern struct {
    Data1: c_ulong = 0,
    Data2: c_ushort = 0,
    Data3: c_ushort = 0,
    Data4: [8]u8 = @splat(0),
};

pub const RECT = extern struct {
    left: LONG = 0,
    top: LONG = 0,
    right: LONG = 0,
    bottom: LONG = 0,
};
pub const LPRECT = [*c]RECT;

pub const POINT = extern struct {
    x: LONG = 0,
    y: LONG = 0,
};
pub const LPPOINT = [*c]POINT;

pub const SIZE = extern struct {
    cx: LONG = 0,
    cy: LONG = 0,
};

pub const TEXTMETRICW = extern struct {
    tmHeight: LONG = 0,
    tmAscent: LONG = 0,
    tmDescent: LONG = 0,
    tmInternalLeading: LONG = 0,
    tmExternalLeading: LONG = 0,
    tmAveCharWidth: LONG = 0,
    tmMaxCharWidth: LONG = 0,
    tmWeight: LONG = 0,
    tmOverhang: LONG = 0,
    tmDigitizedAspectX: LONG = 0,
    tmDigitizedAspectY: LONG = 0,
    tmFirstChar: WCHAR = 0,
    tmLastChar: WCHAR = 0,
    tmDefaultChar: WCHAR = 0,
    tmBreakChar: WCHAR = 0,
    tmItalic: BYTE = 0,
    tmUnderlined: BYTE = 0,
    tmStruckOut: BYTE = 0,
    tmPitchAndFamily: BYTE = 0,
    tmCharSet: BYTE = 0,
};

pub const MSG = extern struct {
    hwnd: HWND = null,
    message: UINT = 0,
    wParam: WPARAM = 0,
    lParam: LPARAM = 0,
    time: DWORD = 0,
    pt: POINT = .{},
};
pub const LPMSG = [*c]MSG;

pub const WNDPROC = ?*const fn (HWND, UINT, WPARAM, LPARAM) callconv(.winapi) LRESULT;
pub const WNDCLASSEXW = extern struct {
    cbSize: UINT = 0,
    style: UINT = 0,
    lpfnWndProc: WNDPROC = null,
    cbClsExtra: c_int = 0,
    cbWndExtra: c_int = 0,
    hInstance: HINSTANCE = null,
    hIcon: HICON = null,
    hCursor: HCURSOR = null,
    hbrBackground: HBRUSH = null,
    lpszMenuName: LPCWSTR = null,
    lpszClassName: LPCWSTR = null,
    hIconSm: HICON = null,
};

pub const CREATESTRUCTW = extern struct {
    lpCreateParams: LPVOID = null,
    hInstance: HINSTANCE = null,
    hMenu: HMENU = null,
    hwndParent: HWND = null,
    cy: c_int = 0,
    cx: c_int = 0,
    y: c_int = 0,
    x: c_int = 0,
    style: LONG = 0,
    lpszName: LPCWSTR = null,
    lpszClass: LPCWSTR = null,
    dwExStyle: DWORD = 0,
};

pub const PAINTSTRUCT = extern struct {
    hdc: HDC = null,
    fErase: WINBOOL = 0,
    rcPaint: RECT = .{},
    fRestore: WINBOOL = 0,
    fIncUpdate: WINBOOL = 0,
    rgbReserved: [32]BYTE = @splat(0),
};
pub const LPPAINTSTRUCT = [*c]PAINTSTRUCT;

pub const OPENFILENAMEW = extern struct {
    lStructSize: DWORD = 0,
    hwndOwner: HWND = null,
    hInstance: HINSTANCE = null,
    lpstrFilter: LPCWSTR = null,
    lpstrCustomFilter: LPWSTR = null,
    nMaxCustFilter: DWORD = 0,
    nFilterIndex: DWORD = 0,
    lpstrFile: LPWSTR = null,
    nMaxFile: DWORD = 0,
    lpstrFileTitle: LPWSTR = null,
    nMaxFileTitle: DWORD = 0,
    lpstrInitialDir: LPCWSTR = null,
    lpstrTitle: LPCWSTR = null,
    Flags: DWORD = 0,
    nFileOffset: WORD = 0,
    nFileExtension: WORD = 0,
    lpstrDefExt: LPCWSTR = null,
    lCustData: LPARAM = 0,
    lpfnHook: ?*const anyopaque = null,
    lpTemplateName: LPCWSTR = null,
    pvReserved: ?*anyopaque = null,
    dwReserved: DWORD = 0,
    FlagsEx: DWORD = 0,
};
pub const LPOPENFILENAMEW = [*c]OPENFILENAMEW;

pub const RGBQUAD = extern struct {
    rgbBlue: BYTE = 0,
    rgbGreen: BYTE = 0,
    rgbRed: BYTE = 0,
    rgbReserved: BYTE = 0,
};

pub const BITMAPINFOHEADER = extern struct {
    biSize: DWORD = 0,
    biWidth: LONG = 0,
    biHeight: LONG = 0,
    biPlanes: WORD = 0,
    biBitCount: WORD = 0,
    biCompression: DWORD = 0,
    biSizeImage: DWORD = 0,
    biXPelsPerMeter: LONG = 0,
    biYPelsPerMeter: LONG = 0,
    biClrUsed: DWORD = 0,
    biClrImportant: DWORD = 0,
};

pub const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER = .{},
    bmiColors: [1]RGBQUAD = .{.{}},
};

pub const BLENDFUNCTION = extern struct {
    BlendOp: BYTE = 0,
    BlendFlags: BYTE = 0,
    SourceConstantAlpha: BYTE = 0,
    AlphaFormat: BYTE = 0,
};

pub const ATOM = WORD;

pub const AC_SRC_ALPHA = 0x01;
pub const AC_SRC_OVER = 0x00;
pub const BI_RGB: DWORD = 0;
pub const CF_UNICODETEXT = 13;
pub const CLEARTYPE_QUALITY = 5;
pub const CLIP_DEFAULT_PRECIS = 0;
pub const CS_HREDRAW = 0x0002;
pub const CS_VREDRAW = 0x0001;
pub const CW_USEDEFAULT: c_int = -2147483648;
pub const DEFAULT_CHARSET = 1;
pub const DEFAULT_PITCH = 0;
pub const DIB_RGB_COLORS = 0;
pub const DT_CALCRECT = 0x00000400;
pub const DT_CENTER = 0x00000001;
pub const DT_END_ELLIPSIS = 0x00008000;
pub const DT_LEFT = 0x00000000;
pub const DT_NOPREFIX = 0x00000800;
pub const DT_SINGLELINE = 0x00000020;
pub const DT_TOP = 0x00000000;
pub const DT_VCENTER = 0x00000004;
pub const DT_WORDBREAK = 0x00000010;
pub const ERROR = 0;
pub const ERROR_CLASS_ALREADY_EXISTS: DWORD = 1410;
pub const FALSE = 0;
pub const FF_DECORATIVE = 5 << 4;
pub const FF_DONTCARE = 0 << 4;
pub const FF_MODERN = 3 << 4;
pub const FF_ROMAN = 1 << 4;
pub const FF_SCRIPT = 4 << 4;
pub const FF_SWISS = 2 << 4;
pub const FIXED_PITCH = 1;
pub const GCS_COMPSTR = 0x0008;
pub const GCS_RESULTSTR = 0x0800;
pub const GMEM_MOVEABLE = 0x2;
pub const GWLP_USERDATA = -21;
pub const MA_ACTIVATE = 1;
pub const MAX_PATH = 260;
pub const MK_LBUTTON = 0x0001;
pub const MK_MBUTTON = 0x0010;
pub const MK_RBUTTON = 0x0002;
pub const MK_XBUTTON1 = 0x0020;
pub const MK_XBUTTON2 = 0x0040;
pub const OFN_ALLOWMULTISELECT = 0x200;
pub const OFN_EXPLORER = 0x80000;
pub const OFN_FILEMUSTEXIST = 0x1000;
pub const OFN_NOCHANGEDIR = 0x8;
pub const OFN_PATHMUSTEXIST = 0x800;
pub const OUT_DEFAULT_PRECIS = 0;
pub const PM_REMOVE = 0x0001;
pub const SM_CXSCREEN = 0;
pub const SM_CYSCREEN = 1;
pub const SM_CXFULLSCREEN = 16;
pub const SM_CYFULLSCREEN = 17;
pub const SW_SHOW = 5;
pub const SWP_NOACTIVATE = 0x0010;
pub const SWP_NOMOVE = 0x0002;
pub const SWP_NOOWNERZORDER = 0x0200;
pub const SWP_NOZORDER = 0x0004;
pub const TA_LEFT = 0;
pub const TA_TOP = 0;
pub const TRANSPARENT = 1;
pub const TRUE = 1;
pub const VARIABLE_PITCH = 2;
pub const WA_INACTIVE = 0;
pub const WHEEL_DELTA = 120;
pub const WM_ACTIVATE = 0x0006;
pub const WM_APP = 0x8000;
pub const WM_CAPTURECHANGED = 0x0215;
pub const WM_CHAR = 0x0102;
pub const WM_CLOSE = 0x0010;
pub const WM_DESTROY = 0x0002;
pub const WM_IME_CHAR = 0x0286;
pub const WM_IME_COMPOSITION = 0x010F;
pub const WM_IME_ENDCOMPOSITION = 0x010E;
pub const WM_IME_STARTCOMPOSITION = 0x010D;
pub const WM_KEYDOWN = 0x0100;
pub const WM_KEYUP = 0x0101;
pub const WM_KILLFOCUS = 0x0008;
pub const WM_LBUTTONDOWN = 0x0201;
pub const WM_LBUTTONUP = 0x0202;
pub const WM_MBUTTONDOWN = 0x0207;
pub const WM_MBUTTONUP = 0x0208;
pub const WM_MOUSEACTIVATE = 0x0021;
pub const WM_MOUSEHWHEEL = 0x020e;
pub const WM_MOUSEMOVE = 0x0200;
pub const WM_MOUSEWHEEL = 0x020A;
pub const WM_NCCREATE = 0x0081;
pub const WM_PAINT = 0x000F;
pub const WM_RBUTTONDOWN = 0x0204;
pub const WM_RBUTTONUP = 0x0205;
pub const WM_SETFOCUS = 0x0007;
pub const WM_SYSCHAR = 0x0106;
pub const WM_SYSKEYDOWN = 0x0104;
pub const WM_SYSKEYUP = 0x0105;
pub const WM_UNICHAR = 0x0109;
pub const WM_XBUTTONDOWN = 0x020B;
pub const WM_XBUTTONUP = 0x020C;
pub const WS_CAPTION: DWORD = 0x00C00000;
pub const WS_EX_APPWINDOW: DWORD = 0x00040000;
pub const WS_MINIMIZEBOX: DWORD = 0x00020000;
pub const WS_OVERLAPPED: DWORD = 0;
pub const WS_SYSMENU: DWORD = 0x00080000;
pub const XBUTTON1 = 0x0001;
pub const XBUTTON2 = 0x0002;

pub const VK_ADD = 0x6B;
pub const VK_APPS = 0x5D;
pub const VK_BACK = 0x08;
pub const VK_CAPITAL = 0x14;
pub const VK_CLEAR = 0x0C;
pub const VK_CONTROL = 0x11;
pub const VK_DECIMAL = 0x6E;
pub const VK_DELETE = 0x2E;
pub const VK_DIVIDE = 0x6F;
pub const VK_DOWN = 0x28;
pub const VK_END = 0x23;
pub const VK_ESCAPE = 0x1B;
pub const VK_F1 = 0x70;
pub const VK_F2 = 0x71;
pub const VK_F3 = 0x72;
pub const VK_F4 = 0x73;
pub const VK_F5 = 0x74;
pub const VK_F6 = 0x75;
pub const VK_F7 = 0x76;
pub const VK_F8 = 0x77;
pub const VK_F9 = 0x78;
pub const VK_F10 = 0x79;
pub const VK_F11 = 0x7A;
pub const VK_F12 = 0x7B;
pub const VK_HOME = 0x24;
pub const VK_INSERT = 0x2D;
pub const VK_LCONTROL = 0xA2;
pub const VK_LEFT = 0x25;
pub const VK_LMENU = 0xA4;
pub const VK_LSHIFT = 0xA0;
pub const VK_LWIN = 0x5B;
pub const VK_MENU = 0x12;
pub const VK_MULTIPLY = 0x6A;
pub const VK_NEXT = 0x22;
pub const VK_NUMLOCK = 0x90;
pub const VK_NUMPAD0 = 0x60;
pub const VK_NUMPAD9 = 0x69;
pub const VK_OEM_1 = 0xBA;
pub const VK_OEM_2 = 0xBF;
pub const VK_OEM_3 = 0xC0;
pub const VK_OEM_4 = 0xDB;
pub const VK_OEM_5 = 0xDC;
pub const VK_OEM_6 = 0xDD;
pub const VK_OEM_7 = 0xDE;
pub const VK_OEM_COMMA = 0xBC;
pub const VK_OEM_MINUS = 0xBD;
pub const VK_OEM_PERIOD = 0xBE;
pub const VK_OEM_PLUS = 0xBB;
pub const VK_PAUSE = 0x13;
pub const VK_PRIOR = 0x21;
pub const VK_RCONTROL = 0xA3;
pub const VK_RETURN = 0x0D;
pub const VK_RIGHT = 0x27;
pub const VK_RMENU = 0xA5;
pub const VK_RSHIFT = 0xA1;
pub const VK_RWIN = 0x5C;
pub const VK_SCROLL = 0x91;
pub const VK_SHIFT = 0x10;
pub const VK_SNAPSHOT = 0x2C;
pub const VK_SPACE = 0x20;
pub const VK_SUBTRACT = 0x6D;
pub const VK_TAB = 0x09;
pub const VK_UP = 0x26;

pub inline fn RGB(red: anytype, green: anytype, blue: anytype) COLORREF {
    return @as(COLORREF, @intCast(red)) |
        (@as(COLORREF, @intCast(green)) << 8) |
        (@as(COLORREF, @intCast(blue)) << 16);
}

pub extern fn AddFontMemResourceEx(pFileView: PVOID, cjSize: DWORD, pvResrved: PVOID, pNumFonts: [*c]DWORD) HANDLE;
pub extern fn AdjustWindowRectEx(lpRect: LPRECT, dwStyle: DWORD, bMenu: WINBOOL, dwExStyle: DWORD) WINBOOL;
pub extern fn AlphaBlend(hdcDest: HDC, xoriginDest: c_int, yoriginDest: c_int, wDest: c_int, hDest: c_int, hdcSrc: HDC, xoriginSrc: c_int, yoriginSrc: c_int, wSrc: c_int, hSrc: c_int, ftn: BLENDFUNCTION) WINBOOL;
pub extern fn BeginPaint(hWnd: HWND, lpPaint: LPPAINTSTRUCT) HDC;
pub extern fn CloseClipboard() WINBOOL;
pub extern fn CommDlgExtendedError() DWORD;
pub extern fn CreateCompatibleDC(hdc: HDC) HDC;
pub extern fn CreateDIBSection(hdc: HDC, lpbmi: [*c]const BITMAPINFO, usage: UINT, ppvBits: [*c]?*anyopaque, hSection: HANDLE, offset: DWORD) HBITMAP;
pub extern fn CreateFontW(cHeight: c_int, cWidth: c_int, cEscapement: c_int, cOrientation: c_int, cWeight: c_int, bItalic: DWORD, bUnderline: DWORD, bStrikeOut: DWORD, iCharSet: DWORD, iOutPrecision: DWORD, iClipPrecision: DWORD, iQuality: DWORD, iPitchAndFamily: DWORD, pszFaceName: LPCWSTR) HFONT;
pub extern fn CreateRoundRectRgn(x1: c_int, y1: c_int, x2: c_int, y2: c_int, w: c_int, h: c_int) HRGN;
pub extern fn CreateSolidBrush(color: COLORREF) HBRUSH;
pub extern fn CreateWindowExW(dwExStyle: DWORD, lpClassName: LPCWSTR, lpWindowName: LPCWSTR, dwStyle: DWORD, X: c_int, Y: c_int, nWidth: c_int, nHeight: c_int, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID) HWND;
pub extern fn DefWindowProcW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) LRESULT;
pub extern fn DeleteDC(hdc: HDC) WINBOOL;
pub extern fn DeleteObject(ho: HGDIOBJ) WINBOOL;
pub extern fn DestroyWindow(hWnd: HWND) WINBOOL;
pub extern fn DispatchMessageW(lpMsg: [*c]const MSG) LRESULT;
pub extern fn DrawTextW(hdc: HDC, lpchText: LPCWSTR, cchText: c_int, lprc: LPRECT, format: UINT) c_int;
pub extern fn EmptyClipboard() WINBOOL;
pub extern fn EndPaint(hWnd: HWND, lpPaint: [*c]const PAINTSTRUCT) WINBOOL;
pub extern fn FillRect(hDC: HDC, lprc: [*c]const RECT, hbr: HBRUSH) c_int;
pub extern fn FillRgn(hdc: HDC, hrgn: HRGN, hbr: HBRUSH) WINBOOL;
pub extern fn FrameRect(hDC: HDC, lprc: [*c]const RECT, hbr: HBRUSH) c_int;
pub extern fn FrameRgn(hdc: HDC, hrgn: HRGN, hbr: HBRUSH, w: c_int, h: c_int) WINBOOL;
pub extern fn GetClientRect(hWnd: HWND, lpRect: LPRECT) WINBOOL;
pub extern fn GetClipboardData(uFormat: UINT) HANDLE;
pub extern fn GetCurrentProcessId() DWORD;
pub extern fn GetFocus() HWND;
pub extern fn GetForegroundWindow() HWND;
pub extern fn GetKeyState(nVirtKey: c_int) SHORT;
pub extern fn GetLastError() DWORD;
pub extern fn GetModuleHandleW(lpModuleName: LPCWSTR) HMODULE;
pub extern fn GetOpenFileNameW(arg: LPOPENFILENAMEW) WINBOOL;
pub extern fn GetSystemMetrics(nIndex: c_int) c_int;
pub extern fn GetTextExtentPoint32W(hdc: HDC, lpString: LPCWSTR, c: c_int, psizl: *SIZE) WINBOOL;
pub extern fn GetTextMetricsW(hdc: HDC, lptm: *TEXTMETRICW) WINBOOL;
pub extern fn GetWindowLongPtrW(hWnd: HWND, nIndex: c_int) LONG_PTR;
pub extern fn GlobalAlloc(uFlags: UINT, dwBytes: SIZE_T) HGLOBAL;
pub extern fn GlobalFree(hMem: HGLOBAL) HGLOBAL;
pub extern fn GlobalLock(hMem: HGLOBAL) LPVOID;
pub extern fn GlobalUnlock(hMem: HGLOBAL) WINBOOL;
pub extern fn ImmGetCompositionStringW(himc: HIMC, dwIndex: DWORD, lpBuf: LPVOID, dwBufLen: DWORD) LONG;
pub extern fn ImmGetContext(hwnd: HWND) HIMC;
pub extern fn ImmReleaseContext(hwnd: HWND, himc: HIMC) WINBOOL;
pub extern fn IntersectClipRect(hdc: HDC, left: c_int, top: c_int, right: c_int, bottom: c_int) c_int;
pub extern fn InvalidateRect(hWnd: HWND, lpRect: [*c]const RECT, bErase: WINBOOL) WINBOOL;
pub extern fn IsWindow(hWnd: HWND) WINBOOL;
pub extern fn LineTo(hdc: HDC, x: c_int, y: c_int) WINBOOL;
pub extern fn MoveToEx(hdc: HDC, x: c_int, y: c_int, lppt: LPPOINT) WINBOOL;
pub extern fn OpenClipboard(hWndNewOwner: HWND) WINBOOL;
pub extern fn PeekMessageW(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) WINBOOL;
pub extern fn RegisterClassExW(arg: [*c]const WNDCLASSEXW) ATOM;
pub extern fn ReleaseCapture() WINBOOL;
pub extern fn RemoveFontMemResourceEx(h: HANDLE) WINBOOL;
pub extern fn RestoreDC(hdc: HDC, nSavedDC: c_int) WINBOOL;
pub extern fn SaveDC(hdc: HDC) c_int;
pub extern fn ScreenToClient(hWnd: HWND, lpPoint: LPPOINT) WINBOOL;
pub extern fn SelectObject(hdc: HDC, h: HGDIOBJ) HGDIOBJ;
pub extern fn SetActiveWindow(hWnd: HWND) HWND;
pub extern fn SetBkMode(hdc: HDC, mode: c_int) c_int;
pub extern fn SetCapture(hWnd: HWND) HWND;
pub extern fn SetClipboardData(uFormat: UINT, hMem: HANDLE) HANDLE;
pub extern fn SetConsoleTitleW(console_title: LPCWSTR) WINBOOL;
pub extern fn SetCursor(hCursor: HCURSOR) HCURSOR;
pub extern fn SetFocus(hWnd: HWND) HWND;
pub extern fn SetForegroundWindow(hWnd: HWND) WINBOOL;
pub extern fn SetTextAlign(hdc: HDC, @"align": UINT) UINT;
pub extern fn SetTextCharacterExtra(hdc: HDC, extra: c_int) c_int;
pub extern fn SetTextColor(hdc: HDC, color: COLORREF) COLORREF;
pub extern fn SetTextJustification(hdc: HDC, extra: c_int, count: c_int) WINBOOL;
pub extern fn SetWindowLongPtrW(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) LONG_PTR;
pub extern fn SetWindowPos(hWnd: HWND, hWndInsertAfter: HWND, X: c_int, Y: c_int, cx: c_int, cy: c_int, uFlags: UINT) WINBOOL;
pub extern fn SetWindowTextW(hWnd: HWND, lpString: LPCWSTR) WINBOOL;
pub extern fn ShowWindow(hWnd: HWND, nCmdShow: c_int) WINBOOL;
pub extern fn TextOutW(hdc: HDC, x: c_int, y: c_int, lpString: LPCWSTR, c: c_int) WINBOOL;
pub extern fn TranslateMessage(lpMsg: [*c]const MSG) WINBOOL;
pub extern fn UpdateWindow(hWnd: HWND) WINBOOL;
pub extern fn URLDownloadToCacheFileW(caller: LPUNKNOWN, url: LPCWSTR, file_name: LPWSTR, file_name_len: DWORD, reserved: DWORD, status_callback: LPBINDSTATUSCALLBACK) HRESULT;
