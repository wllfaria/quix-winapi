///! Some of the Console API functions on windows are not yet on kernel32 module
///! on the standard library, this is a ffi that shall be deleted once those
///! functions are available
const std = @import("std");
const windows = std.os.windows;

pub const HKL = *opaque {};

const structs = @import("structs.zig");
pub const INPUT_RECORD = structs.INPUT_RECORD;
pub const INPUT_RECORD_EVENT = structs.INPUT_RECORD_EVENT;
pub const KEY_EVENT_RECORD = structs.KEY_EVENT_RECORD;
pub const KEY_EVENT_UCHAR = structs.KEY_EVENT_UCHAR;
pub const MENU_EVENT_RECORD = structs.MENU_EVENT_RECORD;
pub const MOUSE_EVENT_RECORD = structs.MOUSE_EVENT_RECORD;
pub const WINDOW_BUFFER_SIZE_RECORD = structs.WINDOW_BUFFER_SIZE_RECORD;
pub const FOCUS_EVENT_RECORD = structs.FOCUS_EVENT_RECORD;

pub extern "kernel32" fn CreateConsoleScreenBuffer(
    dwDesiredAccess: windows.DWORD,
    dwShareMode: windows.DWORD,
    lpSecurityAttributes: ?*const windows.SECURITY_ATTRIBUTES,
    dwFlags: windows.DWORD,
    lpScreenBufferData: ?*const anyopaque,
) callconv(windows.WINAPI) windows.HANDLE;

pub extern "kernel32" fn SetConsoleActiveScreenBuffer(
    hConsoleOutput: windows.HANDLE,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn SetConsoleWindowInfo(
    hConsoleOutput: windows.HANDLE,
    bAbsolute: windows.BOOL,
    small_rect: *const windows.SMALL_RECT,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn ReadConsoleInputW(
    hConsoleInput: windows.HANDLE,
    lpBuffer: [*]structs.INPUT_RECORD,
    nLength: windows.DWORD,
    lpNumberOfEventsRead: *windows.DWORD,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn GetNumberOfConsoleInputEvents(
    hConsoleInput: windows.HANDLE,
    lpcNumberOfEvents: *windows.DWORD,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn SetConsoleCursorInfo(
    hConsoleOutput: windows.HANDLE,
    lpConsoleCursorInfo: *const structs.CONSOLE_CURSOR_INFO,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn PeekNamedPipe(
    hNamedPipe: windows.HANDLE,
    lpBuffer: ?windows.LPVOID,
    nBufferSize: windows.DWORD,
    lpBytesRead: ?*windows.DWORD,
    lpTotalBytesAvail: ?*windows.DWORD,
    lpBytesLeftThisMessage: ?*windows.DWORD,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn PeekConsoleInput(
    hConsoleInput: windows.HANDLE,
    lpBuffer: [*]structs.INPUT_RECORD,
    nLength: windows.DWORD,
    lpNumberOfEventsRead: *windows.DWORD,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn SetConsoleScreenBufferSize(
    hConsoleOutput: windows.HANDLE,
    dwSize: windows.COORD,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn GetLargestConsoleWindowSize(
    hConsoleOutput: windows.HANDLE,
) callconv(windows.WINAPI) windows.COORD;

pub extern "user32" fn GetForegroundWindow() callconv(windows.WINAPI) windows.HWND;

pub extern "user32" fn GetWindowThreadProcessId(
    hWnd: windows.HWND,
    lpdwProcessId: ?*windows.DWORD,
) callconv(windows.WINAPI) windows.DWORD;

pub extern "user32" fn GetKeyboardLayout(
    idThread: windows.DWORD,
) callconv(windows.WINAPI) HKL;

pub extern "user32" fn ToUnicodeEx(
    wVirtKey: windows.UINT,
    wScanCode: windows.UINT,
    lpKeyState: [*]const windows.BYTE,
    pwszBuff: windows.LPWSTR,
    cchBuff: windows.INT,
    wFlags: windows.UINT,
    dwhkl: HKL,
) callconv(windows.WINAPI) windows.INT;

pub extern "kernel32" fn FillConsoleOutputCharacterA(
    hConsoleOutput: windows.HANDLE,
    cCharacter: windows.CHAR,
    nLength: windows.DWORD,
    dwWriteCoord: windows.COORD,
    lpNumberOfCharsWritten: *windows.DWORD,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn FillConsoleOutputAttribute(
    hConsoleOutput: windows.HANDLE,
    wAttribute: windows.WORD,
    nLength: windows.DWORD,
    dwWriteCoord: windows.COORD,
    lpNumberOfAttrsWritten: *windows.DWORD,
) callconv(windows.WINAPI) windows.BOOL;
