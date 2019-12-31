const std = @import("std");
const testing = std.testing;
const mem = std.mem;

const utilities = @import("./utilities.zig");

const input = @embedFile("input-day06.txt");

const Coordinates = struct {
    x: usize,
    y: usize,
};

fn Lights(comptime L: usize, comptime T: type) type {
    return [L][L]T;
}

pub fn main() anyerror!void {
    std.debug.warn("Day 06:\n", .{});

    var bool_lights = initialLights(1000, bool, false);
    var lines1 = try utilities.splitIntoLines(std.heap.page_allocator, input);
    for (lines1) |line| {
        const command = try Command.fromLine(line);
        switch (command) {
            .TurnOn => |cs| turnOn(1000, &bool_lights, cs.c1, cs.c2),
            .TurnOff => |cs| turnOff(1000, &bool_lights, cs.c1, cs.c2),
            .Toggle => |cs| toggle(1000, &bool_lights, cs.c1, cs.c2),
        }
    }

    const solution_1_count = countLights(1000, bool_lights);
    std.debug.warn("\tSolution 1: {}\n", .{solution_1_count});

    var u32_lights = initialLights(1000, u32, 0);
    var lines2 = try utilities.splitIntoLines(std.heap.page_allocator, input);
    for (lines2) |line| {
        const command = try Command.fromLine(line);
        switch (command) {
            .TurnOn => |cs| raise(1000, &u32_lights, cs.c1, cs.c2),
            .TurnOff => |cs| dim(1000, &u32_lights, cs.c1, cs.c2),
            .Toggle => |cs| raiseTwo(1000, &u32_lights, cs.c1, cs.c2),
        }
    }
    const solution_2_count = countBrightness(1000, u32_lights);
    std.debug.warn("\tSolution 2: {}\n", .{solution_2_count});
}

fn initialLights(comptime L: usize, comptime T: type, comptime initial_value: T) Lights(L, T) {
    var lights: Lights(L, T) = undefined;

    for (lights) |*row| {
        row.* = [_]T{initial_value} ** L;
    }

    return lights;
}

fn turnOn(
    comptime L: usize,
    lights: *Lights(L, bool),
    c1: Coordinates,
    c2: Coordinates,
) void {
    var current_y = c1.y;
    while (current_y <= c2.y) : (current_y += 1) {
        var current_x = c1.x;
        while (current_x <= c2.x) : (current_x += 1) {
            lights[current_y][current_x] = true;
        }
    }
}

fn turnOff(
    comptime L: usize,
    lights: *Lights(L, bool),
    c1: Coordinates,
    c2: Coordinates,
) void {
    var current_y = c1.y;
    while (current_y <= c2.y) : (current_y += 1) {
        var current_x = c1.x;
        while (current_x <= c2.x) : (current_x += 1) {
            lights[current_y][current_x] = false;
        }
    }
}

fn toggle(
    comptime L: usize,
    lights: *Lights(L, bool),
    c1: Coordinates,
    c2: Coordinates,
) void {
    var current_y = c1.y;
    while (current_y <= c2.y) : (current_y += 1) {
        var current_x = c1.x;
        while (current_x <= c2.x) : (current_x += 1) {
            lights[current_y][current_x] = !lights[current_y][current_x];
        }
    }
}

fn raise(
    comptime L: usize,
    lights: *Lights(L, u32),
    c1: Coordinates,
    c2: Coordinates,
) void {
    var current_y = c1.y;
    while (current_y <= c2.y) : (current_y += 1) {
        var current_x = c1.x;
        while (current_x <= c2.x) : (current_x += 1) {
            lights[current_y][current_x] += 1;
        }
    }
}

fn dim(
    comptime L: usize,
    lights: *Lights(L, u32),
    c1: Coordinates,
    c2: Coordinates,
) void {
    var current_y = c1.y;
    while (current_y <= c2.y) : (current_y += 1) {
        var current_x = c1.x;
        while (current_x <= c2.x) : (current_x += 1) {
            if (lights[current_y][current_x] > 0) lights[current_y][current_x] -= 1;
        }
    }
}

fn raiseTwo(
    comptime L: usize,
    lights: *Lights(L, u32),
    c1: Coordinates,
    c2: Coordinates,
) void {
    var current_y = c1.y;
    while (current_y <= c2.y) : (current_y += 1) {
        var current_x = c1.x;
        while (current_x <= c2.x) : (current_x += 1) {
            lights[current_y][current_x] += 2;
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

fn countBrightness(comptime L: usize, lights: [L][L]u32) usize {
    var count: usize = 0;

    for (lights) |row| {
        for (row) |l| {
            count += l;
        }
    }

    return count;
}

const CoordinatePair = struct {
    c1: Coordinates,
    c2: Coordinates,
};

const Command = union(enum) {
    TurnOn: CoordinatePair,
    TurnOff: CoordinatePair,
    Toggle: CoordinatePair,

    pub fn fromLine(line: []const u8) !Command {
        var tokens = mem.tokenize(line, " ");
        const initial_token = tokens.next().?;
        if (mem.eql(u8, initial_token, "turn")) {
            const onOrOff = tokens.next().?;
            if (mem.eql(u8, onOrOff, "on")) {
                const c1 = tokens.next().?;
                _ = tokens.next().?;
                const c2 = tokens.next().?;

                return Command{
                    .TurnOn = CoordinatePair{
                        .c1 = try constructCoordinates(c1),
                        .c2 = try constructCoordinates(c2),
                    },
                };
            } else if (mem.eql(u8, onOrOff, "off")) {
                const c1 = tokens.next().?;
                _ = tokens.next().?;
                const c2 = tokens.next().?;

                return Command{
                    .TurnOff = CoordinatePair{
                        .c1 = try constructCoordinates(c1),
                        .c2 = try constructCoordinates(c2),
                    },
                };
            }
        } else if (mem.eql(u8, initial_token, "toggle")) {
            const c1 = tokens.next().?;
            _ = tokens.next().?;
            const c2 = tokens.next().?;

            return Command{
                .Toggle = CoordinatePair{
                    .c1 = try constructCoordinates(c1),
                    .c2 = try constructCoordinates(c2),
                },
            };
        }

        return error.InvalidInitialToken;
    }
};

fn constructCoordinates(string: []const u8) !Coordinates {
    var it = mem.separate(string, ",");
    const x = try std.fmt.parseInt(usize, it.next().?, 10);
    const y = try std.fmt.parseInt(usize, it.next().?, 10);

    return Coordinates{ .x = x, .y = y };
}

test "input file is parsed correctly" {
    const lines = try utilities.splitIntoLines(std.heap.page_allocator, input);
    for (lines) |line| {
        const command = try Command.fromLine(line);
    }
}

test "`turnOn(0,0, 999,999)` returns correct result" {
    var lights = initialLights(1000, bool, false);
    turnOn(1000, &lights, Coordinates{ .x = 0, .y = 0 }, Coordinates{ .x = 999, .y = 999 });
    const count = countLights(1000, lights);
    testing.expectEqual(count, 1000000);
}

test "`turnOn(0,0, 999,0)` returns correct result" {
    var lights = initialLights(1000, bool, false);
    turnOn(1000, &lights, Coordinates{ .x = 0, .y = 0 }, Coordinates{ .x = 999, .y = 0 });
    const count = countLights(1000, lights);
    testing.expectEqual(count, 1000);
}

test "`turnOn(499,499, 500,500)` returns correct result" {
    var lights = initialLights(1000, bool, false);
    turnOn(1000, &lights, Coordinates{ .x = 499, .y = 499 }, Coordinates{ .x = 500, .y = 500 });
    const count = countLights(1000, lights);
    testing.expectEqual(count, 4);
}
