const std = @import("std");
const Result = @import("./utils.zig").Result;

const day_runs = [_]DayRun{
    @import("./day1.zig").day1,
    @import("./day2.zig").day2,
    @import("./day3.zig").day3,
    @import("./day4.zig").day4,
    @import("./day5.zig").day5,
};

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

const DayRun = fn() anyerror!Result;

const ESC = "\x1b[";
const GRAY = ESC ++ "1;30m";
const RED = ESC ++ "1;31m";
const GREEN = ESC ++ "1;32m";
const YELLOW = ESC ++ "1;33m";
const CYAN = ESC ++ "1;36m";
const RESET = ESC ++ "0m";

const RED_STAR = RED ++ "*" ++ RESET;
const GREEN_STAR = GREEN ++ "*" ++ RESET;

const TITLE = "\n" ++
    (GREEN_STAR ++ " " ++ RED_STAR ++ " ") ** 5 ++
    GREEN ++ "Advent of Code 2023" ++
    (" " ++ RED_STAR ++ " " ++ GREEN_STAR) ** 5 ++
    "\n\n";

fn task(run: anytype, result: *Result) void {
    var timer = std.time.Timer.start() catch unreachable;
    var res = run() catch unreachable;
    result.* = res;
    result.time = timer.read();
}

pub fn main() !void {
    try stdout.print(TITLE, .{});

    var timer = try std.time.Timer.start();

    // ===============

    const allocator = std.heap.page_allocator;
    var results: [day_runs.len]*Result = undefined;
    var threads: [day_runs.len]std.Thread = undefined;

    var res: *Result = undefined;

    inline for (day_runs, 0..) |dayRun, i| {
        res = try allocator.create(Result);

        results[i] = res;
        threads[i] = try std.Thread.spawn(.{}, task, .{dayRun, res});
    }

    for (results, 0..) |result, i| {
        threads[i].join();
        try stdout.print("{s}Day {d:>2}:{s} {s}Part 1{s} = {d:>10}, {s}Part 2{s} = {d:>10} {s}({d:.3} ms){s}\n", .{
            YELLOW,
            i+1,
            RESET,
            CYAN,
            RESET,
            result.part1,
            CYAN,
            RESET,
            result.part2,
            GRAY,
            @as(f64, @floatFromInt(result.time)) / 10E6,
            RESET,
        });
    }

    // ===============

    const elapsed = timer.read();
    try stdout.print("\n{s}Elapsed time:{s} {d:.3} ms\n", .{ YELLOW, RESET, @as(f64, @floatFromInt(elapsed)) / 10E6 });

    try bw.flush();
}