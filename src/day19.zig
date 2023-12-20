const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const Operation = enum(u1) {
    more,
    less,

    pub fn fromChar(c: u8) Operation {
        return switch (c) {
            '>' => .more,
            '<' => .less,
            else => unreachable,
        };
    }

    pub fn cut(self: Operation, int: *Interval, count: u16) ?Interval {
        switch (self) {
            .less => if (int.start >= count) {
                return null;
            } else {
                const new = .{ .start = int.start, .end = count - 1 };
                int.start = count;
                return new;
            },
            .more => if (int.end <= count) {
                return null;
            } else {
                const new = .{ .start = count + 1, .end = int.end };
                int.end = count;
                return new;
            },
        }
    }
};

const RuleCondition = struct { category: Category, operation: Operation, count: u16 };

const Rule = struct { condition: ?RuleCondition, result: RuleResult };

const RuleResult = union(enum) {
    accepted: void,
    rejected: void,
    next: []const u8,

    pub fn fromStr(allocator: std.mem.Allocator, str: []const u8) !RuleResult {
        return switch (str[0]) {
            'A' => .{ .accepted = {} },
            'R' => .{ .rejected = {} },
            else => .{ .next = try allocator.dupe(u8, str) },
        };
    }
};

const Category = enum(u2) {
    x,
    m,
    a,
    s,

    pub fn fromChar(c: u8) Category {
        return switch (c) {
            'x' => .x,
            'm' => .m,
            'a' => .a,
            's' => .s,
            else => unreachable,
        };
    }

    pub fn getRatingCount(self: Category, rating: Rating) u16 {
        return switch (self) {
            .x => rating.x,
            .m => rating.m,
            .a => rating.a,
            .s => rating.s,
        };
    }
};

const Rating = struct {
    x: u16,
    m: u16,
    a: u16,
    s: u16,
};

const Interval = struct {
    start: u16,
    end: u16,

    pub fn format(self: Interval, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        return writer.print("{d}..{d}", .{ self.start, self.end });
    }
};

const RatingInterval = struct {
    name: []const u8,
    x: Interval,
    m: Interval,
    a: Interval,
    s: Interval,

    pub fn cut(self: *RatingInterval, operation: Operation, category: Category, count: u16) ?RatingInterval {
        var cut_interval = self.*;
        switch (category) {
            .x => if (operation.cut(&self.x, count)) |int| {
                cut_interval.x = int;
            } else {
                return null;
            },
            .m => if (operation.cut(&self.m, count)) |int| {
                cut_interval.m = int;
            } else {
                return null;
            },
            .a => if (operation.cut(&self.a, count)) |int| {
                cut_interval.a = int;
            } else {
                return null;
            },
            .s => if (operation.cut(&self.s, count)) |int| {
                cut_interval.s = int;
            } else {
                return null;
            },
        }
        return cut_interval;
    }

    pub fn nonEmpty(self: RatingInterval) bool {
        return self.x.start < self.x.end and
            self.m.start < self.m.end and
            self.a.start < self.a.end and
            self.s.start < self.s.end;
    }

    pub fn combinations(self: RatingInterval) i64 {
        return (@as(i64, self.x.end) - self.x.start + 1) *
            (@as(i64, self.m.end) - self.m.start + 1) *
            (@as(i64, self.a.end) - self.a.start + 1) *
            (@as(i64, self.s.end) - self.s.start + 1);
    }

    pub fn format(self: RatingInterval, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        return writer.print("[{s}] x = {}, m = {}, a = {}, s = {}", .{ self.name, self.x, self.m, self.a, self.s });
    }
};

pub fn day19(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var n: u32 = 0;

    var workflows = std.StringHashMap(std.ArrayList(Rule)).init(allocator);
    defer workflows.deinit();
    var ratings = std.ArrayList(Rating).init(allocator);
    defer ratings.deinit();

    while (try reader.next()) |line| : (n += 1) {
        if (line.len == 0) continue;
        if (line[0] != '{') {
            var rules = std.ArrayList(Rule).init(arena_allocator);
            var it = std.mem.tokenizeAny(u8, line, "{}");
            const name = try arena_allocator.dupe(u8, it.next().?);
            const rules_str = it.next().?;
            var it1 = std.mem.tokenizeScalar(u8, rules_str, ',');

            while (it1.next()) |rule_str| {
                if (std.mem.indexOfScalar(u8, rule_str, ':')) |idx| {
                    const cond_str = rule_str[0..idx];
                    const next = rule_str[idx + 1 ..];
                    const cond = RuleCondition{ .category = Category.fromChar(cond_str[0]), .operation = Operation.fromChar(cond_str[1]), .count = try std.fmt.parseInt(u16, cond_str[2..], 10) };
                    const rule = Rule{ .condition = cond, .result = try RuleResult.fromStr(arena_allocator, next) };
                    try rules.append(rule);
                } else {
                    try rules.append(.{ .condition = null, .result = try RuleResult.fromStr(arena_allocator, rule_str) });
                }
            }
            try workflows.put(name, rules);
        } else {
            var it = std.mem.tokenizeAny(u8, std.mem.trim(u8, line, "{}"), ",");
            var rating = std.mem.zeroes(Rating);
            while (it.next()) |keyval| {
                const count = try std.fmt.parseInt(u16, keyval[2..], 10);
                switch (Category.fromChar(keyval[0])) {
                    .x => rating.x = count,
                    .m => rating.m = count,
                    .a => rating.a = count,
                    .s => rating.s = count,
                }
            }
            try ratings.append(rating);
        }
    }

    for (ratings.items) |rating| {
        var rule_res = RuleResult{ .next = "in" };

        loop: while (true) {
            if (workflows.get(rule_res.next)) |rule_list| {
                rule_loop: for (rule_list.items) |rule| {
                    if (rule.condition) |cond| {
                        const count = cond.category.getRatingCount(rating);
                        const pass = switch (cond.operation) {
                            .less => count < cond.count,
                            .more => count > cond.count,
                        };
                        if (pass) {
                            rule_res = rule.result;
                            break :rule_loop;
                        }
                    } else {
                        rule_res = rule.result;
                        break :rule_loop;
                    }
                }
                switch (rule_res) {
                    .next => {},
                    .accepted, .rejected => {
                        break :loop;
                    },
                }
            } else {
                unreachable;
            }
        }

        switch (rule_res) {
            .accepted => {
                result.part1 += rating.x + rating.m + rating.a + rating.s;
            },
            else => {},
        }
    }

    var intervals = std.ArrayList(RatingInterval).init(allocator);
    defer intervals.deinit();

    var int: ?RatingInterval = .{
        .name = "in",
        .x = .{ .start = 1, .end = 4000 },
        .m = .{ .start = 1, .end = 4000 },
        .a = .{ .start = 1, .end = 4000 },
        .s = .{ .start = 1, .end = 4000 },
    };

    while (int != null) : (int = intervals.popOrNull()) {
        var interval = int.?;
        if (workflows.get(interval.name)) |rule_list| {
            for (rule_list.items) |rule| {
                if (rule.condition) |cond| {
                    if (interval.cut(cond.operation, cond.category, cond.count)) |new_interval| {
                        switch (rule.result) {
                            .accepted => {
                                result.part2 += new_interval.combinations();
                            },
                            .rejected => {},
                            .next => |next| {
                                var new_int = new_interval;
                                new_int.name = next;
                                try intervals.append(new_int);
                            },
                        }
                    }
                } else {
                    switch (rule.result) {
                        .accepted => {
                            result.part2 += interval.combinations();
                        },
                        .rejected => {},
                        .next => |next| {
                            interval.name = next;
                            try intervals.append(interval);
                        },
                    }
                }
                if (!interval.nonEmpty()) {
                    break;
                }
            }
        } else {
            unreachable;
        }
    }

    return result;
}

const testResult = @import("utils.zig").testResult;

test "day19 - Part 1" {
    try testResult("test-data/day19.txt", day19, .Part1, 19114);
}

test "day19 - Part 2" {
    try testResult("test-data/day19.txt", day19, .Part2, 167409079868000);
}
