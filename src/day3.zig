const std = @import("std");
const LineReader = @import("./utils.zig").LineReader;
const Result = @import("./utils.zig").Result;

const Number = struct {
    num: u32,
    pos: usize,
    len: usize
};

const Gear = struct {
    count: u8,
    left_part: u32,
    right_part: u32,
};

const GearMap = std.AutoHashMap(struct{usize,usize}, *Gear);

const len = 140;

pub fn day3() anyerror!Result {
    var allocator = std.heap.page_allocator;
    var result: Result = std.mem.zeroes(Result);

    var reader = try LineReader.open("data/day3.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    var symbol_lines = std.ArrayList([len]u8).init(allocator);
    defer symbol_lines.deinit();

    var symbols: [3][len]u8 = std.mem.zeroes([3][len]u8);

    var prev_line_numbers: std.ArrayList(Number) = undefined;

    var gears = GearMap.init(allocator);
    defer gears.deinit();

    while (try reader.next()) |line| : (n += 1) {
        @memcpy(symbols[0][0..len], symbols[1][0..len]);
        @memcpy(symbols[1][0..len], symbols[2][0..len]);

        var line_numbers = std.ArrayList(Number).init(allocator);
        defer line_numbers.deinit();

        var start_pos: usize = 0;
        var cur_number: u32 = 0;
        var num_len: usize = 0;

        for (line, 0..) |char, pos| {
            if (char >= '0' and char <= '9') {
                if (cur_number == 0) {
                    start_pos = pos;
                    cur_number = char - '0';
                } else {
                    cur_number *= 10;
                    cur_number += char - '0';
                }
                num_len += 1;
                symbols[2][pos] = 0;
            } else {
                if (cur_number > 0) {
                    try line_numbers.append(Number{.num = cur_number,.pos = start_pos, .len = num_len});
                    start_pos = 0;
                    cur_number = 0;
                    num_len = 0;
                }
                if (char != '.') {
                    symbols[2][pos] = char;
                } else {
                    symbols[2][pos] = 0;
                }
            }
        }
        if (cur_number > 0) {
            try line_numbers.append(Number{.num = cur_number,.pos = start_pos, .len = num_len});
        }

        if (n > 0) {
            result.part1 += try sumValidNumbers(allocator, n, prev_line_numbers, symbols, &gears);
        }

        prev_line_numbers = try line_numbers.clone();
    }

    @memcpy(symbols[0][0..len], symbols[1][0..len]);
    @memcpy(symbols[1][0..len], symbols[2][0..len]);
    symbols[2] = std.mem.zeroes([len]u8);
    result.part1 += try sumValidNumbers(allocator, n, prev_line_numbers, symbols, &gears);

    var it = gears.iterator();

    while (it.next()) |entry| {
        var gear = entry.value_ptr;

        if (gear.*.count == 2) {
            result.part2 += gear.*.left_part * gear.*.right_part;
        }
    }

    return result;
}

fn sumValidNumbers(allocator: std.mem.Allocator, line: usize, numbers: std.ArrayList(Number), symbols: [3][len]u8, gears: *GearMap) !u32 {
    var sum: u32 = 0;

    for (numbers.items) |number| {
        // std.debug.print("Number: {}\n", .{number});
        var min_pos = if (number.pos == 0) 0 else number.pos - 1;
        var max_pos = @min(len-1, number.pos + number.len + 1);

        num: for(min_pos..max_pos) |i| {
            for (symbols, 0..) |symbol_line, l| {
                if (line + l < 2) {
                    continue;
                }
                var gear_line = line + l - 2;
                if (symbol_line[i] != 0) {
                    sum += number.num;
                    if (symbol_line[i] == '*') {
                        var val = try gears.getOrPut(.{gear_line, i});
                        if (val.found_existing) {
                            val.value_ptr.*.count += 1;
                            val.value_ptr.*.right_part = number.num;
                        } else {
                            var gear = try allocator.create(Gear);
                            errdefer allocator.destroy(gear);

                            gear.* = .{
                                .count = 1,
                                .left_part = number.num,
                                .right_part = 0,
                            };
                            val.value_ptr.* = gear;
                        }
                    }
                    break :num;
                }
            }
        }
    }

    return sum;
}