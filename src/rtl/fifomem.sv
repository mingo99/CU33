module fifomem #(
    parameter DWIDTH = 25,
    parameter AWIDTH = 4
) (  // verilog_format: off
    input  wire              clk, wen,
    input  wire [AWIDTH-1:0] waddr, raddr,
    input  wire [DWIDTH-1:0] wdata,
    output wire [DWIDTH-1:0] rdata
);  // verilog_format: on

`ifdef VENDORRAM
    // instantiation of a vendor's dual-port RAM
    vendor_ram mem (
        .dout    (rdata),
        .din     (wdata),
        .waddr   (waddr),
        .raddr   (raddr),
        .wclken  (wen),
        .wclken_n(!wen),
        .clk     (wclk)
    );
`else
    // RTL Verilog memory model
    localparam DEPTH = 1 << AWIDTH;
    reg [DWIDTH-1:0] mem[DEPTH];

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end

    assign rdata = mem[raddr];

`endif

endmodule

