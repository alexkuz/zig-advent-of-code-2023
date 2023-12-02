const std = @import("std");
const LineReader = @import("./utils.zig").LineReader;

const Cubes = struct {
    green: u32 = 1,
    red: u32 = 1,
    blue: u32 = 1
};
const fields = std.meta.fields(Cubes);

pub fn day2() !struct {u32, u32} {
    var part1: u32 = 0;
    var part2: u32 = 0;

    var total_cubes = Cubes{
        .red = 12,
        .green = 13,
        .blue = 14
    };

    var buf: [1024]u8 = undefined;

    var reader = try LineReader.open("data/day2.txt", &buf);
    defer reader.close();

    var n: u32 = 0;

    while (try reader.next()) |line| : (n += 1) {
        var colon_idx = std.mem.indexOf(u8, line, ":").?;
        var game_no = try std.fmt.parseInt(u32, line[5..colon_idx], 10);
        var turns = line[(colon_idx + 2)..];

        var it = std.mem.split(u8, turns, "; ");

        var possible = true;

        var min_cubes = Cubes{};

        while (it.next()) |turn| {
            var it1 = std.mem.split(u8, turn, ", ");
            while(it1.next()) |keyval| {
                var space_idx = std.mem.indexOf(u8, keyval, " ").?;
                var val = try std.fmt.parseInt(u32, keyval[0..space_idx], 10);
                var color = keyval[(space_idx+1)..];

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
            part1 += game_no;
        }

        var power = min_cubes.red * min_cubes.green * min_cubes.blue;
        part2 += power;
    }

    return .{ part1, part2 };
}