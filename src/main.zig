const std = @import("std");

pub fn main() void {
    var processor = Processor.new();

    std.debug.print("Size: {}, Align: {}\n", .{ @sizeOf(Processor), @alignOf(Processor) });

    processor.adc(0);

    std.debug.print("Processor: {?}\n", .{processor});
}

const Memory = struct {
    data: [0x10000]u8,

    fn new() Memory {
        return Memory{
            .data = undefined,
        };
    }
};

const Processor = struct {
    // CPU flags
    sCarry: u1,
    sZero: u1,
    sInterrupt: u1,
    sDecimal: u1,
    sBreak: u1,
    sOverflow: u1,
    sNegative: u1,

    // Misc
    stackPointer: u8,
    programCounter: u16,

    // Registers
    accumulator: u8,
    xRegister: u8,
    yRegister: u8,

    fn new() Processor {
        return Processor{
            .programCounter = 0xFFFC,
            .stackPointer = 0xFF,
            .accumulator = 0x0,
            .xRegister = 0x0,
            .yRegister = 0x0,
            .sCarry = 0x0,
            .sZero = 0x0,
            .sInterrupt = 0x0,
            .sDecimal = 0x0,
            .sBreak = 0x0,
            .sOverflow = 0x0,
            .sNegative = 0x0,
        };
    }

    fn adc(self: *Processor, operand: u8) void {
        const result: u8 = self.accumulator + operand + self.sCarry;

        self.sCarry = if (result > 0xFF) 1 else 0;
        self.sOverflow = if ((~(self.accumulator ^ operand) & (self.accumulator ^ result) & 0x80) == 1) 1 else 0;
        self.sNegative = if (result & 0x80 == 1) 1 else 0;
        self.sZero = if (result == 0) 1 else 0;

        self.accumulator = result;
    }
};

const Instructions = struct {
    const ADC = struct {
        const IMMEDIATE: u8 = 0x69;
        const ZERO_PAGE: u8 = 0x65;
        const ZERO_PAGE_X: u8 = 0x75;
        const ABSOLUTE: u8 = 0x6D;
        const ABSOLUTE_X: u8 = 0x7D;
        const ABSOLUTE_Y: u8 = 0x79;
        const INDIRECT_X: u8 = 0x61;
        const INDIRECT_Y: u8 = 0x71;
    };
};
