module rf_ifm (
    input               clk,
    input               rstn,
    input  signed [7:0] ifm_in,
    input               ifm_read,
    output signed [7:0] ifm_buf0,
    output signed [7:0] ifm_buf1,
    output signed [7:0] ifm_buf2
);

    reg signed [7:0] ifm_buf[3];

    always @(posedge clk or negedge rstn)
        if (~rstn) begin
            for (int i = 0; i < 3; i = i + 1) begin
                ifm_buf[i] <= 0;
            end
        end else begin
            if (ifm_read) begin
                ifm_buf[2] <= ifm_buf[1];
                ifm_buf[1] <= ifm_buf[0];
                ifm_buf[0] <= ifm_in;
            end else begin
                ifm_buf[2] <= ifm_buf[2];
                ifm_buf[1] <= ifm_buf[1];
                ifm_buf[0] <= ifm_buf[0];
            end
        end

    assign ifm_buf0 = ifm_buf[0];
    assign ifm_buf1 = ifm_buf[1];
    assign ifm_buf2 = ifm_buf[2];

endmodule

