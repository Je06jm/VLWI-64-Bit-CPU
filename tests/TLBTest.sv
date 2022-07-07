`include "rtl/TLB.sv"

module TLBTest();

    reg clock, reset;
    reg enabled;

    reg[31:0] paging;
    reg is_user;
    reg[31:0] address;
    reg mem_read, mem_write;
    wire mem_valid;
    wire[31:0] i_mem_data = mem_read ? io_mem_data : 'bz;
    reg[31:0] o_mem_data;
    wire[31:0] io_mem_data = mem_write ? o_mem_data : 'bz;

    wire error_not_present;
    wire error_not_user;
    wire[47:0] tlb_mem_address;
    wire tlb_device_space;
    wire tlb_mem_read, tlb_mem_write;
    reg tlb_mem_valid;
    wire[31:0] tlb_i_mem_data = tlb_mem_write ? tlb_io_mem_data : 'bz;
    reg[31:0] tlb_o_mem_data;
    wire[31:0] tlb_io_mem_data = tlb_mem_read ? tlb_o_mem_data : 'bz;

    TLB tlb_module(
        clock, reset,
        enabled,
        paging,
        is_user,
        address,
        mem_read, mem_write,
        mem_valid,
        io_mem_data,
        error_not_present,
        error_not_user,
        tlb_mem_address,
        tlb_device_space,
        tlb_mem_read, tlb_mem_write,
        tlb_mem_valid,
        tlb_io_mem_data
    );

    initial begin
        clock = 0;
        reset = 1;
        enabled = 0;
        paging = 'h1000;
        is_user = 0;
        address = 0;
        mem_read = 0;
        mem_write = 0;
        o_mem_data = 0;
        tlb_mem_valid = 0;
    end

    initial begin
        $dumpfile("TLBTest.vcd");
        $dumpvars();
        #2

        reset = 0;
        address = 'h4000;
        mem_read = 1;

        #2
        tlb_o_mem_data = 'h1234;
        tlb_mem_valid = 1;

        #2
        tlb_mem_valid = 0;

        #2
        enabled = 1;
        address = 'habcd;

        #8
        tlb_o_mem_data = 'h80001;
        tlb_mem_valid = 1;

        #2
        tlb_mem_valid = 0;

        #8
        $finish();
    end

    always begin
        #1 clock = !clock;
    end

endmodule