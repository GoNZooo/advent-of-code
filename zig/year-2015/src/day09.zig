const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const debug = std.debug;
const heap = std.heap;
const fmt = std.fmt;

const StringMap = std.hash_map.StringHashMap;

const utilities = @import("./utilities.zig");

const input = @embedFile("./input-day09.txt");

pub fn main() void {}

const Routes = struct {
    routes: StringMap(StringMap(u32)),
    _allocator: *mem.Allocator,

    pub fn init(allocator: *mem.Allocator) Routes {
        var routes = StringMap(StringMap(u32)).init(allocator);

        return Routes{ .routes = routes, ._allocator = allocator };
    }

    pub fn addRoute(self: *Routes, a: []const u8, b: []const u8, distance: u32) !void {
        var route_result = try self.routes.getOrPut(a);
        if (route_result.found_existing) {
            _ = try route_result.kv.value.getOrPutValue(b, distance);
        } else {
            var empty_routes = StringMap(u32).init(self._allocator);
            _ = try empty_routes.getOrPutValue(b, distance);
            route_result.kv.value = empty_routes;
        }

        var route_result2 = try self.routes.getOrPut(b);
        if (route_result2.found_existing) {
            _ = try route_result2.kv.value.getOrPutValue(a, distance);
        } else {
            var empty_routes = StringMap(u32).init(self._allocator);
            _ = try empty_routes.getOrPutValue(a, distance);
            route_result2.kv.value = empty_routes;
        }
    }
};

const DistanceSpec = struct {
    a: []const u8,
    b: []const u8,
    distance: u32,

    pub fn fromLine(line: []const u8) !DistanceSpec {
        var it = mem.separate(line, " ");
        const a = it.next().?;
        _ = it.next();
        const b = it.next().?;
        _ = it.next();
        const distance = try fmt.parseInt(u32, it.next().?, 10);

        return DistanceSpec{ .a = a, .b = b, .distance = distance };
    }
};

test "creates top-level route map from test input" {
    const lines = try utilities.splitIntoLines(heap.page_allocator, test_input);
    var route_map = Routes.init(heap.page_allocator);
    for (lines) |line| {
        const distance_spec = try DistanceSpec.fromLine(line);
        try route_map.addRoute(distance_spec.a, distance_spec.b, distance_spec.distance);
    }

    testing.expectEqual(route_map.routes.count(), 3);

    var it = route_map.routes.iterator();
    while (it.next()) |entry| {
        testing.expectEqual(entry.value.count(), 2);
    }
}

test "creates top-level route map" {
    const lines = try utilities.splitIntoLines(heap.page_allocator, input);
    var route_map = Routes.init(heap.page_allocator);
    for (lines) |line| {
        const distance_spec = try DistanceSpec.fromLine(line);
        try route_map.addRoute(distance_spec.a, distance_spec.b, distance_spec.distance);
    }

    // ensure there are 8 maps of starting points
    testing.expectEqual(route_map.routes.count(), 8);

    var it = route_map.routes.iterator();
    while (it.next()) |entry| {
        // ensure all those 7 starting points have 7 destinations
        testing.expectEqual(entry.value.count(), 7);
    }
}

const test_input =
    \\London to Dublin = 464
    \\London to Belfast = 518
    \\Dublin to Belfast = 141
;
