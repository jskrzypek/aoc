const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");

const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
const digits = "123456789";

const allocator = std.heap.page_allocator;

const one = "one";
const two = "two";
const three = "three";
const four = "four";
const five = "five";
const six = "six";
const seven = "seven";
const eight = "eight";
const nine = "nine";

const digwords = [9][]const u8{
    one,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,
};

const maxDigwordLen = 5;

pub fn part1() !void {
    var sum: u128 = 0;
    var lines = split(u8, data, "\n");
    var indices = [2]usize{ 0, 0 };
    // const firstLast = [2][]const u8;
    while (lines.next()) |line| {
        var first = indexOfAny(u8, line, digits) orelse line.len;
        var last = lastIndexOfAny(u8, line, digits) orelse line.len;
        indices[0] = first;
        indices[1] = last;
        // print("{s}\n", .{line});
        if (indices[0] < line.len and indices[1] < line.len) {
            // const pref = try util.repeat(".", first, allocator);
            // var mid = try util.repeat("^", last - first + 1, allocator);
            // const suff = try util.repeat(".", @max(0, line.len - last - 1), allocator);
            // print("{s}{s}{s}\n", .{ pref, mid, suff });
            const firstDig = line[first .. first + 1];
            // print("{s}", .{firstDig});
            const lastDig = line[last .. last + 1];
            // print("{s}\n", .{lastDig});

            const firstNum = try parseInt(u8, firstDig, 10) * 10;
            const lastNum = try parseInt(u8, lastDig, 10);
            // var lastDig = parseInt(u8, line[last .. last + 1], 10);
            sum += firstNum + lastNum;
        }
    }

    print("part1 answer: {d}\n", .{sum});

    // return sum;
}

const SlidingWindowsIterator = struct {
    text: []const u8,
    size: usize,
    advance: usize,
    debug: bool = false,
    index: usize = 0,
    initialized: bool = false,

    fn assertValid(self: *SlidingWindowsIterator) void {
        assert(self.size > 0);
        assert(self.advance > 0);
        assert(self.text.len >= self.size);
    }

    fn assertSafeWindows(self: *SlidingWindowsIterator) void {
        self.assertValid();
        assert(self.index <= self.text.len);
    }

    pub fn leading(self: *SlidingWindowsIterator, front: bool) usize {
        if (front)
            return @min(self.trailing(true) + self.size, self.text.len);

        return @max(self.text.len - self.leading(true), 0);
    }

    pub fn trailing(self: *SlidingWindowsIterator, front: bool) usize {
        if (front)
            return self.index;

        return self.text.len - self.index;
    }

    pub fn width(self: *SlidingWindowsIterator) usize {
        return self.leading(true) - self.trailing(true);
    }

    fn frontWindow(self: *SlidingWindowsIterator) []const u8 {
        return self.text[self.trailing(true)..self.leading(true)];
    }

    fn backWindow(self: *SlidingWindowsIterator) []const u8 {
        return self.text[self.leading(false)..self.trailing(false)];
    }

    fn getWindows(self: *SlidingWindowsIterator) [2][]const u8 {
        self.assertSafeWindows();
        return .{ self.frontWindow(), self.backWindow() };
    }

    pub fn reset(self: *SlidingWindowsIterator) void {
        self.index = 0;
        self.initialized = false;
    }

    pub fn first(self: *SlidingWindowsIterator) [2][]const u8 {
        self.assertValid();
        self.initialized = true;
        return self.getWindows();
    }

    pub fn next(self: *SlidingWindowsIterator) ?[2][]const u8 {
        if (!self.initialized) {
            return self.first();
        }

        self.index += self.advance;

        if (self.index >= self.text.len) {
            return null;
        }

        if (self.debug) self.debugPrint();

        return self.getWindows();
    }

    pub fn debugPrintSide(self: *SlidingWindowsIterator, front: bool, lf: bool) void {
        // print("{s}\n", .{self.text});
        if (front) {
            for (0..self.trailing(true)) |_| {
                print("<", .{});
            }
            print("{s}", .{self.text[self.trailing(true)..self.leading(true)]});
            for (self.leading(true)..self.text.len) |_| {
                print("<", .{});
            }
        } else {
            for (0..self.leading(false)) |_| {
                print(">", .{});
            }
            print("{s}", .{self.text[self.leading(false)..self.trailing(false)]});
            for (self.trailing(false)..self.text.len) |_| {
                print(">", .{});
            }
        }
        if (lf) {
            print("\n", .{});
        } else {
            print(" - ", .{});
        }
    }

    pub fn debugPrint(self: *SlidingWindowsIterator) void {
        print("{s}\n", .{self.text});

        // print("{d}:{d}, {d}:{d}\n", .{ self.trailing(true), self.leading(true), self.leading(false), self.trailing(false) });

        for (0..@min(self.trailing(true), self.leading(false))) |_| {
            print(".", .{});
        }

        if (self.leading(true) < self.leading(false)) {
            for (self.trailing(true)..self.leading(true)) |_| {
                print("<", .{});
            }

            for (self.leading(true)..self.leading(false)) |_| {
                print(".", .{});
            }

            for (self.leading(false)..self.trailing(false)) |_| {
                print(">", .{});
            }
        } else if (self.trailing(false) < self.trailing(true)) {
            for (self.leading(false)..self.trailing(false)) |_| {
                print(">", .{});
            }

            for (self.trailing(false)..self.trailing(true)) |_| {
                print(".", .{});
            }

            for (self.trailing(true)..self.leading(true)) |_| {
                print("<", .{});
            }
        } else if (self.trailing(true) <= self.leading(false) and self.leading(true) <= self.trailing(false)) {
            for (self.trailing(true)..self.leading(false)) |_| {
                print("<", .{});
            }

            for (self.leading(false)..self.leading(true)) |_| {
                print("x", .{});
            }

            for (self.leading(true)..self.trailing(false)) |_| {
                print(">", .{});
            }
        } else {
            for (self.leading(false)..self.trailing(true)) |_| {
                print(">", .{});
            }

            for (self.trailing(true)..self.trailing(false)) |_| {
                print("x", .{});
            }

            for (self.trailing(false)..self.leading(true)) |_| {
                print("<", .{});
            }
        }

        for (@max(self.trailing(false), self.leading(true))..self.text.len) |_| {
            print(".", .{});
        }

        print("\n", .{});
    }
};

fn getSlidingWindows(buf: []const u8, size: usize, advance: usize) SlidingWindowsIterator {
    return .{
        .text = buf,
        .size = size,
        .advance = advance,
        .debug = true,
    };
}

const best = struct {
    index: ?usize = null,
    val: usize = 0,
    match: []const u8 = "",
    pub fn debugPrint(self: *best) void {
        if (self.index == null) {
            print("{{}}", .{});
        } else {
            print("{{{?d}:{d}:\"{s}\"}}", .{ self.index, self.val, self.match });
        }
    }
};

pub fn part2() !void {
    var sum: u128 = 0;
    var lines = split(u8, data, "\n");

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (line.len == 1) {
            const dig = indexOf(u8, digits, line[0]) orelse 9;
            if (dig < 9) {
                sum += (dig + 1) * 11;
            }
            continue;
        }

        var windows = getSlidingWindows(
            line,
            @min(line.len, maxDigwordLen),
            1,
        );

        // windows.debugPrint();
        var first: best = .{};
        var last: best = .{};

        while (windows.next()) |wins| {
            for (digits, digwords, 1..10) |dig, word, val| {
                if (first.index == null)
                    if (wins[0][0] == dig) {
                        first.val = val;
                        first.index = windows.trailing(true);
                        first.match = wins[0][0..1];
                        windows.debugPrintSide(true, false);
                        first.debugPrint();
                        last.debugPrint();
                        print("\n", .{});
                    } else if (std.mem.eql(u8, wins[0][0..@min(windows.width(), word.len)], word)) {
                        first.val = val;
                        first.index = windows.trailing(true);
                        first.match = wins[0][0..word.len];
                        windows.debugPrintSide(true, false);
                        first.debugPrint();
                        last.debugPrint();
                        print("\n", .{});
                    };

                if (last.index == null)
                    if (wins[1][windows.width() - 1] == dig) {
                        last.val = val;
                        last.index = windows.leading(false);
                        last.match = wins[1][windows.width() - 1 .. windows.width()];
                        windows.debugPrintSide(false, false);
                        first.debugPrint();
                        last.debugPrint();
                        print("\n", .{});
                    } else if (std.mem.eql(u8, wins[1][windows.width() - @min(windows.width(), word.len) .. windows.width()], word)) {
                        last.val = val;
                        last.index = windows.leading(false);
                        last.match = wins[1][windows.width() - @min(windows.width(), word.len) .. windows.width()];
                        windows.debugPrintSide(false, false);
                        first.debugPrint();
                        last.debugPrint();
                        print("\n", .{});
                    };

                if (first.index != null and last.index != null) break;
            }

            if (first.index != null and last.index != null) {
                break;
            }
        }

        if (first.index == null) {
            first = last;
        }

        if (last.index == null) {
            last = first;
        }

        print("line: {d}{d} ", .{ first.val, last.val });

        sum += first.val * 10 + last.val;

        print("sum: {d}  -  {s}\n", .{ sum, line });
    }

    print("part2 answer: {d}\n", .{sum});
}

pub fn main() !void {
    // try part1();
    try part2();
    // std.debug.print("answer: {d}\n", .{part1Result});
}

// Useful stdlib functions
const window = std.mem.window;
const reverseIterator = std.mem.reverseIterator;
const tokenize = std.mem.tokenize;
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

const format = std.fmt.format;
const formatBuf = std.fmt.formatBuf;
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
