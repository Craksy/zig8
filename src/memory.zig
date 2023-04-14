const std = @import("std");
const mem = std.mem;

const MemoryError = error{YouNoob};
const Self = @This();

memory: [4096]u8 = mem.zeroes([4096]u8),

pub fn dump(self: *Self, path: []const u8) !void {
    var fp = try std.fs.cwd().createFile(path, std.fs.File.CreateFlags{});
    defer fp.close();
    _ = try fp.write(&self.memory);
    std.debug.print("Memory dumped to: {s}\n", .{path});
}

pub fn read_byte(self: *Self, address: u12) !u8 {
    return self.memory[address];
}

pub fn write_byte(self: *Self, address: u12, value: u8) !void {
    self.memory[address] = value;
}

pub fn read_word(self: *Self, address: u12) !u16 {
    var b1 = @as(u16, try self.read_byte(address));
    var b2 = @as(u16, try self.read_byte(address + 1));
    var word = (b1 << 8) | b2;
    return word;
}

pub fn write_word(self: *Self, address: u12, value: u16) !void {
    try self.write_byte(address, @truncate(u8, value >> 8));
    try self.write_byte(address + 1, @truncate(u8, value & 0xff));
}

const MyError = error{YouFuckedUp};
