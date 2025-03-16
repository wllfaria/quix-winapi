const std = @import("std");
const windows = std.os.windows;
const DWORD = windows.DWORD;
const WORD = windows.WORD;

pub const console = @import("console.zig");
const ffi = @import("ffi/ffi.zig");
pub const handle = @import("handle.zig");
pub const screen_buffer = @import("screen_buffer.zig");
pub const csbi = @import("csbi.zig");

// zig fmt: off
pub const ENABLE_LINE_INPUT: DWORD              = 0x0002;
pub const ENABLE_PROCESSED_INPUT: DWORD         = 0x0001;
pub const ENABLE_ECHO_INPUT: DWORD              = 0x0004;
pub const ENABLE_WRAP_AT_EOL_OUTPUT: DWORD      = 0x0002;
pub const CONSOLE_TEXTMODE_BUFFER: DWORD        = 0x0001;
pub const ENABLE_VIRTUAL_TERMINAL_INPUT: DWORD  = 0x0200;

pub const FROM_LEFT_1ST_BUTTON_PRESSED: DWORD   = 0x0001;
pub const FROM_LEFT_2ND_BUTTON_PRESSED: DWORD   = 0x0004;
pub const FROM_LEFT_3RD_BUTTON_PRESSED: DWORD   = 0x0008;
pub const FROM_LEFT_4TH_BUTTON_PRESSED: DWORD   = 0x0010;
pub const RIGHTMOST_BUTTON_PRESSED: DWORD       = 0x0002;

pub const CAPSLOCK_ON: DWORD                    = 0x0080;
pub const ENHANCED_KEY: DWORD                   = 0x0100;
pub const LEFT_ALT_PRESSED: DWORD               = 0x0002;
pub const LEFT_CTRL_PRESSED: DWORD              = 0x0008;
pub const NUMLOCK_ON: DWORD                     = 0x0020;
pub const RIGHT_ALT_PRESSED: DWORD              = 0x0001;
pub const RIGHT_CTRL_PRESSED: DWORD             = 0x0004;
pub const SCROLLLOCK_ON: DWORD                  = 0x0040;
pub const SHIFT_PRESSED: DWORD                  = 0x0010;

pub const MOUSE_MOVED: DWORD                    = 0x0001;
pub const DOUBLE_CLICK: DWORD                   = 0x0002;
pub const MOUSE_WHEELED: DWORD                  = 0x0004;
pub const MOUSE_HWHEELED: DWORD                 = 0x0008;

pub const FOCUS_EVENT: WORD                     = 0x0010;
pub const KEY_EVENT: WORD                       = 0x0001;
pub const MENU_EVENT: WORD                      = 0x0008;
pub const MOUSE_EVENT: WORD                     = 0x0002;
pub const WINDOW_BUFFER_SIZE_EVENT: WORD        = 0x0004;
// zig fmt: on

pub const ConsoleError = error{
    FailedToRetrieveMode,
    FailedToSetMode,
    FailedToRetrieveInfo,
    FailedToCreateHandle,
    FailedToCreateScreenBuffer,
    FailedToShowScreenBuffer,
    FailedToWriteToHandle,
    FailedToSetWindowInfo,
    FailedToReadInput,
    FailedToGetHandle,
    FailedToSetCursorPosition,
    FailedToSetCursorInfo,
    Unsupported,
};

pub const ConsoleCursorInfo = struct {
    size: u32,
    visible: bool,

    pub fn fromRaw(info: ffi.CONSOLE_CURSOR_INFO) @This() {
        return @This(){
            .size = info.dwSize,
            .visible = if (info.bVisible == 1) true else false,
        };
    }

    pub fn toRaw(self: @This()) ffi.CONSOLE_CURSOR_INFO {
        return ffi.CONSOLE_CURSOR_INFO{
            .dwSize = self.size,
            .bVisible = if (self.visible) windows.TRUE else windows.FALSE,
        };
    }
};

/// Defines the size of the terminal screen buffer, this is the same as
/// calcualting `Coord.right - Coord.left` and `Coord.bottom - Coord.top`
pub const Size = struct {
    width: i16,
    height: i16,
};

/// Defines the coordinates of the upper left and lower right corners of a
/// the terminal screen buffer.
pub const WindowPosition = struct {
    left: i16,
    right: i16,
    bottom: i16,
    top: i16,

    pub fn toSmallRect(self: @This()) windows.SMALL_RECT {
        return windows.SMALL_RECT{
            .Top = self.top,
            .Bottom = self.bottom,
            .Left = self.left,
            .Right = self.right,
        };
    }

    pub fn fromSmallRect(rect: windows.SMALL_RECT) @This() {
        return @This(){
            .left = rect.Left,
            .right = rect.Right,
            .bottom = rect.Bottom,
            .top = rect.Top,
        };
    }
};

/// Defines the coordinates of a character cell in a console screen buffer.
/// The origin of the coordinate system (0,0) is at the top, left cell of the
/// buffer.
pub const Coord = struct {
    x: i16,
    y: i16,

    pub fn new(x: i16, y: i16) @This() {
        return @This(){ .x = x, .y = y };
    }

    pub fn fromRaw(coord: windows.COORD) @This() {
        return @This(){
            .x = coord.X,
            .y = coord.Y,
        };
    }

    pub fn toRaw(self: @This()) windows.COORD {
        return windows.COORD{
            .X = self.x,
            .Y = self.y,
        };
    }
};

/// Describes an input event in the console input buffer.
pub const InputRecord = union(enum) {
    /// The Event member contains a `KeyEventRecord` with information about a
    /// keyboard event.
    KeyEvent: KeyEventRecord,
    /// The Event member contains a `MouseEventRecord` with information about a
    /// mouse movement or button press event.
    MouseEvent: MouseEventRecord,
    /// The Event member contains a `WindowBufferSizeRecord` with information
    /// about the new size of the console screen buffer.
    WindowBufferSizeEvent: WindowBufferSizeRecord,
    /// The Event member contains a `FocusEventRecord`. These events are used
    /// internally and should be ignored.
    FocusEvent: FocusEventRecord,
    /// The Event member contains a `MenuEventRecord`. These events are used
    /// internally and should be ignored. [See](https://learn.microsoft.com/en-us/windows/console/input-record-str#members)
    MenuEvent: MenuEventRecord,

    pub fn fromRaw(input_record: ffi.INPUT_RECORD) @This() {
        return switch (input_record.EventType) {
            KEY_EVENT => InputRecord{
                .KeyEvent = KeyEventRecord.fromRaw(input_record.Event.KeyEvent),
            },
            MOUSE_EVENT => InputRecord{
                .MouseEvent = MouseEventRecord.fromRaw(
                    input_record.Event.MouseEvent,
                ),
            },
            WINDOW_BUFFER_SIZE_EVENT => InputRecord{
                .WindowBufferSizeEvent = WindowBufferSizeRecord.fromRaw(
                    input_record.Event.WindowBufferSizeEvent,
                ),
            },
            MENU_EVENT => InputRecord{
                .MenuEvent = MenuEventRecord.fromRaw(
                    input_record.Event.MenuEvent,
                ),
            },
            FOCUS_EVENT => InputRecord{
                .FocusEvent = FocusEventRecord.fromRaw(
                    input_record.Event.FocusEvent,
                ),
            },
            else => unreachable,
        };
    }
};

/// The Event member contains a `KeyEventRecord` with information about a
/// keyboard event.
pub const KeyEventRecord = struct {
    key_down: bool,
    repeat_count: u16,
    virtual_key_code: u16,
    virtual_scan_code: u16,
    u_char: u16,
    control_key_state: ControlKeyState,

    pub fn fromRaw(key_event: ffi.KEY_EVENT_RECORD) @This() {
        return @This(){
            .key_down = if (key_event.bKeyDown == 1) true else false,
            .repeat_count = key_event.wRepeatCount,
            .virtual_key_code = key_event.wVirtualKeyCode,
            .virtual_scan_code = key_event.wVirtualScanCode,
            .control_key_state = @bitCast(key_event.dwControlKeyState),
            .u_char = @as(u16, key_event.uChar.UnicodeChar),
        };
    }
};

/// The Event member contains a `MouseEventRecord` with information about a
/// mouse movement or button press event.
pub const MouseEventRecord = struct {
    mouse_position: Coord,
    button_state: MouseButtonState,
    control_key_state: ControlKeyState,
    event_flags: EventFlags,

    pub fn fromRaw(mouse_event: ffi.MOUSE_EVENT_RECORD) @This() {
        return @This(){
            .mouse_position = Coord.fromRaw(mouse_event.dwMousePosition),
            .button_state = @bitCast(mouse_event.dwButtonState),
            .control_key_state = @bitCast(mouse_event.dwControlKeyState),
            .event_flags = @bitCast(mouse_event.dwEventFlags),
        };
    }
};

/// The Event member contains a `WindowBufferSizeRecord` with information
/// about the new size of the console screen buffer.
pub const WindowBufferSizeRecord = struct {
    size: Coord,

    pub fn fromRaw(window_buffer_size: ffi.WINDOW_BUFFER_SIZE_RECORD) @This() {
        return @This(){
            .size = Coord.fromRaw(window_buffer_size.dwSize),
        };
    }
};

/// The Event member contains a `FocusEventRecord`. These events are used
/// internally and should be ignored.
pub const FocusEventRecord = struct {
    set_focus: bool,

    pub fn fromRaw(focus_event: ffi.FOCUS_EVENT_RECORD) @This() {
        return @This(){
            .set_focus = if (focus_event.bSetFocus == 1) true else false,
        };
    }
};

/// The Event member contains a `MenuEventRecord`. These events are used
/// internally and should be ignored. [See](https://learn.microsoft.com/en-us/windows/console/input-record-str#members)
pub const MenuEventRecord = struct {
    command_id: u32,

    pub fn fromRaw(menu_event: ffi.MENU_EVENT_RECORD) @This() {
        return @This(){
            .command_id = @as(u32, menu_event.dwCommandId),
        };
    }
};

/// Represents the state of modifier keys given an event.
pub const ControlKeyState = packed struct {
    right_alt: bool,
    left_alt: bool,
    right_ctrl: bool,
    left_ctrl: bool,
    shift: bool,
    numlock: bool,
    scroll_lock: bool,
    capslock: bool,
    enhanced_key: bool,
    _pad: u23 = 0,
};

// TODO: find a way to represent mouse wheel events
/// Represents the state of mouse buttons during a mouse input event.
pub const MouseButtonState = packed struct {
    from_left_first_button: bool,
    rightmost_button: bool,
    from_left_second_button: bool,
    from_left_third_button: bool,
    from_left_fourth_button: bool,
    _pad: u27 = 0,

    pub fn release_button(self: @This()) bool {
        return @as(u32, @bitCast(self)) == 0;
    }

    pub fn left_button_pressed(self: @This()) bool {
        return self.from_left_first_button;
    }

    pub fn right_button_pressed(self: @This()) bool {
        return self.rightmost_button or
            self.from_left_third_button or
            self.from_left_fourth_button;
    }

    pub fn middle_button_pressed(self: @This()) bool {
        return self.from_left_second_button;
    }
};

/// Represents which kind of mouse event happened.
pub const EventFlags = packed struct {
    mouse_move: bool,
    mouse_click: bool,
    mouse_scroll: bool,
    mouse_horizontal_scroll: bool,
    _pad: u28 = 0,
};
