const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Cubes = struct { green: u32 = 1, red: u32 = 1, blue: u32 = 1 };
const fields = std.meta.fields(Cubes);

pub fn day2(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    _ = allocator;
    var result: Result = std.mem.zeroes(Result);

    const total_cubes = Cubes{ .red = 12, .green = 13, .blue = 14 };

    var n: u32 = 0;

    while (try reader.next()) |line| : (n += 1) {
        const colon_idx = std.mem.indexOf(u8, line, ":").?;
        const game_no = try std.fmt.parseInt(u32, line[5..colon_idx], 10);
        const turns = line[(colon_idx + 2)..];

        var it = std.mem.split(u8, turns, "; ");

        var possible = true;

        var min_cubes = Cubes{};

        while (it.next()) |turn| {
            var it1 = std.mem.split(u8, turn, ", ");
            while (it1.next()) |keyval| {
                const space_idx = std.mem.indexOf(u8, keyval, " ").?;
                const val = try std.fmt.parseInt(u32, keyval[0..space_idx], 10);
                const color = keyval[(space_idx + 1)..];

                inline for (fields) |field| {
                    if (std.mem.eql(u8, color, field.name)) {
                        if (possible) {
                            possible = @field(total_cubes, field.name) >= val;
                        }
                        @field(min_cubes, field.name) = @max(@field(min_cubes, field.name), val);
                    }
                }
            }
        }

        if (possible) {
            result.part1 += game_no;
        }

        const power = min_cubes.red * min_cubes.green * min_cubes.blue;
        result.part2 += power;
    }

    return result;
}

const testResult = @import("utils.zig").testResult;

test "day2" {
    try testResult("test-data/day2.txt", day2, .Part1, 8);
    try testResult("test-data/day2.txt", day2, .Part2, 2286);
}
