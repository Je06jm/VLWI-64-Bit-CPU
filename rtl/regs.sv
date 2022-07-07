module Regs(
    input wire i_clk, i_rst,
    input wire[4:0] i_reg_sel0, i_reg_sel1,
    input wire i_reg_read0, i_reg_read1,
    input wire i_reg_write0, i_reg_write1,
    inout wire[31:0] io_reg_data0, io_reg_data1
    input wire i_mov_reg_to_reg0_0, i_mov_reg_to_reg0_1,
    input wire i_mov_reg_from_reg0_0, i_mov_reg_from_reg0_1,
    input wire i_mov_reg_to_reg1_0, i_mov_reg_to_reg1_1,
    input wire i_mov_reg_from_reg1_0, i_mov_reg_from_reg1_1
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
            if (i_mov_reg_to_reg0_0) begin
                regs[0] <= regs[i_reg_sel0];
            end
            if (i_mov_reg_to_reg0_1) begin
                regs[0] <= regs[i_reg_sel1];
            end
            if (i_mov_reg_from_reg0_0) begin
                regs[i_reg_sel0] <= regs[0];
            end
            if (i_mov_reg_from_reg0_1) begin
                regs[i_reg_sel1] <= regs[0];
            end
            if (i_mov_reg_to_reg1_0) begin
                regs[1] <= regs[i_reg_sel0];
            end
            if (i_mov_reg_to_reg1_1) begin
                regs[1] <= regs[i_reg_sel1];
            end
            if (i_mov_reg_from_reg1_0) begin
                regs[i_reg_sel0] <= regs[1];
            end
            if (i_mov_reg_from_reg1_1) begin
                regs[i_reg_sel1] <= regs[1];
            end
        end
    end
endmodule