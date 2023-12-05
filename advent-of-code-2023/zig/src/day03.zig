const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const BitSet = std.DynamicBitSet;
const StringHashMap = std.StringHashMap;
const default_allocator = std.heap.page_allocator;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");

const digits = "0123456789";

const Point = struct {
    x: usize,
    y: usize,

    const Self = @This();

    pub fn fromPos(pos: usize, width: usize) Point {
        return .{
            .x = pos % width,
            .y = pos / width,
        };
    }

    pub fn toPos(self: *const Point, width: usize) usize {
        return self.y * width + self.x;
    }
};

const PointList = struct {
    x: []usize,
    y: []usize,
    index: usize = 0,

    const Self = @This();

    pub fn fromSlice(pts: []Point, allocator: Allocator) PointList {
        const x = ArrayList(Point).initCapacity(allocator, pts.len);
        defer x.deinit();
        const y = ArrayList(Point).initCapacity(allocator, pts.len);
        defer y.deinit();

        for (pts) |pt| {
            x.append(pt.x);
            y.append(pt.y);
        }

        return .{ .x = x.toOwnedSlice(), .y = y.toOwnedSlice() };
    }

    pub fn toSlice(self: PointList, allocator: Allocator) []Point {
        const pts = ArrayList(Point).initCapacity(allocator, self.len);
        defer pts.deinit();

        while (self.next()) |pt| {
            pts.append(pt);
        }

        return pts.toOwnedSlice();
    }

    pub fn next(self: *Self) ?Point {
        const result = self.peek() orelse return null;
        self.index += 1;
        return result;
    }

    pub fn peek(self: *Self) ?Point {
        if (self.index >= self.x.len) return null;
        return .{
            .x = self.x[self.index],
            .y = self.y[self.index],
        };
    }

    pub fn reset(self: *Self) void {
        self.index = 0;
    }

    pub fn destroy(self: *Self, allocator: Allocator) !void {
        try allocator.destroy(self.x);
        try allocator.destroy(self.y);
    }
};

const Part = struct {
    id: []const u8,
    idNo: u32,
    pos: usize,
    idx: usize,
    lastIdx: usize,

    const Self = @This();

    pub fn coords(self: *Self, width: usize) PointList {
        var x = self.pos % width;
        var y = self.pos / width;

        assert(x + self.id.len < width);

        return .{
            .x = util.range(x, x + self.id.len, 1, default_allocator),
            .y = util.rep(y, self.id.len, default_allocator),
        };
    }

    pub fn adjacent(self: *const Self, source: Board, allocator: Allocator) []Point {
        const pts = self.coords(source.width);
        const idLen = self.id.len;

        const adj = ArrayList(Point).initCapacity(allocator, 2 * idLen + 6);
        defer adj.deinit();

        const top = pts.y[0] == 0;
        const left = pts.x[0] == 0;
        const right = pts.x[pts.x.len] == source.width - 1;
        const bottom = pts.y[0] == source.height - 1;

        if (!top) {
            if (!left) adj.append(.{ .x = pts.x[0] - 1, .y = pts.y[0] - 1 });
            for (pts.x, pts.y) |x, y| adj.appen(.{ .x = x, .y = y - 1 });
            if (!right) adj.append(.{ .x = pts.x[idLen] + 1, .y = pts.y[0] - 1 });
        }

        if (!left) adj.append(.{ .x = pts.x[0] - 1, .y = pts.y[0] });
        // it would be
        // for (pts.x, pts.y) |x, y| adj.appen(.{ .x = x, .y = y });
        // but those are the source points
        if (!right) adj.append(.{ .x = pts.x[idLen] + 1, .y = pts.y[0] });

        if (!bottom) {
            if (!left) adj.append(.{ .x = pts.x[0] - 1, .y = pts.y[0] + 1 });
            for (pts.x, pts.y) |x, y| adj.appen(.{ .x = x, .y = y + 1 });
            if (!right) adj.append(.{ .x = pts.x[idLen] + 1, .y = pts.y[0] + 1 });
        }

        return adj.toOwnedSlice();
    }
};

const PartsList = struct {
    allocator: Allocator,
    size: usize = 0,
    capacity: usize,
    width: usize,

    index: usize = 0,
    id: [][]const u8,
    idNo: []u32,
    pos: []usize,
    lastIdx: []?usize,
    id2Idx: StringHashMap(usize),

    const Self = @This();

    pub fn init(allocator: Allocator, capacity: usize, width: usize) Self {
        return .{
            .allocator = allocator,
            .capacity = capacity,
            .width = width,
            .id = try allocator.alloc([]const u8, capacity),
            .pos = try allocator.alloc(usize, capacity),
            .id2Idx = StringHashMap(usize).init(allocator),
        };
    }

    pub fn deinit(self: *Self) !void {
        self.allocator.destroy(self.id);
        self.allocator.destroy(self.pos);
        self.id2Idx.clearAndFree();
        self.allocator.destroy(self.id2Idx);
    }

    pub fn push(self: *Self, idNo: u32, id: []const u8, pos: usize) !void {
        self.idNo[self.index] = idNo;
        self.id[self.index] = id;
        self.pos[self.index] = pos;
        self.lastIdx[self.index] = self.id2Idx.get(id);
        try self.id2Idx.put(id, self.index);
        self.index += 1;
        self.size += 1;
    }

    pub fn get(self: *Self, id: []const u8) ?Part {
        var idx = self.id2Idx.get(id);
        if (idx == null) return null;
        return .{
            .idx = idx,
            .id = id,
            .idNo = self.idNo[idx],
            .pos = self.pos[idx],
            .lastIdx = self.lastIdx[idx],
        };
    }

    pub fn next(self: *Self) ?Part {
        const result = self.peek() orelse return null;
        self.index += 1;
        return result;
    }

    pub fn peek(self: *Self) ?Part {
        if (self.index >= self.size) return null;
        return .{
            .id = self.id[self.index],
            .idNo = self.idNo[self.index],
            .pos = self.pos[self.index],
            .idx = self.index,
            .lastIdx = self.lastIdx[self.index],
        };
    }

    pub fn reset(self: *Self) void {
        self.index = 0;
    }
};

const Board = struct {
    buf: []const u8,
    width: usize,
    height: usize,
    delims: []const u8 = ".\n",
    parts: PartsList,

    pub fn ingestFrom(source: []const u8, delims: []const u8, allocator: Allocator) Board {
        var width = (indexOf(u8, source, "\n") orelse source.len) + 1;
        if (width >= source.len) return .{};
        var parts = PartsList.init(allocator, source.len, width);
        var height = source.len / width;
        var tokens = tokenizeAny(u8, data, delims);
        while (tokens.next()) |token| {
            var idNo = try parseInt(u32, token, 10) catch continue;
            parts.push(idNo, token, tokens.index);
        }

        return .{
            .buf = source,
            .width = width,
            .height = height,
            .delims = delims,
            .parts = parts,
        };
    }
};

pub fn part1() !void {
    var board = Board.ingestFrom(data, ".\n", default_allocator);
    var sum: u32 = 0;
    board.parts.reset();
    while (board.parts.next()) |part| {
        for (part.adjacent(board, default_allocator)) |pt| {
            if (!std.mem.eql(u8, data[pt.toPos(board.width)], ".") and indexOf(u8, digits, data[pt.toPos(board.width)]) == null) {
                sum += part.idNo;
            }
        }
    }
}

pub fn part2() !void {}

pub fn main() !void {
    try part1();
    try part2();
}

// Useful stdlib functions
const nDigits = std.math.log10_int;
const tokenizeAny = std.mem.tokenizeAny;
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

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
