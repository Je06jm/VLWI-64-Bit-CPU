typedef enum logic[4:0] {
    R0,
    R1,
    R2,
    R3,
    R4,
    R5,
    R6,
    R7,
    R8,
    R9,
    R10,
    R11,
    R12,
    R13,
    R14,
    R15,
    R16,
    R17,
    R18,
    R19,
    R20,
    R21,
    R22,
    R23,
    R24,
    R25,
    R26,
    R27,
    R28,
    R29,
    R30,
    R31
} RegNum;

module Regs(
    input wire i_clk, i_rst,
    input wire RegNum i_reg_sel0, i_reg_sel1,
    input wire i_reg_read0, i_reg_read1,
    input wire i_reg_write0, i_reg_write1,
    inout wire[31:0] io_reg_data0, io_reg_data1
);
    reg[31:0] regs[31:0];

    wire[31:0] i_reg_data0 = i_reg_write0 ? io_reg_data0 : 'bz;
    wire[31:0] i_reg_data1 = i_reg_write1 ? io_reg_data1 : 'bz;
    
    wire[31:0] o_reg_data0 = regs[i_reg_sel0];
    wire[31:0] o_reg_data1 = regs[i_reg_sel1];

    assign io_reg_data0 = i_reg_read0 ? o_reg_data0 : 'bz;
    assign io_reg_data1 = i_reg_read1 ? o_reg_data1 : 'bz;

    integer i;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 0;
            end
        end else begin
            if (i_reg_write0) begin
                regs[i_reg_sel0] <= i_reg_data0;
            end
            if (i_reg_write1) begin
                regs[i_reg_sel1] <= i_reg_data1;
            end
        end
    end
endmodule