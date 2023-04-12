const std = @import("std");

const mem = @import("memory.zig");
const c8 = @import("cpu.zig");


const print = std.debug.print;



pub fn main() !void {
    var chip8 = c8.Chip8{};
    try chip8.memory.write_word(0, 0xffff);
    var inst = try chip8.fetch_instruction();
    try c8.decode_instruction(inst);
}


test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
