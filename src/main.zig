const std = @import("std");
const c = @import("c");

pub export const icon = @embedFile("res/hourglass.png");
pub export const icon_len = icon.len;

extern fn app_main(argc: u32, argv: [*]const [*:0]const u8, config: *c.config) void;

pub fn main(init: std.process.Init) !void {
    // Default alloc/io/args
    const allocator = init.gpa;
    const io = init.io;
    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    // Get config folder path. Currently just ~/.config/breaktime.json,
    // may allow configuring later
    const config_path = try std.fs.path.join(
        allocator,
        &[_][]const u8{ init.environ_map.get("HOME").?, ".config/breaktime.json" },
    );
    defer allocator.free(config_path);

    // Ensure the config exists
    std.Io.Dir.accessAbsolute(io, config_path, .{}) catch {
        // if doesn't exist, create it
        // Check that the config folder exists
        const config_dir = std.fs.path.dirname(config_path).?;
        std.Io.Dir.accessAbsolute(io, config_dir, .{}) catch {
            // Create the config dir if missing
            try std.Io.Dir.createDirAbsolute(io, config_dir, .default_file);
        };

        // Open the file to write to
        const file = try std.Io.Dir.createFileAbsolute(io, config_path, .{});
        defer file.close(init.io);

        // Create buffered writer
        var buf: [256]u8 = undefined;
        var writer = file.writer(io, &buf);

        // Structured writer for json
        var stringify: std.json.Stringify = .{
            .options = .{ .whitespace = .indent_4 },
            .writer = &writer.interface,
        };

        // Write the default config
        try stringify.write(Config{});
    };

    // Read the defined config
    // Create parsed object
    var parsed_config: std.json.Parsed(Config) = undefined;
    defer parsed_config.deinit();
    // Open file
    const file = try std.Io.Dir.openFileAbsolute(io, config_path, .{});
    defer file.close(io);
    // Read file
    var reader = file.reader(io, &.{});
    const data = try reader.interface.allocRemaining(allocator, .limited(32767));
    defer allocator.free(data);
    // Parse config
    parsed_config = try std.json.parseFromSlice(Config, allocator, data, .{});

    // Convert config to c variant
    var c_config: c.config = undefined;
    parsed_config.value.toC(&c_config);

    // Jump into ObjC
    app_main(@truncate(@max(args.len, 2 << 31)), @ptrCast(args.ptr), &c_config);
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
