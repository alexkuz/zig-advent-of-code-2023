const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Mirror = enum(u3) {
    none,
    vSplitter,
    hSplitter,
    mirrorDown,
    mirrorUp,

    pub fn reflect(self: Mirror, direction: Direction) Direction {
        return switch (self) {
            .mirrorDown => switch (direction) {
                .right => .bottom,
                .left => .top,
                .bottom => .right,
                .top => .left,
            },
            .mirrorUp => switch (direction) {
                .right => .top,
                .left => .bottom,
                .bottom => .left,
                .top => .right,
            },
            else => unreachable,
        };
    }

    pub fn split(self: Mirror, direction: Direction) ?struct { Direction, Direction } {
        return switch (self) {
            .vSplitter => switch (direction) {
                .right, .left => .{ .top, .bottom },
                else => null,
            },
            .hSplitter => switch (direction) {
                .top, .bottom => .{ .left, .right },
                else => null,
            },
            else => unreachable,
        };
    }
};

const Mirrors = [110][110]Mirror;
const Energized = [110]u110;

const HashMapKey = struct {
    direction: Direction,
    x: u8,
    y: u8,
};

const EnergizedMap = std.AutoHashMap(HashMapKey, *Energized);

const Direction = enum(u2) {
    right,
    left,
    top,
    bottom,

    pub fn move(self: Direction, x: *u8, y: *u8, size: u8) bool {
        var moved = false;
        switch (self) {
            .right => if (x.* < size - 1) {
                x.* += 1;
                moved = true;
            },
            .left => if (x.* > 0) {
                x.* -= 1;
                moved = true;
            },
            .bottom => if (y.* < size - 1) {
                y.* += 1;
                moved = true;
            },
            .top => if (y.* > 0) {
                y.* -= 1;
                moved = true;
            },
        }
        return moved;
    }
};

pub fn day16(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;
    var size: u8 = 0;

    var mirrors: Mirrors = undefined;
    var energized_map = EnergizedMap.init(allocator);
    defer energized_map.deinit();

    while (try reader.next()) |line| : (n += 1) {
        if (size == 0) size = @truncate(line.len);

        for (line, 0..) |c, i| {
            mirrors[n][i] = switch (c) {
                '|' => .vSplitter,
                '-' => .hSplitter,
                '/' => .mirrorUp,
                '\\' => .mirrorDown,
                else => .none,
            };
        }
    }

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    for (0..size) |y| {
        if (try createBeams(arena_allocator, &energized_map, mirrors, 0, @truncate(y), .right, size, true)) |energized| {
            if (y == 0) {
                result.part1 = getEnergized(energized.*, size);
            }
            result.part2 = @max(result.part2, getEnergized(energized.*, size));
        }

        if (try createBeams(arena_allocator, &energized_map, mirrors, @truncate(size - 1), @truncate(y), .left, size, true)) |energized| {
            result.part2 = @max(result.part2, getEnergized(energized.*, size));
        }
    }

    for (0..size) |x| {
        // std.debug.print("TEST\n",.{});
        if (try createBeams(arena_allocator, &energized_map, mirrors, @truncate(x), 0, .bottom, size, true)) |energized| {
            result.part2 = @max(result.part2, getEnergized(energized.*, size));
            // printEnergized(energized.*);
        }

        if (try createBeams(arena_allocator, &energized_map, mirrors, @truncate(x), @truncate(size - 1), .top, size, true)) |energized| {
            result.part2 = @max(result.part2, getEnergized(energized.*, size));
        }
    }

    return result;
}

fn printEnergized(energized: Energized) void {
    std.debug.print("-------\n", .{});
    for (0..2) |y| {
        for (0..110) |x| {
            const bit = @as(u110, 1) << @truncate(x);
            if (bit & energized[y] != 0) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
        //std.debug.print("{b:>110}\n",.{energized[x]});
    }
    std.debug.print("-------\n", .{});
}

fn energizeTile(energized: *Energized, x: u8, y: u8) void {
    energized[y] |= @as(u110, 1) << @truncate(x);
}

fn getEnergized(energized: Energized, size: u8) u32 {
    var count: u32 = 0;
    // std.debug.print("-------\n",.{});
    for (0..size) |x| {
        // std.debug.print("{b}\n",.{energized[x]});
        count += @popCount(energized[x]);
    }
    // std.debug.print("-------\n",.{});
    return count;
}

fn mergeEnergized(a: *Energized, b: *Energized, size: u8) void {
    for (0..size) |y| {
        a[y] |= b[y];
    }
}

fn createBeams(allocator: std.mem.Allocator, energized_map: *EnergizedMap, mirrors: Mirrors, x: u8, y: u8, direction: Direction, size: u8, start: bool) anyerror!?*Energized {
    const mirror = mirrors[y][x];
    switch (mirror) {
        .mirrorDown, .mirrorUp => {
            return try shootBeam(allocator, energized_map, mirrors, x, y, mirror.reflect(direction), size);
        },
        .vSplitter, .hSplitter => {
            if (mirror.split(direction)) |directions| {
                const energized = try allocator.create(Energized);
                for (0..size) |i| {
                    energized[i] = 0;
                }

                const first = try shootBeam(allocator, energized_map, mirrors, x, y, directions[0], size);
                mergeEnergized(energized, first, size);
                const second = try shootBeam(allocator, energized_map, mirrors, x, y, directions[1], size);
                mergeEnergized(energized, second, size);

                return energized;
            }
        },
        .none => {
            if (start) {
                return try shootBeam(allocator, energized_map, mirrors, x, y, direction, size);
            }
        },
    }
    return null;
}

fn shootBeam(allocator: std.mem.Allocator, energized_map: *EnergizedMap, mirrors: Mirrors, start_x: u8, start_y: u8, direction: Direction, size: u8) anyerror!*Energized {
    const hash_key = HashMapKey{ .direction = direction, .x = start_x, .y = start_y };
    if (energized_map.get(hash_key)) |e| {
        // std.debug.print("CACHED: {d}, {d} ({any})\n", .{start_x, start_y, direction});
        return e;
    }

    const energized = try allocator.create(Energized);
    for (0..size) |i| {
        energized[i] = 0;
    }

    var x = start_x;
    var y = start_y;
    energizeTile(energized, x, y);

    // std.debug.print("PUT: {d}, {d} ({any})\n", .{start_x, start_y, direction});

    // if (print) {
    //     std.debug.print("PUT {any}: {d}, {d}\n", .{direction, start_x, start_y});
    //     printEnergized(energized.*);
    // }

    try energized_map.put(hash_key, energized);

    while (direction.move(&x, &y, size)) {
        // if (print) {
        //     std.debug.print("{d}, {d}\n", .{x, y});
        // }
        energizeTile(energized, x, y);
        // if (print) {
        //     printEnergized(energized.*);
        // }

        if (try createBeams(allocator, energized_map, mirrors, x, y, direction, size, false)) |e| {
            // if (print) {
            //     std.debug.print("{d}, {d}\n", .{x, y});
            //     printEnergized(e.*);
            // }
            // std.debug.print("{d}, {d} => {d}, {d} ({any})\n", .{start_x, start_y, x, y, direction});
            mergeEnergized(energized, e, size);
            break;
        }
    }

    // if (print) {
    // std.debug.print("{any}: {d}, {d}\n", .{direction, start_x, start_y});
    // printEnergized(energized.*);
    // }

    return energized;
}

const testResult = @import("utils.zig").testResult;

test "day16 - Part 1" {
    try testResult("test-data/day16.txt", day16, .Part1, 46);
}

test "day16 - Part 2" {
    try testResult("test-data/day16.txt", day16, .Part2, 51);
}
