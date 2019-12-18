const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const math = std.math;

const ArrayList = std.ArrayList;

const input = @embedFile("input-day02.txt");

const newline_delimiter = if (std.builtin.os == .windows) "\n" else "\n";

fn splitIntoLines(allocator: *mem.Allocator, string: []const u8) ![]const []const u8 {
    var lines = ArrayList([]const u8).init(allocator);
    var newline_iterator = mem.separate(string, newline_delimiter);

    while (newline_iterator.next()) |line| {
        var trimmed_line = mem.trim(u8, line, "\n\r");
        if (!mem.eql(u8, trimmed_line, "")) (try lines.append(line));
    }

    return lines.toSliceConst();
}

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
        const sides = removeMax(3, [_]u32{ self.length, self.width, self.height });
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
        var split_iterator = mem.separate(line, "x");
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
    const lines = try splitIntoLines(allocator, input);
    const square_feet_of_paper = calculateNeededPaper(lines);
    const ribbon = calculateNeededRibbon(lines);
    std.debug.warn("Day 02:\n", .{});
    std.debug.warn("\tSolution 1: {}\n", .{square_feet_of_paper});
    std.debug.warn("\tSolution 2: {}\n", .{ribbon});
}

fn removeMax(comptime length: usize, numbers: [length]u32) [length - 1]u32 {
    const max_number = mem.max(u32, &numbers);
    var new_array = [_]u32{0} ** (length - 1);
    var skipped = false;
    var i: usize = 0;

    for (numbers) |n| {
        if (n != max_number or skipped) {
            new_array[i] = n;
            i += 1;
        } else if (n == max_number) {
            skipped = true;
        }
    }

    return new_array;
}
