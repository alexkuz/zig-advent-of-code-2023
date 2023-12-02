const std = @import("std");

const day1 = @import("./day1.zig").day1;

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();


pub fn main() !void {
    const result = try day1();
    try stdout.print("Day 1: Part 1 = {d}, Part 2 = {d}\n", result);

    try bw.flush(); // don't forget to flush!
}
