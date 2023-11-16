// `include "typedef.svh"

module pe_8x8 (
    input  wire              clk,
    input  wire              rstn,
    input  mult_t            ifm_in[8],
    input  mult_t            wgt_in[8],
    output reg signed [24:0] psum
);

    reg signed [15:0] product[8];
    reg signed [24:0] psum_l1[4];
    reg signed [24:0] psum_l2[2];

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            for (int i = 0; i < 8; ++i) begin
                product[i] <= 0;
            end
            psum <= 0;
        end else begin
            for (int i = 0; i < 8; ++i) begin
                product[i] <= ifm_in[i] * wgt_in[i];
            end

            for (int i = 0; i < 4; ++i) begin
                psum_l1[i] <= product[2*i] + product[2*i+1];
            end

            for (int i = 0; i < 2; ++i) begin
                psum_l2[i] <= psum_l1[2*i] + psum_l1[2*i+1];
            end

            psum <= psum_l2[0] + psum_l2[1];

        end
    end

endmodule

