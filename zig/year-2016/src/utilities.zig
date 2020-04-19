const std = @import("std");
const mem = std.mem;

const ArrayList = std.ArrayList;

pub fn splitIntoLines(allocator: *mem.Allocator, string: []const u8) ![]const []const u8 {
    var lines = ArrayList([]const u8).init(allocator);
    var newline_iterator = mem.split(string, "\n");

    while (newline_iterator.next()) |line| {
        var trimmed_line = mem.trim(u8, line, "\n\r");
        if (!mem.eql(u8, trimmed_line, "")) (try lines.append(line));
    }

    return lines.items;
}
