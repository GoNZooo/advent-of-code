const std = @import("std");
const mem = std.mem;

const ArrayList = std.ArrayList;

pub fn splitIntoLines(allocator: *mem.Allocator, string: []const u8) ![]const []const u8 {
    var lines = ArrayList([]const u8).init(allocator);
    var newline_iterator = mem.separate(string, "\n");

    while (newline_iterator.next()) |line| {
        var trimmed_line = mem.trim(u8, line, "\n\r");
        if (!mem.eql(u8, trimmed_line, "")) (try lines.append(line));
    }

    return lines.toSliceConst();
}

pub fn filterSlice(
    comptime T: type,
    allocator: *mem.Allocator,
    slice: []const T,
    predicate: fn (x: T) bool,
) ![]T {
    var filtered = try allocator.alloc(T, slice.len);
    var matching: usize = 0;
    for (slice) |x| {
        if (predicate(x)) {
            filtered[matching] = x;
            matching += 1;
        }
    }
    filtered = allocator.shrink(filtered, matching);

    return filtered;
}

pub fn containsSlice(comptime T: type, haystack: []const T, needle: []const T) bool {
    return mem.indexOf(T, haystack, needle) != null;
}

pub fn containsAnyOf(comptime T: type, haystack: []const T, needles: []const []const T) bool {
    for (needles) |needle| {
        if (containsSlice(T, haystack, needle)) return true;
    }

    return false;
}

pub fn removeMax(comptime length: usize, numbers: [length]u32) [length - 1]u32 {
    const max_number = mem.max(u32, &numbers);
    var new_array = [_]u32{0} ** (length - 1);
    var skipped = false;
    var i: usize = 0;

    for (numbers) |n| {
        if (n != max_number or skipped) {
            new_array[i] = n;
            i += 1;
        } else if (n == max_number) {
            skipped = true;
        }
    }

    return new_array;
}

pub fn all(comptime T: type, ts: []const T, p: fn (t: T) bool) bool {
    for (ts) |t| {
        if (!p(t)) return false;
    }

    return true;
}

pub fn UnzipResult(comptime T: type) type {
    return struct {
        a: []T,
        b: []T,
    };
}

pub fn unzipMemory(comptime T: type, allocator: *mem.Allocator, memory: []const T) !UnzipResult(T) {
    std.debug.assert(memory.len % 2 == 0);

    const a = try allocator.alloc(T, memory.len / 2);
    const b = try allocator.alloc(T, memory.len / 2);
    var a_index: usize = 0;
    var b_index: usize = 0;

    for (memory) |x, i| {
        if (i % 2 == 0) {
            a[a_index] = x;
            a_index += 1;
        } else {
            b[b_index] = x;
            b_index += 1;
        }
    }

    return UnzipResult(T){
        .a = a,
        .b = b,
    };
}
