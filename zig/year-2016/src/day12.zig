const std = @import("std");
const debug = std.debug;
const testing = std.testing;
const mem = std.mem;
const heap = std.heap;
const fmt = std.fmt;

const utilities = @import("./utilities.zig");

pub fn main() anyerror!void {
    var allocator = &heap.ArenaAllocator.init(heap.page_allocator).allocator;
    const lines = try utilities.splitIntoLines(allocator, input);
    var solution_1_program = try ProgramState.init(allocator, lines);

    debug.warn("Day 12:\n", .{});

    solution_1_program.run();
    const solution_1 = solution_1_program.valueIn('a');
    debug.warn("\tSolution 1: {}\n", .{solution_1});

    var solution_2_program = try ProgramState.init(allocator, lines);
    solution_2_program.putValueIn('c', 1);
    solution_2_program.run();
    const solution_2 = solution_2_program.valueIn('a');
    debug.warn("\tSolution 2: {}\n", .{solution_2});
}

const input = @embedFile("./input-day12.txt");

const test_input =
    \\cpy 41 a
    \\inc a
    \\inc a
    \\dec a
    \\jnz a 2
    \\dec a
;

const Register = u8;
const Offset = i32;

const Instruction = union(enum) {
    const Self = @This();

    Copy: CopyData,
    Increment: Register,
    Decrement: Register,
    JumpIfNotZero: JumpIfNotZeroData,

    fn fromLine(line: []const u8) !Self {
        var it = mem.split(line, " ");
        const instruction_identifier = it.next().?;

        if (mem.eql(u8, instruction_identifier, "cpy")) {
            const source_string = it.next().?;
            const source = source: {
                if (isRegister(source_string)) {
                    break :source CopySource{ .Register = source_string[0] };
                } else if (isNumeric(source_string)) {
                    const parsed_int = try fmt.parseInt(i32, source_string, 10);
                    break :source CopySource{ .Value = parsed_int };
                } else {
                    return error.InvalidSourceArgument;
                }
            };

            const destination_string = it.next().?;
            const destination = destination_string[0];

            return Self{
                .Copy = CopyData{
                    .source = source,
                    .destination = destination,
                },
            };
        } else if (mem.eql(u8, instruction_identifier, "inc")) {
            const register_string = it.next().?;
            const register = register_string[0];

            return Self{ .Increment = register };
        } else if (mem.eql(u8, instruction_identifier, "dec")) {
            const register_string = it.next().?;
            const register = register_string[0];

            return Self{ .Decrement = register };
        } else if (mem.eql(u8, instruction_identifier, "jnz")) {
            const comparator_string = it.next().?;
            const comparator = comparator: {
                if (isRegister(comparator_string)) {
                    break :comparator JumpComparator{ .Register = comparator_string[0] };
                } else if (isNumeric(comparator_string)) {
                    const parsed_int = try fmt.parseInt(i32, comparator_string, 10);
                    break :comparator JumpComparator{ .Value = parsed_int };
                } else {
                    return error.InvalidJumpComparator;
                }
            };
            const offset_string = mem.trim(u8, it.next().?, "\r\n+");
            const offset = try fmt.parseInt(i32, offset_string, 10);

            return Self{
                .JumpIfNotZero = JumpIfNotZeroData{
                    .comparator = comparator,
                    .offset = offset,
                },
            };
        } else {
            return error.UnknownInstruction;
        }
    }

    pub fn format(
        self: Self,
        comptime formatting: []const u8,
        options: fmt.FormatOptions,
        out_stream: var,
    ) !void {
        return switch (self) {
            .Copy => |copy_data| {
                switch (copy_data.source) {
                    .Value => |v| {
                        try fmt.format(
                            out_stream,
                            "cpy {} {c}",
                            .{ v, copy_data.destination },
                        );
                    },
                    .Register => |r| {
                        try fmt.format(
                            out_stream,
                            "cpy {c} {c}",
                            .{ r, copy_data.destination },
                        );
                    },
                }
            },
            .Increment => |register| {
                try fmt.format(out_stream, "inc {c}", .{register});
            },
            .Decrement => |register| {
                try fmt.format(out_stream, "dec {c}", .{register});
            },
            .JumpIfNotZero => |jump_data| {
                switch (jump_data.comparator) {
                    .Value => |v| {
                        try fmt.format(
                            out_stream,
                            "jnz {} {}",
                            .{ v, jump_data.offset },
                        );
                    },
                    .Register => |r| {
                        try fmt.format(
                            out_stream,
                            "jnz {c} {}",
                            .{ r, jump_data.offset },
                        );
                    },
                }
            },
        };
    }
};

const CopyData = struct {
    source: CopySource,
    destination: Register,
};

const JumpIfNotZeroData = struct {
    comparator: JumpComparator,
    offset: Offset,
};

const CopySource = union(enum) {
    Register: Register,
    Value: i32,
};

const JumpComparator = union(enum) {
    Register: Register,
    Value: i32,
};

fn isRegister(s: []const u8) bool {
    return s.len == 1 and isAlphaChar(s[0]);
}

fn isNumeric(s: []const u8) bool {
    for (s) |c| {
        if (!isNumericChar(c) and c != '-') return false;
    }

    return true;
}

fn isAlphaChar(c: u8) bool {
    return switch (c) {
        'a'...'z' => true,
        'A'...'Z' => true,
        else => false,
    };
}

fn isNumericChar(c: u8) bool {
    return switch (c) {
        '0'...'9' => true,
        else => false,
    };
}

const ProgramState = struct {
    const Self = @This();

    registers: [256]i32,
    instructions: []const Instruction,

    fn init(allocator: *mem.Allocator, lines: []const []const u8) !Self {
        var instructions = try allocator.alloc(Instruction, lines.len);
        for (lines) |line, i| {
            instructions[i] = try Instruction.fromLine(line);
        }

        return Self{
            .registers = [_]i32{0} ** 256,
            .instructions = instructions,
        };
    }

    fn run(self: *Self) void {
        var program_counter: i32 = 0;
        while (program_counter < self.instructions.len) {
            const instruction = self.instructions[@intCast(usize, program_counter)];
            switch (instruction) {
                .Copy => |copy_data| {
                    const value_to_copy = switch (copy_data.source) {
                        .Value => |v| v,
                        .Register => |r| self.registers[r],
                    };
                    self.registers[copy_data.destination] = value_to_copy;
                    program_counter += 1;
                },
                .Increment => |register| {
                    self.registers[register] += 1;
                    program_counter += 1;
                },
                .Decrement => |register| {
                    self.registers[register] -= 1;
                    program_counter += 1;
                },
                .JumpIfNotZero => |jump_data| {
                    const value = switch (jump_data.comparator) {
                        .Value => |v| v,
                        .Register => |r| self.registers[r],
                    };
                    const offset = jump_data.offset;
                    const zero = value == 0;
                    const jump_length = if (!zero) offset else 1;
                    program_counter += jump_length;
                },
            }
        }
    }

    fn valueIn(self: Self, register: Register) i32 {
        return self.registers[register];
    }

    fn putValueIn(self: *Self, register: Register, value: i32) void {
        self.registers[register] = value;
    }
};

test "test input parses" {
    const lines = try utilities.splitIntoLines(heap.page_allocator, test_input);
    var program_state = try ProgramState.init(heap.page_allocator, lines);
    program_state.run();
    const a = program_state.valueIn('a');
    testing.expectEqual(a, 42);
}
