const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const LensHashMap = std.AutoArrayHashMap(u64, u4);

pub fn day15(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var boxes: [256]LensHashMap = undefined;
    for (0..256) |i| {
        boxes[i] = LensHashMap.init(allocator);
    }

    while (try reader.nextUntilDelimiter(',')) |step| {
        result.part1 += getHash(step);
        var it = std.mem.tokenizeAny(u8, step, "-=");
        const label = it.next().?;
        var buf: [8]u8 = std.mem.zeroes([8]u8);
        std.mem.copyForwards(u8, &buf, label);
        const label_key = std.mem.readInt(u64, &buf, .big);
        const label_hash = getHash(label);

        const focal_length = it.next();

        if (focal_length) |l| {
            const entry = try boxes[label_hash].getOrPut(label_key);
            entry.value_ptr.* = @truncate(try std.fmt.parseInt(u8, l, 10));
        } else {
            _ = boxes[label_hash].orderedRemove(label_key);
        }
    }

    for (0..256) |i| {
        if (boxes[i].count() == 0) {
            boxes[i].deinit();
            continue;
        }

        for (boxes[i].values(), 1..) |value, idx| {
            result.part2 += (@as(u32, @truncate(i)) + 1) * @as(u32, @truncate(idx)) * value;
        }
        boxes[i].deinit();
    }

    return result;
}

fn getHash(str: []const u8) u8 {
    var hash: u16 = 0;
    for (str) |c| {
        hash = ((hash + c) * 17) % 256;
    }
    return @truncate(hash);
}

const testResult = @import("utils.zig").testResult;

test "day15" {
    try testResult("test-data/day15.txt", day15, .Part1, 1320);
    try testResult("test-data/day15.txt", day15, .Part2, 145);
}
