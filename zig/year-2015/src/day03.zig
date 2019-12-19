const std = @import("std");
const mem = std.mem;
const HashMap = std.hash_map.AutoHashMap;
const utilities = @import("./utilities.zig");

const input = @embedFile("input-day03.txt");

const Direction = enum {
    North,
    South,
    West,
    East,
};

const Coordinates = struct {
    x: i32,
    y: i32,

    pub fn go(self: *Coordinates, direction: Direction) void {
        return switch (direction) {
            .North => self.y += 1,
            .South => self.y -= 1,
            .West => self.x -= 1,
            .East => self.x += 1,
        };
    }
};

fn inputToCoordinates(
    allocator: *mem.Allocator,
    position: *Coordinates,
    directions: []const u8,
) ![]Coordinates {
    var coordinates = try allocator.alloc(Coordinates, directions.len + 1);

    coordinates[0] = position.*;
    for (directions) |c, i| {
        switch (c) {
            '^' => position.go(.North),
            'v' => position.go(.South),
            '<' => position.go(.West),
            '>' => position.go(.East),
            else => unreachable,
        }
        coordinates[i + 1] = position.*;
    }

    return coordinates;
}

fn visitedHouses(
    coordinates: []Coordinates,
    coordinate_map: *HashMap(Coordinates, bool),
) !HashMap(Coordinates, bool) {
    for (coordinates) |c| {
        _ = try coordinate_map.put(c, true);
    }

    return coordinate_map.*;
}

fn visitedHousesWithRobot(
    santa: []Coordinates,
    robot: []Coordinates,
    coordinate_map: *HashMap(Coordinates, bool),
) !HashMap(Coordinates, bool) {
    for (santa) |c| {
        _ = try coordinate_map.put(c, true);
    }

    for (robot) |c| {
        _ = try coordinate_map.put(c, true);
    }

    return coordinate_map.*;
}

const test_input1 = "^v";
const test_input2 = "^>v<";
const test_input3 = "^v^v^v^v^v";

pub fn main() anyerror!void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = &arena_allocator.allocator;

    var coordinate_map = HashMap(Coordinates, bool).init(allocator);
    var start = Coordinates{ .x = 0, .y = 0 };
    var coordinates = try inputToCoordinates(allocator, &start, input);
    var visited_map = try visitedHouses(coordinates, &coordinate_map);

    var unzipped_memory = try utilities.unzipMemory(u8, allocator, input);
    var santa_start = Coordinates{ .x = 0, .y = 0 };
    var robot_start = Coordinates{ .x = 0, .y = 0 };
    var with_robot_coordinate_map = HashMap(Coordinates, bool).init(allocator);
    var santa = try inputToCoordinates(allocator, &santa_start, unzipped_memory.a);
    var robot = try inputToCoordinates(allocator, &robot_start, unzipped_memory.b);
    var visited_with_robot = try visitedHousesWithRobot(santa, robot, &with_robot_coordinate_map);

    std.debug.warn("Day 03:\n", .{});
    std.debug.warn("\tSolution 1: {}\n", .{visited_map.count()});
    std.debug.warn("\tSolution 2: {}\n", .{visited_with_robot.count()});
}
