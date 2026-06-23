//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const style_mod = @import("style.zig");
const text_mod = @import("text.zig");

pub const style = style_mod;
pub const Color = style_mod.Color;
pub const Modifier = style_mod.Modifier;
pub const Style = style_mod.Style;
pub const text = text_mod;
pub const Span = text_mod.Span;
pub const Line = text_mod.Line;

test {
    std.testing.refAllDecls(@This());
}
