const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Number = struct {
    num: u16,
    line: usize,
    pos: usize,
    len: usize
};

const Symbol = struct {
    left_part: u16,
    right_part: u16,
    count: u8,
    gear: bool
};


const len = 140;

pub fn day3(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var numbers = std.ArrayList(Number).init(allocator);
    defer numbers.deinit();

    var symbol_loc = std.mem.zeroes([len][len]usize);

    var symbols = std.ArrayList(Symbol).init(allocator);
    defer symbols.deinit();

    while (try reader.next()) |line| : (n += 1) {
        var start_pos: usize = 0;
        var cur_number: u16 = 0;
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
            } else {
                if (cur_number > 0) {
                    try numbers.append(Number{.num = cur_number,.pos = start_pos, .len = num_len, .line = n});
                    start_pos = 0;
                    cur_number = 0;
                    num_len = 0;
                }
                if (char != '.') {
                    try symbols.append(Symbol{.count = 0, .left_part = 0, .right_part = 0, .gear = char == '*'});
                    symbol_loc[n][pos] = symbols.items.len;
                }
            }
        }
        if (cur_number > 0) {
            try numbers.append(Number{.num = cur_number,.pos = start_pos, .len = num_len, .line = n});
        }
    }

    for (numbers.items) |number| {
        var symbol_found = false;
        inline for (0..5) |p| {
            if (p > 0 or number.pos > 0) {
                const pos = number.pos + p - 1;
                if (pos < len and p < number.len + 2) { 
                    inline for (0..3) |l| {
                        if (l > 0 or number.line > 0) {
                            const ln = number.line + l - 1;
                            if (ln < n) {
                                const idx = symbol_loc[ln][pos];
                                if (idx > 0) {
                                    var sym = &symbols.items[idx - 1];
                                    if (sym.gear) {
                                        sym.count += 1;
                                        if (sym.count > 1) {
                                            sym.right_part = number.num;
                                        } else {
                                            sym.left_part = number.num;
                                        }
                                    }
                                    if (!symbol_found) {
                                        result.part1 += number.num;
                                        symbol_found = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    for (symbols.items) |symbol| {
        if (symbol.gear and symbol.count == 2) {
            result.part2 += @as(u32,symbol.left_part) * @as(u32,symbol.right_part);
        }
    }

    return result;
}
