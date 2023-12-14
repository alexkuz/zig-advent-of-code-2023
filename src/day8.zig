const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Name = packed struct {
    a: u5,
    b: u5,
    c: u5,
    pub fn fromString(str: []const u8) Name {
        return .{
            .a = @as(u5, @truncate(str[0] - 'A')),
            .b = @as(u5, @truncate(str[1] - 'A')),
            .c = @as(u5, @truncate(str[2] - 'A')),
        };
    }
    pub fn eql(self: *Name, n: Name) bool {
        return self.a == n.a and self.b == n.b and self.c == n.c;
    }
};

const Route = packed struct { left: Name, right: Name };

const Node = packed struct { name: Name, cycle_count: u16 };

const len = 'Z' - 'A' + 1;
const final = Name.fromString("ZZZ");

pub fn day8(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var buf: [1024]u2 = undefined;

    const first_line = (try reader.next()).?;
    for (first_line, 0..) |c, i| {
        buf[i] = if (c == 'L') 0 else 1;
    }
    const directions = buf[0..first_line.len];

    var routeMap: [len][len][len]Route = undefined;

    var nodes = std.ArrayList(Node).init(allocator);
    defer nodes.deinit();

    var aaaIdx: usize = 0;

    while (try reader.next()) |line| : (n += 1) {
        if (line.len == 0) continue;
        const route: Route = .{
            .left = Name.fromString(line[7..10]),
            .right = Name.fromString(line[12..15]),
        };
        routeMap[line[0] - 'A'][line[1] - 'A'][line[2] - 'A'] = route;
        if (line[2] == 'A') {
            if (line[0] == 'A' and line[1] == 'A') {
                aaaIdx = nodes.items.len;
            }
            try nodes.append(.{ .name = Name.fromString(line[0..3]), .cycle_count = 0 });
        }
    }

    var step: u32 = 0;

    var part1_found = false;

    var final_count: u8 = 0;

    while (step < 10E5) : (step += 1) {
        const dir = directions[step % directions.len];

        for (nodes.items, 0..) |*node, i| {
            const name = node.name;
            const route = routeMap[name.a][name.b][name.c];
            var next = if (dir == 0) route.left else route.right;

            node.name = next;

            if (!part1_found) {
                if (aaaIdx == i and next.eql(final)) {
                    part1_found = true;
                    result.part1 = step + 1;
                }
            }

            if (next.c == final.c and node.cycle_count == 0) {
                final_count += 1;
                node.cycle_count = @as(u16, @truncate((step + 1) / directions.len));
            }
        }
        if (final_count == nodes.items.len) {
            break;
        }
    }

    var gcd: u64 = 1;
    var mul: u64 = 1;
    for (0..nodes.items.len) |i| {
        gcd = std.math.gcd(gcd, nodes.items[i].cycle_count);
        mul *= nodes.items[i].cycle_count;
    }
    const lcm = mul / gcd;

    result.part2 = @intCast(lcm * directions.len);

    return result;
}

const testResult = @import("utils.zig").testResult;

test "day8" {
    try testResult("test-data/day8.txt", day8, .Part1, 2);
    try testResult("test-data/day8.txt", day8, .Part2, 2);
}
