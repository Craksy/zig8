const mem = @import("memory.zig");
const std = @import ("std");


const Instruction = struct {
    instruction: u16,
    pub fn get_nipple(self: *Instruction, n:u2) !u4 {
        return @truncate(u4, self.instruction >> (n*4) & 0xFF);
    }

    pub fn get_address(self: *Instruction) !u12{
        return @truncate(u12, self.instruction & 0xfff);
    }

    pub fn get_immediate(self: *Instruction) !u8{
        return @truncate(u8, self.instruction & 0xFF);
    }
};

const Operation = enum {
    Clear,
    Jump,
    Call,
    Return,
    SE_IMM,
    SNE_IMM,
    LD_IMM,
    OR_REG,
    AND_REG,
};

pub const Chip8 = struct {
    memory: mem.Memory = mem.Memory{},
    registers: [16]u8 = std.mem.zeroes([16]u8),
    pc: u12 = 0,
    i: u16 = 0,
    stack: [128]u12 = std.mem.zeroes([128]u12),
    sp: u7,


    fn push_stack(self: *Chip8, addr: u12) !void {
        self.sp += 1;
        self.stack[self.sp] = addr;
    }

    fn pop_stack(self: *Chip8) !u12{
        var val = self.stack[self.sp];
        self.sp -= 1;
        return val;
    }

    pub fn fetch_instruction(self: *Chip8) !Instruction{
        var inst = Instruction{
            .instruction = try self.memory.read_word(self.pc)
        };
        self.pc += 2;
        return inst;
    }

    pub fn decode_instruction(self: *Chip8, instruction: Instruction) !void {
        var inst = instruction.instruction;
        var n1 = try instruction.get_nipple(0);
        var x = try instruction.get_nipple(1);
        var y = try instruction.get_nipple(2);
        var n3 = try instruction.get_nipple(3);
        var addr = try instruction.get_address();
        var imm = try instruction.get_immediate();


        switch (n1) {
            0x0 => {
                if (inst == 0x00E0){
                    try cls();
                }else if(inst == 0x00EE){
                    try ret();
                }else if(inst.get_nipple(0) == 0){
                    try sys(addr);
                }
            },
            0x1 => self.jump(addr),
            0x2 => self.call(addr),
            0x3 => self.se_imm(x,imm),
            0x4 => self.sne(x,imm),
            0x5 => self.se_reg(x,y),
            0x6 => self.load_imm(x,imm),
            0x7 => self.add_imm(x,imm),
            0x8 => {
                switch (n3) {
                    0x0 => self.load_reg(x,y),
                    0x1 => self.or_reg(x,y),
                    0x2 => self.and_reg(x,y),
                    0x3 => self.xor_reg(x,y),
                    0x4 => self.add_reg(x,y),
                    0x5 => self.sub_reg(x,y),
                    0x6 => self.shift_right(x),
                    0x7 => self.subn_reg(x,y),
                    0xE => self.shift_left(x),
                }
            },
            0x9 => self.sne_reg(x,y),
            0xA => self.load_addr(addr),
            0xB => self.jump_rel(addr),
        }
    }

    fn use_thing() !void{}


    fn cls(self: *Chip8) !void {
        self.use_thing();
    }
    fn ret(self: *Chip8) !void {
        self.pc = self.pop_stack();
    }
    fn sys(self: *Chip8, addr: u12) !void {
        _ = self.memory.read_byte(addr);
    }
    fn jump(self: *Chip8, addr: u12) !void {
        self.pc = addr;
    }
    fn se_imm(self: *Chip8, x: u4, imm: u8) !void {
        if(self.registers[x] == imm){
            self.pc += 2;
        }
    }

    fn sne(self: *Chip8, x: u4, imm: u8) !void {
        if(self.registers[x] != imm){
            self.pc += 2;
        }
    }
    fn se_reg(self: *Chip8, x: u4, y:u4) !void {
        if(self.registers[x] == self.registers[y]){
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
        self.registers[0xf] = if(vx+vy > 0xff) 1 else 0;
        self.registers[x] += self.registers[y];
    }
    fn sub_reg(self: *Chip8, x: u4, y: u4) !void {
        self.registers[0xf] = if(self.registers[y] > self.registers[x]) 0 else 1;
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
    // fn load_addr(self: *Chip8) !void {}
    // fn jump_rel(self: *Chip8) !void {}


};
