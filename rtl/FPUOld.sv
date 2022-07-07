`include "rtl/instructions.svh"

typedef struct packed {
    logic sign;
    logic[10:0] exponent;
    logic[51:0] fraction;
} Float;

module FPUMul(
    input wire i_clk,
    input wire i_start,
    input wire[10:0] i_exp0, i_exp1,
    input wire[52:0] i_data0, i_data1,
    output reg o_wait, o_finish,
    output reg[10:0] o_exp,
    output reg[52:0] o_result
);

    reg[105:0] product;
    reg[105:0] shifted;
    reg[7:0] index;

    always @(posedge i_clk) begin
        if (o_wait) begin
            if (index == 53) begin
                o_finish <= 1;
                
            end
        end else if (i_start) begin
            o_wait <= 1;
            o_finish <= 0;
            index <= 0;
            shifted <= i_exp1;
            product <= 0;
        end
    end

endmodule

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
    // res - X
    // res1 - N 
    reg[105:0] res, res1, res2;
    wire[63:0] res_diff = res > res2 ? res - res2 : res2 - res;

    wire sign = flt_0.sign ^ flt_1.sign;
    reg sqrt_stage;

    reg flt_sign;
    Float flt_final;

    integer i;
    reg[7:0] sel;

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
            if (i_gen_flags) begin
                o_z = (flt_0.exponent == 0) && (flt_0.fraction == 0);
                o_n = flt_0.sign;
                o_c = (flt_0.exponent == 2047) && (flt_0.fraction == 0);
                o_o = (flt_0.exponent == 2047) && (flt_0.fraction != 0);
            end

            case (i_inst)
                FPU_ADD: begin
                    o_wait = 0;
                    res = sign ? res_sub : res_add;
                    flt_sign = sign;
                end
                FPU_SUB: begin
                    o_wait = 0;
                    res = sign ? res_add : res_sub;
                    flt_sign = ~(adj_0_greater ? flt_0.sign : flt_1.sign);
                end
                FPU_MUL: begin
                    o_wait = 0;
                    res = res_mul;
                    flt_sign = sign;
                end
                FPU_DIV: begin
                    o_wait = 0;
                    res = res_div;
                    flt_sign = sign;
                end
                FPU_SQRT: begin
                    case (sqrt_stage)
                        0: begin
                            o_wait = 1;
                            res = frac0 >> 1;
                            res1 = frac0;
                            res2 = frac0;
                            sqrt_stage = 1;
                        end
                        1: begin
                            if (res_diff <= SQRT_ERROR_AMOUNT) begin
                                o_wait = 0;
                                sqrt_stage = 0;
                            end else begin
                                res2 = res;
                                res = (res + ({res1, 51'b0} / res)) >> 1;
                            end
                        end
                    endcase
                    flt_sign = 0;
                end
                
            endcase
        end

        casez (res)
            106'b1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd53, res[104:53]};sel = 105; end
            106'b01zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd52, res[103:52]};sel = 104; end
            106'b001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd51, res[102:51]};sel = 103; end
            106'b0001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd50, res[101:50]};sel = 102; end
            106'b00001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd49, res[100:49]};sel = 101; end
            106'b000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd48, res[99:48]};sel = 100; end
            106'b0000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd47, res[98:47]};sel = 99; end
            106'b00000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd46, res[97:46]};sel = 98; end
            106'b000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd45, res[96:45]};sel = 97; end
            106'b0000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd44, res[95:44]};sel = 96; end
            106'b00000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd43, res[94:43]};sel = 95; end
            106'b000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd42, res[93:42]};sel = 94; end
            106'b0000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd41, res[92:41]};sel = 93; end
            106'b00000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd40, res[91:40]};sel = 92; end
            106'b000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd39, res[90:39]};sel = 91; end
            106'b0000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd38, res[89:38]};sel = 90; end
            106'b00000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd37, res[88:37]};sel = 89; end
            106'b000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd36, res[87:36]};sel = 88; end
            106'b0000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd35, res[86:35]};sel = 87; end
            106'b00000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd34, res[85:34]};sel = 86; end
            106'b000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd33, res[84:33]};sel = 85; end
            106'b0000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd32, res[83:32]};sel = 84; end
            106'b00000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd31, res[82:31]};sel = 83; end
            106'b000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd30, res[81:30]};sel = 82; end
            106'b0000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd29, res[80:29]};sel = 81; end
            106'b00000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd28, res[79:28]};sel = 80; end
            106'b000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd27, res[78:27]};sel = 79; end
            106'b0000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd26, res[77:26]};sel = 78; end
            106'b00000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd25, res[76:25]};sel = 77; end
            106'b000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd24, res[75:24]};sel = 76; end
            106'b0000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd23, res[74:23]};sel = 75; end
            106'b00000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd22, res[73:22]};sel = 74; end
            106'b000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd21, res[72:21]};sel = 73; end
            106'b0000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd20, res[71:20]};sel = 72; end
            106'b00000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd19, res[70:19]};sel = 71; end
            106'b000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd18, res[69:18]};sel = 70; end
            106'b0000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd17, res[68:17]};sel = 69; end
            106'b00000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd16, res[67:16]};sel = 68; end
            106'b000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd15, res[66:15]};sel = 67; end
            106'b0000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd14, res[65:14]};sel = 66; end
            106'b00000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd13, res[64:13]};sel = 65; end
            106'b000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd12, res[63:12]};sel = 64; end
            106'b0000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd11, res[62:11]};sel = 63; end
            106'b00000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd10, res[61:10]};sel = 62; end
            106'b000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd9, res[60:9]};sel = 61; end
            106'b0000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd8, res[59:8]};sel = 60; end
            106'b00000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd7, res[58:7]};sel = 59; end
            106'b000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd6, res[57:6]};sel = 58; end
            106'b0000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd5, res[56:5]};sel = 57; end
            106'b00000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd4, res[55:4]};sel = 56; end
            106'b000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd3, res[54:3]};sel = 55; end
            106'b0000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd2, res[53:2]};sel = 54; end
            106'b00000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp + 11'd1, res[52:1]};sel = 53; end
            106'b000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp, res[51:0]};sel = 52; end
            106'b0000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd1, {1'b0, res[51:0]}}; sel = 51; end
            106'b00000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd2, {2'b0, res[50:0]}}; sel = 50; end
            106'b000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd3, {3'b0, res[49:0]}}; sel = 49; end
            106'b0000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd4, {4'b0, res[48:0]}}; sel = 48; end
            106'b00000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd5, {5'b0, res[47:0]}}; sel = 47; end
            106'b000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd6, {6'b0, res[46:0]}}; sel = 46; end
            106'b0000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd7, {7'b0, res[45:0]}}; sel = 45; end
            106'b00000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd8, {8'b0, res[44:0]}}; sel = 44; end
            106'b000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd9, {9'b0, res[43:0]}}; sel = 43; end
            106'b0000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd10, {10'b0, res[42:0]}}; sel = 42; end
            106'b00000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd11, {11'b0, res[41:0]}}; sel = 41; end
            106'b000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd12, {12'b0, res[40:0]}}; sel = 40; end
            106'b0000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd13, {13'b0, res[39:0]}}; sel = 39; end
            106'b00000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd14, {14'b0, res[38:0]}}; sel = 38; end
            106'b000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd15, {15'b0, res[37:0]}}; sel = 37; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd16, {16'b0, res[36:0]}}; sel = 36; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd17, {17'b0, res[35:0]}}; sel = 35; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd18, {18'b0, res[34:0]}}; sel = 34; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd19, {19'b0, res[33:0]}}; sel = 33; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd20, {20'b0, res[32:0]}}; sel = 32; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd21, {21'b0, res[31:0]}}; sel = 31; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd22, {22'b0, res[30:0]}}; sel = 30; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd23, {23'b0, res[29:0]}}; sel = 29; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd24, {24'b0, res[28:0]}}; sel = 28; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd25, {25'b0, res[27:0]}}; sel = 27; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd26, {26'b0, res[26:0]}}; sel = 26; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd27, {27'b0, res[25:0]}}; sel = 25; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd28, {28'b0, res[24:0]}}; sel = 24; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd29, {29'b0, res[23:0]}}; sel = 23; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd30, {30'b0, res[22:0]}}; sel = 22; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd31, {31'b0, res[21:0]}}; sel = 21; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd32, {32'b0, res[20:0]}}; sel = 20; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd33, {33'b0, res[19:0]}}; sel = 19; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd34, {34'b0, res[18:0]}}; sel = 18; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd35, {35'b0, res[17:0]}}; sel = 17; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd36, {36'b0, res[16:0]}}; sel = 16; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd37, {37'b0, res[15:0]}}; sel = 15; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd38, {38'b0, res[14:0]}}; sel = 14; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd39, {39'b0, res[13:0]}}; sel = 13; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd40, {40'b0, res[12:0]}}; sel = 12; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd41, {41'b0, res[11:0]}}; sel = 11; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd42, {42'b0, res[10:0]}}; sel = 10; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd43, {43'b0, res[9:0]}}; sel = 9; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd44, {44'b0, res[8:0]}}; sel = 8; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd45, {45'b0, res[7:0]}}; sel = 7; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd46, {46'b0, res[6:0]}}; sel = 6; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzzz: begin flt_final = {flt_sign, biggest_exp - 11'd47, {47'b0, res[5:0]}}; sel = 5; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzzz: begin flt_final = {flt_sign, biggest_exp - 11'd48, {48'b0, res[4:0]}}; sel = 4; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zzz: begin flt_final = {flt_sign, biggest_exp - 11'd49, {49'b0, res[3:0]}}; sel = 3; end
            106'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zz: begin flt_final = {flt_sign, biggest_exp - 11'd50, {50'b0, res[2:0]}}; sel = 2; end
            106'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001z: begin flt_final = {flt_sign, biggest_exp - 11'd51, {51'b0, res[1:0]}}; sel = 1; end
            106'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001: begin flt_final = {flt_sign, biggest_exp - 11'd52, {52'b0, res[0]}}; sel = 0; end
            default: flt_final = 64'b0;
        endcase

        o_result = o_error_div_by_zero ? 0 : flt_final;
    end

endmodule