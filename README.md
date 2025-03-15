# Quix Windows API Layer

Some hopefully useful abstractions over common functions usedin WinAPI console
functions.

This library was created for the [quix](https://github.com/wllfaria/quix), but
could be used by itself.

# Examples


## Screen Buffer Information
```zig
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
```

