const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;

const ArrayList = std.ArrayList;

const utilities = @import("./utilities.zig");

const input = @embedFile("input-day02.txt");

const Dimensions = struct {
    length: u32,
    width: u32,
    height: u32,

    pub fn areaOfSmallestSide(self: Dimensions) u32 {
        const lw = self.length + self.width;
        const wh = self.width + self.height;
        const hl = self.height + self.length;
        const smallest_side = math.min(lw, math.min(wh, hl));

        if (smallest_side == lw) return self.length * self.width;
        if (smallest_side == wh) return self.width * self.height;
        if (smallest_side == hl) return self.height * self.length;

        std.debug.panic("no answer\n", .{});
    }

    pub fn neededPaper(self: Dimensions) u32 {
        const side1 = 2 * self.length * self.width;
        const side2 = 2 * self.width * self.height;
        const side3 = 2 * self.height * self.length;

        return side1 + side2 + side3 + self.areaOfSmallestSide();
    }

    pub fn neededRibbon(self: Dimensions) u32 {
        return self.wrappingRibbon() + self.bowRibbon();
    }

    pub fn wrappingRibbon(self: Dimensions) u32 {
        const sides = utilities.removeMax(3, [_]u32{ self.length, self.width, self.height });
        var ribbon: u32 = 0;
        for (sides) |s| {
            ribbon += s * 2;
        }

        return ribbon;
    }

    pub fn bowRibbon(self: Dimensions) u32 {
        return self.length * self.height * self.width;
    }

    pub fn fromLine(line: []const u8) !Dimensions {
        var split_iterator = mem.split(line, "x");
        const length_string = split_iterator.next() orelse unreachable;
        const width_string = split_iterator.next() orelse unreachable;
        const height_string = split_iterator.next() orelse unreachable;

        const length = try fmt.parseInt(u32, length_string, 10);
        const width = try fmt.parseInt(u32, width_string, 10);
        const height = try fmt.parseInt(u32, height_string, 10);

        return Dimensions{ .length = length, .width = width, .height = height };
    }
};

fn calculateNeededPaper(lines: []const []const u8) !u32 {
    var square_feet_of_paper: u32 = 0;

    for (lines) |line| {
        const dimensions = try Dimensions.fromLine(line);
        const needed = dimensions.neededPaper();
        square_feet_of_paper += needed;
    }

    return square_feet_of_paper;
}

fn calculateNeededRibbon(lines: []const []const u8) !u64 {
    var ribbon: u64 = 0;

    for (lines) |line| {
        const dimensions = try Dimensions.fromLine(line);
        const needed = dimensions.neededRibbon();
        ribbon += needed;
    }

    return ribbon;
}

pub fn main() anyerror!void {
    var allocator = &std.heap.ArenaAllocator.init(std.heap.page_allocator).allocator;
    const lines = try utilities.splitIntoLines(allocator, input);
    const square_feet_of_paper = calculateNeededPaper(lines);
    const ribbon = calculateNeededRibbon(lines);
    std.debug.warn("Day 02:\n", .{});
    std.debug.warn("\tSolution 1: {}\n", .{square_feet_of_paper});
    std.debug.warn("\tSolution 2: {}\n", .{ribbon});
}
