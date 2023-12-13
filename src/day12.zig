const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const HashInt = u64;
const MaskInt = u104;
const VarInt = u44;
const CountInt = u5;

const MapSize = 100000;

const SolvedHashMap = std.AutoHashMap(HashInt, VarInt);

pub fn day12(allocator: std.mem.Allocator) anyerror!Result {
    var result: Result = std.mem.zeroes(Result);

    var reader = try LineReader.open("data/day12.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    var solved = SolvedHashMap.init(allocator);
    defer solved.deinit();
    try solved.ensureTotalCapacity(100000);

    var count_list: [6]CountInt = undefined;
    var count_list2: [30]CountInt = undefined;

    while (try reader.next()) |line| : (n += 1) {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        var mask_all: u20 = 0;
        var mask_none: u20 = 0;

        var mask_all2: MaskInt = 0;
        var mask_none2: MaskInt = 0;

        const template_str = it.next().?;
        const counts_str = it.next().?;
        var count_it = std.mem.tokenizeScalar(u8, counts_str, ',');
        
        for (template_str) |c| {
            mask_all <<= 1;
            mask_none <<= 1;
            if (c == '?') {
                mask_all += 1;
            }
            if (c == '#') {
                mask_all += 1;
                mask_none += 1;
            }
        }

        var count_sum: u8 = 0;
        var count_idx: usize = 0;
        while(count_it.next()) |count_str|: (count_idx += 1) {
            const count = try std.fmt.parseInt(CountInt, count_str, 10);
            count_list[count_idx] = count;
            count_sum += count;
        }
        const count_slice = count_list[0..count_idx];
        const variants = try getVariants(&solved, mask_all, mask_none, @truncate(template_str.len), count_slice, count_sum, 0);

        result.part1 += @intCast(variants);

        const count_sum2: u8 = count_sum * 5;

        for (0..5) |i| {
            for (0..count_idx) |k| {
                count_list2[i * count_idx + k] = count_list[k];
            }
            mask_all2 |= @as(MaskInt,mask_all) << @truncate(i * template_str.len + i);
            if (i > 0) {
                // '?' between copies
                mask_all2 |= @as(MaskInt,1) << @truncate(i * template_str.len + i - 1);
            }
            mask_none2 |= @as(MaskInt,mask_none) << @truncate(i * template_str.len + i);
        }

        const count_slice2 = count_list2[0..(count_idx * 5)];

        const len: u8 = @truncate(template_str.len * 5 + 4);

        const variants2 = try getVariants(&solved, mask_all2, mask_none2, len, count_slice2, count_sum2, 0);

        result.part2 += @intCast(variants2);
    }

    return result;
}

const CACHED_SHIFT = 1;

const count_hash_factor: [6]u8 = [6]u8{7,11,13,17,19,29};

fn getVariants(solved: *SolvedHashMap, mask_all: MaskInt, mask_none: MaskInt, len: u8, counts: []CountInt, sum: u8, shift: u5) !VarInt {
    var variants: VarInt = 0;

    if (counts.len == 0) {
        return if ((mask_none & ((@as(MaskInt,1) << @truncate(len)) - 1)) > 0) 0 else 1; 
    }

    const mask_all_base: MaskInt = mask_all & ((1 << 20) - 1);
    const mask_none_base: MaskInt = mask_none & ((1 << 20) - 1);

    const len_hash: HashInt = @as(HashInt,len) << 24;

    //cheating 
    var hash_key: HashInt = @truncate((mask_all_base * 5 + mask_none_base * 7) | len_hash);

    hash_key |= counts.len << 32;
    
    var count_hash_sum: HashInt = 0;
    for (0..@min(counts.len,6)) |i| {
        // more cheating
        count_hash_sum += @as(HashInt, counts[i]) * count_hash_factor[i];
    }            

    const count_hash: HashInt = count_hash_sum << 37;
    hash_key |= count_hash;

    hash_key |= @as(HashInt,shift) << 47;

    if (shift > CACHED_SHIFT) {
        if (solved.get(hash_key)) |value| {
            return value;
        }
    }

    const max_pos: u8 = @truncate(len - (sum + counts.len - 1) + 1);
    const count: CountInt = counts[0];
    // ???.###
    // mask_all  = 1110111
    // mask_none = 0000111
    // max_pos = 1, count = 3:
    // ###.......
    // .###......
    for (0..max_pos) |pos| {
        if (pos > 0) {
            // 1000000000 & mask_none == 0
            const empty_previous = ((@as(MaskInt,1) << @truncate(pos)) - 1) << @truncate(len - pos);
            if (empty_previous & mask_none != 0) {
                continue;
            }            
        }

        const right_pad: u8 = @truncate(len - count - pos);
        // 1110000000 & mask_all == 1110000000
        const group: MaskInt = ((@as(MaskInt,1) << count) - 1) << @truncate(right_pad);
        if ((group & mask_all) != group) {
            continue;
        }
        if (right_pad > 0) {
            // 0001000000 & mask_none == 0
            const empty_next = @as(MaskInt,1) << @truncate(right_pad - 1);
            if (empty_next & mask_none != 0) {
                continue;
            }

            if (right_pad > 1) {
                variants += try getVariants(solved, mask_all, mask_none, right_pad - 1, counts[1..], sum - count, shift + 1);
            } else {
                variants += 1;
            }
        } else {
            variants += 1;
        }
    }

    if (shift > CACHED_SHIFT) {
        try solved.putNoClobber(hash_key, variants);
    }

    return variants;
}
