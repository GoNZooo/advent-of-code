const std = @import("std");
const testing = std.testing;
const page_allocator = std.heap.page_allocator;
const mem = std.mem;
const HashMap = std.hash_map.AutoHashMap;

const utilities = @import("./utilities.zig");

const input = @embedFile("./input-day05.txt");

const naughty_strings: []const []const u8 = &[_][]const u8{ "ab", "cd", "pq", "xy" };

pub fn main() anyerror!void {
    var lines = try utilities.splitIntoLines(page_allocator, input);
    std.debug.warn("Day 05:\n", .{});

    const solution_1 = try solution1(std.heap.page_allocator, lines);
    std.debug.warn("\tSolution 1: {}\n", .{solution_1});

    const solution_2 = solution2(lines);
    std.debug.warn("\tSolution 2: {}\n", .{solution_2});
}

fn solution1(allocator: *mem.Allocator, lines: []const []const u8) !u32 {
    var nice_strings: u32 = 0;
    for (lines) |line| {
        if (try isNice(allocator, line)) nice_strings += 1;
    }

    return nice_strings;
}

fn solution2(lines: []const []const u8) u32 {
    var nice_strings: u32 = 0;

    for (lines) |line| {
        if (isNice2(line)) nice_strings += 1;
    }

    return nice_strings;
}

fn isNice(allocator: *mem.Allocator, word: []const u8) !bool {
    return (try hasThreeVowels(allocator, word)) and hasRepeatedCharacter(word) and
        doesNotHaveNaughtyString(word);
}

fn isNice2(word: []const u8) bool {
    return hasXYX(word) and hasRepeatingPair(word);
}

fn hasThreeVowels(allocator: *mem.Allocator, word: []const u8) !bool {
    const vowels = try utilities.filterSlice(u8, allocator, word, isVowel);

    return vowels.len >= 3;
}

fn hasRepeatedCharacter(word: []const u8) bool {
    var last_character: u8 = undefined;
    for (word) |c| {
        if (c == last_character) return true;
        last_character = c;
    }

    return false;
}

fn hasXYX(word: []const u8) bool {
    if (word.len < 3) return false;

    for (word) |c, i| {
        if (i + 2 < word.len) {
            if (c == word[i + 2] and c != word[i + 1]) return true;
        }
    }

    return false;
}

fn doesNotHaveNaughtyString(word: []const u8) bool {
    return !utilities.containsAnyOf(u8, word, naughty_strings);
}

fn hasRepeatingPair(word: []const u8) bool {
    for (word) |c, i| {
        if (i + 2 < word.len) {
            if (utilities.containsSlice(u8, word[(i + 2)..], word[i..(i + 2)])) {
                return true;
            }
        } else {
            return false;
        }
    }

    return false;
}

fn isVowel(c: u8) bool {
    return switch (c) {
        'a', 'o', 'e', 'i', 'u' => true,
        'A', 'O', 'E', 'I', 'U' => true,
        else => false,
    };
}

test "solution 1 is correct" {
    var lines = try utilities.splitIntoLines(page_allocator, input);
    const solution_1 = try solution1(std.heap.page_allocator, lines);
    testing.expectEqual(solution_1, 258);
}

test "solution 2 is correct" {
    var lines = try utilities.splitIntoLines(page_allocator, input);
    const solution_2 = solution2(lines);
    testing.expectEqual(solution_2, 53);
}

test "reports are correct for `hasThreeVowels`" {
    testing.expect(try hasThreeVowels(page_allocator, "aei"));
    testing.expect(try hasThreeVowels(page_allocator, "xazegov"));
    testing.expect(try hasThreeVowels(page_allocator, "aeiouaeiouaeiou"));
    testing.expect(try hasThreeVowels(page_allocator, "AeI"));
    testing.expect(try hasThreeVowels(page_allocator, "xAzEgov"));
    testing.expect(try hasThreeVowels(page_allocator, "Aeiouaeiouaeiou"));
    testing.expect(!try hasThreeVowels(page_allocator, "abcdfghijklmnpqrstvwxyz"));
}

test "reports are correct for `hasRepeatedCharacter`" {
    testing.expect(hasRepeatedCharacter("aaa"));
    testing.expect(!hasRepeatedCharacter("aba"));
}

test "reports are correct for `doesNotHaveNaughtyString`" {
    testing.expect(doesNotHaveNaughtyString("aa"));
    testing.expect(!doesNotHaveNaughtyString("aba"));
}

test "reports are correct for `hasRepeatingPair`" {
    testing.expect(hasRepeatingPair("xyxy"));
    testing.expect(hasRepeatingPair("aabcdefgaa"));
    testing.expect(!hasRepeatingPair("aaa"));
}

test "reports are correct for `hasXYX`" {
    testing.expect(!hasXYX("aa"));
    testing.expect(hasXYX("aba"));
    testing.expect(!hasXYX("aaa"));
}

test "`filterSlice` works" {
    const slice = &[_]u32{ 1, 2, 3, 4, 5 };
    const filtered = try utilities.filterSlice(u32, page_allocator, slice, isEven);
    testing.expectEqualSlices(u32, filtered, &[_]u32{ 2, 4 });
}

test "`containsSlice` works" {
    testing.expect(utilities.containsSlice(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &[_]u8{ 1, 2, 3, 4, 5 }));
    testing.expect(utilities.containsSlice(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &[_]u8{ 1, 2 }));
    testing.expect(!utilities.containsSlice(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &[_]u8{ 1, 2, 4 }));
}

fn isEven(x: u32) bool {
    return x % 2 == 0;
}
