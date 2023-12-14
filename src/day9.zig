const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Int = i32;
const NumArray = std.ArrayList(Int);

pub fn day9(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    _ = allocator;
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var seq_list: [21][21]Int = undefined;

    var sum1: Int = 0;
    var sum2: Int = 0;

    while (try reader.next()) |line| : (n += 1) {
        var it = std.mem.tokenizeScalar(u8, line, ' ');

        var len: usize = 0;

        while (it.next()) |str| {
            const num = try std.fmt.parseInt(Int, str, 10);
            seq_list[0][len] = num;
            len += 1;
        }

        var seq_no: u32 = 1;

        while (seq_no < seq_list.len) : (seq_no += 1) {
            var all_equal = true;
            const first = seq_list[seq_no - 1][1] - seq_list[seq_no - 1][0];
            seq_list[seq_no][0] = first;
            for (0..(len - seq_no)) |i| {
                const curr = seq_list[seq_no - 1][i + 1] - seq_list[seq_no - 1][i];
                seq_list[seq_no][i] = curr;
                if (curr != first) {
                    all_equal = false;
                }
            }
            if (all_equal) {
                break;
            }
        }

        var last_num1: Int = seq_list[seq_no][0];
        var last_num2: Int = seq_list[seq_no][0];

        for (0..seq_no) |i| {
            const seq_back_no = seq_no - i - 1;
            last_num1 = seq_list[seq_back_no][len - seq_back_no - 1] + last_num1;
            last_num2 = seq_list[seq_back_no][0] - last_num2;
        }

        sum1 += last_num1;
        sum2 += last_num2;
    }

    result.part1 = sum1;
    result.part2 = sum2;

    return result;
}

const testResult = @import("utils.zig").testResult;

test "day9" {
    try testResult("test-data/day9.txt", day9, .Part1, 114);
    try testResult("test-data/day9.txt", day9, .Part2, 2);
}
