const std = @import("std");

pub fn main() void {
    var processor = Processor.new();
    var memory = Memory.new();

    // JMP #$0x600    ; Jump to subroutine
    memory.data[0xFFFC] = Instructions.Jmp.ABSOLUTE;
    memory.data[0xFFFD] = 0x00;
    memory.data[0xFFFE] = 0x06;

    // ADC #$nn
    memory.data[0x0600] = Instructions.Adc.IMMEDIATE;
    memory.data[0x0601] = 0x69;

    // ADC #$nn
    memory.data[0x0602] = Instructions.Adc.IMMEDIATE;
    memory.data[0x0603] = 0x1;

    // Set x and y registers
    memory.data[0x0604] = Instructions.TAX;
    memory.data[0x0605] = Instructions.TAY;

    // Break execution
    memory.data[0x0606] = Instructions.HALT;

    processor.execute(&memory);
}

const Memory = struct {
    const ZERO_PAGE_ADDR: u16 = 0x0020;
    const USER_SPACE_BEGIN_ADDR: u16 = 0x0600;

    data: [0x10000]u8,

    fn new() Memory {
        return Memory{
            .data = undefined,
        };
    }
};

const Processor = struct {

    // CPU flags
    s_carry: u1,
    s_zero: u1,
    s_interrupt: u1,
    s_decimal: u1,
    s_break: u1,
    s_overflow: u1,
    s_negative: u1,

    // Misc
    stack_pointer: u8,
    program_counter: u16,

    // Registers
    accumulator: u8,
    x_register: u8,
    y_register: u8,

    fn new() Processor {
        return Processor{
            .program_counter = 0xFFFC,
            .stack_pointer = 0xFF,
            .accumulator = 0x0,
            .x_register = 0x0,
            .y_register = 0x0,
            .s_carry = 0x0,
            .s_zero = 0x0,
            .s_interrupt = 0x0,
            .s_decimal = 0x0,
            .s_break = 0x0,
            .s_overflow = 0x0,
            .s_negative = 0x0,
        };
    }

    fn fetchByte(self: *Processor, addr: u16, memory: *Memory) u8 {
        @setRuntimeSafety(false);

        self.program_counter += 1;

        return memory.data[addr];
    }

    fn fetchWord(self: *Processor, addr: u16, memory: *Memory) u16 {
        self.program_counter += 2;

        // Little endian addressing
        return @as(u16, memory.data[addr]) | (@as(u16, memory.data[addr + 1]) << 8);
    }

    fn execute(self: *Processor, memory: *Memory) void {
        // This is a hack I don't want to use cycles yet
        outer: while (self.program_counter <= 0xFFFF) {
            const instruction = self.fetchByte(self.program_counter, memory);

            switch (instruction) {
                // Add with carry instructions
                Instructions.Adc.IMMEDIATE => {
                    const byte = self.fetchByte(self.program_counter, memory);
                    self.adc(byte);
                },
                Instructions.Jmp.ABSOLUTE => {
                    const word = self.fetchWord(self.program_counter, memory);
                    self.jmp(word);
                },
                Instructions.TAY => self.tay(),
                Instructions.TAX => self.tax(),
                Instructions.HALT => {
                    std.debug.print("Processor state: {any}\n", .{self});
                    std.process.exit(0);
                },
                // When an unknown instruction is found break
                // the loop.
                else => break :outer,
            }
        }
    }

    fn tay(self: *Processor) void {
        self.y_register = self.accumulator;
    }

    fn tax(self: *Processor) void {
        self.x_register = self.accumulator;
    }

    fn jmp(self: *Processor, operand: u16) void {
        self.program_counter = operand;
    }

    fn adc(self: *Processor, operand: u8) void {
        const result: u16 = self.accumulator + operand + self.s_carry;

        self.s_carry = if (result > 0xFF) 1 else 0;
        self.s_overflow = if ((~(self.accumulator ^ operand) & (self.accumulator ^ result) & 0x80) > 0) 1 else 0;
        self.s_negative = if (result & 0x80 > 0) 1 else 0;
        self.s_zero = if (result == 0) 1 else 0;

        self.accumulator = @truncate(result);
    }
};

const Instructions = struct {
    const Adc = struct {
        const IMMEDIATE: u8 = 0x69;
        // const ZERO_PAGE: u8 = 0x65;
        // const ZERO_PAGE_X: u8 = 0x75;
        // const ABSOLUTE: u8 = 0x6D;
        // const ABSOLUTE_X: u8 = 0x7D;
        // const ABSOLUTE_Y: u8 = 0x79;
        // const INDIRECT_X: u8 = 0x61;
        // const INDIRECT_Y: u8 = 0x71;
    };

    const Jmp = struct {
        const ABSOLUTE: u8 = 0x4C;
    };

    const TAX: u8 = 0xAA;
    const TAY: u8 = 0xA8;

    // FIXME: This is a helper so I don't have to
    // run an infinite loop.
    const HALT: u8 = 0x00;
};
