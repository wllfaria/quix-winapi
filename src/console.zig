const std = @import("std");
const windows = std.os.windows;
const DWORD = windows.DWORD;
const WORD = windows.WORD;

const csbi = @import("csbi.zig");
const ffi = @import("ffi/ffi.zig");
const Handle = @import("handle.zig").Handle;
const quix_winapi = @import("main.zig");
const ConsoleError = quix_winapi.ConsoleError;

const U32_MAX: u32 = 0xFFFFFFFF;

pub fn getMode(handle: Handle) ConsoleError!u32 {
    var console_mode: DWORD = 0;
    const result = windows.kernel32.GetConsoleMode(handle.inner, &console_mode);
    if (result == 0) return ConsoleError.FailedToRetrieveMode;
    return console_mode;
}

pub fn setMode(handle: Handle, new_mode: DWORD) ConsoleError!void {
    const result = windows.kernel32.SetConsoleMode(handle.inner, new_mode);
    if (result == 0) return ConsoleError.FailedToSetMode;
}

pub fn getInfo(handle: Handle) ConsoleError!csbi.Csbi {
    var screen_buf_info = csbi.init();
    const result = windows.kernel32.GetConsoleScreenBufferInfo(
        handle.inner,
        &screen_buf_info.csbi,
    );
    if (result == 0) return ConsoleError.FailedToRetrieveInfo;
    return screen_buf_info;
}

pub const WindowPlacement = enum {
    absolute,
    relative,
};

pub fn setInfo(
    handle: Handle,
    placement: WindowPlacement,
    rect: quix_winapi.WindowPosition,
) ConsoleError!void {
    const absolute: windows.BOOL = switch (placement) {
        .absolute => 1,
        .relative => 0,
    };
    const small_rect = rect.toSmallRect();
    const result = ffi.SetConsoleWindowInfo(handle.inner, absolute, &small_rect);
    if (result == 0) return ConsoleError.FailedToSetWindowInfo;
}

pub fn numberOfConsoleInputEvents(handle: Handle) ConsoleError!u32 {
    var buf_len: DWORD = 0;
    const result = ffi.GetNumberOfConsoleInputEvents(handle.inner, &buf_len);
    if (result == 0) return ConsoleError.FailedToReadInput;
    return buf_len;
}

const MAX_EVENTS = 32;
var read_input_buffer: [MAX_EVENTS]ffi.INPUT_RECORD = undefined;

pub fn readSingleInput(
    handle: Handle,
) ConsoleError!quix_winapi.InputRecord {
    var buffer: [1]ffi.INPUT_RECORD = undefined;

    const read_len = try readInput(handle, &buffer);
    std.debug.assert(read_len == 1);

    return quix_winapi.InputRecord.fromRaw(buffer[0]);
}

pub fn readConsoleInput(
    handle: Handle,
    buffer: []quix_winapi.InputRecord,
) ConsoleError![]const quix_winapi.InputRecord {
    if (buffer.len == 0) return buffer[0..0];

    const read_len = try readInput(handle, &read_input_buffer);
    if (read_len == 0) return buffer[0..0];

    const amount_to_copy: usize = @min(read_len, buffer.len);
    for (read_input_buffer[0..amount_to_copy], 0..) |ir, idx| {
        buffer[idx] = quix_winapi.InputRecord.fromRaw(ir);
    }

    return buffer[0..amount_to_copy];
}

fn readInput(handle: Handle, buf: []ffi.INPUT_RECORD) ConsoleError!usize {
    std.debug.assert(buf.len < U32_MAX);

    var records_len: DWORD = 0;
    const result = ffi.ReadConsoleInputW(
        handle.inner,
        buf.ptr,
        @as(u32, @intCast(buf.len)),
        &records_len,
    );
    if (result == 0) return ConsoleError.FailedToReadInput;
    return @as(usize, records_len);
}

pub fn setCursorPosition(
    handle: Handle,
    coord: quix_winapi.Coord,
) ConsoleError!void {
    const result = windows.kernel32.SetConsoleCursorPosition(
        handle.inner,
        coord.toRaw(),
    );

    if (result == 0) return ConsoleError.FailedToSetCursorPosition;
}

pub fn setCursorInfo(
    handle: Handle,
    info: quix_winapi.ConsoleCursorInfo,
) ConsoleError!void {
    const raw_info = info.toRaw();
    const result = ffi.SetConsoleCursorInfo(handle.inner, &raw_info);
    if (result == 0) return ConsoleError.FailedToSetCursorInfo;
}

pub fn setTextAttribute(handle: Handle, attributes: WORD) ConsoleError!void {
    const result = windows.kernel32.SetConsoleTextAttribute(handle.inner, attributes);
    if (result == 0) return ConsoleError.FailedToSetTextAttributes;
}

pub fn peekNamedPipe(handle: Handle) ConsoleError!u32 {
    var bytes_available: u32 = 0;
    const result = ffi.PeekNamedPipe(
        handle.inner,
        null,
        0,
        null,
        &bytes_available,
        null,
    );
    if (result == 0) return ConsoleError.FailedToPeekNamedPipe;
    return bytes_available;
}

pub fn peekInput(handle: Handle) ConsoleError!u32 {
    var buffer: [1]ffi.INPUT_RECORD = undefined;
    var events_read: u32 = 0;

    const result = ffi.PeekConsoleInput(handle.inner, &buffer, 1, &events_read);
    if (result == 0) return ConsoleError.FailedToPeekConsoleInput;

    return events_read;
}

pub fn setSize(handle: Handle, width: i16, height: i16) ConsoleError!void {
    const result = ffi.SetConsoleScreenBufferSize(
        handle.inner,
        quix_winapi.Coord.new(width, height).toRaw(),
    );
    if (result == 0) return ConsoleError.FailedToSetConsoleSize;
}

pub fn largestWindowSize(handle: Handle) ConsoleError!quix_winapi.Coord {
    const result = ffi.GetLargestConsoleWindowSize(handle.inner);
    if (result.X == 0 and result.Y == 0) return ConsoleError.FailedToGetLargestWindowSize;
    return quix_winapi.Coord.fromRaw(result);
}

pub fn fillWithChar(
    handle: Handle,
    char: u8,
    total_cells: u32,
    location: quix_winapi.Coord,
) ConsoleError!u32 {
    var chars_written: u32 = 0;

    const result = ffi.FillConsoleOutputCharacterA(
        handle.inner,
        char,
        total_cells,
        location.toRaw(),
        &chars_written,
    );

    if (result == 0) return ConsoleError.FailedToFillOutput;

    return @as(u32, @intCast(chars_written));
}

pub fn fillWithAttribute(
    handle: Handle,
    attribute: u16,
    total_cells: u32,
    location: quix_winapi.Coord,
) ConsoleError!u32 {
    var attributes_written: u32 = 0;

    const result = ffi.FillConsoleOutputAttribute(
        handle.inner,
        attribute,
        total_cells,
        location.toRaw(),
        &attributes_written,
    );

    if (result == 0) return ConsoleError.FailedToFillOutput;

    return @as(u32, @intCast(attributes_written));
}
