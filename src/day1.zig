const std = @import("std");
const LineReader = @import("./utils.zig").LineReader;
const Result = @import("./utils.zig").Result;

pub fn day1() anyerror!Result {
    var allocator = std.heap.page_allocator;
    const digits = [9]u8{
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9'
    };

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

    var part1: u32 = 0;
    var part2: u32 = 0;

    var reader = try LineReader.open("data/day1.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    while (try reader.next()) |line| : (n += 1) {
        var part2_found = false;

        var i: usize = 0;
        outer: while(i < line.len) : (i += 1) {
            for (digits, 1..) |digit, k| {
                if (digit == line[i]) {
                    part1 += @as(u8, @intCast(k)) * 10;
                    if (!part2_found) {
                       part2 += @as(u8, @intCast(k)) * 10;
                    }
                    break :outer;
                }
            }

            if (part2_found) continue;

            for (text_digits, 1..) |digit, k| {
                if (line.len >= i + digit.len) {
                    if (std.mem.eql(u8, line[i .. i + digit.len], digit)) {
                        part2 += @as(u8, @intCast(k)) * 10;
                        part2_found = true;
                    }
                }
            }
        }

        part2_found = false;

        i = line.len;
        outer: while(i != 0) {
            i -= 1;
            for (digits, 1..) |digit, k| {
                if (digit == line[i]) {
                    part1 += @as(u8, @intCast(k));
                    if (!part2_found) {
                        part2 += @as(u8, @intCast(k));
                    }
                    break :outer;
                }
            }

            if (part2_found) continue;

            for (text_digits, 1..) |digit, k| {
                if (line.len >= i + digit.len) {
                    if (std.mem.eql(u8, line[i .. i + digit.len], digit)) {
                        part2 += @as(u8, @intCast(k));
                        part2_found = true;
                    }
                }
            }
        }
    }

    return .{ part1, part2 };
}