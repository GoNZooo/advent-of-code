const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const ascii = std.ascii;
const debug = std.debug;
const fmt = std.fmt;
const HashMap = std.hash_map.StringHashMap;

const utilities = @import("./utilities.zig");

pub fn main() anyerror!void {
    debug.warn("Day 07:\n", .{});
    var store = Store.init(std.heap.page_allocator);

    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);
    for (lines) |line| {
        const op = try Operation.fromLine(line);
        try store.store(op);
    }

    const solution_1 = try store.execute("a");
    debug.warn("\tSolution 1: {}\n", .{solution_1});

    var store2 = Store.init(std.heap.page_allocator);
    for (lines) |line| {
        const op = try Operation.fromLine(line);
        try store2.store(op);
    }
    try store2.putInCache("b", solution_1);
    const solution_2 = try store2.execute("a");
    debug.warn("\tSolution 2: {}\n", .{solution_2});
}

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

    pub fn format(
        value: Operand,
        comptime format_string: []const u8,
        options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@TypeOf(context), []const u8) Errors!void,
    ) Errors!void {
        switch (value) {
            .Literal => |v| {
                try fmt.format(context, Errors, output, "{}", .{v});
            },
            .Identifier => |id| {
                try fmt.format(context, Errors, output, "{}", .{id});
            },
        }
    }
};

const Operation = struct {
    instruction: Instruction,
    destination: []const u8,

    pub fn fromLine(line: []const u8) !Operation {
        var it = mem.split(line, " -> ");
        const left_hand = it.next().?;
        const instruction = try Instruction.fromString(left_hand);
        const destination = it.next().?;

        return Operation{ .instruction = instruction, .destination = destination };
    }
};

const ShiftData = struct {
    operand: Operand,
    shift: u4,
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

        if (utilities.all(u8, string, ascii.isDigit)) {
            const value = try Operand.fromString(string);

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

            return Instruction{
                .LSHIFT = ShiftData{ .operand = left_operand, .shift = @intCast(u4, shift) },
            };
        } else if (mem.eql(u8, instruction_token.?, "RSHIFT")) {
            const shift = switch (right_operand) {
                .Literal => |value| value,
                else => unreachable,
            };

            return Instruction{
                .RSHIFT = ShiftData{ .operand = left_operand, .shift = @intCast(u4, shift) },
            };
        }

        return error.UnableToParseInstruction;
    }

    pub fn format(
        value: Instruction,
        comptime format_string: []const u8,
        options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@TypeOf(context), []const u8) Errors!void,
    ) Errors!void {
        switch (value) {
            .Value => |v| {
                try fmt.format(context, Errors, output, "{}", .{v});
            },
            .AND => |ops| {
                try fmt.format(context, Errors, output, "{} AND {}", .{ ops.left, ops.right });
            },
            .OR => |ops| {
                try fmt.format(context, Errors, output, "{} OR {}", .{ ops.left, ops.right });
            },
            .LSHIFT => |shift_data| {
                try fmt.format(
                    context,
                    Errors,
                    output,
                    "{} << {}",
                    .{ shift_data.operand, shift_data.shift },
                );
            },
            .RSHIFT => |shift_data| {
                try fmt.format(
                    context,
                    Errors,
                    output,
                    "{} >> {}",
                    .{ shift_data.operand, shift_data.shift },
                );
            },
            .NOT => |op| {
                try fmt.format(context, Errors, output, "NOT {}", .{op});
            },
        }
    }
};

const Store = struct {
    values: HashMap(Instruction),
    cache: HashMap(u16),

    pub fn init(allocator: *mem.Allocator) Store {
        return Store{
            .values = HashMap(Instruction).init(allocator),
            .cache = HashMap(u16).init(allocator),
        };
    }

    pub fn store(self: *Store, operation: Operation) !void {
        try self.values.putNoClobber(operation.destination, operation.instruction);
    }

    pub fn get(self: Store, destination: []const u8) Instruction {
        return self.values.getValue(destination) orelse
            @panic("Trying to get non-existant destination");
    }

    pub fn putInCache(self: *Store, destination: []const u8, value: u16) !void {
        _ = try self.cache.put(destination, value);
    }

    pub fn execute(self: *Store, destination: []const u8) !u16 {
        const cached_value = self.cache.getValue(destination);

        if (cached_value) |value| {
            return value;
        }

        const instruction = self.get(destination);

        return switch (instruction) {
            .Value => |op| try self.evaluateOperand(op),
            .AND => |ops| (try self.evaluateOperand(ops.left)) & (try self.evaluateOperand(ops.right)),
            .OR => |ops| (try self.evaluateOperand(ops.left)) | (try self.evaluateOperand(ops.right)),
            .NOT => |op| ~(try self.evaluateOperand(op)),
            .LSHIFT => |shift_data| (try self.evaluateOperand(shift_data.operand)) << shift_data.shift,
            .RSHIFT => |shift_data| (try self.evaluateOperand(shift_data.operand)) >> shift_data.shift,
        };
    }

    pub fn evaluateOperand(self: *Store, operand: Operand) error{OutOfMemory}!u16 {
        return switch (operand) {
            .Literal => |x| x,
            .Identifier => |id| ret: {
                const cached_value = self.cache.getValue(id);

                if (cached_value) |value| {
                    break :ret value;
                } else {
                    const v = try self.execute(id);
                    try self.cache.putNoClobber(id, v);
                    break :ret v;
                }
            },
        };
    }
};

test "test input parses and executes" {
    var lines = try utilities.splitIntoLines(std.heap.page_allocator, test_input);
    var store = Store.init(std.heap.page_allocator);

    for (lines) |line| {
        const op = try Operation.fromLine(line);
        try store.store(op);
    }

    testing.expectEqual(store.values.count(), 8);

    const d = store.execute("d");
    const e = store.execute("e");
    const f = store.execute("f");
    const g = store.execute("g");
    const h = store.execute("h");
    const i = store.execute("i");
    const x = store.execute("x");
    const y = store.execute("y");
    testing.expectEqual(d, 72);
    testing.expectEqual(e, 507);
    testing.expectEqual(f, 492);
    testing.expectEqual(g, 114);
    testing.expectEqual(h, 65412);
    testing.expectEqual(i, 65079);
    testing.expectEqual(x, 123);
    testing.expectEqual(y, 456);
}

test "input executes" {
    var lines = try utilities.splitIntoLines(std.heap.page_allocator, input);
    var store = Store.init(std.heap.page_allocator);

    for (lines) |line| {
        const op = try Operation.fromLine(line);
        try store.store(op);
    }

    testing.expectEqual(store.values.count(), 339);

    const a = try store.execute("a");
    testing.expectEqual(a, 3176);

    var store2 = Store.init(std.heap.page_allocator);

    for (lines) |line| {
        const op = try Operation.fromLine(line);
        try store2.store(op);
    }

    try store2.putInCache("b", a);
    const a2 = store2.execute("a");
    testing.expectEqual(a2, 14710);
}

const input = @embedFile("input-day07.txt");

const test_input =
    \\123 -> x
    \\456 -> y
    \\x AND y -> d
    \\x OR y -> e
    \\x LSHIFT 2 -> f
    \\y RSHIFT 2 -> g
    \\NOT x -> h
    \\NOT y -> i
;
