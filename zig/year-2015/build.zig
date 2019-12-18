const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe_01 = b.addExecutable("day01", "src/day01.zig");
    const exe_02 = b.addExecutable("day02", "src/day02.zig");
    exe_01.setBuildMode(mode);
    exe_01.install();
    exe_02.setBuildMode(mode);
    exe_02.install();

    const run_01_cmd = exe_01.run();
    const run_02_cmd = exe_02.run();
    run_01_cmd.step.dependOn(b.getInstallStep());
    run_02_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_01_cmd.step);
    run_step.dependOn(&run_02_cmd.step);
}
