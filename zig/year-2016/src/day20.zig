const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const debug = std.debug;
const fmt = std.fmt;
const testing = std.testing;

const utilities = @import("./utilities.zig");

const input = @embedFile("./input-day20.txt");

const ArrayList = std.ArrayList;

const test_input =
    \\5-8
    \\0-2
    \\4-7
;

pub fn main() anyerror!void {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;
    debug.warn("Day 20:\n", .{});
    const lines = try utilities.splitIntoLines(allocator, input);
    const blacklisted_ranges = try linesToRanges(allocator, lines);
    const solution_1 = try allowedIp(blacklisted_ranges);
    debug.warn("\tSolution 1: {}\n", .{solution_1});

    const solution_2 = try allowedIps(
        allocator,
        blacklisted_ranges,
        std.math.maxInt(u32) + 1,
    );
    debug.warn("\tSolution 2: {}\n", .{solution_2});
}

const Range = struct {
    const Self = @This();

    start: u32,
    end: u32,

    fn fromLine(line: []const u8) !Self {
        var it = mem.split(line, "-");
        const start_string = it.next().?;
        const end_string = it.next().?;

        const start = try fmt.parseInt(u32, start_string, 10);
        const end = try fmt.parseInt(u32, end_string, 10);

        return Self{ .start = start, .end = end };
    }
};

fn linesToRanges(allocator: *mem.Allocator, lines: []const []const u8) ![]const Range {
    var ranges = try allocator.alloc(Range, lines.len);
    for (lines) |l, i| {
        const r = try Range.fromLine(mem.trim(u8, l, " \r\n"));
        ranges[i] = r;
    }

    return ranges;
}

fn allowedIps(allocator: *mem.Allocator, blacklisted: []const Range, upper_bound: usize) !usize {
    // Using `u8` here is like 1.6x as fast as `bool` and since they use the
    // same amount of memory it doesn't make sense to use `bool`.
    // Not freeing because it's needless in this program, by the way.
    var allowed = try allocator.alloc(u8, upper_bound);
    mem.set(u8, allowed, 1);
    for (blacklisted) |r| {
        mem.set(u8, allowed[r.start..(r.end + 1)], 0);
    }

    var allowed_count: usize = 0;
    for (allowed) |a| {
        if (a == 1) allowed_count += 1;
    }

    return allowed_count;
}

fn allowedIp(blacklisted: []const Range) !u32 {
    var ip: u32 = 0;
    while (ip < std.math.maxInt(u32)) : (ip += 1) {
        if (!isBlacklisted(ip, blacklisted)) return ip;
    }

    return error.NoAllowedIp;
}

fn isBlacklisted(ip: u32, blacklisted: []const Range) bool {
    for (blacklisted) |r| {
        if (ip >= r.start and ip <= r.end) return true;
    }

    return false;
}

fn expandRange(allocator: *mem.Allocator, range: Range) ![]u32 {
    const count = range.end - range.start + 1;
    var numbers = try allocator.alloc(u32, count);
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        numbers[i] = range.start + i;
    }

    return numbers;
}

test "test input gives correct results" {
    const lines = try utilities.splitIntoLines(heap.page_allocator, test_input);
    var blacklisted_ranges = try linesToRanges(heap.page_allocator, lines);
    const allowed = try allowedIp(blacklisted_ranges);
    testing.expectEqual(allowed, 3);

    const allowed_ips = try allowedIps(
        heap.page_allocator,
        blacklisted_ranges,
        10,
    );
    testing.expectEqual(allowed_ips, 2);
}
