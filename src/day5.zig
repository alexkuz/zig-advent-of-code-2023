const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const SeedSlice = struct{
    start: u64,
    len: u64,
    used: bool
};

pub fn day5() anyerror!Result {
    var allocator = std.heap.page_allocator;
    var result: Result = std.mem.zeroes(Result);

    var reader = try LineReader.open("data/day5.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    var seeds: [20]u64 = undefined;
    var seed_mapped: [20]bool = undefined;
    var seed_ranges = std.ArrayList(SeedSlice).init(allocator);
    defer seed_ranges.deinit();

    var first_line = (try reader.next()).?;

    var it = std.mem.split(u8, first_line[7..], " ");
    var seed_no: usize = 0;
    while(it.next()) |seed| {
        seeds[seed_no] = try std.fmt.parseInt(u64, seed, 10);
        if (seed_no % 2 == 1) {
            try seed_ranges.append(.{ .start = seeds[seed_no-1], .len = seeds[seed_no], .used = false });
        }
        seed_no += 1;
    }

    while (try reader.next()) |line| : (n += 1) {
        if (line.len == 0) continue;
        if (line[0] > '9' or line[0] < '0') {
            for (seed_ranges.items) |*seed_range| {
                seed_range.used = false;
            }
            seed_mapped = std.mem.zeroes([20]bool);
            continue;
        }

        var it1 = std.mem.split(u8, line, " ");
        var dest_start = try std.fmt.parseInt(u64, it1.next().?, 10);
        var source_start = try std.fmt.parseInt(u64, it1.next().?, 10);
        var range_len = try std.fmt.parseInt(u64, it1.next().?, 10);

        for (seeds, 0..) |seed, idx| {
            if (seed_mapped[idx]) continue;
            if (seed >= source_start and seed < source_start + range_len) {
                seeds[idx] = seed - source_start + dest_start;
                seed_mapped[idx] = true;
            }
        }

        var len = seed_ranges.items.len;
        for (0..len) |i| {
            var seed_range = &seed_ranges.items[i];
            if (seed_range.used) continue;
            if (seed_range.start + seed_range.len <= source_start or seed_range.start >= source_start + range_len) {
                continue;
            }
            seed_range.used = true;
            if (seed_range.start < source_start) {
                try seed_ranges.append(.{
                    .start = seed_range.start,
                    .len = source_start - seed_range.start,
                    .used = false
                });
            }
            if (seed_range.start + seed_range.len > source_start + range_len) {
                try seed_ranges.append(.{
                    .start = source_start + range_len,
                    .len = seed_range.start + seed_range.len - (source_start + range_len),
                    .used = false
                }); 
            }

            var start = @max(seed_range.start,source_start);
            var end = @min(seed_range.start + seed_range.len,source_start + range_len);
            seed_ranges.items[i] = .{
                .start = start - source_start + dest_start,
                .len = end - start,
                .used = true
            };
        }
    }

    result.part1 = seeds[0];

    for (seeds) |seed| {
        result.part1 = @min(result.part1, seed);
    }

    result.part2 = seed_ranges.items[0].start;

    for (seed_ranges.items) |seed_range| {
        result.part2 = @min(result.part2, seed_range.start);
    }

    return result;
}