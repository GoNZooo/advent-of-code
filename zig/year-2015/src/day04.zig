const std = @import("std");

const input = "";
const test_input = "abcdef";

pub fn main() anyerror!void {
    var allocator = &std.heap.ArenaAllocator.init(std.heap.page_allocator).allocator;
    std.debug.warn("Day 04:\n", .{});
    std.debug.warn("\tSolution 1: \n", .{});
}
