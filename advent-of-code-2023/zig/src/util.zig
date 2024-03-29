const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_impl.allocator();

// Add utility functions here

pub fn repeat(s: []const u8, times: usize, allocator: Allocator) ![]u8 {
    const repeated = try allocator.alloc(u8, @max(0, s.len * times));
    @memset(repeated, s);
    // if (times <= 0) {
    //     return repeated;
    // }

    // var i: usize = 0;
    // while (i < s.len * times) : (i += 1) {
    //     if (s.len == 1) {
    //         repeated[i] = s[0];
    //     } else {
    //         repeated[i] = s[i % 2];
    //     }
    // }

    return repeated;
}

pub fn range(start: anytype, stop: @TypeOf(start), step: @TypeOf(start), allocator: Allocator) ![]@TypeOf(start) {
    const T = @TypeOf(start);

    assert(start <= stop);
    assert(step > 0);

    var r = try ArrayList(T).initCapacity(allocator, ((stop - start) / step) + 1);
    defer r.deinit();

    var i = start;

    while (i < stop) : (i += step) try r.append(i);

    return r.toOwnedSlice();
}

pub fn rep(x: anytype, times: usize, allocator: Allocator) ![]@TypeOf(x) {
    const T = @TypeOf(x);
    var r = try ArrayList(T).initCapacity(allocator, times);
    defer r.deinit();

    try r.appendNTimes(x, times);

    return r.toOwnedSlice();
}

// Useful stdlib functions
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
