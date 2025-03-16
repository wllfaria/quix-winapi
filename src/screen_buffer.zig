const std = @import("std");
const windows = std.os.windows;
const DWORD = windows.DWORD;
const HANDLE = windows.HANDLE;

const ConsoleError = @import("main.zig").ConsoleError;
const ffi = @import("ffi/ffi.zig");
const Handle = @import("handle.zig").Handle;
const quix_winapi = @import("main.zig");

pub const ScreenBuffer = struct {
    handle: Handle,

    /// Activates this screen buffer, making it the visible console output.
    ///
    /// **Errors:**
    /// - `FailedToShowScreenBuffer`: If the system call to activate the buffer fails.
    pub fn show(self: @This()) ConsoleError!void {
        const result = ffi.SetConsoleActiveScreenBuffer(self.handle.inner);
        if (result == 0) return ConsoleError.FailedToShowScreenBuffer;
    }
};

/// Creates a new console screen buffer. This must be manually activated through
/// `show` method.
///
/// **Errors:**
/// - `FailedToCreateScreenBuffer`: If the system call to create the buffer fails.
pub fn create() ConsoleError!ScreenBuffer {
    const security_attrs = windows.SECURITY_ATTRIBUTES{
        .nLength = @as(DWORD, @sizeOf(windows.SECURITY_ATTRIBUTES)),
        .lpSecurityDescriptor = null,
        .bInheritHandle = windows.TRUE,
    };

    const new_screen_buffer = ffi.CreateConsoleScreenBuffer(
        windows.GENERIC_READ | windows.GENERIC_WRITE,
        windows.FILE_SHARE_READ | windows.FILE_SHARE_WRITE,
        &security_attrs,
        quix_winapi.CONSOLE_TEXTMODE_BUFFER,
        null,
    );

    if (new_screen_buffer == windows.INVALID_HANDLE_VALUE) {
        return ConsoleError.FailedToCreateScreenBuffer;
    }

    return ScreenBuffer{ .handle = Handle{
        .inner = new_screen_buffer,
        .is_exclusive = true,
    } };
}

pub fn fromHandle(handle: Handle) ScreenBuffer {
    return ScreenBuffer{ .handle = handle };
}
