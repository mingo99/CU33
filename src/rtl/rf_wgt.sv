module rf_wgt (
    input               clk,
    input               rstn,
    input  signed [7:0] wgt_in,
    input               wgt_read,
    output signed [7:0] wgt_buf0,
    output signed [7:0] wgt_buf1,
    output signed [7:0] wgt_buf2
);

    reg signed [7:0] wgt_buf[3];

    always @(posedge clk or negedge rstn)
        if (~rstn) begin
            for (int i = 0; i < 3; i = i + 1) begin
                wgt_buf[i] <= 0;
            end
        end else begin
            if (wgt_read) begin
                wgt_buf[2] <= wgt_buf[1];
                wgt_buf[1] <= wgt_buf[0];
                wgt_buf[0] <= wgt_in;
            end else begin
                wgt_buf[2] <= wgt_buf[2];
                wgt_buf[1] <= wgt_buf[1];
                wgt_buf[0] <= wgt_buf[0];
            end
        end

    assign wgt_buf0 = wgt_buf[0];
    assign wgt_buf1 = wgt_buf[1];
    assign wgt_buf2 = wgt_buf[2];

endmodule

