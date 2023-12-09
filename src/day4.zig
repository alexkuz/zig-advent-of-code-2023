const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

pub fn day4() anyerror!Result {
    var allocator = std.heap.page_allocator;
    var result: Result = std.mem.zeroes(Result);

    var reader = try LineReader.open("data/day4.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    var copies: [213]u32 = std.mem.zeroes([213]u32);

    var colon_idx: usize = 0;
    var bar_idx: usize = 0;

    while (try reader.next()) |line| : (n += 1) {
        if (colon_idx == 0) {
            colon_idx = std.mem.indexOf(u8, line, ":").?;
            bar_idx = std.mem.indexOf(u8, line, "|").?;
        }
        var win_numbers = line[colon_idx+2..bar_idx-1];
        var card_numbers = line[bar_idx+2..];

        var points: u32 = 0;

        var count: u8 = 0;

        for (0..25) |i| {
            for (0..10) |k| {
                if (std.mem.eql(u8, win_numbers[3*k..3*k+2], card_numbers[3*i..3*i+2])) {
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

    for (copies) |count| {
        result.part2 += 1 + count;
    }

    return result;
}