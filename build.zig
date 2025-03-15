const std = @import("std");

const Examples = enum {
    screen_buffer_info,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/main.zig");

    const quix_winapi_mod = b.addModule("quix_winapi", .{
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
    });

    const unit_tests = b.addTest(.{
        .root_module = quix_winapi_mod,
        .target = target,
        .optimize = optimize,
    });

    const example_step = b.step("example", "Run example");

    const example_opt = b.option(
        Examples,
        "example",
        "Example to show (default: screen_buffer_info)",
    ) orelse .screen_buffer_info;

    const example_name = b.fmt("examples/{s}.zig", .{@tagName(example_opt)});
    const example_mod = b.addModule("example", .{
        .root_source_file = b.path(example_name),
        .target = target,
        .optimize = optimize,
    });

    const example = b.addExecutable(.{
        .name = "example",
        .root_module = example_mod,
    });

    example_mod.addImport("quix_winapi", quix_winapi_mod);

    const example_run = b.addRunArtifact(example);
    example_step.dependOn(&example_run.step);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
