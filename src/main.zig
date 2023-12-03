const std = @import("std");

const day1 = @import("./day1.zig").day1;
const day2 = @import("./day2.zig").day2;
const day3 = @import("./day3.zig").day3;

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();


pub fn main() !void {
    var timer = try std.time.Timer.start();

    // ===============

    const allocator = std.heap.page_allocator;
    var results = std.ArrayList(struct {u32,u32}).init(allocator);
    defer results.deinit();

    try results.append(try day1());

    try results.append(try day2());

    try results.append(try day3());

    for (results.items, 1..) |result, day| {
        try stdout.print("Day {d}: Part 1 = {d}, Part 2 = {d}\n", .{day,result[0],result[1]});        
    }

    // ===============

    const elapsed = timer.read();
    try stdout.print("\nElapsed time: {d:.3} ms\n", .{ @as(f64, @floatFromInt(elapsed)) / 10E6 });

    try bw.flush();
}