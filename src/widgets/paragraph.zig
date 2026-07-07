const std = @import("std");
const Style = @import("../style.zig").Style;
const Block = @import("block.zig").Block;
const Rect = @import("../layout.zig").Rect;
const Buffer = @import("../buffer.zig").Buffer;
const Line = @import("line.zig").Line;

pub const Paragraph = struct {
    const Self = @This();

    text: ?[]const u8 = null,
    lines: ?[]const Line = null,
    block: ?Block = null,
    style: Style = .{},
    /// If this option is on `true` text inside `Paragraph` will be
    /// automaticly wrapped.
    wraping: bool = false,

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

        if (self.text) |t| {
            if (self.wraping) {
                var start: usize = 0;
                var y_offset: u16 = 0;

                while (start < t.len and y_offset < current_area.height) : (y_offset += 1) {
                    const end = @min(start + current_area.width, t.len);
                    const line_text = t[start..end];

                    buf.setString(
                        current_area.x,
                        current_area.y + y_offset,
                        line_text,
                        self.style,
                    );

                    start = end;
                }
            } else {
                const end = @min(t.len, current_area.width);
                buf.setString(current_area.x, current_area.y, t[0..end], self.style);
            }
        } else if (self.lines) |lines| {
            for (lines, 0..) |line, y_offset| {
                if (y_offset >= current_area.height) break;

                var x_offset: u16 = 0;
                const y = current_area.y + @as(u16, @intCast(y_offset));

                for (line.spans) |span| {
                    if (x_offset >= current_area.width) break;

                    const available_width = current_area.width - x_offset;
                    const end = @min(span.text.len, available_width);
                    const visible_text = span.text[0..end];

                    buf.setString(current_area.x + x_offset, y, visible_text, span.style);
                    x_offset += @as(u16, @intCast(visible_text.len));
                }
            }
        }
    }
};
