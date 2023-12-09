const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

pub fn day6() anyerror!Result {
    var allocator = std.heap.page_allocator;
    var result: Result = std.mem.zeroes(Result);

    var reader = try LineReader.open("data/day6.txt", allocator);
    defer reader.close();

    var times = std.ArrayList(u64).init(allocator);
    var distances = std.ArrayList(u64).init(allocator);

    var line = (try reader.next()).?;
    line = line[(std.mem.indexOf(u8, line, ":").?+2)..];
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    while (it.next()) |value| {
        try times.append(try std.fmt.parseInt(u64, value, 10));
    }

    line = std.mem.trim(u8, line, " ");
    std.mem.replaceScalar(u8, @constCast(line), ' ', '_');
    var total_time = try std.fmt.parseInt(u64, line, 10);

    line = (try reader.next()).?;
    line = line[(std.mem.indexOf(u8, line, ":").?+2)..];
    it = std.mem.tokenizeScalar(u8, line, ' ');
    while (it.next()) |value| {
        try distances.append(try std.fmt.parseInt(u64, value, 10));
    }

    line = std.mem.trim(u8, line, " ");
    std.mem.replaceScalar(u8, @constCast(line), ' ', '_');
    var total_distance = try std.fmt.parseInt(u64, line, 10);

    result.part1 = 1;

    for (times.items, 0..) |time, i| {
        var distance = distances.items[i];
        result.part1 *= calcTimeRange(time, distance);
    }

    result.part2 = calcTimeRange(total_time, total_distance);

    return result;
}

fn calcTimeRange(time: u64, distance: u64) u64 {
    // t ^ 2 - time * t + dist = 0 => t = ...
    var sqrt = @sqrt(@as(f64,@floatFromInt(time * time - 4 * distance)));
    var f_time: f64 = @floatFromInt(time);
    var min_time: u64 = @intFromFloat(@ceil((f_time - sqrt) / 2.0));
    var max_time: u64 = @intFromFloat(@floor((f_time + sqrt) / 2.0));

    if (distance == (time - min_time) * min_time) {
        min_time += 1;
        max_time -= 1;
    }
    return max_time - min_time + 1;
}
