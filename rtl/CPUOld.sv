`include "rtl/instructions.svh"
`include "rtl/ALU.sv"
`include "rtl/FPU.sv"
`include "rtl/regs.sv"

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
    inout wire[63:0] io_mem_data,
    
    output wire[63:0] o_page_table_base,
    output wire o_is_user,

    input wire i_error_not_present,
    input wire i_error_not_user
);

    wire[63:0] i_mem_data = o_mem_read ? io_mem_data : 'bz;
    reg[63:0] o_mem_data;
    assign io_mem_data = o_mem_write ? o_mem_data : 'bz;

    reg[4:0] regs_sel0, regs_sel1;
    reg regs_read0, regs_read1;
    reg regs_write0, regs_write1;
    wire[63:0] i_regs_data0, i_regs_data1;
    reg[63:0] o_regs_data0, o_regs_data1;
    wire[63:0] regs_data0, regs_data1

    Regs regs_module(
        .i_clk(i_clk), .i_rst(i_rst),
        .i_reg_sel0(regs_sel0), .i_reg_sel1(regs_sel1),
        .i_reg_read0(regs_read0), .i_reg_read1(regs_read1),
        .i_reg_write0(regs_write0), .i_reg_write1(regs_write1),
        .i_reg_data0(reg_data0), .i_reg_data0(regs_data1)
    );

    reg[31:0] stack;
    reg[31:0] ip;
    reg Flags flags;

    reg Instruction instruction;

    reg alu_start;
    reg[63:0] alu_data0, alu_data1;
    wire alu_wait, alu_finished;

    wire[63:0] alu_result;
    wire alu_c, alu_o, alu_z, alu_n;
    wire alu_error_div_by_zero;

    ALU alu_module(
        .i_clk(i_clk), .i_rst(i_rst),
        .i_start(alu_start),
        .i_instr(instruction.alu),
        .i_data0(alu_data0), .i_data1(alu_data1),
        .i_c(flags.c & instruction.alu_use_carry),
        .o_wait(alu_wait),
        .o_finished(alu_finished),
        .o_result(alu_result),
        .o_c(alu_c),
        .o_o(alu_o), .o_z(alu_z), .o_n(alu_n),
        .o_error_div_by_zero(alu_error_div_by_zero)
    );

    reg[63:0] fpu_data0, fpu_data1;
    reg fpu_start;
    wire[63:0] fpu_result;
    wire fpu_wait;
    wire fpu_finished;
    reg fpu_gen_flags;
    wire fpu_z, fpu_n, fpu_c, fpu_o;

    FPU fpu_module(
        .i_clk(i_clk), .i_rst(i_rst),
        .i_start(fpu_start),
        .i_inst(instruction.fpu),
        .i_data0(fpu_data0), .i_data1(fpu_data1);
        .o_result(fpu_result),
        .o_wait(fpu_wait), .o_finished(fpu_finished),
        .o_z(fpu_z), .o_n(fpu_n), .o_c(fpu_c), .o_o(fpu_o)
    );

    reg[2:0] stage;
    
    reg[63:0] control_regs[4:0];

    assign o_page_table_base = control_regs[0];

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

            alu_start <= 0;
            alu_data0 <= 0;
            alu_data1 <= 0;

            fpu_start <= 0;
            fpu_data0 <= 0;
            fpu_data1 <= 0;
            fpu_gen_flags <= 0;

            o_mem_address <= ip;
            o_mem_read <= 1;
        end else if (flags.running) begin
            alu_start <= 0;
            fpu_start <= 0;
            case (stage)
                0: begin // Instruction decode
                    if (i_mem_valid) begin
                        o_mem_read <= 0;
                        instruction <= i_mem_data;
                        stage <= 1;

                        regs_write0 <= 0;
                        regs_write1 <= 0;
                    end
                end
                // ALU and FPU
                1: begin
                    if (instruction.move_bits) begin
                        regs_sel0 <= R0;
                        o_regs_data0 <= {i_mem_data[62], i_mem_data[62:0]};
                        regs_write0 <= 1;
                        // GOTO Fetch
                    end else begin
                        if (instruction.alu != ALU_NOP) begin
                            regs_sel0 <= R0;
                            regs_read0 <= 1;
                        end
                        if (instruction.fpu != FPU_NOP) begin
                            regs_sel1 <= R1;
                            regs_read1 <= 1;
                        end
                        stage <= 2;
                    end
                end
                2: begin
                    if (instruction.alu != ALU_NOP) begin
                        alu_data0 <= o_reg_data0;
                        if (instruction.alu != ALU_NOT) begin
                            regs_sel0 <= instruction.arg_alu;
                        end else begin
                            regs_read0 <= 0;
                            alu_start <= 1;
                        end
                    end
                    if (instruction.fpu != FPU_NOP) begin
                        fpu_data0 <= i_reg_data1;
                        if ((instruction.fpu != FPU_FLAGS) || (instruction.fpu != FPU_FLOAT_TO_INT) || (instruction.fpu != FPU_INT_TO_FLOAT)) begin
                            regs_sel1 <= instruction.arg_fpu;
                        end else begin
                            regs_read1 <= 0;
                            fpu_start <= 1;
                        end
                    end
                    stage <= 3;
                end
                3: begin
                    if (instruction.alu != ALU_NOP) begin
                        regs_read0 <= 0;
                        if (alu_finished) begin
                            regs_sel0 <= R0;
                            o_regs_data0 <= alu_result;
                            regs_write0 <= 1;
                        end
                    end
                    if (instruction.fpu != FPU_NOP) begin
                        regs_read1 <= 0;
                        if (fpu_finished) begin
                            regs_sel1 <= R1;
                            o_regs_data1 <= alu_result;
                            regs_write1 <= 1;
                        end
                    end
                    if (((instruction.alu == ALU_NOP) || alu_finished) && ((instruction.fpu == FPU_NOP) || fpu_finished)) begin
                        stage <= 4;
                    end
                end
                // Data and Control
                4: begin
                    if (instruction.data != DATA_NOP) begin
                        case (instruction.data)
                            DATA_REG_TO_ACCU: begin
                                regs_sel0 <= instruction.arg_data;
                                regs_read0 <= 1;
                            end
                            DATA_ACCU_TO_REG: begin
                                regs_sel0 <= R0;
                                regs_read0 <= 1;
                            end
                            DATA_LOAD: begin
                                regs_sel0 <= R0;
                                regs_read0 <= 1;
                            end
                            DATA_STORE: begin
                                regs_sel0 <= R0;
                                regs_read0 <= 1;
                            end
                            DATA_SWAP: begin
                                regs_sel0 <= R0;
                                regs_read0 <= 1;
                            end
                        endcase
                    end
                    if (instruction.control != CONTROL_NOP) begin
                        case (instruction.control)
                            CONTROL_FLAG_TO_REG0: begin
                                regs_sel1 <= R0;
                                regs_write1 <= 1;
                                o_regs_data1 <= {54'b0, flags};
                            end
                            CONTROL_REG0_TO_FLAG: begin
                                regs_sel1 <= R0;
                                regs_read1 <= 1;
                            end
                            CONTROL_STACK_TO_REG0: begin
                                regs_sel1 <= R0;
                                regs_write1 <= 1;
                                o_regs_data1 <= {32'b0, stack};
                            end
                            CONTROL_REG0_TO_STACK: begin
                                regs_sel1 <= R0;
                                regs_read1 <= 1;
                            end
                            CONTROL_IP_TO_REG0: begin
                                regs_sel1 <= R0;
                                regs_write1 <= 1;
                                o_regs_data1 <= {32'b0, ip};
                            end
                            CONTROL_REG0_TO_IP: begin
                                regs_sel1 <= R0;
                                regs_read1 <= 1;
                            end
                            CONTROL_CPU_TO_REG1: begin
                                regs_sel1 <= R0;
                                regs_read1 <= 1;
                            end
                            CONTROL_REG1_TO_CPU: begin
                                regs_sel1 <= R0;
                                regs_read1 <= 1;
                            end
                        endcase
                    end
                    stage <= 5;
                end
            endcase
        end
    end
    
endmodule