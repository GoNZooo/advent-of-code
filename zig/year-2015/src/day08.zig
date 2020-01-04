const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;

const utilities = @import("./utilities.zig");

const input = @embedFile("./input-day08.txt");

pub fn main() anyerror!void {
    debug.warn("Day 08:\n", .{});

    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);

    const solution_1 = encodingAndContentDifference(lines);
    debug.warn("\tSolution 1: {}\n", .{solution_1});

    const solution_2 = "not solved";
    debug.warn("\tSolution 2: {}\n", .{solution_2});
}

const Size = struct {
    encoding: usize,
    content: usize,

    pub fn fromString(string: []const u8) Size {
        return stringSize(string);
    }
};

const StringIterator = struct {
    _current: ?usize,
    _slice: []const u8,

    pub fn fromSlice(slice: []const u8) StringIterator {
        return StringIterator{ ._current = null, ._slice = slice };
    }

    pub fn next(self: *StringIterator) ?u8 {
        if (self._current) |*current| {
            if (current.* < (self._slice.len - 1)) {
                current.* += 1;
            } else {
                return null;
            }

            return self._slice[current.*];
        } else if (self._slice.len == 0) {
            return null;
        } else {
            self._current = 0;

            return self._slice[0];
        }
    }

    pub fn skip(self: *StringIterator, skip_length: usize) void {
        if (self._current) |*current| current.* += skip_length;
    }

    pub fn peek(self: StringIterator, forward: usize) ?u8 {
        if (self._current) |current| {
            if (current + forward >= self._slice.len) return null;

            return self._slice[current + forward];
        }

        return null;
    }
};

fn encodingAndContentDifference(strings: []const []const u8) usize {
    var total_encoding: usize = 0;
    var total_content: usize = 0;
    for (strings) |string| {
        const line_size = Size.fromString(string);
        total_encoding += line_size.encoding;
        total_content += line_size.content;
    }

    return total_encoding - total_content;
}

fn stringSize(string: []const u8) Size {
    var content: usize = 0;
    const trimmed_string = string[1..(string.len - 1)];

    var it = StringIterator.fromSlice(trimmed_string);
    while (it.next()) |c| {
        switch (c) {
            '\\' => {
                const next = it.peek(1) orelse 0;
                switch (next) {
                    'x' => {
                        content += 1;
                        it.skip(3);
                    },
                    else => {
                        content += 1;
                        it.skip(1);
                    },
                }
            },
            else => {
                content += 1;
            },
        }
    }

    return Size{ .encoding = string.len, .content = content };
}

test "empty string" {
    const size = stringSize("\"\"");
    testing.expectEqual(size.encoding, 2);
    testing.expectEqual(size.content, 0);
}

test "hex literals" {
    const size = stringSize("\"\\x27\"");
    testing.expectEqual(size.encoding, 6);
    testing.expectEqual(size.content, 1);
}

test "abc" {
    const size = stringSize("\"abc\"");
    testing.expectEqual(size.encoding, 5);
    testing.expectEqual(size.content, 3);
}

test "aaa\"aaa" {
    const size = stringSize("\"aaa\\\"aaa\"");
    testing.expectEqual(size.encoding, 10);
    testing.expectEqual(size.content, 7);
}

test "works on total test input" {
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, test_input);

    const difference = encodingAndContentDifference(lines);
    testing.expectEqual(difference, 12);
}

test "works on total input" {
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);

    const difference = encodingAndContentDifference(lines);
    testing.expectEqual(difference, 1342);
}

const test_input =
    \\""
    \\"abc"
    \\"aaa\"aaa"
    \\"\x27"
;
