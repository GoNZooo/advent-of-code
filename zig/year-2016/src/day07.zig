const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const debug = std.debug;

const utilities = @import("./utilities.zig");

const input = @embedFile("input-day07.txt");

const test_input =
    \\abba[mnop]qrst
    \\abcd[bddb]xyyx
    \\aaaa[qwer]tyui
    \\ioxxoj[asdfgh]zxcvbn
;

pub fn main() anyerror!void {
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);
    debug.warn("Day 07:\n", .{});

    const solution_1 = supportingTls(lines);
    debug.warn("\tSolution 1: {}\n", .{solution_1});
}

fn supportingTls(addresses: []const []const u8) u32 {
    var supporting: u32 = 0;

    for (addresses) |address| {
        if (supportsTls(address)) supporting += 1;
    }

    return supporting;
}

fn supportsTls(address: []const u8) bool {
    var start: usize = 0;
    var inside_brackets = false;
    var abba = false;
    while (start < (address.len - 4)) : (start += 1) {
        const current_char = address[start];
        if (current_char == '[') inside_brackets = true;
        if (current_char == ']') inside_brackets = false;
        const slice = address[start..(start + 4)];
        if (isAbba(slice) and inside_brackets) return false;
        if (isAbba(slice)) abba = true;
    }

    return abba;
}

fn isAbba(slice: []const u8) bool {
    return slice[0] == slice[3] and slice[1] == slice[2] and slice[1] != slice[0];
}

test "gets correct solution 1 result for test input" {
    const lines = try utilities.splitIntoLines(
        std.heap.page_allocator,
        test_input,
    );
    testing.expectEqual(lines.len, 4);
    testing.expectEqual(supportsTls(lines[0]), true);
    testing.expectEqual(supportsTls(lines[1]), false);
    testing.expectEqual(supportsTls(lines[2]), false);
    testing.expectEqual(supportsTls(lines[3]), true);
}
