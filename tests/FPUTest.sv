`include "rtl/instructions.svh"
`include "rtl/FPU.sv"

module FPUTest();

    reg clock, reset;
    reg FPUInstruction instr;
    reg[63:0] data0, data1;
    wire[63:0] result;
    wire wait_sig;

    reg gen_flags;
    wire z, n, c, o;
    wire error_div_by_zero;

    FPU fpu_module(
        clock, reset,
        instr,
        data0, data1,
        result,
        wait_sig,
        gen_flags,
        z, n, c, o,
        error_div_by_zero
    );

    initial begin
        clock = 0;
        reset = 1;
        instr = FPU_NOP;
        data0 = 0;
        data1 = 0;

        gen_flags = 0;
    end

    initial begin
        $dumpfile("FPUTest.vcd");
        $dumpvars();
        #2
        reset = 0;

        instr = FPU_ADD;
        data0 = 'h3ff3333333333333; // 1.2
        data1 = 'h400b333333333333; // 3.4
        // 
        #2

        instr = FPU_SUB;

        #2

        instr = FPU_MUL;

        #2

        //instr = FPU_DIV;
        instr = FPU_SQRT;
        data0 = 'h4000000000000000; // 2.0

        #2

        //instr = FPU_SQRT;
        //data0 = 'h44000000;

        #16

        //instr = FPU_DIV;
        //data1 = 0;

        #2

        //instr = FPU_NOP;
        //data0 = 0;
        //gen_flags = 1;

        #2

        //data0 = 'hbf800000;

        #2

        //data0 = 'h7fc00000;

        #2

        //data0 = 'h7f800000;

        #2

        //data0 = 'h80000000;

        #2

        //data0 = 'hffc00000;

        #2

        //data0 = 'hff800000;

        #2
        $finish();
    end

    always begin
        #1 clock = !clock;
    end

endmodule