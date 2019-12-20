const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const testing = std.testing;

const Md5 = std.crypto.Md5;

const input = "iwrupvqb";
const test_input = "abcdef";

pub fn main() anyerror!void {
    var digest_bytes = [_]u8{0} ** 16;
    var concat_buffer = [_]u8{0} ** 16;

    std.debug.warn("Day 04:\n", .{});

    var solution_1 = try findInitialZeroes(5, &digest_bytes, &concat_buffer);
    std.debug.warn("\tSolution 1: {}\n", .{solution_1});

    var solution_2 = try findInitialZeroes(6, &digest_bytes, &concat_buffer);
    std.debug.warn("\tSolution 2: {}\n", .{solution_2});
}

fn findInitialZeroes(comptime N: u8, digest_bytes: []u8, concat_buffer: []u8) !u32 {
    var n: u32 = 0;

    while (true) : (n += 1) {
        var concatted_string = try buildConcatString(input, n, concat_buffer);
        Md5.hash(concatted_string, digest_bytes);
        const initial = firstNibblesInHex(N, digest_bytes);

        if (mem.eql(u8, &initial, &([_]u8{0} ** N))) {
            break;
        }
    }

    return n;
}

fn buildConcatString(secret: []const u8, number: u32, buffer: []u8) ![]const u8 {
    return try fmt.bufPrint(buffer, "{}{}", .{ secret, number });
}

fn firstNibblesInHex(comptime N: u8, slice: []u8) [N]u8 {
    var nibbles: [N]u8 = undefined;
    var current_nibble: u8 = 0;

    while (current_nibble < N) : (current_nibble += 1) {
        const index = current_nibble / 2;
        if (current_nibble % 2 == 0) {
            nibbles[current_nibble] = (slice[index] & 0xf0) >> 4;
        } else {
            nibbles[current_nibble] = slice[index] & 0xf;
        }
    }

    return nibbles;
}

test "digest for test_input1 is correct" {
    const test_success_i: u32 = 609043;
    var digest_bytes: [16]u8 = undefined;
    var success_test_input = [_]u8{0} ** 32;
    var total_test_input = try fmt.bufPrint(
        &success_test_input,
        "{}{}",
        .{ test_input, test_success_i },
    );

    Md5.hash(total_test_input, &digest_bytes);

    var first_5 = firstNibblesInHex(5, &digest_bytes);
    testing.expectEqualSlices(u8, &first_5, &([_]u8{0} ** 5));
}
