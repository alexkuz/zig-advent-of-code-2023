const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Direction = enum(u2) {
    right,
    down,
    left,
    up,

    pub fn fromChar(c: u8) Direction {
        return switch (c) {
            'R' => .right,
            'D' => .down,
            'L' => .left,
            'U' => .up,
            else => unreachable,
        };
    }
};

const Step = struct {
    dir: Direction,
    count: u32,
};

const Line = struct {
    x: u32,
    start_y: u32,
    end_y: u32,
};

const Cursor = struct {
    x: i64,
    y: i64,
    min_x: i64,
    min_y: i64,
    max_x: i64,
    max_y: i64,
};

pub fn day18(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var plan_pt1 = std.ArrayList(Step).init(allocator);
    defer plan_pt1.deinit();

    var plan_pt2 = std.ArrayList(Step).init(allocator);
    defer plan_pt2.deinit();

    var cur_pt1 = std.mem.zeroes(Cursor);
    var cur_pt2 = std.mem.zeroes(Cursor);

    var vert_lines_pt1 = std.ArrayList(Line).init(allocator);
    defer vert_lines_pt1.deinit();

    var vert_lines_pt2 = std.ArrayList(Line).init(allocator);
    defer vert_lines_pt2.deinit();

    while (try reader.next()) |line| : (n += 1) {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const dir_pt1 = Direction.fromChar((it.next().?)[0]);
        const count_pt1 = try std.fmt.parseInt(u4, it.next().?, 10);

        const color = try std.fmt.parseInt(u24, it.next().?[2..8], 16);
        const dir_pt2: Direction = @enumFromInt(color & 0xF);
        const count_pt2 = (color & 0xFFFFF0) >> 4;

        updateCursor(&cur_pt1, dir_pt1, count_pt1);
        updateCursor(&cur_pt2, dir_pt2, count_pt2);

        try plan_pt1.append(.{
            .dir = dir_pt1,
            .count = count_pt1,
        });

        try plan_pt2.append(.{
            .dir = dir_pt2,
            .count = count_pt2,
        });
    }

    try fillVertLines(&vert_lines_pt1, plan_pt1.items, cur_pt1.min_x, cur_pt1.min_y);
    try fillVertLines(&vert_lines_pt2, plan_pt2.items, cur_pt2.min_x, cur_pt2.min_y);

    result.part1 = try calcVolume(allocator, vert_lines_pt1);
    result.part2 = try calcVolume(allocator, vert_lines_pt2);

    return result;
}

fn updateCursor(cursor: *Cursor, dir: Direction, count: u32) void {
    switch (dir) {
        .right => {
            cursor.x += count;
            cursor.max_x = @max(cursor.max_x, cursor.x);
        },
        .left => {
            cursor.x -= count;
            cursor.min_x = @min(cursor.min_x, cursor.x);
        },
        .down => {
            cursor.y += count;
            cursor.max_y = @max(cursor.max_y, cursor.y);
        },
        .up => {
            cursor.y -= count;
            cursor.min_y = @min(cursor.min_y, cursor.y);
        },
    }
}

fn fillVertLines(lines: *std.ArrayList(Line), plan_items: []Step, min_x: i64, min_y: i64) anyerror!void {
    var x: u32 = @intCast(-min_x);
    var y: u32 = @intCast(-min_y);
    for (plan_items) |step| {
        switch (step.dir) {
            .right => x += step.count,
            .left => x -= step.count,
            .down => {
                try lines.append(.{ .x = x, .start_y = y, .end_y = y + step.count });
                y += step.count;
            },
            .up => {
                try lines.append(.{ .x = x, .start_y = y - step.count, .end_y = y });
                y -= step.count;
            },
        }
    }
}

fn calcVolume(allocator: std.mem.Allocator, lines: std.ArrayList(Line)) anyerror!i64 {
    var result: i64 = 0;
    var keypoint_map = std.AutoArrayHashMap(u32, void).init(allocator);
    defer keypoint_map.deinit();

    var queue = std.ArrayList(*const Line).init(allocator);
    defer queue.deinit();

    for (lines.items) |line| {
        try keypoint_map.put(line.start_y, {});
        try keypoint_map.put(line.end_y, {});
    }

    const keypoints = keypoint_map.keys();

    std.sort.pdq(u32, keypoints, {}, std.sort.asc(u32));

    var last_y: u32 = 0;

    for (keypoints) |y| {
        var diff_y = y - last_y;
        if (y > 0) {
            diff_y -= 1;
        }

        for (lines.items) |*line| {
            if (line.start_y == y) {
                try queue.append(line);
            }
        }

        std.sort.pdq(*const Line, queue.items, {}, compareLines);

        var inside_before = false;
        var inside_after = false;
        var last_x: u32 = 0;

        var outside = true;
        var outside_before = true;

        for (queue.items) |line| {
            const diff_x = line.x - last_x;
            if (inside_before) {
                result += @as(i64, diff_x) * diff_y;
                if (outside_before) {
                    result += diff_y;
                }
                outside_before = false;
            } else {
                outside_before = true;
            }

            if (inside_before or inside_after) {
                result += diff_x;
                if (outside) {
                    result += 1;
                }
                outside = false;
            } else {
                outside = true;
            }

            if (line.start_y < y) {
                inside_before = !inside_before;
            }
            if (line.end_y > y) {
                inside_after = !inside_after;
            }
            last_x = line.x;
        }

        for (lines.items) |*line| {
            if (line.end_y == y) {
                if (std.mem.indexOfScalar(*const Line, queue.items, line)) |idx| {
                    _ = queue.orderedRemove(idx);
                }
            }
        }

        last_y = y;
    }

    return result;
}

fn compareLines(_: void, a: *const Line, b: *const Line) bool {
    return a.x < b.x;
}

const testResult = @import("utils.zig").testResult;

test "day18 - Part 1" {
    try testResult("test-data/day18.txt", day18, .Part1, 62);
}

test "day18 - Part 2" {
    try testResult("test-data/day18.txt", day18, .Part2, 952408144115);
}
