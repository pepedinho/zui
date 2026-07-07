const std = @import("std");
const zui = @import("zui");

const App = struct {
    counter: usize = 0,
};

fn render(app: *App, frame: *zui.terminal.Frame) void {
    const screen = frame.size();

    const vertical_chunks = zui.layout.Layout.init(&.{
        .{ .Length = 3 }, // Header
        .{ .Fill = 1 }, // Body (3 columns)
        .{ .Length = 3 }, // Footer (Gauge)
    })
        .dir(.Vertical)
        .split(frame.allocator, screen) catch return;

    const header_area = vertical_chunks[0];
    const body_area = vertical_chunks[1];
    const footer_area = vertical_chunks[2];

    const horizontal_chunks = zui.layout.Layout.init(&.{
        .{ .Percentage = 33 },
        .{ .Percentage = 33 },
        .{ .Percentage = 33 },
    })
        .dir(.Horizontal)
        .split(frame.allocator, body_area) catch return;

    const left_area = horizontal_chunks[0];
    const mid_area = horizontal_chunks[1];
    const right_area = horizontal_chunks[2];

    const menu_items = &[_][]const u8{
        "1. File",
        "2. Editor",
        "3. Git",
        "4. Option",
        "5. Very long option just to see how is render",
    };
    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "[*] Frame: {d}", .{app.counter}) catch "Error";

    const list = zui.widgets.List{
        .items = menu_items,
        .selected_index = app.counter % menu_items.len,
        .style = .{ .fg = .Red },
        .highlight_style = .{ .fg = .Black, .bg = .Cyan, .add_modifier = .{ .bold = true } },
        .block = .{ .borders = .ALL, .style = .{ .fg = .Red } },
    };

    const header_par = zui.widgets.Paragraph{
        .text = "Zui Dashboard",
        .alignement = .Center,
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

    const progress = @as(f32, @floatFromInt(app.counter % 100)) / 100;
    const gauge = zui.widgets.Gauge{
        .percent = progress,
        .style = .{ .fg = .Yellow },
        .block = .{ .borders = .ALL },
    };

    gauge.render(footer_area, frame.buffer);
    list.render(left_area, frame.buffer);
    left_par.render(mid_area, frame.buffer);
    header_par.render(header_area, frame.buffer);
    right_par.render(right_area, frame.buffer);

    if (app.counter > 150 and app.counter < 250) {
        const popup_area = zui.layout.Rect{
            .x = (screen.width - 40) / 2,
            .y = (screen.height - 6) / 2,
            .width = 40,
            .height = 6,
        };

        const clear = zui.widgets.Clear{};
        clear.render(popup_area, frame.buffer);

        const popup = zui.widgets.Paragraph{
            .lines = &.{
                .{ .spans = &.{.{ .text = "  ALERTE SYSTEME !", .style = .{ .fg = .Red, .add_modifier = .{ .bold = true } } }} },
                .{ .spans = &.{.{ .text = "  Le composant Clear fonctionne.", .style = .{ .fg = .White } }} },
            },
            .block = .{
                .title = "POPUP",
                .borders = .ALL,
                .style = .{ .fg = .Red },
            },
        };

        popup.render(popup_area, frame.buffer);
    }
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
