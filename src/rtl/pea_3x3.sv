// `include "typedef.svh"

module pea_3x3 #(
    parameter ROW       = 3,
    parameter COL       = 8,
    parameter WGT_WIDTH = 24,
    parameter IFM_WIDTH = 128,
    parameter OFM_WIDTH = 32,
    parameter RF_AWIDTH = 4
) (
    input wire                 clk,
    input wire                 rstn,
    input wire                 stride,
    input wire                 wgt_read,
    input wire                 ifm_read,
    input wire [      COL-1:0] pvalid,
    input wire                 ic_done,
    input wire                 oc_done,
    input wire [WGT_WIDTH-1:0] wgt_group,
    input wire [IFM_WIDTH-1:0] ifm_group,

    output wire  [COL-1:0] sum_valid,
    output sum_t           sum      [COL]
);

    wire [7:0] ifm_buf0[ROW+COL-1];
    wire [7:0] ifm_buf1[ROW+COL-1];
    wire [7:0] ifm_buf2[ROW+COL-1];

    wire [7:0] wgt_buf0[ROW];
    wire [7:0] wgt_buf1[ROW];
    wire [7:0] wgt_buf2[ROW];

    wire [OFM_WIDTH-1:0] pe_data[ROW*COL];


    wire [COL-1:0] result_valid;
    assign sum_valid = stride ? result_valid & {(COL >> 1) {2'b01}} : result_valid;

    genvar row, col, i, j;
    generate
        for (row = 0; row < ROW; row = row + 1) begin : g_pe_row
            for (col = 0; col < COL; col = col + 1) begin : g_pe_col
                wire [7:0] ifm_in[3];
                wire [7:0] wgt_in[3];
                assign ifm_in[0] = ifm_buf0[row+col];
                assign ifm_in[1] = ifm_buf1[row+col];
                assign ifm_in[2] = ifm_buf2[row+col];
                assign wgt_in[0] = wgt_buf0[row];
                assign wgt_in[1] = wgt_buf1[row];
                assign wgt_in[2] = wgt_buf2[row];
                pe_3x3 #(
                    .PSUM_WIDTH(OFM_WIDTH)
                ) u_pe_3x3 (
                    .clk   (clk),
                    .rstn  (rstn),
                    .ifm_in(ifm_in),
                    .wgt_in(wgt_in),
                    .psum  (pe_data[row*COL+col])
                );

            end
        end

        for (i = 0; i < ROW + COL - 1; i = i + 1) begin : g_ifm_buffer
            rf_ifm u_rf_ifm (
                .clk     (clk),
                .rstn    (rstn),
                .ifm_read(ifm_read),
                .ifm_in  (ifm_group[i*8+:8]),
                .ifm_buf0(ifm_buf0[i]),
                .ifm_buf1(ifm_buf1[i]),
                .ifm_buf2(ifm_buf2[i])
            );
        end

        for (j = 0; j < ROW; j = j + 1) begin : g_wgt_buffer
            rf_wgt u_rf_wgt (
                .clk     (clk),
                .rstn    (rstn),
                .wgt_read(wgt_read),
                .wgt_in  (wgt_group[j*8+:8]),
                .wgt_buf0(wgt_buf0[j]),
                .wgt_buf1(wgt_buf1[j]),
                .wgt_buf2(wgt_buf2[j])
            );
        end

        for (j = 0; j < COL; j = j + 1) begin : g_psum_buffer
            rf_psum #(
                .DWIDTH(OFM_WIDTH),
                .AWIDTH(RF_AWIDTH)
            ) u_rf_psum (
                .clk         (clk),
                .rstn        (rstn),
                .data_valid  (pvalid[j]),
                .ic_done     (ic_done),
                .oc_done     (oc_done),
                .pe0_data    (pe_data[j]),
                .pe1_data    (pe_data[j+COL]),
                .pe2_data    (pe_data[j+COL*2]),
                .result_valid(result_valid[j]),
                .result      (sum[j])
            );
        end
    endgenerate


endmodule

