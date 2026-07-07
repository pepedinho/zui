const std = @import("std");
const zui = @import("zui");

const App = struct {
    counter: usize = 0,
};

fn render(app: *App, frame: *zui.terminal.Frame) void {
    const screen = frame.size();

    const vertical_chunks = zui.layout.Layout.init(&.{
        .{ .Length = 3 },
        .{ .Fill = 1 },
    })
        .dir(.Vertical)
        .split(frame.allocator, screen) catch return;

    const header_area = vertical_chunks[0];
    const body_area = vertical_chunks[1];

    const horizontal_chunks = zui.layout.Layout.init(&.{
        .{ .Percentage = 30 },
        .{ .Percentage = 70 },
    })
        .dir(.Horizontal)
        .split(frame.allocator, body_area) catch return;

    const left_area = horizontal_chunks[0];
    const right_area = horizontal_chunks[1];

    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "[*] Frame: {d}", .{app.counter}) catch "Error";

    const header_par = zui.widgets.Paragraph{
        .text = "Zui Dashboard",
        .style = .{ .add_modifier = .{ .bold = true } },
        .block = .{
            .borders = .ALL,
            .style = .{ .fg = .Yellow },
        },
    };

    const left_par = zui.widgets.Paragraph{
        .text = text,
        .style = .{
            .fg = .Cyan,
            .add_modifier = .{ .bold = true },
        },
        .block = .{ .borders = .ALL, .style = .{ .fg = .Cyan } },
    };

    const right_par = zui.widgets.Paragraph{
        .text = "Wait 5 secondes...",
        .style = .{ .add_modifier = .{ .dim = true } },
        .block = .{ .borders = .ALL, .style = .{
            .fg = .Green,
        } },
    };

    left_par.render(left_area, frame.buffer);
    header_par.render(header_area, frame.buffer);
    right_par.render(right_area, frame.buffer);
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    var stoudt_buf: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stoudt_buf);
    const stdout = &stdout_writer.interface;

    var term = try zui.terminal.Terminal.init(gpa, stdout, 100, 30);
    defer term.deinit();

    var app = App{};

    while (app.counter < 500) : (app.counter += 1) {
        try term.draw(&app, render);
        try std.Io.sleep(init.io, .fromMilliseconds(10), .real);
    }
}
