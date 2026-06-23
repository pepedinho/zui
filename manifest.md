# Zui: A Declarative Terminal UI Library in Zig
## Manifesto & Architecture Specification

### 1. Vision & Philosophy
The goal of this project is to build a robust, high-performance, and ergonomic Text User Interface (TUI) library in Zig. Heavily inspired by Rust's `ratatui` and the immediate-mode GUI paradigm, **Zui** adopts a declarative rendering approach backed by double-buffering. 

By leveraging Zig's explicit memory management—specifically utilizing per-frame Arena Allocators—Zui aims to completely eliminate allocation overhead during the render loop while providing a high-level, developer-friendly API. Developers should focus on *what* the UI looks like and how it reacts to state, while Zui handles *how* to efficiently draw it to the terminal screen.

---

### 2. Core Concepts

#### 2.1. Declarative UI
Instead of manually moving the cursor and printing strings to standard output, the developer constructs a tree of Widgets (like Paragraphs, Lists, Blocks, and Charts) on every frame. Zui's layout engine automatically calculates spatial constraints and translates these widgets into precise terminal cell updates.

#### 2.2. Double Buffering & Diffing Engine
Directly writing to the terminal per widget causes visual artifacts and flickering. Zui solves this by using a double-buffer approach:
1. **Current Buffer:** A grid of cells representing what is currently visible on the terminal.
2. **Next Buffer:** An empty grid where widgets render their intended state for the current frame.
3. **Diffing Engine:** Once all widgets have drawn to the Next Buffer, Zui compares it to the Current Buffer cell by cell. It then generates the absolute minimal set of ANSI escape sequences (cursor movements, color changes, character writes) needed to update the physical screen.

#### 2.3. Frame-based Memory Management (The Zig Advantage)
UI construction naturally generates thousands of small, short-lived objects (`Span`, `Line`, layout constraints) every single frame. 
In Zig, allocating and freeing these individually would cause severe memory fragmentation and performance hits. Zui solves this by mandating a **Frame Arena**. 
At the start of `Terminal.draw()`, an `ArenaAllocator` is spun up and provided to the UI closure. When the frame concludes, the arena is entirely reset. This guarantees constant-time cleanup, zero memory leaks, and drastically simplifies the API since UI components do not require `deinit()` calls.

---

### 3. Core Data Structures

These fundamental structures define Zui's layout, styling, and rendering primitives.

#### `Color` & `Modifier`
Enums and bitsets defining the visual appearance of characters.

    pub const Color = enum { 
        Reset, Black, Red, Green, Yellow, Blue, Magenta, Cyan, White, 
        Indexed(u8), Rgb(u8, u8, u8) 
    };

    pub const Modifier = packed struct {
        bold: bool = false,
        dim: bool = false,
        italic: bool = false,
        underlined: bool = false,
        slow_blink: bool = false,
        rapid_blink: bool = false,
        reversed: bool = false,
        hidden: bool = false,
        crossed_out: bool = false,
        _padding: u7 = 0,
    };

#### `Style`
A unified struct holding foreground color, background color, and text modifiers. Designed to be easily composable.

    pub const Style = struct {
        fg: ?Color = null,
        bg: ?Color = null,
        add_modifier: Modifier = .{},
        sub_modifier: Modifier = .{},

        pub fn patch(self: Style, other: Style) Style {
            // Implementation to merge styles
        }
    };

#### Text Primitives: `Span`, `Line`, and `Text`
The building blocks of string rendering.
* **`Span`**: A contiguous string slice (`[]const u8`) paired with a single `Style`. It is the smallest stylable unit.
* **`Line`**: A slice of `Span`s (`[]const Span`), representing a single visual line on the screen. It also provides alignment properties.
* **`Text`**: A slice of `Line`s (`[]const Line`), representing multi-line text blocks like paragraphs.

#### Rendering Grid: `Cell` & `Buffer`
The low-level grid system.
* **`Cell`**: Represents a single terminal coordinate. Contains a unicode grapheme (`[]const u8`) and a `Style`.
* **`Buffer`**: A 1D slice of `Cell`s simulating a 2D grid (`width × height`). Includes utility methods to efficiently set strings, styles, or borders within a given region.

#### Layout: `Rect`
Represents layout boundaries and spatial positioning.

    pub const Rect = struct {
        x: u16, 
        y: u16, 
        width: u16, 
        height: u16,

        pub fn intersection(self: Rect, other: Rect) Rect { ... }
        pub fn area(self: Rect) u32 { ... }
    };

---

### 4. Public API Preview

#### The `Terminal` Application Loop
The main entry point for a Zui application. It abstracts over the specific terminal backend.

    const std = @import("std");
    const zui = @import("zui");

    pub fn main() !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        // Initialize backend (raw mode, alternate screen)
        var backend = try zui.backend.CrosstermBackend.init(allocator, std.io.getStdOut());
        defer backend.deinit();

        var terminal = try zui.Terminal.init(allocator, backend);
        defer terminal.deinit();

        try terminal.clear();

        var should_quit = false;
        while (!should_quit) {
            // Pass a context/app state and a render function
            try terminal.draw(&app_state, renderFn);
            
            // Handle input events here
        }
    }

#### The `Frame` and Render Closure
The `draw` function receives a `*Frame`, which exposes the screen area and the frame-local allocator.

    pub fn renderFn(state: *AppState, frame: *zui.Frame) void {
        const area = frame.size();
        
        // Create a styled block
        const block = zui.widgets.Block.init()
            .title(zui.Span.init(" Zui App ", .{ .fg = .Cyan, .bold = true }))
            .borders(.All);
        
        // Wrap text inside the block
        const p = zui.widgets.Paragraph.init("Welcome to Zui!")
            .block(block)
            .alignment(.Center);
        
        // Render to the buffer
        frame.renderWidget(p, area);
    }

#### The `Layout` Engine
A system to subdivide a `Rect` into smaller `Rect`s based on user-defined constraints.

    const chunks = try zui.Layout.init()
        .direction(.Vertical)
        .constraints(&[_]zui.Constraint{
            .{ .Length = 3 },       // Header
            .{ .Percentage = 80 },  // Main content body
            .{ .Min = 1 },          // Footer
        })
        .split(frame.allocator, area);

    // chunks[0], chunks[1], chunks[2] can now be used as render areas.

---

### 5. Roadmap & Development Phases

* **Phase 1: Foundations & Terminal Backend**
    * ANSI escape code generation.
    * Raw mode enablement and alternate screen buffer.
    * Terminal size querying and SIGWINCH handling.
* **Phase 2: The Core Rendering Engine**
    * Implement `Cell`, `Buffer`, and `Rect`.
    * Build the diffing algorithm to optimize terminal updates.
    * Implement the `Terminal` and `Frame` control flow.
* **Phase 3: The Styling & Text Primitives**
    * `Color`, `Modifier`, `Style`, `Span`, `Line`, and `Text`.
    * Unicode grapheme width calculations.
* **Phase 4: Layout & Basic Widgets**
    * Constraint-based layout solver.
    * `Block` and `Paragraph`.
* **Phase 5: Advanced Interactive Widgets**
    * `List` and `Table` with selectable states.
    * `Gauge`, `Sparkline`, and `BarChart` for data visualization.
