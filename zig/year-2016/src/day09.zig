const std = @import("std");
const debug = std.debug;
const testing = std.testing;
const mem = std.mem;
const heap = std.heap;
const fmt = std.fmt;
const math = std.math;

const string = @import("./string.zig");

const String = string.String;

const input = @embedFile("./input-day09.txt");

pub fn main() anyerror!void {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;
    const trimmed_input = mem.trim(u8, input, "\r\n");

    debug.warn("Day 09:\n", .{});

    const solution_1 = (try decode(allocator, trimmed_input)).len;
    debug.warn("\tSolution 1: {}\n", .{solution_1});
}

fn decode(allocator: *mem.Allocator, encoded: []const u8) ![]const u8 {
    var decoded = try String(u8).init(allocator, string.StringInitOptions{});

    var position: usize = 0;
    while (position < encoded.len) : (position += 1) {
        const c = encoded[position];
        switch (c) {
            '(' => {
                position += 1;
                var range_characters = [_]u8{0} ** 256;
                var range_index: usize = 0;
                while (encoded[position] != 'x') : (position += 1) {
                    range_characters[range_index] = encoded[position];
                    range_index += 1;
                }
                position += 1;
                const range_string = range_characters[0..range_index];
                const range = try fmt.parseInt(
                    u32,
                    range_characters[0..range_index],
                    10,
                );
                var repeat_characters = [_]u8{0} ** 256;
                var repeat_index: usize = 0;
                while (encoded[position] != ')') : (position += 1) {
                    repeat_characters[repeat_index] = encoded[position];
                    repeat_index += 1;
                }
                position += 1;
                const repeat_string = repeat_characters[0..repeat_index];
                const repeat = try fmt.parseInt(
                    u32,
                    repeat_characters[0..repeat_index],
                    10,
                );

                const slice_length = math.min(range, encoded.len - position + 1);
                const slice = encoded[position..(position + slice_length)];
                // `- 1` because we will advance one in the while regardless
                position += slice_length - 1;

                var repeated: u32 = 0;
                while (repeated < repeat) : (repeated += 1) {
                    try decoded.append(slice);
                }
            },
            else => {
                try decoded.append(&[_]u8{c});
            },
        }
    }

    return decoded.sliceConst();
}

test "ADVENT" {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;

    const decoded = try decode(allocator, "ADVENT");
    testing.expectEqualSlices(u8, decoded, "ADVENT");
}

test "A(1x5)BC" {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;

    const decoded = try decode(allocator, "A(1x5)BC");
    testing.expectEqualSlices(u8, decoded, "ABBBBBC");
}

test "(3x3)XYZ" {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;

    const decoded = try decode(allocator, "(3x3)XYZ");
    testing.expectEqualSlices(u8, decoded, "XYZXYZXYZ");
}

test "A(2x2)BCD(2x2)EFG" {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;

    const decoded = try decode(allocator, "A(2x2)BCD(2x2)EFG");
    testing.expectEqualSlices(u8, decoded, "ABCBCDEFEFG");
}

test "(6x1)(1x3)A" {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;

    const decoded = try decode(allocator, "(6x1)(1x3)A");
    testing.expectEqualSlices(u8, decoded, "(1x3)A");
}

test "X(8x2)(3x3)ABCY" {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;

    const decoded = try decode(allocator, "X(8x2)(3x3)ABCY");
    testing.expectEqualSlices(u8, decoded, "X(3x3)ABC(3x3)ABCY");
}
