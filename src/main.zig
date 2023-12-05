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

fn task(run: anytype, result: *Result) void {
    var timer = std.time.Timer.start() catch unreachable;
    var res = run() catch unreachable;
    result.* = res;
    result.time = timer.read();
}

pub fn main() !void {
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
        try stdout.print("Day {d:>2}: Part 1 = {d:>10}, Part 2 = {d:>8} ({d:.3} ms)\n", .{
            i+1,
            result.part1,
            result.part2,
            @as(f64, @floatFromInt(result.time)) / 10E6
        });
    }

    // ===============

    const elapsed = timer.read();
    try stdout.print("\nElapsed time: {d:.3} ms\n", .{ @as(f64, @floatFromInt(elapsed)) / 10E6 });

    try bw.flush();
}