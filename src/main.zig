const std = @import("std");
const Result = @import("utils.zig").Result;
const AppAllocator = @import("utils.zig").AppAllocator;
const LineReader = @import("utils.zig").LineReader;
const FileLineReader = @import("utils.zig").FileLineReader;

const DayRun = struct{
    run: fn(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result,
    data: []const u8,
};

const day_runs = [_]DayRun{
    .{ .run = @import("day1.zig").day1, .data = "data/day1.txt"},
    .{ .run = @import("day2.zig").day2, .data = "data/day2.txt"},
    .{ .run = @import("day3.zig").day3, .data = "data/day3.txt"},
    .{ .run = @import("day4.zig").day4, .data = "data/day4.txt"},
    .{ .run = @import("day5.zig").day5, .data = "data/day5.txt"},
    .{ .run = @import("day6.zig").day6, .data = "data/day6.txt"},
    .{ .run = @import("day7.zig").day7, .data = "data/day7.txt"},
    .{ .run = @import("day8.zig").day8, .data = "data/day8.txt"},
    .{ .run = @import("day9.zig").day9, .data = "data/day9.txt"},
    .{ .run = @import("day10.zig").day10, .data = "data/day10.txt"},
    .{ .run = @import("day11.zig").day11, .data = "data/day11.txt"},
    .{ .run = @import("day12.zig").day12, .data = "data/day12.txt"},
    .{ .run = @import("day13.zig").day13, .data = "data/day13.txt"},
    .{ .run = @import("day14.zig").day14, .data = "data/day14.txt"},
};

const stdout_file = std.io.getStdOut().writer();

const ESC = "\x1b[";
const WHITE = ESC ++ "1m";
const GRAY = ESC ++ "1;30m";
const RED = ESC ++ "1;31m";
const GREEN = ESC ++ "1;32m";
const YELLOW = ESC ++ "1;33m";
const CYAN = ESC ++ "1;36m";
const RESET = ESC ++ "0m";

const RED_STAR = RED ++ "*" ++ RESET;
const GREEN_STAR = GREEN ++ "*" ++ RESET;

const TITLE = RED_STAR ++ " " ++ (GREEN_STAR ++ " " ++ RED_STAR ++ " ") ** 3 ++
    GREEN ++ "Advent of Code 2023" ++
    (" " ++ RED_STAR ++ " " ++ GREEN_STAR) ** 3 ++ " " ++ RED_STAR;

fn task(run: anytype, data: []const u8, result: *Result, allocator: std.mem.Allocator) void {
    var timer = std.time.Timer.start() catch unreachable;
    var reader = FileLineReader.open(data, allocator) catch unreachable;
    defer reader.close();
    const res = run(allocator, &reader) catch unreachable;
    result.* = res;
    result.time = timer.read();
}

pub fn main() !void {
    const allocator = AppAllocator;
    var no_print = false;
    var no_spoilers = false;

    var args = try std.process.argsWithAllocator(allocator);
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--no-print")) {
            no_print = true;
        }
        if (std.mem.eql(u8, arg, "--no-spoilers")) {
            no_spoilers = true;
        }
    }

    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    if (!no_print) {
        try stdout.print("╭───────────────────────────────────────────────────╮\n", .{});
        try stdout.print("│  {s}  │\n", .{TITLE});
        try stdout.print("├────────┬────────────────┬────────────────┬────────┤\n", .{});
        try stdout.print("│        │         {s}Part 1{s} │         {s}Part 2{s} │        │\n", .{CYAN,RESET,CYAN,RESET});
        try stdout.print("├────────┼────────────────┼────────────────┼────────┤\n", .{});
    }

    var timer = try std.time.Timer.start();

    // ===============

    var results: [day_runs.len]*Result = undefined;
    var threads: [day_runs.len]std.Thread = undefined;

    var res: *Result = undefined;

    inline for (day_runs, 0..) |dayRun, i| {
        res = try allocator.create(Result);

        results[i] = res;
        threads[i] = try std.Thread.spawn(.{}, task, .{dayRun.run, dayRun.data, res, allocator});
    }

    var totalTime: u64 = 0;

    for (results, 0..) |result, i| {
        threads[i].join();
        totalTime += result.time;

        if (!no_print) {
            var buf1: [32]u8 = undefined;
            var buf2: [32]u8 = undefined;
            const part1 = if (no_spoilers) "*" ** 14 else try printNumber(result.part1, &buf1);
            const part2 = if (no_spoilers) "*" ** 14 else try printNumber(result.part2, &buf2);

            var buf: [10]u8 = undefined;
            var time_str: []u8 = undefined;
            if (result.time >= 10E6) {
                time_str = try std.fmt.bufPrint(&buf, "{d:>3.1} ms", .{@as(f64, @floatFromInt(result.time)) / 10E6});
            } else {
                time_str = try std.fmt.bufPrint(&buf, "{d:>3.0} μs", .{@as(f64, @floatFromInt(result.time)) / 10E3});
            }

            try stdout.print("│ {s}Day {d:<2}{s} │ {s} │ {s} │ {s}{s}{s} │\n", .{
                YELLOW,
                i+1,
                RESET,
                part1,
                part2,
                GRAY,
                time_str,
                RESET,
            });
        }
    }

    if (!no_print) {
        try stdout.print("├────────┼────────────────┴────────────────┴────────┤\n", .{});

        const elapsed = timer.read();
        var buf: [100]u8 = undefined;
        const timeStr = try std.fmt.bufPrint(&buf, "{s}{d:.0}{s} μs (threaded), {s}{d:.0}{s} μs (total)", .{
            WHITE,
            @as(f64, @floatFromInt(elapsed)) / 10E3,
            RESET,
            WHITE,
            @as(f64, @floatFromInt(totalTime)) / 10E3,
            RESET
        });
        try stdout.print("│ {s}Time{s}   │ {s:<56} │\n", .{
            YELLOW,
            RESET,
            timeStr
        });

        try stdout.print("╰────────┴──────────────────────────────────────────╯\n", .{});
    }

    try bw.flush();
}

fn printNumber(num: i64, buf: []u8) ![]u8 {
    if (num >= 0) {
        return try std.fmt.bufPrint(buf, "{d:>14}", .{@as(u64,@intCast(num))});
    } else {
        return try std.fmt.bufPrint(buf, "{d:>14}", .{num});
    }
}

test {
 @import("std").testing.refAllDecls(@This());
}