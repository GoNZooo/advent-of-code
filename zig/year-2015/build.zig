const Builder = @import("std").build.Builder;

const files = [_]*const [5:0]u8{ "day01", "day02", "day03", "day04" };

fn addExecutables(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const run_step = b.step("run", "Run the app");

    inline for (files) |f| {
        const exe = b.addExecutable(f, "src/" ++ f ++ ".zig");
        exe.setBuildMode(mode);
        exe.install();
        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        run_step.dependOn(&run_cmd.step);
    }
}

pub fn build(b: *Builder) void {
    addExecutables(b);
}
