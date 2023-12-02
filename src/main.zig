const std = @import("std");

const day1 = @import("./day1.zig").day1;
const day2 = @import("./day2.zig").day2;

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();


pub fn main() !void {
    const result1 = try day1();
    try stdout.print("Day 1: Part 1 = {d}, Part 2 = {d}\n", result1);

    const result2 = try day2();
    try stdout.print("Day 1: Part 1 = {d}, Part 2 = {d}\n", result2);    

    try bw.flush(); // don't forget to flush!
}
