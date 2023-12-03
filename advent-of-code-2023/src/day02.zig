const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const StringHashMap = std.StringHashMap;
const allocator = std.heap.page_allocator;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day02.txt");

pub fn part1() !void {
    var sum: usize = 0;
    var lines = tokenizeSequence(u8, data, "\n");

    var maxCubesForColor = StringHashMap(u8).init(allocator);
    try maxCubesForColor.put("red", 12);
    try maxCubesForColor.put("green", 13);
    try maxCubesForColor.put("blue", 14);

    while (lines.next()) |line| {
        // print("{s}\n", .{line});
        var gameIt = tokenizeSequence(u8, line, ": ");
        var id = gameIt.next();
        if (id == null) continue;
        var idIt = tokenizeSequence(u8, id orelse "", " ");
        id = idIt.next();
        var idNum = try parseInt(usize, idIt.next() orelse "0", 10);
        var game = gameIt.next();
        if (game == null) continue;
        // print("G{d}:  |", .{idNum});
        var gameOk: bool = true;
        var plays = tokenizeSequence(u8, game orelse "", "; ");
        while (plays.next()) |play| {
            var colors = tokenizeSequence(u8, play, ", ");
            while (colors.next()) |color| {
                var cubes = tokenizeSequence(u8, color, " ");
                var cFirst = cubes.next();
                if (cFirst == null) continue;
                var cSecond = cubes.next() orelse "";
                var numCubes = try parseInt(u8, cFirst orelse "0", 10);
                var maxCubes = maxCubesForColor.get(cSecond) orelse numCubes;
                // print("{{{s}: {d}/{d}}}", .{ cSecond, numCubes, maxCubes });
                gameOk = gameOk and numCubes <= maxCubes;
            }
            // print("|", .{});
        }
        // print("\n", .{});
        if (gameOk) {
            sum += idNum;
        }
    }

    print("part1 answer: {d}\n", .{sum});
}

pub fn part2() !void {
    var powProd: usize = 0;
    var lines = tokenizeSequence(u8, data, "\n");

    var minCubesForColor = StringHashMap(usize).init(allocator);

    while (lines.next()) |line| {
        print("{s}\n", .{line});
        var gameIt = tokenizeSequence(u8, line, ": ");
        var id = gameIt.next();
        if (id == null) continue;
        // var idIt = tokenizeSequence(u8, id orelse "", " ");
        // id = idIt.next();
        // var idNum = try parseInt(usize, idIt.next() orelse "0", 10);
        var game = gameIt.next();
        if (game == null) continue;
        try minCubesForColor.put("red", 0);
        try minCubesForColor.put("green", 0);
        try minCubesForColor.put("blue", 0);
        var plays = tokenizeSequence(u8, game orelse "", "; ");
        while (plays.next()) |play| {
            var colors = tokenizeSequence(u8, play, ", ");
            while (colors.next()) |color| {
                var cubes = tokenizeSequence(u8, color, " ");
                var cFirst = cubes.next();
                if (cFirst == null) continue;
                var cSecond = cubes.next() orelse "";
                var numCubes = try parseInt(usize, cFirst orelse "0", 10);
                var maxCubes = @max(numCubes, minCubesForColor.get(cSecond) orelse numCubes);
                try minCubesForColor.put(cSecond, maxCubes);
            }
        }
        var minRed = minCubesForColor.get("red") orelse 0;
        var minGreen = minCubesForColor.get("green") orelse 0;
        var minBlue = minCubesForColor.get("blue") orelse 0;
        powProd += minRed * minGreen * minBlue;
    }

    print("part2 answer: {d}\n", .{powProd});
}

pub fn main() !void {
    try part1();
    try part2();
}

// Useful stdlib functions
const Tuple = std.meta.Tuple;
const tokenize = std.mem.tokenize;
const tokenizeSequence = std.mem.tokenizeSequence;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
