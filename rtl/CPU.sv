`include "rtl/instructions.svh"

typedef struct packed {
    logic o;
    logic z;
    logic n;
    logic c;
    logic paging;
    logic user;
    logic interrupt;
    logic running;
} Flags;

module CPU(
    input wire i_clk, i_rst,
    input wire i_int,

    output reg[31:0] o_mem_address,
    output reg o_mem_read, o_mem_write,
    input wire i_mem_valid,
    inout wire[31:0] io_mem_data,
    
    output reg[31:0] o_page_table_base,
    output wire o_is_user,

    input wire i_error_not_present,
    input wire i_error_not_user
);

    wire[31:0] i_mem_data = o_mem_read ? io_mem_data : 'bz;
    reg[31:0] o_mem_data;
    assign io_mem_data = o_mem_write ? o_mem_data : 'bz;

    reg[4:0] regs_sel0, regs_sel1;
    reg regs_read0, regs_read1;
    reg regs_write0, regs_write1;
    wire[31:0] i_regs_data0, i_regs_data1;
    reg[31:0] o_regs_data0, o_regs_data1;
    wire[31:0] regs_data0, regs_data1;
    reg regs_mov_reg_to_reg0_0, regs_mov_reg_to_reg0_1;
    reg regs_mov_reg_from_reg0_0, regs_mov_reg_from_reg0_1;
    reg regs_mov_reg_to_reg1_0, regs_mov_reg_to_reg1_1;
    reg regs_mov_reg_from_reg1_0, regs_mov_reg_from_reg1_1;

    Regs regs_module(
        i_clk, i_rst,
        regs_sel0, regs_sel1,
        regs_read0, regs_read1,
        regs_write0, regs_write1,
        reg_data0, regs_data1,
        regs_mov_reg_to_reg0_0, regs_mov_reg_to_reg0_1,
        regs_mov_reg_from_reg0_0, regs_mov_reg_from_reg0_1,
        regs_mov_reg_to_reg1_0, regs_mov_reg_to_reg1_1,
        regs_mov_reg_from_reg1_0, regs_mov_reg_from_reg1_1
    );

    reg[31:0] stack;
    reg[31:0] ip;
    reg Flags flags;

    reg Instruction instruction;
    reg[31:0] alu_data0, alu_data1;

    wire[31:0] alu_result;
    wire alu_c, alu_o, alu_z, alu_n;
    wire alu_error_div_by_zero;

    ALU alu_module(
        instruction.alu,
        alu_data0, alu_data1,
        flags.c,
        alu_result,
        alu_c,
        alu_o, alu_z, alu_n
    );

    reg[31:0] fpu_data0, fpu_data1;
    wire[31:0] fpu_result;
    wire fpu_wait;
    reg fpu_gen_flags;
    wire fpu_z, fpu_n, fpu_c, fpu_o;
    wire fpu_error_div_by_zero;

    FPU fpu_module(
        i_clk, i_rst,
        instruction.fpu,
        fpu_data0, fpu_data1,
        fpu_result,
        fpu_wait,
        fpu_gen_flags,
        fpu_z, fpu_n, fpu_c, fpu_o,
        fpu_error_div_by_zero
    );

    reg[1:0] stage;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            stage <= 0;
            flags <= 8'b1;
            stack <= 0;
            ip <= 0;

            o_mem_write <= 0;
            o_page_table_base <= 0;
            o_mem_data <= 0;
            regs_sel0 <= 0;
            regs_sel1 <= 0;
            regs_read0 <= 0;
            regs_read1 <= 0;
            regs_write0 <= 0;
            regs_write1 <= 0;
            o_regs_data0 <= 0;
            o_regs_data1 <= 0;
            regs_mov_reg_to_reg0_0 <= 0;
            regs_mov_reg_to_reg0_1 <= 0;
            regs_mov_reg_from_reg0_0 <= 0;
            regs_mov_reg_from_reg0_1 <= 0;
            regs_mov_reg_to_reg1_0 <= 0;
            regs_mov_reg_to_reg1_1 <= 0;
            regs_mov_reg_from_reg1_0 <= 0;
            regs_mov_reg_from_reg1_1 <= 0;

            alu_data0 <= 0;
            alu_data1 <= 0;
            fpu_data0 <= 0;
            fpu_data1 <= 0;
            fpu_gen_flags <= 0;

            o_mem_address <= ip;
            o_mem_read <= 1;
        end else begin
            case (stage)
                0: begin // Instruction decode
                    if (i_mem_valid) begin
                        o_mem_read <= 0;
                        instruction <= i_mem_data;
                        stage <= 1;
                    end
                end
                1: begin
                    
                end
            endcase
        end
    end
    
endmodule