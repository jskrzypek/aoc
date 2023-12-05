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
    lastIdx: ?usize,

    const Self = @This();

    pub fn coords(self: *Self, board: Board) !PointList {
        var x = self.pos % board.width;
        var y = self.pos / board.width;
        print(
            "{{{d}..{d},{d},[{d}]const u8: '{s}' (source: '{s}')}} ",
            .{ x, x + self.id.len, y, self.id.len, self.id, board.source[self.pos .. self.pos + self.id.len] },
        );
        assert(x + self.id.len - 1 <= board.width);

        return .{
            .x = try util.range(x, x + self.id.len, 1, default_allocator),
            .y = try util.rep(y, self.id.len, default_allocator),
        };
    }

    pub fn adjacent(self: *Self, board: Board, allocator: Allocator) ![]u8 {
        const pts = try self.coords(board);
        print("{}\n", .{pts});
        const partSize = self.id.len;

        var adj = try ArrayList(u8).initCapacity(allocator, 2 * partSize + 6);
        defer adj.deinit();

        const leftCol = pts.x[0];
        const rightCol = pts.x[partSize - 1];
        const row = pts.y[0];

        const top = row == 0;
        const left = leftCol == 0;
        const right = rightCol == board.width - 1;
        const bottom = row == board.height - 1;

        if (!top) {
            if (!left) try adj.append(board.getChar(.{ .x = leftCol - 1, .y = row - 1 }));
            for (pts.x, pts.y) |x, y| try adj.append(board.getChar(.{ .x = x, .y = y - 1 }));
            if (!right) try adj.append(board.getChar(.{ .x = rightCol + 1, .y = row - 1 }));
        }

        if (!left) try adj.append(board.getChar(.{ .x = leftCol - 1, .y = row }));
        // it would be
        // for (pts.x, pts.y) |x, y| try adj.append(board.getChar(.{ .x = x, .y = y }));
        // but those are the source points
        if (!right) try adj.append(board.getChar(.{ .x = rightCol + 1, .y = row }));

        if (!bottom) {
            if (!left) try adj.append(board.getChar(.{ .x = leftCol - 1, .y = row + 1 }));
            for (pts.x, pts.y) |x, y| try adj.append(board.getChar(.{ .x = x, .y = y + 1 }));
            if (!right) try adj.append(board.getChar(.{ .x = rightCol + 1, .y = row + 1 }));
        }

        return adj.toOwnedSlice();
    }
};

const PartsListError = error{ AtCapacity, PeekAfterPushNull };

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

    pub fn init(allocator: Allocator, capacity: usize, width: usize) !Self {
        return .{
            .allocator = allocator,
            .capacity = capacity,
            .width = width,
            .id = try allocator.alloc([]const u8, capacity),
            .idNo = try allocator.alloc(u32, capacity),
            .pos = try allocator.alloc(usize, capacity),
            .lastIdx = try allocator.alloc(?usize, capacity),
            .id2Idx = StringHashMap(usize).init(allocator),
        };
    }

    pub fn deinit(self: *Self) !void {
        self.allocator.destroy(self.id);
        self.allocator.destroy(self.pos);
        self.id2Idx.clearAndFree();
        self.allocator.destroy(self.id2Idx);
    }

    pub fn push(self: *Self, idNo: u32, id: []const u8, endPos: usize) !Part {
        if (self.size >= self.capacity) return PartsListError.AtCapacity;
        if (self.size > 0) self.index += 1;
        self.size += 1;
        self.idNo[self.index] = idNo;
        self.id[self.index] = id;
        self.pos[self.index] = endPos - id.len;
        self.lastIdx[self.index] = self.id2Idx.get(id);
        try self.id2Idx.put(id, self.index);
        return self.peek() orelse PartsListError.PeekAfterPushNull;
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
    source: []const u8,
    width: usize,
    height: usize,
    rowTerm: u8,
    naRune: u8,
    delims: []const u8,
    tokens: std.mem.TokenIterator(u8, std.mem.DelimiterType.any),

    const Self = @This();

    pub fn getChar(self: *const Self, pt: Point) u8 {
        const pos = pt.toPos(self.width);
        return self.source[pos];
    }

    pub fn init(allocator: Allocator, source: []const u8, rowTerm: u8, naRune: u8) !Self {
        const firstLF = indexOf(u8, source, '\n') orelse source.len;
        const width = firstLF + 1;
        const height = source.len / width;
        print(
            "Board: source.len {d} | w*h: {d}*{d} | first '\\n': {d}\n",
            .{ source.len, width, height, firstLF },
        );
        assert(width < source.len);
        assert(source.len % width == 0); // len doesn't count the EOF
        var delims = try std.fmt.allocPrint(allocator, "{c}{c}", .{ naRune, rowTerm });
        var tokens = tokenizeAny(u8, source, delims);

        return .{
            .source = source,
            .width = width,
            .height = height,
            .rowTerm = rowTerm,
            .naRune = naRune,
            .delims = delims,
            .tokens = tokens,
        };
    }
};

pub fn part1() !void {
    var board = try Board.init(default_allocator, data, '\n', '.');
    var sum: u32 = 0;

    var parts = try PartsList.init(
        default_allocator,
        board.source.len,
        board.width,
    );

    while (board.tokens.next()) |token| {
        var idNo = parseInt(u32, token, 10) catch continue;
        var part = try parts.push(idNo, token, board.tokens.index);
        for (try part.adjacent(board, default_allocator)) |cha| {
            if (cha != '.' and indexOf(u8, digits, cha) == null) {
                sum += part.idNo;
            }
        }
    }

    print("part1 answer is: {d}", .{sum});
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
