const std = @import("std");

pub fn day1() !struct {u32, u32} {
    const digits = [9]u8{
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9'
    };

    const text_digits = [9][]const u8{
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine"
    };

    var part1: u32 = 0;
    var part2: u32 = 0;

    var file = try std.fs.cwd().openFile("data/day1.txt", .{});
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();
    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    var writer = fbs.writer();

    var n: u32 = 0;
    
    while (true): (n += 1) {
        fbs.reset();
        stream.streamUntilDelimiter(writer, '\n', 1024) catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| return e,
        };

        var line = fbs.getWritten();

        var part2_found = false;

        var i: usize = 0;
        outer: while(i < line.len) : (i += 1) {
            for (digits, 1..) |digit, k| {
                if (digit == line[i]) {
                    part1 += @as(u8, @intCast(k)) * 10;
                    if (!part2_found) {
                       part2 += @as(u8, @intCast(k)) * 10;
                    }
                    break :outer;
                }
            }

            if (part2_found) continue;

            for (text_digits, 1..) |digit, k| {
                if (line.len >= i + digit.len) {
                    if (std.mem.eql(u8, line[i .. i + digit.len], digit)) {
                        part2 += @as(u8, @intCast(k)) * 10;
                        part2_found = true;
                    }
                }
            }
        }

        part2_found = false;

        i = line.len;
        outer: while(i != 0) {
            i -= 1;
            for (digits, 1..) |digit, k| {
                if (digit == line[i]) {
                    part1 += @as(u8, @intCast(k));
                    if (!part2_found) {
                        part2 += @as(u8, @intCast(k));
                    }
                    break :outer;
                }
            }

            if (part2_found) continue;

            for (text_digits, 1..) |digit, k| {
                if (line.len >= i + digit.len) {
                    if (std.mem.eql(u8, line[i .. i + digit.len], digit)) {
                        part2 += @as(u8, @intCast(k));
                        part2_found = true;
                    }
                }
            }
        }
    }

    return .{ part1, part2 };
}