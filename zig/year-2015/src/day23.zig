const std = @import("std");
const testing = std.testing;
const debug = std.debug;
const mem = std.mem;
const fmt = std.fmt;

const utilities = @import("./utilities.zig");

const input = @embedFile("input-day23.txt");

const Instruction = union(enum) {
    Increment: RegisterName,
    Triple: RegisterName,
    Half: RegisterName,
    Jump: i32,
    JumpIfEven: JumpIfPayload,
    JumpIfOdd: JumpIfPayload,

    fn fromLine(line: []const u8) !Instruction {
        var comma_iterator = mem.separate(line, ",");
        const l1 = comma_iterator.next() orelse unreachable;
        var l1_iterator = mem.separate(l1, " ");
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
                .JumpIfOdd = .{
                    .register = register[0],
                    .offset = offset,
                },
            };
        } else {
            return error.UnknownInstruction;
        }
    }

    fn parseOffset(string: []const u8) !i32 {
        const trimmed = mem.trim(u8, string, " +\r\n");

        return try fmt.parseInt(i32, trimmed, 10);
    }
};

const RegisterName = u8;

const JumpIfPayload = struct { register: RegisterName, offset: i32 };

test "parses instructions" {
    const input_lines = try utilities.splitIntoLines(
        std.heap.page_allocator,
        input,
    );
    testing.expect(input_lines.len != 0);
    var instructions = try std.heap.page_allocator.alloc(Instruction, input_lines.len);
    for (input_lines) |line, i| {
        instructions[i] = try Instruction.fromLine(line);
    }
}
