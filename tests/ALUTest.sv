`include "rtl/instructions.svh"
`include "rtl/ALU.sv"

module ALUTest();

    reg clock, reset;
    reg start;
    reg ALUInstruction instr;
    reg[63:0] data0, data1;
    reg i_carry;
    wire[63:0] result;
    wire wait_sig;
    wire finish_sig;
    wire carry;
    wire negative;
    wire zero;
    wire overflow;
    wire error_div_by_zero;

    ALU alu_module(
        clock, reset,
        start,
        instr,
        data0, data1,
        i_carry,
        wait_sig,
        finish_sig,
        result,
        carry,
        overflow, zero, negative,
        error_div_by_zero
    );

    initial begin
        clock = 0;
        reset = 1;
        start = 0;
        instr = ALU_NOP;
        data0 = 0;
        data1 = 0;
        i_carry = 0;
    end

    initial begin
        $dumpfile("ALUTest.vcd");
        $dumpvars();
        #2
        reset = 0;

        instr = ALU_ADD;
        data0 = 6;
        data1 = 3;
        start = 1;

        #2
        start = 0;

        #8

        instr = ALU_SUB;
        start = 1;

        #2
        start = 0;

        #8

        instr = ALU_MUL;
        start = 1;

        #2
        start = 0;

        #8

        instr = ALU_AND;
        start = 1;

        #2
        start = 0;

        #8

        instr = ALU_OR;
        start = 1;

        #2
        start = 0;

        #8

        instr = ALU_XOR;
        start = 1;

        #2
        start = 0;

        #8

        instr = ALU_BSET;
        start = 1;

        #2
        start = 0;

        #8

        instr = ALU_BRESET;
        start = 1;

        #2
        start = 0;

        #8

        instr = ALU_DIV;
        data0 = 7;
        start = 1;

        #2
        start = 0;

        #32

        instr = ALU_MOD;
        start = 1;

        #2
        start = 0;

        #32

        #2
        $finish();
    end

    always begin
        #1 clock = !clock;
    end

endmodule