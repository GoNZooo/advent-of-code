const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const fmt = std.fmt;
const testing = std.testing;

const Md5 = std.crypto.hash.Md5;

const input = "uqwqemis";
const test_input = "abc";

pub fn main() anyerror!void {
    debug.warn("Day 05:\n", .{});
    const solution_1 = findPassword(6, input);
    debug.warn("\tSolution 1: {}\n", .{solution_1});
    const solution_2 = findPassword2(7, input);
    debug.warn("\tSolution 2: {}\n", .{solution_2});
}

const PositionData = struct {
    position: u8,
    character: u8,
};

fn findPassword2(comptime N: u8, secret: []const u8) ![8]u8 {
    var n: u32 = 0;
    var digest_bytes = [_]u8{0} ** 16;
    var concat_buffer = [_]u8{0} ** 16;
    var found_characters = [_]bool{false} ** 8;
    const all_true = &[_]bool{true} ** 8;
    var password = [_]u8{0} ** 8;

    while (!mem.eql(bool, &found_characters, all_true)) {
        const position_data = try findPositionData(
            N,
            &n,
            &digest_bytes,
            &concat_buffer,
            secret,
        );
        if (!found_characters[position_data.position]) {
            found_characters[position_data.position] = true;
            password[position_data.position] = position_data.character;
        }
    }

    return password;
}

fn findPositionData(
    comptime N: u8,
    n: *u32,
    digest_bytes: []u8,
    concat_buffer: []u8,
    secret: []const u8,
) !PositionData {
    var position: u8 = undefined;
    var character: u8 = undefined;
    while (true) : (n.* += 1) {
        const concatted_string = try buildConcatString(secret, n.*, concat_buffer);
        Md5.hash(concatted_string, digest_bytes[0..16], .{});
        const initial = firstNibbles(N, digest_bytes);
        const comparison_string = initial[0..(N - 2)];
        const zeroes = &([_]u8{0} ** (N - 2));
        const areEqual = mem.eql(u8, comparison_string, zeroes);

        if (areEqual) {
            position = initial[N - 2];
            character = initial[N - 1];
            if (position < 8) {
                n.* += 1;
                break;
            }
        }
    }

    return PositionData{
        .position = position,
        .character = try hexChar(character),
    };
}

fn findPassword(comptime N: u8, secret: []const u8) ![8]u8 {
    var n: u32 = 0;
    var digest_bytes = [_]u8{0} ** 16;
    var concat_buffer = [_]u8{0} ** 16;
    var found_characters: u32 = 0;
    var password = [_]u8{0} ** 8;

    while (found_characters < 8) : (found_characters += 1) {
        const password_character = try findPasswordCharacter(
            N,
            &n,
            &digest_bytes,
            &concat_buffer,
            secret,
        );
        password[found_characters] = password_character;
    }

    return password;
}

fn findPasswordCharacter(
    comptime N: u8,
    n: *u32,
    digest_bytes: []u8,
    concat_buffer: []u8,
    secret: []const u8,
) !u8 {
    var sixth_character: u8 = undefined;
    while (true) : (n.* += 1) {
        const concatted_string = try buildConcatString(secret, n.*, concat_buffer);
        Md5.hash(concatted_string, digest_bytes[0..16], .{});
        const initial = firstNibbles(N, digest_bytes);
        const comparison_string = initial[0..(N - 1)];
        const zeroes = &([_]u8{0} ** (N - 1));
        const areEqual = mem.eql(u8, comparison_string, zeroes);

        if (areEqual) {
            sixth_character = initial[N - 1];
            n.* += 1;
            break;
        }
    }

    return try hexChar(sixth_character);
}

fn hexChar(c: u8) !u8 {
    return switch (c) {
        0...9 => c + 48,
        0xa => 'a',
        0xb => 'b',
        0xc => 'c',
        0xd => 'd',
        0xe => 'e',
        0xf => 'f',
        else => error.NotHexaDecimal,
    };
}

fn buildConcatString(secret: []const u8, number: u32, buffer: []u8) ![]const u8 {
    return try fmt.bufPrint(buffer, "{}{}", .{ secret, number });
}

fn firstNibbles(comptime N: u8, slice: []u8) [N]u8 {
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

test "test input gives correct password" {
    const password = try findPassword(6, test_input);
    testing.expectEqualSlices(u8, &password, "18f47a30");
}

test "test input gives correct password for password2" {
    const password = try findPassword2(7, test_input);
    testing.expectEqualSlices(u8, &password, "05ace8e3");
}
