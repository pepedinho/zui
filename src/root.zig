//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const style_mod = @import("style.zig");

pub const style = style_mod;
pub const Color = style_mod.Color;
pub const Modifier = style_mod.Modifier;
pub const Style = style_mod.Style;

test {
    std.testing.refAllDecls(@This());
}
