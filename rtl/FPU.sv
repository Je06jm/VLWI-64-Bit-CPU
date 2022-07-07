`include "rtl/instructions.svh"

typedef struct packed {
    logic sign;
    logic[10:0] exponent;
    logic[51:0] fraction;
} Float;

module FPU(
    input i_clk, i_rst,
    
    input FPUInstruction i_inst,
    input wire[63:0] i_data0, i_data1,
    output reg[63:0] o_result,
    output reg o_wait,

    input wire i_gen_flags,
    output reg o_z, o_n, o_c, o_o,

    output wire o_error_div_by_zero
);
    localparam SQRT_ERROR_AMOUNT = 'h100;

    wire Float flt_0 = i_data0;
    wire Float flt_1 = i_data1;

    wire[52:0] frac0 = {1'b1, flt_0.fraction};
    wire[52:0] frac1 = {1'b1, flt_1.fraction};

    wire exp_0_greater = flt_0.exponent >= flt_1.exponent;
    wire[10:0] biggest_exp = exp_0_greater ? flt_0.exponent : flt_1.exponent;
    wire[10:0] exp_diff = exp_0_greater ? flt_0.exponent - flt_1.exponent : flt_1.exponent - flt_0.exponent;

    wire[52:0] adj0 = exp_0_greater ? frac0 : frac0 >> exp_diff;
    wire[52:0] adj1 = exp_0_greater ? frac1 >> exp_diff : frac1;

    wire adj_0_greater = adj0 > adj1;

    wire[52:0] greater = adj_0_greater ? adj0 : adj1;
    wire[52:0] lesser = adj_0_greater ? adj1 : adj0;

    wire[53:0] res_add = greater + lesser;
    wire[53:0] res_sub = greater - lesser;

    wire[105:0] res_mul = (adj0 * adj1) >> 51;
    wire[105:0] res_div = (adj0 << 51) / {53'b0, adj1};
    // res - X
    // res1 - N 
    reg[105:0] res, res1, res2;
    wire[63:0] res_diff = res > res2 ? res - res2 : res2 - res;

    wire sign = flt_0.sign ^ flt_1.sign;
    reg sqrt_stage;

    reg flt_sign;
    Float flt_final;

    assign o_error_div_by_zero = (i_inst == FPU_DIV) && (flt_1.exponent == 0) && (flt_1.fraction == 0);

    always @(posedge i_clk or negedge i_rst) begin
        if (i_rst) begin
            o_result = 0;
            o_wait = 0;
            o_z = 0;
            o_n = 0;
            o_c = 0;
            o_o = 0;
            sqrt_stage = 0;
        end else begin
            case (i_inst)
                FPU_ADD: begin

                end
            endcase
        end
    end
endmodule