`include "rtl/instructions.svh"

module ALU(
    input ALUInstruction i_inst,
    input wire[31:0] i_data0, i_data1,
    input wire i_c,
    output reg[31:0] o_result,
    output reg o_c,
    output wire o_o, o_z, o_n,

    output wire o_error_div_by_zero
);

    assign o_o = o_c & i_data0[31] & i_data1[31];
    assign o_z = o_result == 0;
    assign o_n = o_result[31];

    assign o_error_div_by_zero = ((i_inst == ALU_DIV) | (i_inst == ALU_MOD)) && (i_data1 == 0);

    always @(*) begin
        case (i_inst)
            ALU_ADD: {o_c, o_result} <= i_data0 + i_data1 + {31'b0, i_c};
            ALU_SUB: {o_c, o_result} <= i_data0 - i_data1 - {31'b0, i_c};
            ALU_MUL: {o_c, o_result} <= i_data0 * i_data1;
            ALU_DIV: {o_c, o_result} <= o_error_div_by_zero ? 0 : i_data0 / i_data1;
            ALU_MOD: {o_c, o_result} <= o_error_div_by_zero ? 0 : i_data0 % i_data1;
            ALU_SHL: {o_c, o_result} <= {i_data0, i_c} << i_data1;
            ALU_SHR: {o_c, o_result} <= {i_c, i_data0} >> i_data1;
            ALU_XOR: o_result <= i_data0 ^ i_data1;
            ALU_AND: o_result <= i_data0 & i_data1;
            ALU_OR: o_result <= i_data0 | i_data1;
            ALU_NOT: o_result <= ~i_data0;
            ALU_BSET: o_result <= i_data0 | (1 << i_data1);
            ALU_BRESET: o_result <= i_data0 & ~(1 << i_data1);
        endcase
    end

endmodule