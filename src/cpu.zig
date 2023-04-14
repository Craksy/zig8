const Memory = @import("memory.zig");
const std = @import("std");

const Instruction = struct {
    instruction: u16,

    pub fn format(self: Instruction, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("0x{X}", .{self.instruction});
    }

    pub fn get_nipple(self: *const Instruction, n: u4) !u4 {
        return @truncate(u4, self.instruction >> (n * 4) & 0xFF);
    }

    pub fn get_address(self: *const Instruction) !u12 {
        return @truncate(u12, self.instruction & 0xfff);
    }

    pub fn get_immediate(self: *const Instruction) !u8 {
        return @truncate(u8, self.instruction & 0xFF);
    }
};

pub const Chip8Error = error{DecoderError};

pub const Chip8 = struct {
    memory: Memory = Memory{},
    registers: [16]u8 = std.mem.zeroes([16]u8),
    pc: u12 = 0,
    i: u12 = 0,
    stack: [128]u12 = std.mem.zeroes([128]u12),
    sp: u7 = 0,

    pub fn dump_regs(self: *Chip8) !void {
        std.debug.print("Registers:\n", .{});
        for (self.registers) |reg, i| {
            std.debug.print("V{X}: {}\n", .{ i, reg });
        }
    }

    pub fn dump_mem(self: *Chip8) !void {
        try self.memory.dump("memory.dump");
    }

    fn push_stack(self: *Chip8, addr: u12) !void {
        self.sp += 1;
        self.stack[self.sp] = addr;
    }

    fn pop_stack(self: *Chip8) !u12 {
        var val = self.stack[self.sp];
        self.sp -= 1;
        return val;
    }

    pub fn fetch_instruction(self: *Chip8) !Instruction {
        const inst = Instruction{ .instruction = try self.memory.read_word(self.pc) };
        self.pc += 2;
        return inst;
    }

    pub fn decode_instruction(self: *Chip8, instruction: Instruction) !void {
        std.debug.print("decode instruction: {}\n", .{instruction});
        var inst = instruction.instruction;
        var n1 = try instruction.get_nipple(3);
        var x = try instruction.get_nipple(2);
        var y = try instruction.get_nipple(1);
        var n3 = try instruction.get_nipple(0);
        var addr = try instruction.get_address();
        var imm = try instruction.get_immediate();

        try switch (n1) {
            0x0 => {
                if (inst == 0x00E0) {
                    try self.cls();
                } else if (inst == 0x00EE) {
                    try self.ret();
                } else if (n1 == 0) {
                    try self.sys(addr);
                }
            },
            0x1 => self.jump(addr),
            0x2 => self.call(addr),
            0x3 => self.se_imm(x, imm),
            0x4 => self.sne(x, imm),
            0x5 => self.se_reg(x, y),
            0x6 => self.load_imm(x, imm),
            0x7 => self.add_imm(x, imm),
            0x8 => {
                try switch (n3) {
                    0x0 => self.load_reg(x, y),
                    0x1 => self.or_reg(x, y),
                    0x2 => self.and_reg(x, y),
                    0x3 => self.xor_reg(x, y),
                    0x4 => self.add_reg(x, y),
                    0x5 => self.sub_reg(x, y),
                    0x6 => self.shift_right(x),
                    0x7 => self.subn_reg(x, y),
                    0xE => self.shift_left(x),
                    else => return Chip8Error.DecoderError,
                };
            },
            0x9 => self.sne_reg(x, y),
            0xA => self.load_addr(addr),
            0xB => self.jump_rel(addr),
            0xF => {
                try switch (imm) {
                    0x1E => self.addi(x),
                    0x55 => self.reg_dump(x),
                    else => return Chip8Error.DecoderError,
                };
            },
            else => return Chip8Error.DecoderError,
        };
    }

    fn cls(self: *Chip8) !void {
        std.debug.print("{}", .{self.pc});
    }

    fn call(self: *Chip8, addr: u12) !void {
        std.debug.print("Call. pc: {}, addr: {}\n", .{ self.pc, addr });
    }

    fn ret(self: *Chip8) !void {
        self.pc = try self.pop_stack();
    }
    fn sys(self: *Chip8, addr: u12) !void {
        _ = try self.memory.read_byte(addr);
    }
    fn jump(self: *Chip8, addr: u12) !void {
        self.pc = addr;
    }
    fn se_imm(self: *Chip8, x: u4, imm: u8) !void {
        if (self.registers[x] == imm) {
            self.pc += 2;
        }
    }

    fn sne(self: *Chip8, x: u4, imm: u8) !void {
        if (self.registers[x] != imm) {
            self.pc += 2;
        }
    }
    fn se_reg(self: *Chip8, x: u4, y: u4) !void {
        if (self.registers[x] == self.registers[y]) {
            self.pc += 2;
        }
    }
    fn sne_reg(self: *Chip8, x: u4, y: u4) !void {
        if (self.registers[x] != self.registers[y]) {
            self.pc += 2;
        }
    }
    fn load_imm(self: *Chip8, x: u4, imm: u8) !void {
        self.registers[x] = imm;
    }

    fn add_imm(self: *Chip8, x: u4, imm: u8) !void {
        self.registers[x] += imm;
    }
    fn load_reg(self: *Chip8, x: u4, y: u4) !void {
        self.registers[x] = self.registers[y];
    }
    fn or_reg(self: *Chip8, x: u4, y: u4) !void {
        self.registers[x] |= self.registers[y];
    }
    fn and_reg(self: *Chip8, x: u4, y: u4) !void {
        self.registers[x] &= self.registers[y];
    }
    fn xor_reg(self: *Chip8, x: u4, y: u4) !void {
        self.registers[x] ^= self.registers[y];
    }
    fn add_reg(self: *Chip8, x: u4, y: u4) !void {
        var vx = self.registers[x];
        var vy = self.registers[y];
        self.registers[0xf] = if (vx + vy > 0xff) 1 else 0;
        self.registers[x] += self.registers[y];
    }
    fn sub_reg(self: *Chip8, x: u4, y: u4) !void {
        std.debug.print("trying to subtract {} ({X}) from {}({X})", .{ self.registers[y], y, self.registers[x], x });
        self.registers[0xf] = if (self.registers[y] > self.registers[x]) 0 else 1;
        self.registers[x] -= self.registers[y];
    }

    fn shift_right(self: *Chip8, x: u4) !void {
        self.registers[0xf] = self.registers[x] & 0b1;
        self.registers[x] >>= 1;
    }

    fn subn_reg(self: *Chip8, x: u4, y: u4) !void {
        self.registers[x] = self.registers[y] - self.registers[x];
    }

    fn shift_left(self: *Chip8, x: u4) !void {
        self.registers[0xf] = self.registers[x] >> 7;
        self.registers[x] <<= 1;
    }
    // fn sne_reg(self: *Chip8) !void {}
    fn load_addr(self: *Chip8, addr: u12) !void {
        self.i = addr;
    }
    fn jump_rel(self: *Chip8, addr: u12) !void {
        self.pc = addr + self.registers[0];
    }

    fn reg_dump(self: *Chip8, x: u4) !void {
        var i: usize = 0;
        while (i <= x) : (i += 1) {
            try self.memory.write_byte(self.i + @truncate(u12, i), self.registers[i]);
        }
    }

    fn addi(self: *Chip8, x: u4) !void {
        self.i += self.registers[x];
    }
};
