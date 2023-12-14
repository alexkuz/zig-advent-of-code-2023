const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

pub fn day4(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    _ = allocator;
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var copies: [213]u32 = std.mem.zeroes([213]u32);

    var colon_idx: usize = 0;
    var bar_idx: usize = 0;

    while (try reader.next()) |line| : (n += 1) {
        if (colon_idx == 0) {
            colon_idx = std.mem.indexOf(u8, line, ":").?;
            bar_idx = std.mem.indexOf(u8, line, "|").?;
        }
        var win_numbers = line[colon_idx+1..bar_idx-1];
        var card_numbers = line[bar_idx+1..];

        const win_len: u32 = @truncate(@divFloor(win_numbers.len, 3));
        const card_len: u32 = @truncate(@divFloor(card_numbers.len, 3));

        var points: u32 = 0;

        var count: u8 = 0;

        for (0..card_len) |i| {
            for (0..win_len) |k| {
                if (std.mem.eql(u8, win_numbers[3*k..3*k+3], card_numbers[3*i..3*i+3])) {
                    points = @max(points*2, 1);
                    count += 1;
                }
            }
        }

        for(0..count) |i| {
            copies[n + i + 1] += (1 + copies[n]);
        }

        result.part1 += points;
    }

    for (0..n) |i| {
        const count = copies[i];
        result.part2 += 1 + count;
    }

    return result;
}

const testResult = @import("utils.zig").testResult;

test "day4" {
    try testResult("test-data/day4.txt", day4, .Part1, 13);
    try testResult("test-data/day4.txt", day4, .Part2, 30);
}
