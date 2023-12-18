const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const NodeIterator = struct {
    current: ?Direction,
    node: *const Node,

    fn nextDir(dir: ?Direction) ?Direction {
        if (dir) |d| {
            return switch(d) {
                .top => null,
                else => @enumFromInt(@intFromEnum(d) + 1),
            };
        } else {
            return .right;
        }
    }

    fn backDir(dir: Direction) Direction {
        return switch (dir) {
            .right => .left,
            .left => .right,
            .bottom => .top,
            .top => .bottom,
        };
    }

    pub fn next(self: *NodeIterator, size: u8) ?Direction {
        var dir = nextDir(self.current);
        const prev = self.node.prev;
        const pos = self.node.pos;

        // std.debug.print("next node: {d},{d}\n", .{pos.x,pos.y});

        while (dir) |_| : (dir = nextDir(dir)) {
            // std.debug.print("get next dir: {any} (from {any}, {d})\n", .{dir, prev.dir, prev.count});
            if (dir == backDir(prev.dir)) {
                continue;
            }
            if (dir == prev.dir and prev.count == 3) {
                continue;
            }
            switch (dir.?) {
                .right => if (pos.x == size - 1) continue,
                .left => if (pos.x == 0) continue,
                .bottom => if (pos.y == size - 1) continue,
                .top => if (pos.y == 0) continue,
            }
            self.current = dir;
            return dir;
        }
        return null;
    }
};

const Position = struct {
    x: u8,
    y: u8,
};

const Direction = enum(u2) {
    right,
    left,
    bottom,
    top,

    pub fn getPosition(self: Direction, x: u8, y: u8) Position {
        return switch (self) {
            .right => .{.x = x + 1, .y = y },
            .left => .{.x = x - 1, .y = y },
            .bottom => .{.x = x, .y = y + 1 },
            .top => .{.x = x, .y = y - 1 },
        };
    }
};

const Node = struct {
    pos: Position,
    prev: struct { dir: Direction, count: u2, debug_node: ?*Node },
    min_weight: u16,
    min_dist_weight: u16,
    visited: u12,

    pub fn iterator(self: *Node) NodeIterator {
        return NodeIterator {
            .current = null,
            .node = self,
        };
    }
};

pub fn day17(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var weights: [110][110]u4 = undefined;
    var nodes: [110][110]Node = undefined;
    var init: [110][110]bool = std.mem.zeroes([110][110]bool);
    var in_queue: [110][110]bool = std.mem.zeroes([110][110]bool);

    var queue = std.ArrayList(*Node).init(allocator);
    defer queue.deinit();

    var size: u8 = 0;

    while (try reader.next()) |line| : (n += 1) {
        if (size == 0) size = @truncate(line.len);
        for (line, 0..) |c, i| {
            weights[n][i] = @truncate(c - '0');
        }
    }

    nodes[0][0] = .{
        .pos = .{
            .x = 0,
            .y = 0,
        },
        .prev = .{ .dir = .top, .count = 1, .debug_node = null },
        .min_weight = 0,
        .min_dist_weight = (size - 1) + (size - 1),
        .visited = 0,
    };

    var maybe_node: ?*Node = &nodes[0][0];

    while(maybe_node) |node| {
        const x = node.pos.x;
        const y = node.pos.y;
        // std.debug.print("GET ITERATOR FOR: {d},{d}\n", .{node.pos.x, node.pos.y});
        var it = node.iterator();
        // std.debug.print("{d},{d}; prev: {any}, {d}\n", .{x,y, node.prev.dir, node.prev.count});

        while (it.next(size)) |dir| {
            // std.debug.print("{any}\n", .{dir});
            const pos = dir.getPosition(x, y);
            const dist_to_end = (size - pos.x - 1) + (size - pos.y - 1);
            const count = if (dir == node.prev.dir) node.prev.count + 1 else 1;

            const weight = node.min_weight + weights[pos.y][pos.x];
            const dist_weight = weight + dist_to_end + @as(u8, 3 - count) * 2;

            if (!init[pos.y][pos.x]) {
                init[pos.y][pos.x] = true;
                nodes[pos.y][pos.x] = .{
                    .pos = pos,
                    .prev = .{
                        .dir = dir,
                        .count = count,
                        .debug_node = node
                    },
                    .min_weight = weight,
                    .min_dist_weight = dist_weight,
                    .visited = 0,
                };
                try queue.append(&(nodes[pos.y][pos.x]));
                in_queue[pos.y][pos.x] = true;
                std.sort.pdq(*Node, queue.items, {}, compareNodes);
            } else {
                var next_node = nodes[pos.y][pos.x];
                if (isVisited(next_node.visited, dir, count)) continue;
                if (next_node.min_weight > weight) {
                    next_node.min_weight = weight;
                    next_node.min_dist_weight = dist_weight;
                    next_node.prev = .{
                        .dir = dir,
                        .count = count,
                        .debug_node = node,
                    };
                    if (!in_queue[pos.y][pos.x]) {
                        try queue.append(&(nodes[pos.y][pos.x]));
                        in_queue[pos.y][pos.x] = true;                    
                    }
                }
                std.sort.pdq(*Node, queue.items, {}, compareNodes);
            }
        }

        // std.debug.print("VISITED: {d},{d}\n", .{node.pos.x, node.pos.y});
        setVisited(&node.visited, node.prev.dir, node.prev.count);
        if (std.mem.indexOfScalar(*Node, queue.items, node)) |idx| {
            _ = queue.orderedRemove(idx);
            in_queue[node.pos.y][node.pos.x] = false;
        }

        // std.debug.print("ITEMS: {any}\n", .{queue.items});

        maybe_node = if (queue.items.len > 0) queue.items[0] else null;
        // if (maybe_node) |nd| {
        //     std.debug.print("next node: {d},{d}\n", .{nd.pos.x, nd.pos.y});
        // }
        // std.debug.print("queue: {d}\n", .{queue.items.len});
    }

    printPath(&nodes[size - 1][size - 1], weights, size);

    result.part1 = nodes[size - 1][size - 1].min_weight;

    return result;
}

fn isVisited(visited: u12, dir: Direction, count: u2) bool {
    const bit = @as(u12,1) << ((count - 1) * @as(u4,4) + @intFromEnum(dir));
    return visited & bit != 0;
}

fn setVisited(visited: *u12, dir: Direction, count: u2) void {
    const bit = @as(u12,1) << ((count - 1) * @as(u4,4) + @intFromEnum(dir));
    visited.* |= bit;
}

fn printPath(node: *Node, weights: [110][110]u4, size: u8) void {
     std.debug.print("\n", .{});
    var current = node;
    var table: [110][110]u8 = undefined;
    for (0..size) |i| {
        @memcpy(&table[i], "." ** 110);
    }

    while(current.prev.debug_node) |prev_node| {
        // std.debug.print("{d}, {d}\n", .{prev_node.pos.x,prev_node.pos.y});
        table[current.pos.y][current.pos.x] = '#';
        current = prev_node;
        if (current.pos.x == 0 and current.pos.y == 0) break;
    }

    for (0..size) |i| {
        std.debug.print("{s}     ", .{table[i][0..size]});
        for(0..size) |k| {
            if (table[i][k] == '#') {
                std.debug.print("\x1b[1;33m{d}\x1b[0m", .{weights[i][k]});
            } else {
                std.debug.print("{d}", .{weights[i][k]});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn compareNodes(_: void, a: *Node, b: *Node) bool {
    return a.min_dist_weight < b.min_dist_weight;
}


const testResult = @import("utils.zig").testResult;

test "day17 - Part 1" {
    try testResult("test-data/day17.txt", day17, .Part1, 0);
}

test "day17 - Part 2" {
    try testResult("test-data/day17.txt", day17, .Part2, 0);
}
