const std = @import("std");
const Result = @import("utils.zig").Result;

const day_runs = [_]DayRun{
    @import("day1.zig").day1,
    @import("day2.zig").day2,
    @import("day3.zig").day3,
    @import("day4.zig").day4,
    @import("day5.zig").day5,
    @import("day6.zig").day6,
    @import("day7.zig").day7,
    @import("day8.zig").day8,
    @import("day9.zig").day9,
};

const stdout_file = std.io.getStdOut().writer();

const DayRun = fn() anyerror!Result;

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

fn task(run: anytype, result: *Result) void {
    var timer = std.time.Timer.start() catch unreachable;
    var res = run() catch unreachable;
    result.* = res;
    result.time = timer.read();
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var no_print = false;

    var args = try std.process.argsWithAllocator(allocator);
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--no-print")) {
            no_print = true;
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
        threads[i] = try std.Thread.spawn(.{}, task, .{dayRun, res});
    }

    var totalTime: u64 = 0;

    for (results, 0..) |result, i| {
        threads[i].join();
        totalTime += result.time;

        if (!no_print) {
            var buf1: [32]u8 = undefined;
            var buf2: [32]u8 = undefined;
            var part1 = try printNumber(result.part1, &buf1);
            var part2 = try printNumber(result.part2, &buf2);

            try stdout.print("│ {s}Day {d:<2}{s} │ {s} │ {s} │ {s}{d:>3.0} μs{s} │\n", .{
                YELLOW,
                i+1,
                RESET,
                part1,
                part2,
                GRAY,
                @as(f64, @floatFromInt(result.time)) / 10E3,
                RESET,
            });
        }
    }

    if (!no_print) {
        try stdout.print("├────────┼────────────────┴────────────────┴────────┤\n", .{});

        const elapsed = timer.read();
        var buf: [100]u8 = undefined;
        var timeStr = try std.fmt.bufPrint(&buf, "{s}{d:.0}{s} μs (threaded), {s}{d:.0}{s} μs (total)", .{
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
    if (num > 0) {
        return try std.fmt.bufPrint(buf, "{d:>14}", .{@as(u64,@intCast(num))});
    } else {
        return try std.fmt.bufPrint(buf, "{d:>14}", .{num});
    }
}