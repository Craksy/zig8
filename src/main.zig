const std = @import("std");

const mem = @import("memory.zig");
const c8 = @import("cpu.zig");

const print = std.debug.print;

pub fn main() !void {
    var chip8 = c8.Chip8{};
    try chip8.memory.write_word(0, 0x6101); // LD V2, 0x0A
    try chip8.memory.write_word(2, 0x600A); // LD V3, 0x02
    try chip8.memory.write_word(4, 0xA100); // LD V4, V3
    try chip8.memory.write_word(6, 0xF055); // ADD V4, V2
    try chip8.memory.write_word(8, 0x8015); // ADD V4, V2
    try chip8.memory.write_word(10, 0xF11E); // ADD V4, V2
    try chip8.memory.write_word(12, 0x3000); // ADD V4, V2
    try chip8.memory.write_word(14, 0x1006); // ADD V4, V2
    for ([_]u32{0} ** 100) |_| {
        var inst = try chip8.fetch_instruction();
        try chip8.decode_instruction(inst);
    }
    try chip8.dump_regs();
    try chip8.dump_mem();
}
