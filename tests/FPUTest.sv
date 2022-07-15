`include "rtl/instructions.svh"
`include "rtl/FPU.sv"

module FPUTest();

    reg clock, reset;
    reg start;
    reg FPUInstruction instr;
    reg[63:0] data0, data1;
    wire[63:0] result;
    wire wait_sig;
    wire finish_sig;

    wire z, n, c, o;

    FPU fpu_module(
        clock, reset,
        start,
        instr,
        data0, data1,
        result,
        wait_sig,
        finish_sig,
        z, n, c, o
    );

    initial begin
        clock = 0;
        reset = 1;
        start = 0;
        instr = FPU_NOP;
        data0 = 0;
        data1 = 0;
    end

    initial begin
        $dumpfile("FPUTest.vcd");
        $dumpvars();
        #2
        reset = 0;

        instr = FPU_ADD;
        data0 = 'h3ff3333333333333; // 1.2
        data1 = 'h400b333333333333; // 3.4
        start = 1;

        #2
        start = 0;
        // 
        #64

        instr = FPU_SUB;
        start = 1;

        #2
        start = 0;

        #128

        instr = FPU_MUL;
        start = 1;

        #2
        start = 0;

        #64

        instr = FPU_DIV;
        start = 1;

        #2
        start = 0;

        #1024

        instr = FPU_INT_TO_FLOAT;
        data0 = 12;
        start = 1;

        #2
        start = 0;

        #256

        instr = FPU_FLOAT_TO_INT;
        data0 = 'h4045000000000000;
        start = 1;

        #2
        start = 0;

        #256

        #2
        $finish();
    end

    always begin
        #1 clock = !clock;
    end

endmodule