const std = @import("std");
const debug = std.debug;
const heap = std.heap;
const mem = std.mem;
const testing = std.testing;
const fmt = std.fmt;

const utilities = @import("./utilities.zig");

const input = @embedFile("input-day21.txt");

const test_input =
    \\swap position 4 with position 0
    \\swap letter d with letter b
    \\reverse positions 0 through 4
    \\rotate left 1 step
    \\move position 1 to position 4
    \\move position 3 to position 0
    \\rotate based on position of letter b
    \\rotate based on position of letter d
;

const Instruction = union(enum) {
    const Self = @This();

    SwapPosition: SwapPositionData,
    SwapLetter: SwapLetterData,
    ReversePositions: ReversePositionsData,
    RotateLeft: u32,
    RotateRight: u32,
    RotatePosition: u8,
    MovePosition: MovePositionData,

    fn fromString(string: []const u8) !Self {
        var it = mem.split(mem.trim(u8, string, " \r\n"), " ");

        const instruction_base_identifier = it.next().?;
        if (mem.eql(u8, instruction_base_identifier, "swap")) {
            const swap_type = it.next().?;
            if (mem.eql(u8, swap_type, "position")) {
                const x_string = it.next().?;
                const x = try fmt.parseInt(u32, x_string, 10);
                debug.assert(mem.eql(u8, it.next().?, "with"));
                debug.assert(mem.eql(u8, it.next().?, "position"));
                const y_string = it.next().?;
                const y = try fmt.parseInt(u32, y_string, 10);

                return Self{
                    .SwapPosition = SwapPositionData{ .x = x, .y = y },
                };
            } else if (mem.eql(u8, swap_type, "letter")) {
                const x = it.next().?;
                debug.assert(mem.eql(u8, it.next().?, "with"));
                debug.assert(mem.eql(u8, it.next().?, "letter"));
                const y = it.next().?;

                return Self{
                    .SwapLetter = SwapLetterData{ .x = x[0], .y = y[0] },
                };
            } else {
                return error.UnknownSwap;
            }
        } else if (mem.eql(u8, instruction_base_identifier, "reverse")) {
            debug.assert(mem.eql(u8, it.next().?, "positions"));
            const x_string = it.next().?;
            const x = try fmt.parseInt(usize, x_string, 10);
            debug.assert(mem.eql(u8, it.next().?, "through"));
            const y_string = it.next().?;
            const y = try fmt.parseInt(usize, y_string, 10);

            return Self{
                .ReversePositions = ReversePositionsData{ .x = x, .y = y },
            };
        } else if (mem.eql(u8, instruction_base_identifier, "move")) {
            debug.assert(mem.eql(u8, it.next().?, "position"));
            const x_string = it.next().?;
            const x = try fmt.parseInt(usize, x_string, 10);
            debug.assert(mem.eql(u8, it.next().?, "to"));
            debug.assert(mem.eql(u8, it.next().?, "position"));
            const y_string = it.next().?;
            const y = try fmt.parseInt(usize, y_string, 10);

            return Self{
                .MovePosition = MovePositionData{ .x = x, .y = y },
            };
        } else if (mem.eql(u8, instruction_base_identifier, "rotate")) {
            const rotate_type = it.next().?;
            if (mem.eql(u8, rotate_type, "left")) {
                const steps_string = it.next().?;
                const steps = try fmt.parseInt(u32, steps_string, 10);
                return Self{ .RotateLeft = steps };
            } else if (mem.eql(u8, rotate_type, "right")) {
                const steps_string = it.next().?;
                const steps = try fmt.parseInt(u32, steps_string, 10);

                return Self{ .RotateRight = steps };
            } else if (mem.eql(u8, rotate_type, "based")) {
                debug.assert(mem.eql(u8, it.next().?, "on"));
                debug.assert(mem.eql(u8, it.next().?, "position"));
                debug.assert(mem.eql(u8, it.next().?, "of"));
                debug.assert(mem.eql(u8, it.next().?, "letter"));
                const letter = it.next().?[0];

                return Self{ .RotatePosition = letter };
            } else {
                return error.UnknownRotate;
            }
        } else {
            return error.UnknownInstruction;
        }
    }
};

const SwapPositionData = struct {
    x: u32,
    y: u32,
};

const SwapLetterData = struct {
    x: u8,
    y: u8,
};

const ReversePositionsData = struct {
    x: usize,
    y: usize,
};

const MovePositionData = struct {
    x: usize,
    y: usize,
};

pub fn main() anyerror!void {
    const lines = try utilities.splitIntoLines(heap.page_allocator, input);
    for (lines) |l| {
        debug.warn("l: {}\n", .{l});
    }
    debug.warn("Day 21:\n", .{});
}

test "test input parses" {
    const lines = try utilities.splitIntoLines(heap.page_allocator, test_input);
    for (lines) |l| {
        const i = try Instruction.fromString(l);
        debug.warn("i: {}\n", .{i});
    }
}
