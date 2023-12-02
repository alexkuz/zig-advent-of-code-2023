const std = @import("std");

const day1 = @import("./day1.zig").day1;
const day2 = @import("./day2.zig").day2;

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();


pub fn main() !void {
    var timer = try std.time.Timer.start();

    // ===============

    const result1 = try day1();
    try stdout.print("Day 1: Part 1 = {d}, Part 2 = {d}\n", result1);

    const result2 = try day2();
    try stdout.print("Day 2: Part 1 = {d}, Part 2 = {d}\n", result2);

    // ===============

    const elapsed = timer.read();
    try stdout.print("\nElapsed time: {d:.3} ms\n", .{ @as(f64, @floatFromInt(elapsed)) / 10E6 });

    try bw.flush();
}