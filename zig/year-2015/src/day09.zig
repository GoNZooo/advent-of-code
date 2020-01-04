const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const debug = std.debug;

const utilities = @import("./utilities.zig");

const input = @embedFile("./input-day09.txt");

pub fn main() void {}

test "reads input" {
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);
    for (lines) |line| {
        debug.warn("line: {}\n", .{line});
    }
}

const test_input =
    \\London to Dublin = 464
    \\London to Belfast = 518
    \\Dublin to Belfast = 141
;
