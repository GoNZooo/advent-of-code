const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;
const fmt = std.fmt;

const Map = std.AutoHashMap;

const utilities = @import("./utilities.zig");

const input = @embedFile("input-day06.txt");
const test_input =
    \\eedadn
    \\drvtee
    \\eandsr
    \\raavrd
    \\atevrs
    \\tsrnev
    \\sdttsa
    \\rasrtv
    \\nssdts
    \\ntnada
    \\svetve
    \\tesnvt
    \\vntsnd
    \\vrdear
    \\dvrsen
    \\enarar
;

pub fn main() anyerror!void {
    debug.warn("Day 06:\n", .{});
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);

    var most_common = try MostCommon(8).init(std.heap.page_allocator, lines);

    const solution_1 = most_common.getPassword();
    debug.warn("\tSolution 1: {}\n", .{solution_1});

    const solution_2 = most_common.getPasswordByLowestFrequency();
    debug.warn("\tSolution 2: {}\n", .{solution_2});
}

fn MostCommon(comptime N: usize) type {
    return struct {
        const Self = @This();
        const Frequencies = [N]Map(u8, u32);

        frequencies: Frequencies,

        fn init(allocator: *mem.Allocator, lines: []const []const u8) !Self {
            var frequencies: Frequencies = undefined;
            for (frequencies) |*f| {
                f.* = Map(u8, u32).init(allocator);
            }
            var self = Self{ .frequencies = frequencies };
            try self.addLines(lines);

            return self;
        }

        fn getPassword(self: Self) [N]u8 {
            var password: [N]u8 = undefined;
            for (password) |*c, i| {
                c.* = self.getHighestFrequency(i);
            }

            return password;
        }

        fn getPasswordByLowestFrequency(self: Self) [N]u8 {
            var password: [N]u8 = undefined;
            for (password) |*c, i| {
                c.* = self.getLowestFrequency(i);
            }

            return password;
        }

        fn getHighestFrequency(self: Self, position: usize) u8 {
            var it = self.frequencies[position].iterator();
            var frequency: u32 = 0;
            var character: u8 = 0;
            while (it.next()) |kv| {
                if (kv.value > frequency) {
                    frequency = kv.value;
                    character = kv.key;
                }
            }

            return character;
        }

        fn getLowestFrequency(self: Self, position: usize) u8 {
            var it = self.frequencies[position].iterator();
            var frequency: ?u32 = null;
            var character: u8 = 0;
            while (it.next()) |kv| {
                if (frequency) |f| {
                    if (kv.value < f) {
                        frequency = kv.value;
                        character = kv.key;
                    }
                } else {
                    frequency = kv.value;
                    character = kv.key;
                }
            }

            return character;
        }

        fn addLines(self: *Self, lines: []const []const u8) !void {
            for (lines) |line| {
                try self.addLine(mem.trim(u8, line, " \r\n"));
            }
        }

        fn addLine(self: *Self, line: []const u8) !void {
            for (line) |c, i| {
                try self.addCharacter(i, c);
            }
        }

        fn addCharacter(self: *Self, position: usize, character: u8) !void {
            const res = try self.frequencies[position].getOrPut(character);
            if (res.found_existing) {
                res.entry.value += 1;
            } else {
                res.entry.value = 1;
            }
        }
    };
}

test "`MostCommon(6)` adds lines" {
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, test_input);
    var most_common = try MostCommon(6).init(std.heap.page_allocator, lines);
    const password = most_common.getPassword();
    testing.expectEqualSlices(u8, &password, "easter");
}
