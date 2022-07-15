`include "rtl/instructions.svh"
`include "vendors/FPU/double_adder/double_adder.v"
`include "vendors/FPU/double_multiplier/double_multiplier.v"
`include "vendors/FPU/double_divider/double_divider.v"
`include "vendors/FPU/double_to_long/double_to_long.v"
`include "vendors/FPU/long_to_double/long_to_double.v"

module FPU(
    input i_clk, i_rst,
    
    input wire i_start,
    input FPUInstruction i_inst,
    input wire[63:0] i_data0, i_data1,
    output reg[63:0] o_result,
    output reg o_wait, o_finished,

    output reg o_z, o_n, o_c, o_o
);
    wire[63:0] true_data1 = ((i_inst == FPU_SUB) || (i_inst == FPU_CMP)) ? {~i_data1[63], i_data1[62:0]} : i_data1;

    reg[63:0] adder_a, adder_b;
    reg adder_submit;
    reg adder_ack;
    wire adder_a_ack, adder_b_ack;
    wire[63:0] adder_result;
    wire adder_ready;
    double_adder fpu_adder(
        .clk(i_clk),
        .rst(i_rst),

        .input_a(adder_a),
        .input_b(adder_b),

        .input_a_stb(adder_submit),
        .input_b_stb(adder_submit),

        .input_a_ack(adder_a_ack),
        .input_b_ack(adder_b_ack),

        .output_z(adder_result),
        .output_z_stb(adder_ready),
        .output_z_ack(adder_ack)
    );

    reg[63:0] mult_a, mult_b;
    reg mult_submit;
    reg mult_ack;
    wire mult_a_ack, mult_b_ack;
    wire[63:0] mult_result;
    wire mult_ready;
    double_multiplier fpu_mult(
        .clk(i_clk),
        .rst(i_rst),

        .input_a(mult_a),
        .input_b(mult_b),

        .input_a_stb(mult_submit),
        .input_b_stb(mult_submit),

        .input_a_ack(mult_a_ack),
        .input_b_ack(mult_b_ack),

        .output_z(mult_result),
        .output_z_stb(mult_ready),
        .output_z_ack(mult_ack)
    );

    reg[63:0] div_a, div_b;
    reg div_submit;
    reg div_ack;
    wire div_a_ack, div_b_ack;
    wire[63:0] div_result;
    wire div_ready;
    double_divider fpu_div(
        .clk(i_clk),
        .rst(i_rst),

        .input_a(div_a),
        .input_b(div_b),

        .input_a_stb(div_submit),
        .input_b_stb(div_submit),

        .input_a_ack(div_a_ack),
        .input_b_ack(div_b_ack),

        .output_z(div_result),
        .output_z_stb(div_ready),
        .output_z_ack(div_ack)
    );

    reg dtl_submit;
    reg dtl_ack;
    wire dtl_a_ack;
    wire[63:0] dtl_result;
    wire dtl_ready;
    double_to_long fpu_dtl(
        .clk(i_clk),
        .rst(i_rst),

        .input_a(i_data0),
        .input_a_stb(dtl_submit),
        .input_a_ack(dtl_a_ack),

        .output_z(dtl_result),
        .output_z_stb(dtl_ready),
        .output_z_ack(dtl_ack)
    );

    reg ltd_submit;
    reg ltd_ack;
    wire ltd_a_ack;
    wire[63:0] ltd_result;
    wire ltd_ready;
    long_to_double fpu_ltd(
        .clk(i_clk),
        .rst(i_rst),

        .input_a(i_data0),
        .input_a_stb(ltd_submit),
        .input_a_ack(ltd_a_ack),

        .output_z(ltd_result),
        .output_z_stb(ltd_ready),
        .output_z_ack(ltd_ack)
    );

    reg[1:0] stage;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            adder_submit <= 0;
            mult_submit <= 0;
            div_submit <= 0;
            dtl_submit <= 0;
            ltd_submit <= 0;
            o_result <= 0;
            o_finished <= 0;
            o_z <= 0;
            o_n <= 0;
            o_c <= 0;
            o_o <= 0;

            stage <= 0;
        end else begin
            adder_submit <= 0;
            mult_submit <= 0;
            div_submit <= 0;
            dtl_submit <= 0;
            ltd_submit <= 0;

            adder_ack <= 0;
            mult_ack <= 0;
            div_ack <= 0;
            dtl_ack <= 0;
            ltd_ack <= 0;

            o_finished <= 0;

            case (stage)
                0: begin
                    if (o_wait || i_start) begin
                        case (i_inst)
                            FPU_ADD: begin
                                adder_a <= i_data0;
                                adder_b <= true_data1;
                                adder_submit <= 1;
                                o_wait <= 1;
                                if (adder_b_ack) begin
                                    stage <= 1;
                                end
                            end
                            FPU_SUB: begin
                                adder_a <= i_data0;
                                adder_b <= true_data1;
                                adder_submit <= 1;
                                o_wait <= 1;
                                if (adder_b_ack) begin
                                    stage <= 1;
                                end
                            end
                            FPU_MUL: begin
                                mult_a <= i_data0;
                                mult_b <= i_data1;
                                mult_submit <= 1;
                                o_wait <= 1;
                                if (mult_b_ack) begin
                                    stage <= 1;
                                end
                            end
                            FPU_DIV: begin
                                div_a <= i_data0;
                                div_b <= i_data1;
                                div_submit <= 1;
                                o_wait <= 1;
                                if (div_b_ack) begin
                                    stage <= 1;
                                end
                            end
                            FPU_FLOAT_TO_INT: begin
                                dtl_submit <= 1;
                                o_wait <= 1;
                                if (dtl_a_ack) begin
                                    stage <= 1;
                                end
                            end
                            FPU_INT_TO_FLOAT: begin
                                ltd_submit <= 1;
                                o_wait <= 1;
                                if (ltd_a_ack) begin
                                    stage <= 1;
                                end
                            end
                            FPU_CMP: begin
                                adder_a <= i_data0;
                                adder_b <= true_data1;
                                adder_submit <= 1;
                                o_wait <= 1;
                                if (adder_b_ack) begin
                                    stage <= 1;
                                end
                            end
                            FPU_FLAGS: begin
                                o_finished <= 1;
                                o_n = i_data0[63];
                                o_z = i_data0[62:0] == 0;
                                o_c = (i_data0[62:52] == 'h7ff) && (i_data0[50:0] == 0);
                                o_o = (i_data0[62:52] == 'h7ff) && (i_data0[50:0] != 0);
                            end
                        endcase
                    end
                end
                1: begin
                    case (i_inst)
                        FPU_ADD: begin
                            if (adder_ready) begin
                                o_wait <= 0;
                                o_finished <= 1;
                                o_result <= adder_result;
                                adder_ack <= 1;
                                stage <= 0;
                            end
                        end
                        FPU_SUB: begin
                            if (adder_ready) begin
                                o_wait <= 0;
                                o_finished <= 1;
                                o_result <= adder_result;
                                adder_ack <= 1;
                                stage <= 0;
                            end
                        end
                        FPU_MUL: begin
                            if (mult_ready) begin
                                o_wait <= 0;
                                o_finished <= 1;
                                o_result <= mult_result;
                                mult_ack <= 1;
                                stage <= 0;
                            end
                        end
                        FPU_DIV: begin
                            if (div_ready) begin
                                o_wait <= 0;
                                o_finished <= 1;
                                o_result <= div_result;
                                div_ack <= 1;
                                stage <= 0;
                            end
                        end
                        FPU_CMP: begin
                            if (adder_ready) begin
                                o_wait <= 0;
                                o_finished <= 1;
                                o_n <= adder_result[63];
                                o_z <= adder_result[62:0] == 0;
                                adder_ack <= 1;
                                stage <= 0;
                            end
                        end
                        FPU_INT_TO_FLOAT: begin
                            if (ltd_ready) begin
                                o_wait <= 0;
                                o_finished <= 1;
                                o_result <= ltd_result;
                                ltd_ack <= 1;
                                stage <= 0;
                            end
                        end
                        FPU_FLOAT_TO_INT: begin
                            if (dtl_ready) begin
                                o_wait <= 0;
                                o_finished <= 1;
                                o_result <= dtl_result;
                                dtl_ack <= 1;
                                stage <= 0;
                            end
                        end
                    endcase
                end
            endcase
        end
    end
    
endmodule