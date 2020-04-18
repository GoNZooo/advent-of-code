const std = @import("std");
const testing = std.testing;
const debug = std.debug;
const mem = std.mem;
const fmt = std.fmt;

const utilities = @import("./utilities.zig");

pub fn main() anyerror!void {
    debug.warn("Day 23:\n", .{});

    const input_lines = try utilities.splitIntoLines(
        std.heap.page_allocator,
        input,
    );
    testing.expect(input_lines.len != 0);
    const instructions = try std.heap.page_allocator.alloc(Instruction, input_lines.len);
    for (input_lines) |line, i| {
        instructions[i] = try Instruction.fromLine(line);
    }

    const solution_1 = ProgramState.init([_]u32{0} ** 255, instructions).run().valueIn('b');
    debug.warn("\tSolution 1: {}\n", .{solution_1});

    var solution2Registers = [_]u32{0} ** 255;
    solution2Registers['a'] = 1;

    const solution_2 = ProgramState.init(solution2Registers, instructions).run().valueIn('b');
    debug.warn("\tSolution 2: {}\n", .{solution_2});
}

const input = @embedFile("input-day23.txt");

const Instruction = union(enum) {
    const Self = @This();

    Increment: RegisterName,
    Triple: RegisterName,
    Half: RegisterName,
    Jump: Offset,
    JumpIfEven: JumpIfPayload,
    JumpIfOne: JumpIfPayload,

    fn fromLine(line: []const u8) !Instruction {
        var comma_iterator = mem.split(line, ",");
        const l1 = comma_iterator.next() orelse unreachable;
        var l1_iterator = mem.split(l1, " ");
        const instruction_identifier = l1_iterator.next() orelse unreachable;
        if (mem.eql(u8, instruction_identifier, "inc")) {
            const register = l1_iterator.next() orelse unreachable;

            return Instruction{ .Increment = register[0] };
        } else if (mem.eql(u8, instruction_identifier, "tpl")) {
            const register = l1_iterator.next() orelse unreachable;

            return Instruction{ .Triple = register[0] };
        } else if (mem.eql(u8, instruction_identifier, "hlf")) {
            const register = l1_iterator.next() orelse unreachable;

            return Instruction{ .Half = register[0] };
        } else if (mem.eql(u8, instruction_identifier, "jmp")) {
            const offset = try parseOffset(
                l1_iterator.next() orelse unreachable,
            );

            return Instruction{ .Jump = offset };
        } else if (mem.eql(u8, instruction_identifier, "jie")) {
            const register = l1_iterator.next() orelse unreachable;
            const offset = try parseOffset(
                comma_iterator.next() orelse unreachable,
            );

            return Instruction{
                .JumpIfEven = .{
                    .register = register[0],
                    .offset = offset,
                },
            };
        } else if (mem.eql(u8, instruction_identifier, "jio")) {
            const register = l1_iterator.next() orelse unreachable;
            const offset = try parseOffset(
                comma_iterator.next() orelse unreachable,
            );

            return Instruction{
                .JumpIfOne = .{
                    .register = register[0],
                    .offset = offset,
                },
            };
        } else {
            return error.UnknownInstruction;
        }
    }

    fn parseOffset(string: []const u8) !Offset {
        const trimmed = mem.trim(u8, string, " +\r\n");

        return try fmt.parseInt(Offset, trimmed, 10);
    }

    pub fn format(
        self: Self,
        comptime formatting: []const u8,
        options: fmt.FormatOptions,
        out_stream: var,
    ) !void {
        return switch (self) {
            .Increment => |register| {
                try fmt.format(out_stream, "inc {c}", .{register});
            },
            .Triple => |register| {
                try fmt.format(out_stream, "tpl {c}", .{register});
            },
            .Half => |register| {
                try fmt.format(out_stream, "hlf {c}", .{register});
            },
            .Jump => |offset| {
                try fmt.format(out_stream, "jmp {}", .{offset});
            },
            .JumpIfEven => |jump_if_data| {
                try fmt.format(
                    out_stream,
                    "jie {c}, {}",
                    .{ jump_if_data.register, jump_if_data.offset },
                );
            },
            .JumpIfOne => |jump_if_data| {
                try fmt.format(
                    out_stream,
                    "jio {c}, {}",
                    .{ jump_if_data.register, jump_if_data.offset },
                );
            },
        };
    }
};

const Offset = i64;
const Registers = [255]u32;

const ProgramState = struct {
    const Self = @This();

    registers: [255]u32,
    instructions: []const Instruction,
    program_counter: usize = 0,

    fn init(registers: Registers, instructions: []const Instruction) Self {
        return Self{ .registers = registers, .instructions = instructions };
    }

    fn run(self: *Self) Self {
        while (self.program_counter < self.instructions.len) {
            const current_instruction = self.instructions[self.program_counter];
            switch (current_instruction) {
                .Increment => |register| {
                    self.registers[register] += 1;
                    self.program_counter += 1;
                },
                .Triple => |register| {
                    self.registers[register] *= 3;
                    self.program_counter += 1;
                },
                .Half => |register| {
                    self.registers[register] /= 2;
                    self.program_counter += 1;
                },

                .Jump => |offset| {
                    self.program_counter = @intCast(
                        usize,
                        @intCast(Offset, self.program_counter) + offset,
                    );
                },
                .JumpIfEven => |jump_if_data| {
                    const register = jump_if_data.register;
                    const offset = jump_if_data.offset;
                    const register_value = self.registers[register];
                    if (register_value % 2 == 0) {
                        self.program_counter = @intCast(
                            usize,
                            @intCast(Offset, self.program_counter) + offset,
                        );
                    } else {
                        self.program_counter += 1;
                    }
                },
                .JumpIfOne => |jump_if_data| {
                    const register = jump_if_data.register;
                    const offset = jump_if_data.offset;
                    const register_value = self.registers[register];
                    if (register_value == 1) {
                        self.program_counter = @intCast(
                            usize,
                            @intCast(Offset, self.program_counter) + offset,
                        );
                    } else {
                        self.program_counter += 1;
                    }
                },
            }
        }

        return self.*;
    }

    fn valueIn(self: Self, register: u8) u32 {
        return self.registers[register];
    }
};

const RegisterName = u8;

const JumpIfPayload = struct { register: RegisterName, offset: Offset };

test "runs test input" {
    const input_lines = try utilities.splitIntoLines(
        std.heap.page_allocator,
        test_input,
    );
    testing.expect(input_lines.len != 0);
    var instructions = try std.heap.page_allocator.alloc(Instruction, input_lines.len);
    for (input_lines) |line, i| {
        instructions[i] = try Instruction.fromLine(line);
    }

    const register_a = ProgramState.init([_]u32{0} ** 255, instructions).run().valueIn('a');
    testing.expectEqual(register_a, 2);
}

const test_input =
    \\inc a
    \\jio a, +2
    \\tpl a
    \\inc a
;
