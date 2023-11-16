///==------------------------------------------------------------------==///
/// Conv kernel: adder tree of psum module
///==------------------------------------------------------------------==///
/// Two stages pipelined adder tree
module psum_add #(
    parameter DWIDTH = 25
) (
    input  wire                     clk,
    input  wire                     rstn,
    input  wire signed [DWIDTH-1:0] pe0_data,
    input  wire signed [DWIDTH-1:0] pe1_data,
    input  wire signed [DWIDTH-1:0] pe2_data,
    input  wire signed [DWIDTH-1:0] psum_in,
    output reg signed  [DWIDTH-1:0] psum_out
);

    reg signed [DWIDTH-1:0] psum0;
    reg signed [DWIDTH-1:0] psum1;

    /// Adder tree
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum0 <= 0;
            psum1 <= 0;
            psum_out <= 0;
        end else begin
            psum0 <= pe0_data + pe1_data;
            psum1 <= pe2_data + psum_in;
            psum_out <= psum0 + psum1;
        end
    end
endmodule

