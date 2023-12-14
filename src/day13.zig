const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

pub fn day13(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var rows = std.ArrayList(u20).init(allocator);
    defer rows.deinit();
    var cols = std.ArrayList(u20).init(allocator);
    defer cols.deinit();
    var row_no: u5 = 0;

    while (try reader.next()) |line| : ({ n += 1; row_no += 1; }) {
        // std.debug.print("{d}: {s}\n", .{n,line});
        if (line.len == 0 and n > 0) {
            result.part1 += getResult(rows.items, cols.items, false);
            result.part2 += getResult(rows.items, cols.items, true);
            rows.clearAndFree();
            cols.clearAndFree();
            continue;
        }

        if (cols.items.len == 0) {
            row_no = 0;
            for (0..line.len) |_| {
                try cols.append(0);
            }
        }

        var row: u20 = 0;
        for (line, 0..) |c, i| {
            if (c == '#') {
                cols.items[i] |= @as(u20,1) << row_no;
                row |= @as(u20,1) << @truncate(line.len - i - 1);
            }
        }
        try rows.append(row);
    }

    if (cols.items.len > 0) {
        result.part1 += getResult(rows.items, cols.items, false);
        result.part2 += getResult(rows.items, cols.items, true);
    }

    return result;
}

fn getResult(row_items: []u20, col_items: []u20, with_smudge: bool) u32 {
    var result: u32 = 0;

    const row_idx = findMirror(row_items, with_smudge);
    result += 100 * @as(u32,row_idx);
    if (row_idx == 0) {
        const col_idx = findMirror(col_items, with_smudge);
        result += col_idx;
    }

    return result;
}

fn findMirror(items: []u20, with_smudge: bool) u8 {
    var last = items[0];
    var idx: u8 = 0;

    var has_smudge = false;

    loop: for (1..items.len) |i| {
        has_smudge = false;
        const item = items[i];

        var equal = item == last;
        if (!equal and with_smudge and std.math.isPowerOfTwo(item ^ last)) {
            // std.debug.print("found smudge: {b} {b}\n", .{item, last});
            equal = true;
            has_smudge = true;
        }
        if (equal) {
            const min: u8 = if (i < items.len - i) 0 else @truncate(i - (items.len - i));
            for (min..i-1) |k1| {
                const k2 = i + (i - k1 - 1);
                // std.debug.print("check {d} vs {d}\n", .{k1, k2});
                if (items[k1] != items[k2]) {
                    if (with_smudge and !has_smudge) {
                        if (std.math.isPowerOfTwo(items[k1] ^ items[k2])) {
                            // std.debug.print("found smudge: {b} {b}\n", .{items[k1], items[k2]});
                            has_smudge = true;
                            continue;
                        }
                    }
                    equal = false;
                    break;
                }
            }
            if (equal) {
                if (with_smudge and !has_smudge) {
                    continue;
                }
                // std.debug.print("found at {d}: {b}\n", .{i,item});
                idx = @truncate(i);
                break :loop;
            }
        }

        last = item;
    }

    if (with_smudge) {
        return if (has_smudge) idx else 0;
    }

    return idx;
}

const testResult = @import("utils.zig").testResult;

test "day13" {
    try testResult("test-data/day13.txt", day13, .Part1, 405);
    try testResult("test-data/day13.txt", day13, .Part2, 400);
}
