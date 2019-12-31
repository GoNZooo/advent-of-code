const std = @import("std");
const testing = std.testing;

const utilities = @import("./utilities.zig");

const input = @embedFile("input-day06.txt");

const Coordinates = struct {
    x: usize,
    y: usize,
};

fn Lights(comptime L: usize) type {
    return [L][L]bool;
}

pub fn main() void {}

fn initialLights(comptime L: usize) Lights(L) {
    var lights: Lights(L) = undefined;

    for (lights) |*row| {
        row.* = [_]bool{false} ** L;
    }

    return lights;
}

fn turnOn(comptime L: usize, lights: *Lights(L), c1: Coordinates, c2: Coordinates) void {
    var current_y = c1.y;
    while (current_y <= c2.y) : (current_y += 1) {
        var current_x = c1.x;
        while (current_x <= c2.x) : (current_x += 1) {
            lights[current_y][current_x] = true;
        }
    }
}

fn displayLights(comptime L: usize, lights: [L][L]bool) void {
    for (lights) |row| {
        for (row) |l| {
            const status: u1 = if (l) 1 else 0;
            std.debug.warn("{}", .{status});
        }
        std.debug.warn("\n", .{});
    }
}

fn countLights(comptime L: usize, lights: [L][L]bool) usize {
    var count: usize = 0;

    for (lights) |row| {
        for (row) |l| {
            if (l) count += 1;
        }
    }

    return count;
}

test "input file is parsed correctly" {
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);
    for (lines) |line| {
        std.debug.warn("line: {}\n", .{line});
    }
}

test "`turnOn(0,0, 999,999)` returns correct result" {
    var lights = initialLights(1000);
    turnOn(1000, &lights, Coordinates{ .x = 0, .y = 0 }, Coordinates{ .x = 999, .y = 999 });
    const count = countLights(1000, lights);
    testing.expectEqual(count, 1000000);
}

test "`turnOn(0,0, 999,0)` returns correct result" {
    var lights = initialLights(1000);
    turnOn(1000, &lights, Coordinates{ .x = 0, .y = 0 }, Coordinates{ .x = 999, .y = 0 });
    const count = countLights(1000, lights);
    testing.expectEqual(count, 1000);
}

test "`turnOn(499,499, 500,500)` returns correct result" {
    var lights = initialLights(1000);
    turnOn(1000, &lights, Coordinates{ .x = 499, .y = 499 }, Coordinates{ .x = 500, .y = 500 });
    const count = countLights(1000, lights);
    testing.expectEqual(count, 4);
}
