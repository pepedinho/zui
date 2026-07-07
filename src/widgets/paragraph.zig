const std = @import("std");
const Style = @import("../style.zig").Style;
const Block = @import("block.zig").Block;
const Rect = @import("../layout.zig").Rect;
const Buffer = @import("../buffer.zig").Buffer;

pub const Paragraph = struct {
    const Self = @This();

    text: []const u8,
    style: Style = .{},
    block: ?Block = null,

    pub fn init(text: []const u8) Self {
        return .{
            .text = text,
        };
    }

    pub fn render(self: Self, area: Rect, buf: *Buffer) void {
        var current_area = area;
        if (self.block) |block| {
            const inner = block.inner(current_area);
            block.render(current_area, buf);
            current_area = inner;
        }

        if (area.width == 0 or area.height == 0) {
            return;
        }

        buf.setString(current_area.x, current_area.y, self.text, self.style);
    }
};
