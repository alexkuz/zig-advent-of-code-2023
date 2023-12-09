const std = @import("std");
const LineReader = @import("utils.zig").LineReader;
const Result = @import("utils.zig").Result;

const cardNames = "23456789TJQKA";
const jokerIdx: u4 = @as(u4,std.mem.indexOfScalar(u8,cardNames,'J').?);

const cardMap = createCardMap(cardNames);

const Card = struct {
    cardIdx: u4,
    count: u8
};

const HandBid = struct {
    type1: u3,
    type2: u3,
    hand: [5]u4,
    bid: u10,
};

const HandType = enum(u3) {
    None,
    Pair,
    TwoPairs,
    Three,
    FullHouse,
    Four,
    Five
};

pub fn day7() anyerror!Result {
    var allocator = std.heap.page_allocator;
    var result: Result = std.mem.zeroes(Result);

    var reader = try LineReader.open("data/day7.txt", allocator);
    defer reader.close();

    var n: u32 = 0;

    var hands = std.ArrayList(HandBid).init(allocator);
    defer hands.deinit();

    while (try reader.next()) |line| : (n += 1) {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        var hand = it.next().?;
        var bid = try std.fmt.parseInt(u10, it.next().?, 10);
        var sortedHand: [cardNames.len]Card = std.mem.zeroes([cardNames.len]Card);

        var jokerCount: u4 = 0;

        var indexedHand:[5]u4 = undefined;

        for (hand, 0..) |card, i| {
            var cardIdx = cardMap[card];
            sortedHand[cardIdx].cardIdx = cardMap[card];
            sortedHand[cardIdx].count += 1;
            if (card == 'J') jokerCount += 1;
            indexedHand[i] = cardIdx;
        }

        std.sort.pdq(Card, &sortedHand, {}, compareCards);

        var part1maxCount1 = sortedHand[0].count;
        var part1maxCount2 = sortedHand[1].count;

        var part2maxCount1 = if (sortedHand[0].cardIdx == jokerIdx) sortedHand[1].count else sortedHand[0].count;
        var part2maxCount2 = if (sortedHand[1].cardIdx == jokerIdx) sortedHand[2].count else sortedHand[1].count;

        part2maxCount1 += jokerCount;

        var handType1 = getHandType(part1maxCount1, part1maxCount2);
        var handType2 = getHandType(part2maxCount1, part2maxCount2);

        try hands.append(.{
            .hand = indexedHand,
            .type1 = @intFromEnum(handType1),
            .type2 = @intFromEnum(handType2),
            .bid = bid,
        });
    }

    var items = hands.items;

    std.sort.pdq(HandBid, items, {}, compareHands1);

    for (items, 1..) |hand, i| {
        result.part1 += i * hand.bid;
    }

    std.sort.pdq(HandBid, items, {}, compareHands2);

    for (items, 1..) |hand, i| {
        result.part2 += i * hand.bid;
    }

    return result;
}

fn getHandType(group1: usize, group2: usize) HandType {
    return switch(group1) {
        5 => .Five,
        4 => .Four,
        3 => switch(group2) {
            2 => .FullHouse,
            else => .Three
        },
        2 => switch (group2) {
            2 => .TwoPairs,
            else => .Pair,
        },
        else => .None
    };
}

fn createCardMap(names: []const u8) []const u4 {
    var map: ['T' + 1]u4 = undefined;
    for (names, 0..) |card, i| {
        map[card] = @as(u4,i);
    }
    return map[0..];
}

pub fn compareCards(context: void, a: Card, b: Card) bool {
    if (a.count == b.count) {
        return std.sort.desc(usize)(context, a.cardIdx, b.cardIdx);
    }
    return std.sort.desc(u8)(context, a.count, b.count);
}

pub fn compareHands1(_: void, a: HandBid, b: HandBid) bool {
    if (a.type1 != b.type1) {
        return a.type1 < b.type1;
    }

    for (a.hand, 0..) |aCard, i| {
        var bCard = b.hand[i];
        if (aCard != bCard) {
            return aCard < bCard;
        }
    }

    return false;
}

pub fn compareHands2(_: void, a: HandBid, b: HandBid) bool {
    if (a.type2 != b.type2) {
        return a.type2 < b.type2;
    }

    for (a.hand, 0..) |aCard, i| {
        var bCard = b.hand[i];
        if (aCard == bCard) continue;
        if (aCard == jokerIdx) return true;
        if (bCard == jokerIdx) return false;
        return aCard < bCard;
    }

    return false;
}