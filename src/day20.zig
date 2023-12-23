const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const ModuleType = enum(u2) {
    broadcaster,
    flipflop,
    conjunction
};

const NameKey = u16;

const ConjMemSize = 10;

const OutModule = struct {
    key: NameKey,
    mem_idx: u8,
};

const Module = struct {
    type: ModuleType,
    out: [8]OutModule,
    mem_start: u8,
    mem_end: u8,

    pub fn format(self: Module, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        try writer.print("({any}) ", .{self.type});
        for (0..8) |i| {
            if (self.out[i].key == 0) return;
            try writer.print("{s} ({d}),", .{nameFromKey(self.out[i].key), self.out[i].key});
        }
    }
};

fn keyFromName(name: []const u8) u16 {
    if (name.len == 1) {
        return std.mem.readInt(u16, name[0..1] ++ " ", .big);
    } else {
        return std.mem.readInt(u16, name[0..2], .big);
    }
}

fn nameFromKey(key: u16) [2]u8 {
    if (key == 0) {
        return [_]u8{'B','C'};
    }
    var buf: [2]u8 = undefined;
    std.mem.writeInt(u16, &buf, key, .big);
    return buf;
}

const Signal = enum(u1) {
    low,
    high
};

const ModuleSignal = struct {
    signal: Signal,
    module: *const Module,
    mem_idx: u8,
    mod_key: u16,
};

const PulseCount = struct{low: u32, high: u32,};

pub fn day20(allocator: std.mem.Allocator, reader: *LineReader) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var n: u32 = 0;

    var modules = std.AutoArrayHashMap(NameKey, Module).init(allocator);
    defer modules.deinit();
    var broadcaster: Module = undefined;

    var memory: u256 = 0;
    var mem_idx: u8 = 0;

    memory = 0;

    while (try reader.next()) |line| : (n += 1) {
        var it = std.mem.tokenizeSequence(u8, line, "->");
        const name = std.mem.trimRight(u8, it.next().?, " ");
        var out_it = std.mem.tokenizeScalar(u8, it.next().?, ',');
        var out_modules = std.mem.zeroes([8]OutModule);
        var i: usize = 0;
        while(out_it.next()) |out| : (i += 1) {
            const out_name = std.mem.trim(u8, out, " ");
            out_modules[i] = .{ .key = keyFromName(out_name), .mem_idx = 0 };
        }
        const mod_type: ModuleType = switch (line[0]) {
            'b' => .broadcaster,
            '%' => .flipflop,
            '&' => .conjunction,
            else => unreachable
        };
        const mem_size: u8 = switch(mod_type) {
            .broadcaster => 0,
            .flipflop => 1,
            .conjunction => ConjMemSize
        };
        const mod_name = std.mem.trim(u8, name[1..], " ");
        const name_key = keyFromName(mod_name);

        const module: Module = .{
            .type = mod_type,
            .out = out_modules,
            .mem_start = mem_idx,
            .mem_end = mem_idx,
        };
        mem_idx += mem_size;
        if (line[0] == 'b') {
            broadcaster = module;
        }
        try modules.put(name_key, module);
    }

    for (modules.values()) |*module| {
        for (0..module.out.len) |i| {
            const key = module.out[i].key;
            if (key == 0) continue;
            if (modules.getPtr(key)) |mod| {
                module.out[i].mem_idx = mod.mem_end;
                mod.mem_end += 1;
            }
        }
    }

    var queue = std.fifo.LinearFifo(ModuleSignal, .Dynamic).init(allocator);
    defer queue.deinit();

    var cycle_size: usize = 0;

    var i: usize = 0;

    var sum_pulse = PulseCount{.low = 0, .high = 0};

    // hacky :(
    const rx_key = keyFromName("rx");
    const lg_key = keyFromName("lg");
    var lg_triggers: [4]u32 = std.mem.zeroes([4]u32);
    var lg_trigger_count: u4 = 0;

    loop: while(i<1000 or lg_trigger_count < 4) : (i += 1) {
        var pulse = PulseCount{.low = 1, .high = 0};
        if (i < 1000) sum_pulse.low += 1;

        try queue.writeItem(.{ .module = &broadcaster, .signal = .low, .mem_idx = 0, .mod_key = 0 });
        while(queue.readItem()) |sigmod| {
            var signal: ?Signal = null;

            switch(sigmod.module.type) {
                .broadcaster => {
                    signal = .low;
                },
                .flipflop => {
                    if (sigmod.signal == .low) {
                        const bit: u256 = @as(u256,1) << @truncate(sigmod.module.mem_start);
                        if (memory & bit == 0) {
                            memory |= bit;
                            signal = .high;
                        } else {
                            memory &= ~bit;
                            signal = .low;
                        }
                    }
                },
                .conjunction => {
                    const bit: u256 = @as(u256,1) << @truncate(sigmod.mem_idx);
                    if (sigmod.signal == .low) {
                        memory = memory & ~bit;
                    } else {
                        memory = memory | bit;
                    }
                    const mem_size = sigmod.module.mem_end - sigmod.module.mem_start;
                    const mask: u256 = ((@as(u256,1) << mem_size) - 1) << @truncate(sigmod.module.mem_start);
                    signal = if (memory & mask == mask) .low else .high;

                    if (sigmod.mod_key == lg_key) {
                        if (memory & mask != 0) {
                            for (0..4) |k| {
                                const bit1: u256 = @as(u256,1) << @truncate(sigmod.module.mem_start + k);
                                if (memory & bit1 != 0 and lg_triggers[k] == 0) {
                                    lg_triggers[k] = @truncate(i + 1);
                                    lg_trigger_count += 1;
                                }
                                if (lg_trigger_count >= 4) break :loop;
                            }
                        }
                    }
                }
            }

            if (signal) |sig| {
                const out = sigmod.module.out;
                for (0..8) |k| {
                    if (out[k].key == 0) {
                        break;
                    }
                    if (i < 1000) {
                        switch(sig) {
                            .low => {
                                pulse.low += 1;
                                sum_pulse.low += 1;
                            },
                            .high => {
                                pulse.high += 1;
                                sum_pulse.high += 1;
                            },
                        }
                    }

                    if (out[k].key != rx_key) {
                        if (modules.getPtr(out[k].key)) |mod| {
                            try queue.writeItem(.{
                                .module = mod,
                                .signal = sig,
                                .mem_idx = out[k].mem_idx,
                                .mod_key = out[k].key
                            });
                        }
                    }
                }
            }
        }

        if (memory == 0) {
            cycle_size = i + 1;
            break;
        }
    }

    if (cycle_size > 0) {
        const loops: u32 = @truncate(@divTrunc(1000, cycle_size));

        sum_pulse.low *= loops;
        sum_pulse.high *= loops;
    }

    result.part1 = sum_pulse.low * sum_pulse.high;

    var gcd: u63 = 1;
    var mul: u63 = 1;
    for (lg_triggers) |idx| {
        gcd = std.math.gcd(gcd, idx);
        mul *= idx;
    }
    const lcm = mul / gcd;

    result.part2 = lcm;

    return result;
}

const testResult = @import("utils.zig").testResult;

test "day20 - Part 1" {
    try testResult("test-data/day20.txt", day20, .Part1, 11687500);
}
