const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const HashFn = std.hash.XxHash3;

const Position = struct { col: u8, row: u8 };

const MAX_LOOP: u64 = 1E9;

const HashMapContext = struct {
    pub fn hash(_: HashMapContext, key: [100]u100) u64 {
        return HashFn.hash(0, std.mem.asBytes(&key));
    }
    pub fn eql(_: HashMapContext, a: [100]u100, b: [100]u100) bool {
        return std.mem.eql(u100, &a, &b);
    }
};

const SolvedHashMap = std.hash_map.HashMap([100]u100, u32, HashMapContext, std.hash_map.default_max_load_percentage);

pub fn day14(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var rock_table: [100]u100 = std.mem.zeroes([100]u100);
    var trans_rock_table: [100]u100 = std.mem.zeroes([100]u100);

    var cube_table: [100]u100 = std.mem.zeroes([100]u100);
    var trans_cube_table: [100]u100 = std.mem.zeroes([100]u100);

    var len: u8 = 0;

    var solved = SolvedHashMap.init(allocator);
    defer solved.deinit();

    var rock_pos = std.ArrayList(Position).init(allocator);
    defer rock_pos.deinit();

    var weights = std.ArrayList(u32).init(allocator);
    defer weights.deinit();

    while (try reader.next()) |line| : (n += 1) {
        len = @truncate(line.len);
        for (line, 0..) |c, i| {
            if (c == '#') {
                cube_table[n] |= @as(u100, 1) << @truncate(len - i - 1);
                trans_cube_table[i] |= @as(u100, 1) << @truncate(len - n - 1);
            }
            if (c == 'O') {
                rock_table[n] |= @as(u100, 1) << @truncate(len - i - 1);
            }
        }
    }

    var cycle_found = false;

    var loop_idx: u64 = 0;

    while (loop_idx < MAX_LOOP) : (loop_idx += 1) {
        moveTop(rock_table, &trans_rock_table, cube_table, len);

        if (loop_idx == 0) {
            result.part1 = getTransWeight(trans_rock_table, len);
        }

        moveTop(trans_rock_table, &rock_table, trans_cube_table, len);

        moveBottom(rock_table, &trans_rock_table, cube_table, len);

        moveBottom(trans_rock_table, &rock_table, trans_cube_table, len);

        if (!cycle_found) {
            if (solved.get(rock_table)) |found| {
                cycle_found = true;
                const cycle_size = loop_idx - found;
                const skip_loops: u32 = @intFromFloat(@floor(@as(f64, @floatFromInt(MAX_LOOP - loop_idx)) / @as(f64, @floatFromInt(cycle_size))));
                loop_idx += skip_loops * cycle_size;
                result.part2 = weights.items[MAX_LOOP - loop_idx + found - 1];
                break;
            } else {
                try solved.put(rock_table, @truncate(loop_idx));
                try weights.append(getWeight(rock_table, len));
            }
        }
    }

    return result;
}

fn getWeight(rock_table: [100]u100, size: u32) u32 {
    var result: u32 = 0;
    for (0..size) |i| {
        const row = rock_table[i];
        result += @popCount(row) * @as(u32, @truncate(size - i));
    }
    return result;
}

fn getTransWeight(rock_table: [100]u100, size: u32) u32 {
    var result: u32 = 0;
    for (0..size) |i| {
        const row = rock_table[i];
        for (0..size) |k| {
            const bit = @as(u100, 1) << @truncate(size - k - 1);
            if (row & bit != 0) {
                result += @truncate(size - k);
            }
        }
    }
    return result;
}

fn moveTop(src: [100]u100, dest: *[100]u100, cube_table: [100]u100, size: u8) void {
    for (0..size) |col| {
        var dest_col: u100 = 0;
        var pos: u8 = 0;
        const bit: u100 = @as(u100, 1) << @truncate(size - col - 1);
        for (0..size) |row| {
            if (src[row] & bit != 0) {
                dest_col |= @as(u100, 1) << @truncate(size - pos - 1);
                pos += 1;
            } else if (cube_table[row] & bit != 0) {
                pos = @truncate(row + 1);
            }
        }
        dest[col] = dest_col;
    }
}

fn moveBottom(src: [100]u100, dest: *[100]u100, cube_table: [100]u100, size: u8) void {
    for (0..size) |col| {
        var dest_col: u100 = 0;
        var pos: u8 = size - 1;
        const bit: u100 = @as(u100, 1) << @truncate(size - col - 1);
        for (0..size) |i| {
            const row = size - i - 1;

            if (src[row] & bit != 0) {
                dest_col |= @as(u100, 1) << @truncate(size - pos - 1);
                if (pos > 0) pos -= 1;
            } else if (cube_table[row] & bit != 0 and row > 0) {
                pos = @truncate(row - 1);
            }
        }
        dest[col] = dest_col;
    }
}

fn printMap(rock_table: [100]u100, cube_table: [100]u100, size: u8) void {
    for (0..size) |row| {
        for (0..size) |col| {
            const bit: u100 = @as(u100, 1) << @truncate(size - col - 1);
            if (rock_table[row] & bit != 0) {
                std.debug.print("O", .{});
            } else if (cube_table[row] & bit != 0) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n=======\n\n", .{});
}

fn printTransMap(rock_table: [100]u100, cube_table: [100]u100, size: u8) void {
    for (0..size) |row| {
        const bit: u100 = @as(u100, 1) << @truncate(size - row - 1);
        for (0..size) |col| {
            if (rock_table[col] & bit != 0) {
                std.debug.print("O", .{});
            } else if (cube_table[col] & bit != 0) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n=======\n\n", .{});
}

const testResult = @import("utils.zig").testResult;

test "day14" {
    try testResult("test-data/day14.txt", day14, .Part1, 136);
    try testResult("test-data/day14.txt", day14, .Part2, 64);
}
