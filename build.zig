const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "breaktime",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    exe.addIncludePath(b.path("src"));

    exe.addCSourceFiles(.{
        .files = &[_][]const u8{ "src/app.m", "src/BreakTimeWindow.m" },
        .flags = &[_][]const u8{ "-Wall", "-Wextra", "-Werror" },
    });

    exe.linkFramework("AppKit");
    exe.linkFramework("QuartzCore");

    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    b.step("run", "Run breaktime").dependOn(&run.step);
}
