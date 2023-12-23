const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Position = struct {
    x: u8,
    y: u8
};

pub fn day21(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;
    var size: u32 = 0;
    var field: [132]u132 = undefined;
    var reached_pt1 = std.ArrayList(Position).init(allocator);
    defer reached_pt1.deinit();

    var reached_pt2 = std.ArrayList(Position).init(allocator);
    defer reached_pt2.deinit();

    while (try reader.next()) |line| : (n += 1) {
        if (size == 0) {
            size = @truncate(line.len);
        }

        var row: u132 = 0;
        for (line, 0..) |c, i| {
            if (c == '#') {
                const bit = @as(u130,1) << @truncate(i);
                row |= bit;
            } else if (c == 'S') {
                try reached_pt1.append(.{ .x = @truncate(i), .y = @truncate(n) });
                try reached_pt2.append(.{ .x = @truncate(i), .y = @truncate(n) });
            }
        }
        field[n] = row;
    }

    const limit_pt1: u32 = if (size < 20) 6 else 64;

    for (0..limit_pt1) |_| {
        var positions = std.AutoArrayHashMap(Position, void).init(allocator);
        defer positions.deinit();

        for (reached_pt1.items) |pos| {
            // std.debug.print("{d}: position {any}\n", .{step, pos});
            if (pos.y > 0) {
                const bit = @as(u132,1) << @truncate(pos.x);
                if (field[pos.y - 1] & bit == 0) {
                    // std.debug.print("{d}: write north\n", .{step});
                    try positions.put(.{ .x = pos.x, .y = pos.y - 1 }, {});
                }
            }
            if (pos.y < size - 1) {
                const bit = @as(u132,1) << @truncate(pos.x);
                if (field[pos.y + 1] & bit == 0) {
                    // std.debug.print("{d}: write south\n", .{step});
                    try positions.put(.{ .x = pos.x, .y = pos.y + 1 }, {});
                }
            }
            if (pos.x > 0) {
                const bit = @as(u132,1) << @truncate(pos.x - 1);
                if (field[pos.y] & bit == 0) {
                    // std.debug.print("{d}: write west\n", .{step});
                    try positions.put(.{ .x = pos.x - 1, .y = pos.y }, {});
                }
            }
            if (pos.x < size - 1) {
                const bit = @as(u132,1) << @truncate(pos.x + 1);
                if (field[pos.y] & bit == 0) {
                    // std.debug.print("{d}: write east\n", .{step});
                    try positions.put(.{ .x = pos.x + 1, .y = pos.y }, {});
                }
            }
        }

        reached_pt1.clearAndFree();
        try reached_pt1.appendSlice(positions.keys());
    }

    const limit_pt2: u32 = if (size < 20) 5000 else 26501365;

    for (0..limit_pt2) |_| {
        var positions = std.AutoArrayHashMap(Position, void).init(allocator);
        defer positions.deinit();

        for (reached_pt2.items) |pos| {
            const bit_top_bottom = @as(u132,1) << @truncate(pos.x);
            if (field[(pos.y + size - 1) % size] & bit_top_bottom == 0) {
                try positions.put(.{ .x = pos.x, .y = @truncate((pos.y + size - 1) % size) }, {});
            }
            if (field[(pos.y + 1) % size] & bit_top_bottom == 0) {
                try positions.put(.{ .x = pos.x, .y = @truncate((pos.y + 1) % size) }, {});
            }
            const bit_left = @as(u132,1) << @truncate((pos.x + size - 1) % size);
            if (field[pos.y] & bit_left == 0) {
                try positions.put(.{ .x = @truncate((pos.x + size - 1) % size), .y = pos.y }, {});
            }
            const bit_right = @as(u132,1) << @truncate((pos.x + 1) % size);
            if (field[pos.y] & bit_right == 0) {
                try positions.put(.{ .x = @truncate((pos.x + 1) % size), .y = pos.y }, {});
            }
        }

        reached_pt2.clearAndFree();
        try reached_pt2.appendSlice(positions.keys());
    }    

    result.part1 = @as(u32, @truncate(reached_pt1.items.len));
    result.part2 = @as(u32, @truncate(reached_pt2.items.len));

    return result;
}

const testResult = @import("utils.zig").testResult;

test "day21 - Part 1" {
    try testResult("test-data/day21.txt", day21, .Part1, 16);
}

test "day21 - Part 2" {
    try testResult("test-data/day21.txt", day21, .Part2, 0);
}
