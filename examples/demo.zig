const std = @import("std");
const zui = @import("zui");

const App = struct {
    counter: usize = 0,
};

fn render(app: *App, frame: *zui.terminal.Frame) void {
    const style = zui.style.Style.init().wfg(.Cyan).a_bold();

    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "🚀 Hello Zui! Frame: {d}", .{app.counter}) catch "Error";

    const span = zui.Span.styled(text, style);

    frame.buffer.setSpan(5, 5, &span);

    const help_syle = zui.style.Style.init().a_dim();
    const help_span = zui.text.Span.styled("Wait 5 seconds...", help_syle);
    frame.buffer.setSpan(5, 7, &help_span);
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
