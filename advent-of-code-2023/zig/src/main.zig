const std = @import("std");
const aoc = @import("aoc");

// const re = @cImport(@cInclude("regez.h"));
// const REGEX_T_ALIGNOF = re.sizeof_regex_t;
// const REGEX_T_SIZEOF = re.alignof_regex_t;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    aoc.bleh();
    // std.debug.print("regex: {any}", .{re});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "all your tests are belong to us" {
    _ = @import("test_all.zig");
}
