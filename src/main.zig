pub export const icon = @embedFile("res/hourglass.png");
pub export const icon_len = icon.len;

const c = @cImport({
    @cInclude("config.h");
});

const std = @import("std");

extern fn app_main(argc: u32, argv: [*][*:0]u8, config: *c.config) void;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() !void {
    const allocator = gpa.allocator();
    const path = try std.fs.path.join(
        allocator,
        &[_][]const u8{ std.posix.getenv("HOME").?, ".config/breaktime.json" },
    );
    defer allocator.free(path);
    // if doesn't exist, create it
    std.fs.accessAbsolute(path, .{}) catch {
        std.fs.accessAbsolute(std.fs.path.dirname(path).?, .{}) catch {
            try std.fs.makeDirAbsolute(std.fs.path.dirname(path).?);
        };
        const file = try std.fs.createFileAbsolute(path, .{});
        defer file.close();
        try std.json.stringify(Config{}, .{ .whitespace = .indent_4 }, file.writer());
    };
    var parsed_config: std.json.Parsed(Config) = undefined;
    defer parsed_config.deinit();
    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();
    const data = try file.readToEndAlloc(allocator, 32767);
    parsed_config = try std.json.parseFromSlice(Config, allocator, data, .{});

    var c_config: c.config = undefined;
    parsed_config.value.toC(&c_config);
    app_main(@intCast(std.os.argv.len), std.os.argv.ptr, &c_config);
    _ = gpa.deinit();
}

const Config = struct {
    const Font = struct {
        name: [:0]const u8 = "Arial",
        size: u8 = 24,
        color: u24 = 0xFFFFFF,
    };

    functionality: struct {
        use_duration: u8 = 15,
        break_duration: u8 = 5,
    } = .{},

    appearance: struct {
        background: u32 = 0x000000FF,
        message_font: Font = Font{},
        message: [:0]const u8 = "Time to take a break!",
        timer_font: Font = Font{},
        icon_path: ?[:0]const u8 = null,
        animations: struct {
            window: struct {
                fade_in: f32 = 1,
                fade_out: f32 = 2,
            } = .{},
            message: struct {
                fade_in: f32 = 4.0,
            } = .{},
            timer: struct {
                fade_in: f32 = 4.0,
                fade_in_delay: f32 = 2.0,
            } = .{},
        } = .{},
    } = .{},

    fn toC(self: Config, c_config: *c.config) void {
        c_config.functionality.use_duration = self.functionality.use_duration;
        c_config.functionality.break_duration = self.functionality.break_duration;
        c_config.appearance.background = self.appearance.background;
        c_config.appearance.message_font.name = self.appearance.message_font.name;
        c_config.appearance.message_font.size = self.appearance.message_font.size;
        c_config.appearance.message_font.color = self.appearance.message_font.color;
        c_config.appearance.message = self.appearance.message;
        c_config.appearance.timer_font.name = self.appearance.timer_font.name;
        c_config.appearance.timer_font.size = self.appearance.timer_font.size;
        c_config.appearance.timer_font.color = self.appearance.timer_font.color;
        if (self.appearance.icon_path) |path| {
            c_config.appearance.icon_path = path;
        } else {
            c_config.appearance.icon_path = null;
        }
        c_config.appearance.animations.window.fade_in = self.appearance.animations.window.fade_in;
        c_config.appearance.animations.window.fade_out = self.appearance.animations.window.fade_out;
        c_config.appearance.animations.message.fade_in = self.appearance.animations.message.fade_in;
        c_config.appearance.animations.timer.fade_in = self.appearance.animations.timer.fade_in;
        c_config.appearance.animations.timer.fade_in_delay = self.appearance.animations.timer.fade_in_delay;
    }
};
