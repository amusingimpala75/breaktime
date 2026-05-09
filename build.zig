const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c = b.addTranslateC(.{
        .root_source_file = b.path("src/config.h"),
        .target = target,
        .optimize = optimize,
    });

    c.addIncludePath(b.path("src"));

    const exe = b.addExecutable(.{
        .name = "breaktime",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/main.zig"),
            .imports = &.{
                .{
                    .name = "c",
                    .module = c.createModule(),
                },
            },
        }),
    });

    const sdk_path = b.run(&.{
        "xcrun",
        "--show-sdk-path",
    });

    const framework_path = std.fmt.allocPrint(
        b.allocator,
        "{s}/System/Library/Frameworks",
        .{sdk_path[0 .. sdk_path.len - 1]},
    ) catch @panic("OOM");

    exe.root_module.addFrameworkPath(.{
        .cwd_relative = framework_path,
    });

    exe.root_module.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{ "app.m", "BreakTimeWindow.m" },
        .flags = &[_][]const u8{ "-Wall", "-Wextra", "-Werror" },
    });

    exe.root_module.linkFramework("AppKit", .{});
    exe.root_module.linkFramework("QuartzCore", .{});

    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    b.step("run", "Run breaktime").dependOn(&run.step);
}
