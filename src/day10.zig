const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Pipe = enum(u3) {
    ground,
    westEast,
    northSouth,
    westNorth,
    westSouth,
    eastNorth,
    eastSouth,

    pub fn fromChar(char: u8) Pipe {
        return switch(char) {
            '-' => .westEast,
            '|' => .northSouth,
            'J' => .westNorth,
            '7' => .westSouth,
            'L' => .eastNorth,
            'F' => .eastSouth,
            else => .ground
        };        
    }

    pub fn from(self: Pipe, direction: Direction) bool {
        return switch(direction) {
            .north => self == .northSouth or self == .eastSouth or self == .westSouth,
            .west => self == .westEast or self == .eastSouth or self == .eastNorth,
            .south => self == .northSouth or self == .eastNorth or self == .westNorth,
            .east => self == .westEast or self == .westSouth or self == .westNorth,
        };
    }

    const all_moves = [_]Direction{
        .west, .east,
        .north, .south,
        .west, .north,
        .west, .south,
        .east, .north,
        .east, .south,
        .east, .south, .north, .west
    };

    pub fn moves(self: Pipe) []const Direction {
        return switch(self) {
            .westEast => all_moves[0..2],
            .northSouth => all_moves[2..4],
            .westNorth => all_moves[4..6],
            .westSouth => all_moves[6..8],
            .eastNorth => all_moves[8..10],
            .eastSouth => all_moves[10..12],
            else => all_moves[12..16]
        };
    }
};

const Direction = enum(u2) {
    north,
    west,
    east,
    south
};

const directions = std.meta.fields(Direction);

fn movePosition(pos: usize, direction: Direction, table_size: usize) ?usize {
    switch (direction) {
        .north => return if (pos < table_size) null else pos - table_size,
        .west => return if (pos % table_size == 0) null else pos - 1,
        .south => return if (pos + table_size >= table_size * table_size) null else pos + table_size,
        .east => return if (pos + 1 == table_size * table_size) null else pos + 1,
    }
}

pub fn day10(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;
    var table: []Pipe = undefined;
    defer allocator.free(table);
    var main_loop: []bool = undefined;
    defer allocator.free(main_loop);

    var table_size: usize = 0;

    var pos1: usize = undefined;
    var prev_pos1: usize = undefined;
    var pos2: usize = undefined;
    var prev_pos2: usize = undefined;

    while (try reader.next()) |line| : (n += 1) {
        if (table_size == 0) {
            table = try allocator.alloc(Pipe, line.len * line.len);
            main_loop = try allocator.alloc(bool, line.len * line.len);
            table_size = line.len;
        }

        for (line, 0..) |c, i| {
            const pos = n * table_size + i;
            table[pos] = Pipe.fromChar(c);
            main_loop[pos] = c == 'S';
            if (c == 'S') {
                prev_pos1 = pos;
                prev_pos2 = pos;
            }
        }
    }

    pos1 = try getNextPosition(prev_pos1, 0, table, table_size);
    main_loop[pos1] = true;
    pos2 = try getNextPosition(prev_pos2, pos1, table, table_size);
    main_loop[pos2] = true;

    var step: u32 = 2;

    while (true) {
        const next_pos1 = try getNextPosition(pos1, prev_pos1, table, table_size);
        main_loop[next_pos1] = true;
        if (next_pos1 == pos2) {
            break;
        }
        const next_pos2 = try getNextPosition(pos2, prev_pos2, table, table_size);
        main_loop[next_pos2] = true;
        if (next_pos2 == next_pos1) {
            break;
        }
        prev_pos1 = pos1;
        prev_pos2 = pos2;
        pos1 = next_pos1;
        pos2 = next_pos2;
        step += 1;
    }

    var inside = false;
    var inside_count: u32 = 0;

    for (0..table_size*table_size) |i| {
        if (main_loop[i]) {
            switch (table[i]) {
                .northSouth, .westNorth, .eastNorth => inside = !inside,
                else => {}
            }
        } else {
            if (inside) {
                inside_count += 1;
            }
        }
    }

    result.part1 = step;
    result.part2 = inside_count;

    return result;
}

fn getNextPosition(curr: usize, prev: usize, table: []Pipe, table_size: usize) !usize {
    const pipe = table[curr];

    for (pipe.moves()) |direction| {
        if (movePosition(curr, direction, table_size)) |next| {
            if (next != prev) {
                const next_pipe = table[next];
                if (next_pipe.from(direction)) {
                    return next;
                }
            }
        }
    }

    return error.DirectionNotFound;
}