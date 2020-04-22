const std = @import("std");
const debug = std.debug;
const heap = std.heap;
const mem = std.mem;
const testing = std.testing;
const fmt = std.fmt;

const String = @import("./string.zig").String;

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

pub fn main() anyerror!void {
    debug.warn("Day 21:\n", .{});
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;
    const lines = try utilities.splitIntoLines(heap.page_allocator, input);

    var program_1 = try Program.init(allocator, lines, "abcdefgh");
    try program_1.run();
    const solution_1 = program_1.state;
    debug.warn("\tSolution 1: {}", .{solution_1});
}

const Program = struct {
    const Self = @This();

    state: String(u8),
    instructions: []const Instruction,
    program_counter: usize = 0,
    allocator: *mem.Allocator,

    fn init(
        allocator: *mem.Allocator,
        lines: []const []const u8,
        initial_state: []const u8,
    ) !Self {
        var instructions = try allocator.alloc(Instruction, lines.len);
        var state = try String(u8).copyConst(allocator, initial_state);
        for (lines) |line, i| {
            instructions[i] = try Instruction.fromString(line);
        }

        return Self{
            .state = state,
            .instructions = instructions,
            .allocator = allocator,
        };
    }

    fn run(self: *Self) !void {
        for (self.instructions) |i| {
            try self.runInstruction(i);
        }
    }

    fn runBackwards(self: *Self) !void {
        var program_counter = self.instructions[self.instructions.len - 1];
        while (program_counter > 0) : (program_counter -= 1) {
            const instruction = self.instructions[program_counter];
            try self.runInstruction(instruction);
        }
    }

    fn step(self: *Self) !void {
        const instruction = self.instructions[self.program_counter];
        try self.runInstruction(instruction);
    }

    fn runInstruction(self: *Self, instruction: Instruction) !void {
        switch (instruction) {
            .SwapPosition => |swap| {
                const t = self.state.__chars[swap.x];
                self.state.__chars[swap.x] = self.state.__chars[swap.y];
                self.state.__chars[swap.y] = t;
            },
            .SwapLetter => |swap| {
                const maybe_x_index = self.state.find(swap.x);
                const maybe_y_index = self.state.find(swap.y);
                if (maybe_x_index != null and maybe_y_index != null) {
                    const x_index = maybe_x_index.?;
                    const y_index = maybe_y_index.?;
                    const x = self.state.__chars[x_index];
                    const y = self.state.__chars[y_index];
                    self.state.__chars[x_index] = y;
                    self.state.__chars[y_index] = x;
                } else {
                    return error.InvalidIndicesInSwapLetter;
                }
            },
            .ReversePositions => |reverse| {
                const x = reverse.x;
                const y = reverse.y;

                var state_slice = self.state.__chars[x..(y + 1)];
                const reversed = try reverseSlice(self.allocator, state_slice);
                mem.copy(u8, state_slice, reversed);
            },
            .RotateLeft => |left| {
                try self.rotateLeft(left);
            },
            .RotateRight => |right| {
                try self.rotateLeft(self.state.count - right);
            },
            .RotatePosition => |letter| {
                const maybe_letter_index = self.state.find(letter);
                if (maybe_letter_index) |letter_index| {
                    const rotation = r: {
                        if (letter_index >= 4) {
                            break :r letter_index + 2;
                        } else {
                            break :r letter_index + 1;
                        }
                    };
                    try self.rotateLeft(
                        self.state.count - (rotation % self.state.count),
                    );
                }
            },
            .MovePosition => |move| {
                const x_index = move.x;
                const x = self.state.__chars[x_index];
                const y_index = move.y;

                self.state.delete(x_index, x_index + 1, .{});
                try self.state.insertSlice(y_index, &[_]u8{x});
            },
        }
        self.program_counter += 1;
    }

    fn rotateLeft(self: *Self, left: usize) !void {
        var copy = try self.allocator.alloc(u8, self.state.count);
        defer self.allocator.free(copy);
        mem.copy(u8, copy, self.state.__chars);
        for (self.state.__chars) |*c, i| {
            const modded = (i + left) % self.state.count;
            c.* = copy[modded];
        }
    }

    fn reverseSlice(allocator: *mem.Allocator, slice: []const u8) ![]const u8 {
        var reversed = try allocator.alloc(u8, slice.len);
        var i: usize = slice.len;
        while (i > 0) : (i -= 1) {
            reversed[slice.len - i] = slice[i - 1];
        }

        return reversed;
    }
};

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

test "test input steps correctly through instructions" {
    const lines = try utilities.splitIntoLines(heap.page_allocator, test_input);
    var program = try Program.init(heap.page_allocator, lines, "abcde");

    try program.step();
    testing.expectEqualSlices(u8, program.state.sliceConst(), "ebcda");

    try program.step();
    testing.expectEqualSlices(u8, program.state.sliceConst(), "edcba");

    try program.step();
    testing.expectEqualSlices(u8, program.state.sliceConst(), "abcde");

    try program.step();
    testing.expectEqualSlices(u8, program.state.sliceConst(), "bcdea");

    try program.step();
    testing.expectEqualSlices(u8, program.state.sliceConst(), "bdeac");

    try program.step();
    testing.expectEqualSlices(u8, program.state.sliceConst(), "abdec");

    try program.step();
    testing.expectEqualSlices(u8, program.state.sliceConst(), "ecabd");

    try program.step();
    testing.expectEqualSlices(u8, program.state.sliceConst(), "decab");
}
