module syncfifo #(
    parameter DWIDTH = 8,
    parameter AWIDTH = 4
) (  // verilog_format: off
    input  wire                 clk, rstn,
    input  wire                 wren, rden,
    input  wire [DWIDTH-1:0]    din,
    output wire [DWIDTH-1:0]    dout,
    output wire                 full,
    output wire                 empty
); // verilog_format: on

    parameter DEPTH = 1 << AWIDTH;

    reg [AWIDTH-1:0] wptr, rptr;
    wire [AWIDTH-1:0] wptr_nxt, rptr_nxt;

    reg  [AWIDTH:0] pptr;
    wire [AWIDTH:0] pptr_nxt;

    assign empty = pptr == 0;
    assign full = pptr == DEPTH;

    assign pptr_nxt = ~(wren^rden) ? pptr : (
                    wren&(~full) ? pptr + 1'b1 : (
                    rden&(~empty) ? pptr - 1'b1 : pptr));
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            pptr <= 0;
        end else begin
            pptr <= pptr_nxt;
        end
    end

    assign wptr_nxt = wren & (~full) ? wptr + 1'b1 : wptr;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            wptr <= 0;
        end else begin
            wptr <= wptr_nxt;
        end
    end

    assign rptr_nxt = rden & (!empty) ? rptr + 1'b1 : rptr;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            rptr <= 0;
        end else begin
            rptr <= rptr_nxt;
        end
    end

    fifomem #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) u_fifomem (
        .clk  (clk),
        .wen  (wren & (~full)),
        .waddr(wptr),
        .raddr(rptr),
        .wdata(din),
        .rdata(dout)
    );

endmodule
