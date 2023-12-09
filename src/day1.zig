const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const text_digits = [9][]const u8{
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine"
};

pub fn day1(allocator: std.mem.Allocator) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var reader = try LineReader.open("data/day1.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    while (try reader.next()) |line| : (n += 1) {
        var part2_found = false;

        var i: usize = 0;
        outer: while(i < line.len) : (i += 1) {
            if (line[i] >= '0' and line[i] <= '9') {
                result.part1 += (line[i] - '0') * 10;
                if (!part2_found) {
                   result.part2 += (line[i] - '0') * 10;
                }
                break :outer;                
            }

            if (part2_found) continue;

            inline for (text_digits, 1..) |digit, k| {
                if (line.len >= i + digit.len) {
                    if (std.mem.eql(u8, line[i .. i + digit.len], digit)) {
                        result.part2 += @as(u8, @intCast(k)) * 10;
                        part2_found = true;
                    }
                }
            }
        }

        part2_found = false;

        i = line.len;
        outer: while(i != 0) {
            i -= 1;
            if (line[i] >= '0' and line[i] <= '9') {
                result.part1 += line[i] - '0';
                if (!part2_found) {
                    result.part2 += line[i] - '0';
                }
                break :outer;
            }

            if (part2_found) continue;

            inline for (text_digits, 1..) |digit, k| {
                if (line.len >= i + digit.len) {
                    if (std.mem.eql(u8, line[i .. i + digit.len], digit)) {
                        result.part2 += @intCast(k);
                        part2_found = true;
                    }
                }
            }
        }
    }

    return result;
}