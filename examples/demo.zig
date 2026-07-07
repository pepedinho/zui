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

    const header_block = zui.widgets.block.Block.init()
        .setBorders(zui.widgets.block.Borders.ALL)
        .setStyle(zui.style.Style.init().wfg(.Yellow));
    header_block.render(header_area, frame.buffer);

    const left_block = zui.widgets.block.Block.init()
        .setBorders(zui.widgets.block.Borders.ALL)
        .setStyle(zui.style.Style.init().wfg(.Cyan));
    left_block.render(left_area, frame.buffer);

    const right_block = zui.widgets.block.Block.init()
        .setBorders(zui.widgets.block.Borders.ALL)
        .setStyle(zui.style.Style.init().wfg(.Green));
    right_block.render(right_area, frame.buffer);

    const header_inner = header_block.inner(header_area);
    const title_span = zui.text.Span.styled(" ZUI Dashboard ", zui.style.Style.init().a_bold());
    frame.buffer.setSpan(header_inner.x + 2, header_inner.y, &title_span);

    const left_inner = left_block.inner(left_area);
    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "[*] Frame: {d}", .{app.counter}) catch "Error";
    const span = zui.text.Span.styled(text, zui.style.Style.init().wfg(.Cyan).a_bold());
    frame.buffer.setSpan(left_inner.x, left_inner.y, &span);

    const right_inner = right_block.inner(right_area);
    const help_span = zui.text.Span.styled("Patientez 5 secondes...", zui.style.Style.init().a_dim());
    frame.buffer.setSpan(right_inner.x, right_inner.y, &help_span);
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    var stoudt_buf: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stoudt_buf);
    const stdout = &stdout_writer.interface;

    var term = try zui.terminal.Terminal.init(gpa, stdout, 80, 24);
    defer term.deinit();

    var app = App{};

    while (app.counter < 500) : (app.counter += 1) {
        try term.draw(&app, render);
        try std.Io.sleep(init.io, .fromMilliseconds(10), .real);
    }
}
