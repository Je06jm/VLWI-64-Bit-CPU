`include "rtl/instructions.svh"

module ALU(
    input wire i_clk, i_rst,
    input wire i_start,
    input wire ALUInstruction i_inst,
    input wire[63:0] i_data0, i_data1,
    input wire i_c,
    output reg o_wait,
    output reg o_finished,
    output reg[63:0] o_result,
    output reg o_c,
    output wire o_o, o_z, o_n,

    output wire o_error_div_by_zero
);
    assign o_o = o_c & i_data0[63] & i_data1[63];
    assign o_z = o_result == 0;
    assign o_n = o_result[63];

    assign o_error_div_by_zero = ((i_inst == ALU_DIV) | (i_inst == ALU_MOD)) && (i_data1 == 0);

    reg stage;

    reg[63:0] Q, N;
    reg doing_div;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_wait <= 0;
            o_finished <= 0;
            o_result <= 0;
            o_c <= 0;

            stage <= 0;
        end else if (o_error_div_by_zero) begin
            o_result <= 0;
            o_wait <= 0;
            o_finished <= 1;
            stage <= 0;

        end else if (o_wait || i_start) begin
            o_finished <= 0;

            case (stage)
                0: begin
                    case (i_inst)
                        ALU_ADD: begin
                            {o_c, o_result} <= i_data0 + i_data1 + i_c;
                            o_finished <= 1;
                        end
                        ALU_SUB: begin
                            {o_c, o_result} <= i_data0 - i_data1 - i_c;
                            o_finished <= 1;
                        end
                        ALU_MUL: begin
                            o_result <= i_data0 * i_data1;
                            o_finished <= 1;
                        end
                        ALU_DIV: begin
                            o_wait <= 1;
                            Q <= 0;
                            N <= i_data0;
                            stage <= 1;
                            doing_div <= 1;
                        end
                        ALU_MOD: begin
                            o_wait <= 1;
                            Q <= 0;
                            N <= i_data0;
                            stage <= 1;
                            doing_div <= 0;
                        end
                        ALU_CMP: begin
                            {o_c, o_result} <= i_data0 - i_data1 - i_c;
                            o_finished <= 1;
                        end
                        ALU_SHL: begin
                            {o_c, o_result} <= {i_data0, i_c} << i_data1;
                            o_finished <= 1;
                        end
                        ALU_SHR: begin
                            {o_c, o_result} <= {i_c, i_data0} >> i_data1;
                            o_finished <= 1;
                        end
                        ALU_XOR: begin
                            o_result <= i_data0 ^ i_data1;
                            o_finished <= 1;
                        end
                        ALU_AND: begin
                            o_result <= i_data0 & i_data1;
                            o_finished <= 1;
                        end
                        ALU_OR: begin
                            o_result <= i_data0 | i_data1;
                            o_finished <= 1;
                        end
                        ALU_NOT: begin
                            o_result <= ~i_data0;
                            o_finished <= 1;
                        end
                        ALU_BSET: begin
                            o_result <= i_data0 | (1 << i_data1);
                            o_finished <= 1;
                        end
                        ALU_BRESET: begin
                            o_result <= i_data0 & ~(1 << i_data1);
                            o_finished <= 1;
                        end
                    endcase
                end
                1: begin
                    // Only Div and Mod gets here
                    if (N < i_data1) begin
                        o_wait <= 0;
                        o_finished <= 1;
                        stage <= 0;

                        if (doing_div) begin
                            o_result <= Q;
                        end else begin
                            o_result <= N;
                        end
                    end else begin
                        Q <= Q + 1;
                        N <= N - i_data1;
                    end
                end
            endcase
        end else begin
            o_finished <= 0;
        end
    end
endmodule