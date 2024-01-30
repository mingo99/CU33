// Unit for activation and quantization
module aquant #(
    parameter DW_OFM = 32
) (
    input  wire                     clk,
    input  wire signed [      15:0] s,
    input  wire        [       3:0] r,
    input  wire        [       7:0] C,
    input  wire        [       7:0] T,
    input  wire signed [DW_OFM-1:0] din,
    output wire        [       7:0] dout
);

    reg signed [47:0] p1;
    reg signed [47:0] p2;
    reg signed [47:0] p;
    always @(posedge clk) begin
        p1 <= (s * din);
        p2 <= p1 >>> r;
        p  <= p2 + C;
    end

    wire [7:0] p_clamp;
    clamp #(
        .INPUT_DW (48),
        .OUTPUT_DW(8)
    ) u_clamp (
        .data_in (p),
        .data_out(p_clamp)
    );

    reg [7:0] dout_reg;
    always @(posedge clk) begin
        if (p_clamp >= T) dout_reg <= p_clamp;
        else dout_reg <= T;
    end

    assign dout = dout_reg;

endmodule
