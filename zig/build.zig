const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    std.debug.print("building...\n", .{});

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // exec ///////////////////////////////////////////////
    const exe = b.addExecutable(.{
        .name = "advent-of-code-2023",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "../advent-of-code-2023/src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(.{ .path = "lib/regez/regez.h" });

    // modules ///////////////////////////////////////////////
    var aoc = b.addModule("aoc", .{ .source_file = .{ .path = "src/aoc.zig" } });
    exe.addModule("aoc", aoc);

    b.installArtifact(exe);

    // run ///////////////////////////////////////////////
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");

    run_step.dependOn(&run_cmd.step);

    // tests /////////////////////////////////////////////
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "../advent-of-code-2023/src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
