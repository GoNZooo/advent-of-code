const std = @import("std");

const input = @embedFile("input-day01.txt");

fn calculateEndingFloor(directions: []const u8) i32 {
    var floor: i32 = 0;
    for (directions) |direction| {
        switch (direction) {
            '(' => floor += 1,
            ')' => floor -= 1,
            else => unreachable,
        }
    }

    return floor;
}

fn calculateMinus1Iteration(directions: []const u8) usize {
    var floor: i32 = 0;
    var iteration: usize = 0;

    while (floor != -1) : (iteration += 1) {
        switch (directions[iteration]) {
            '(' => floor += 1,
            ')' => floor -= 1,
            else => unreachable,
        }
    }

    return iteration;
}

pub fn main() anyerror!void {
    std.debug.warn("Day 01:\n", .{});
    std.debug.warn("\tSolution 1: {}\n", .{calculateEndingFloor(input)});
    std.debug.warn("\tSolution 2: {}\n", .{calculateMinus1Iteration(input)});
}
