const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Int = u32;

const SHIFT1: u4 = 1;
const SHIFT2: Int = 1E6 - 1;

const Position = struct { x: Int, y: Int };

const Pair = struct { a: Int, b: Int };

pub fn day11(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var galaxies = std.ArrayList(Position).init(allocator);
    defer galaxies.deinit();

    var shift_rows: []Int = undefined;
    defer allocator.free(shift_rows);
    var shift_cols: []Int = undefined;
    defer allocator.free(shift_cols);

    var shift_rows2: []Int = undefined;
    defer allocator.free(shift_rows2);
    var shift_cols2: []Int = undefined;
    defer allocator.free(shift_cols2);

    var n: u8 = 0;

    var size: usize = 0;
    var expanded_width: usize = 0;
    var expanded_height: usize = 0;

    while (try reader.next()) |line| : (n += 1) {
        if (size == 0) {
            size = line.len;
            expanded_width = size;
            expanded_height = size;
            shift_rows = try allocator.alloc(Int, size);
            shift_cols = try allocator.alloc(Int, size);
            shift_rows2 = try allocator.alloc(Int, size);
            shift_cols2 = try allocator.alloc(Int, size);
            for (0..size) |i| {
                shift_rows[i] = 1;
                shift_cols[i] = 1;
                shift_rows2[i] = 1;
                shift_cols2[i] = 1;
            }
        }

        for (line, 0..) |c, i| {
            if (c == '#') {
                shift_rows[n] = 0;
                shift_cols[i] = 0;
                shift_rows2[n] = 0;
                shift_cols2[i] = 0;
                try galaxies.append(.{ .x = @truncate(i), .y = n });
            }
        }
    }

    var shift_x: u4 = 0;
    var shift_y: u4 = 0;
    var shift_x2: u32 = 0;
    var shift_y2: u32 = 0;

    for (0..size) |i| {
        if (shift_rows[i] == 1) {
            expanded_height += 1;
            shift_rows[i] += shift_y;
            shift_rows2[i] += shift_y2;
            shift_y += SHIFT1;
            shift_y2 += SHIFT2;
        } else {
            shift_rows[i] += shift_y;
            shift_rows2[i] += shift_y2;
        }
        if (shift_cols[i] == 1) {
            expanded_width += 1;
            shift_cols[i] += shift_x;
            shift_cols2[i] += shift_x2;
            shift_x += SHIFT1;
            shift_x2 += SHIFT2;
        } else {
            shift_cols[i] += shift_x;
            shift_cols2[i] += shift_x2;
        }
    }

    var galaxies2 = try galaxies.clone();
    defer galaxies2.deinit();

    for (galaxies.items, 0..) |*galaxy, i| {
        galaxy.x += shift_cols[galaxy.x];
        galaxy.y += shift_rows[galaxy.y];

        var galaxy2 = &galaxies2.items[i];
        galaxy2.x += shift_cols2[galaxy2.x];
        galaxy2.y += shift_rows2[galaxy2.y];
    }

    for (galaxies.items, 0..) |a, i| {
        for (0..i) |k| {
            const b = galaxies.items[k];
            result.part1 += @max(a.x, b.x) - @min(a.x, b.x) + @max(a.y, b.y) - @min(a.y, b.y);

            const a2 = galaxies2.items[i];
            const b2 = galaxies2.items[k];

            result.part2 += @max(a2.x, b2.x) - @min(a2.x, b2.x) + @max(a2.y, b2.y) - @min(a2.y, b2.y);
        }
    }

    return result;
}

const testResult = @import("utils.zig").testResult;

test "day11" {
    try testResult("test-data/day11.txt", day11, .Part1, 374);
}
