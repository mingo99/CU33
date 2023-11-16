module pe_3x3 #(
    parameter int PSUM_WIDTH = 32
) (
    input  wire                        clk,
    input  wire                        rstn,
    input  mult_t                      ifm_in[3],
    input  mult_t                      wgt_in[3],
    output reg signed [PSUM_WIDTH-1:0] psum
);

    reg signed [15:0] product[3];
    reg signed [PSUM_WIDTH-1:0] ppsum[2];


    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            for (int i = 0; i < 3; ++i) begin
                product[i] <= 0;
            end
            psum <= 0;
        end else begin
            for (int i = 0; i < 3; ++i) begin
                product[i] <= ifm_in[i] * wgt_in[i];
            end

            ppsum[0] <= product[0] + product[1];
            ppsum[1] <= product[2];
            psum     <= ppsum[0] + ppsum[1];
        end
    end

endmodule

