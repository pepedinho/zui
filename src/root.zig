//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const style_mod = @import("style.zig");
const text_mod = @import("text.zig");
const buffer_mod = @import("buffer.zig");

pub const style = style_mod;
pub const Color = style_mod.Color;
pub const Modifier = style_mod.Modifier;
pub const Style = style_mod.Style;
pub const text = text_mod;
pub const Span = text_mod.Span;
pub const Line = text_mod.Line;
pub const buffer = buffer_mod;
pub const Cell = buffer_mod.Cell;
pub const Buffer = buffer_mod.Buffer;

test {
    std.testing.refAllDecls(@This());
}
