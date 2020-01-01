const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const ascii = std.ascii;
const debug = std.debug;
const fmt = std.fmt;

const utilities = @import("./utilities.zig");

pub fn main() void {}

const Operand = union(enum) {
    Literal: u16,
    Identifier: []const u8,

    pub fn fromString(string: []const u8) !Operand {
        debug.assert(string.len >= 1);
        if (utilities.all(u8, string, ascii.isAlpha)) return Operand{ .Identifier = string };
        if (utilities.all(u8, string, ascii.isDigit)) {
            const value = try fmt.parseInt(u16, string, 10);

            return Operand{ .Literal = value };
        }

        return error.UnableToParseOperand;
    }
};

const Operation = struct {
    instruction: Instruction,
    destination: []const u8,

    pub fn fromLine(line: []const u8) !Operation {
        var it = mem.separate(line, " -> ");
        const left_hand = it.next().?;
        const instruction = try Instruction.fromString(left_hand);
        const destination = it.next().?;

        return Operation{ .instruction = instruction, .destination = destination };
    }
};

const ShiftData = struct {
    operand: Operand,
    shift: u16,
};

const Operands = struct {
    left: Operand,
    right: Operand,
};

const Instruction = union(enum) {
    AND: Operands,
    OR: Operands,
    NOT: Operand,
    LSHIFT: ShiftData,
    RSHIFT: ShiftData,
    Value: Operand,

    pub fn fromString(string: []const u8) !Instruction {
        var it = mem.tokenize(string, " ");
        const first_token = it.next().?;

        if (utilities.all(u8, first_token, ascii.isDigit)) {
            const value = try Operand.fromString(first_token);

            return Instruction{ .Value = value };
        } else if (mem.eql(u8, first_token, "NOT")) {
            const operand = it.next().?;

            return Instruction{ .NOT = try Operand.fromString(operand) };
        }

        const left_operand = try Operand.fromString(first_token);
        const instruction_token = it.next();
        if (instruction_token == null) {
            return Instruction{ .Value = left_operand };
        }
        const right_operand = try Operand.fromString(it.next().?);

        if (mem.eql(u8, instruction_token.?, "AND")) {
            return Instruction{ .AND = Operands{ .left = left_operand, .right = right_operand } };
        } else if (mem.eql(u8, instruction_token.?, "OR")) {
            return Instruction{ .OR = Operands{ .left = left_operand, .right = right_operand } };
        } else if (mem.eql(u8, instruction_token.?, "LSHIFT")) {
            const shift = switch (right_operand) {
                .Literal => |value| value,
                else => unreachable,
            };

            return Instruction{ .LSHIFT = ShiftData{ .operand = left_operand, .shift = shift } };
        } else if (mem.eql(u8, instruction_token.?, "RSHIFT")) {
            const shift = switch (right_operand) {
                .Literal => |value| value,
                else => unreachable,
            };

            return Instruction{ .RSHIFT = ShiftData{ .operand = left_operand, .shift = shift } };
        }

        return error.ParsingFailed;
    }
};

test "input parses correctly" {
    var lines = try utilities.splitIntoLines(std.heap.page_allocator, input);

    for (lines) |line| {
        const op = try Operation.fromLine(line);
    }
}

const input = @embedFile("input-day07.txt");
