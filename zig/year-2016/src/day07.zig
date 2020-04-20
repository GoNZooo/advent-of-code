const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const debug = std.debug;

const utilities = @import("./utilities.zig");

const input = @embedFile("input-day07.txt");

const ArrayList = std.ArrayList;

const test_input =
    \\abba[mnop]qrst
    \\abcd[bddb]xyyx
    \\aaaa[qwer]tyui
    \\ioxxoj[asdfgh]zxcvbn
;

const test_input2 =
    \\aba[bab]xyz
    \\xyx[xyx]xyx
    \\aaa[kek]eke
    \\zazbz[bzb]cdb
;

const AbaStatus = struct {
    abas: []Aba,
    babs: []Bab,
};

const Aba = struct {
    aba: []const u8,
    position: usize,
};

const Bab = struct {
    bab: []const u8,
    position: usize,
};

pub fn main() anyerror!void {
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);
    debug.warn("Day 07:\n", .{});

    const solution_1 = supportingTls(lines);
    debug.warn("\tSolution 1: {}\n", .{solution_1});

    const solution_2 = try supportingSsl(std.heap.page_allocator, lines);
    debug.warn("\tSolution 2: {}\n", .{solution_2});
}

fn supportingTls(addresses: []const []const u8) u32 {
    var supporting: u32 = 0;

    for (addresses) |address| {
        if (supportsTls(address)) supporting += 1;
    }

    return supporting;
}

fn supportsTls(address: []const u8) bool {
    var start: usize = 0;
    var inside_brackets = false;
    var abba = false;
    while (start <= (address.len - 4)) : (start += 1) {
        const current_char = address[start];
        if (current_char == '[') inside_brackets = true;
        if (current_char == ']') inside_brackets = false;
        const slice = address[start..(start + 4)];
        if (isAbba(slice) and inside_brackets) return false;
        if (isAbba(slice)) abba = true;
    }

    return abba;
}

fn supportingSsl(allocator: *mem.Allocator, addresses: []const []const u8) !u32 {
    var supporting: u32 = 0;

    for (addresses) |address| {
        if (try supportsSsl(allocator, address)) supporting += 1;
    }

    return supporting;
}

fn supportsSsl(allocator: *mem.Allocator, address: []const u8) !bool {
    const abaStatus = try getAbaStatus(allocator, address);
    for (abaStatus.babs) |bab| {
        for (abaStatus.abas) |aba| {
            if (isBabToAba(aba, bab)) {
                return true;
            }
        }
    }

    return false;
}

fn getAbaStatus(allocator: *mem.Allocator, address: []const u8) !AbaStatus {
    var start: usize = 0;
    var inside_brackets = false;
    var abas = ArrayList(Aba).init(allocator);
    var babs = ArrayList(Bab).init(allocator);

    while (start <= (address.len - 3)) : (start += 1) {
        const current_char = address[start];
        if (current_char == '[') {
            inside_brackets = true;
            continue;
        }
        if (current_char == ']') {
            inside_brackets = false;
            continue;
        }
        const slice = address[start..(start + 3)];
        if (isAba(slice) and inside_brackets) {
            try babs.append(Bab{ .bab = slice, .position = start });
        }
        if (isAba(slice) and !inside_brackets) {
            try abas.append(Aba{ .aba = slice, .position = start });
        }
    }

    return AbaStatus{ .abas = abas.items, .babs = babs.items };
}

fn isAbba(slice: []const u8) bool {
    return slice[0] == slice[3] and slice[1] == slice[2] and slice[1] != slice[0];
}

fn isAba(slice: []const u8) bool {
    return slice[0] == slice[2] and slice[0] != slice[1];
}

fn isBabToAba(aba: Aba, bab: Bab) bool {
    return aba.aba[0] != bab.bab[0] and
        aba.aba[0] == bab.bab[1] and
        aba.aba[1] == bab.bab[0] and
        aba.aba[1] == bab.bab[2];
}

test "gets correct solution 1 result for test input" {
    const lines = try utilities.splitIntoLines(
        std.heap.page_allocator,
        test_input,
    );
    testing.expectEqual(lines.len, 4);
    testing.expect(supportsTls(lines[0]));
    testing.expect(!supportsTls(lines[1]));
    testing.expect(!supportsTls(lines[2]));
    testing.expect(supportsTls(lines[3]));
}

test "gets correct solution 2 result for test input" {
    const lines = try utilities.splitIntoLines(
        std.heap.page_allocator,
        test_input2,
    );
    testing.expectEqual(lines.len, 4);
    testing.expect(try supportsSsl(std.heap.page_allocator, lines[0]));
    testing.expect(!try supportsSsl(std.heap.page_allocator, lines[1]));
    testing.expect(try supportsSsl(std.heap.page_allocator, lines[2]));
    testing.expect(try supportsSsl(std.heap.page_allocator, lines[3]));
}
