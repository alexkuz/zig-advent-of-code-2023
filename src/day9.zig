const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Int = i32;
const NumArray = std.ArrayList(Int);

pub fn day9() anyerror!Result {
    var allocator = std.heap.page_allocator;
    var result: Result = std.mem.zeroes(Result);

    var reader = try LineReader.open("data/day9.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    var seq_list: [21][21]Int = undefined;

    var sum1: Int = 0;
    var sum2: Int = 0;

    while (try reader.next()) |line| : (n += 1) {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        var sequence = NumArray.init(allocator);
        defer sequence.deinit();

        while (it.next()) |str| {
            var num = try std.fmt.parseInt(Int, str, 10);
            try sequence.append(num);
        }
        
        var len = sequence.items.len;

        for (sequence.items, 0..) |num, i| {
            seq_list[0][i] = num;
        }

        var seq_no: u32 = 1;

        while (seq_no < seq_list.len) : (seq_no += 1) {
            var all_equal = true;
            var first = seq_list[seq_no - 1][1] - seq_list[seq_no - 1][0];
            seq_list[seq_no][0] = first;
            for (0..(len - seq_no)) |i| {
                var curr = seq_list[seq_no - 1][i + 1] - seq_list[seq_no - 1][i];
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
            var seq_back_no = seq_no - i - 1;
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