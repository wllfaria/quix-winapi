const std = @import("std");

const quix_winapi = @import("quix_winapi");

pub fn main() !void {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    const screen_buffer = try quix_winapi.console.getInfo(handle);

    const terminal_size = screen_buffer.terminalSize();
    const window_position = screen_buffer.terminalWindow();

    std.debug.print("terminal size: {}x{}\n", .{
        terminal_size.width,
        terminal_size.height,
    });

    std.debug.print(
        "window position - top: {}, left: {}, right: {}, bottom: {}\n",
        .{
            window_position.top,
            window_position.left,
            window_position.right,
            window_position.bottom,
        },
    );
}
