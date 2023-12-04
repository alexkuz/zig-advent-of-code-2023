const std = @import("std");
const LineReader = @import("./utils.zig").LineReader;

pub fn day4() !struct {u32, u32} {
    var allocator = std.heap.page_allocator;
    var part1: u32 = 0;
    var part2: u32 = 0;

    var reader = try LineReader.open("data/day4.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    var copies: [213]u32 = std.mem.zeroes([213]u32);

    while (try reader.next()) |line| : (n += 1) {
        var colon_idx = std.mem.indexOf(u8, line, ":").?;
        var bar_idx = std.mem.indexOf(u8, line, "|").?;
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

        part1 += points;
    }

    for (copies) |count| {
        part2 += 1 + count;
    }

    return .{ part1, part2 };
}