//! This module provides primitives for spatial arrangement and layout constraints.
//!
//! The fundamental building block is the `Rect`, representing a 2D bounding box
//! on the terminal grid.

const std = @import("std");

pub const Rect = struct {
    const Self = @This();

    x: u16,
    y: u16,
    width: u16,
    height: u16,

    /// Create a new `Rect`
    pub fn init(x: u16, y: u16, width: u16, height: u16) Self {
        return .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        };
    }

    /// Calculates the area of the rectangle.
    pub fn area(self: Self) u32 {
        return @as(u32, self.width) * @as(u32, self.height);
    }

    /// Checks if a given point (x, y) is inside the rectangle.
    pub fn contains(self: Self, target_x: u16, target_y: u16) bool {
        return target_x >= self.x and target_x < self.x + self.width and
            target_y >= self.y and target_y < self.y + self.height;
    }

    /// Computes the intersection of this rectangle with another.
    /// Return a new `Rect` that is the overlapping area.
    /// If they do not intersect, returns a `Rect` with zero width and height.
    pub fn intersection(self: Self, other: Self) Self {
        const x1 = @max(self.x, other.x);
        const y1 = @max(self.y, other.y);

        const self_x2 = self.x + self.width;
        const other_x2 = other.x + other.width;
        const x2 = @min(self_x2, other_x2);

        const self_y2 = self.y + self.height;
        const other_y2 = other.y + other.height;
        const y2 = @min(self_y2, other_y2);

        if (x1 >= x2 or y1 >= y2) {
            return Rect.init(0, 0, 0, 0); // No intersection
        }

        return Rect.init(x1, y1, x2 - x1, y2 - y1);
    }
};

test "Rect contains point" {
    const r = Rect.init(5, 5, 10, 10);

    // Inside
    try std.testing.expect(r.contains(5, 5));
    try std.testing.expect(r.contains(14, 14));

    // Outside
    try std.testing.expect(!r.contains(4, 5));
    try std.testing.expect(!r.contains(15, 15));
}

test "Rect intersection" {
    const r1 = Rect.init(0, 0, 10, 10);
    const r2 = Rect.init(5, 5, 10, 10);

    const intersect = r1.intersection(r2);

    try std.testing.expectEqual(@as(u16, 5), intersect.x);
    try std.testing.expectEqual(@as(u16, 5), intersect.y);
    try std.testing.expectEqual(@as(u16, 5), intersect.width);
    try std.testing.expectEqual(@as(u16, 5), intersect.height);

    // No intersection
    const r3 = Rect.init(20, 20, 5, 5);
    const no_intersect = r1.intersection(r3);
    try std.testing.expectEqual(@as(u16, 0), no_intersect.area());
}
