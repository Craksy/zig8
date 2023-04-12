const std = @import("std");
const mem = std.mem;

const MemoryError = error {
    YouNoob
};

pub const Memory = struct{
    memory: [4096]u8 = mem.zeroes([4096]u8),

    pub fn read_byte(self: *Memory, address: u12) !u8{
        return self.memory[address];
    }

    pub fn write_byte(self: *Memory, address: u12, value: u8) !void{
        self.memory[address] = value;
    }

    pub fn read_word(self: *Memory, address: u12) !u16{
        var b1 = @as(u16, try self.read_byte(address));
        var b2 = @as(u16, try self.read_byte(address+1));
        var word = (b1 << 8 ) | b2;
        return word;
    }

    pub fn write_word(self: *Memory, address: u12, value: u16) !void{
        try self.write_byte(address, @truncate(u8, value >> 8));
        try self.write_byte(address+1, @truncate(u8, value & 0xff));
    }
};

const MyError = error{YouFuckedUp};
