///==------------------------------------------------------------------==///
/// Conv kernel: top level module
///==------------------------------------------------------------------==///
module conv2d_3x3 #(
    parameter COL           = 8,
    parameter WGT_WIDTH     = 24,
    parameter IFM_WIDTH     = 80,
    parameter OFM_WIDTH     = 32,
    parameter RF_AWIDTH     = 4,
    parameter TILE_LEN      = 16,
    parameter CHN_WIDTH     = 4,
    parameter CHN_OFT_WIDTH = 6,
    parameter FMS_WIDTH     = 8,
    parameter PC_ROW_WIDTH  = 3
) (
    input wire                 clk,
    input wire                 rstn,
    input wire [CHN_WIDTH-1:0] cfg_ci,
    input wire [CHN_WIDTH-1:0] cfg_co,
    input wire                 cfg_stride,
    input wire                 cfg_group,
    input wire [FMS_WIDTH-1:0] cfg_ifm_size,
    input wire                 start_conv,
    input wire [IFM_WIDTH-1:0] ifm_group,
    input wire [WGT_WIDTH-1:0] wgt_group,

    output wire                 ifm_read,
    output wire                 wgt_read,
    output wire                 conv_done,
    output wire       [COL-1:0] sum_valid,
    output wire sum_t           sum      [COL]
);

    // Stage configuration parameters
    reg [5:0] chi_reg, cho_reg;
    reg stride_reg, group_reg;
    reg [FMS_WIDTH-1:0] ifm_size_reg;

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            chi_reg      <= 'b0;
            cho_reg      <= 'b0;
            stride_reg   <= 'b0;
            group_reg    <= 'b0;
            ifm_size_reg <= 'b0;
        end else if (start_conv) begin
            chi_reg      <= cfg_ci;
            cho_reg      <= cfg_co;
            stride_reg   <= cfg_stride;
            group_reg    <= cfg_group;
            ifm_size_reg <= cfg_ifm_size;
        end
    end

    wire [5:0] chi, cho;
    wire stride, group;
    wire [FMS_WIDTH-1:0] ifm_size;

    assign chi      = start_conv ? cfg_ci : chi_reg;
    assign cho      = start_conv ? cfg_co : cho_reg;
    assign stride   = start_conv ? cfg_stride : stride_reg;
    assign group    = start_conv ? cfg_group : group_reg;
    assign ifm_size = start_conv ? cfg_ifm_size : ifm_size_reg;

    ///==-------------------------------------------------------------------------------------==

    // wire pvalid, ic_done, oc_done;
    wire ic_done, oc_done;
    wire [COL-1:0] pvalid;

    pea_ctrl #(
        .COL          (COL),
        .TILE_LEN     (TILE_LEN),
        .CHN_WIDTH    (CHN_WIDTH),
        .CHN_OFT_WIDTH(CHN_OFT_WIDTH),
        .FMS_WIDTH    (FMS_WIDTH),
        .PC_COL_WIDTH (RF_AWIDTH),
        .PC_ROW_WIDTH (PC_ROW_WIDTH)
    ) u_pea_ctrl (
        .clk       (clk),
        .rstn      (rstn),
        .chi       (chi),
        .cho       (cho),
        .stride    (stride),
        .group     (group),
        .ifm_size  (ifm_size),
        .start_conv(start_conv),
        .ifm_read  (ifm_read),
        .wgt_read  (wgt_read),
        .pvalid    (pvalid),
        .ic_done   (ic_done),
        .oc_done   (oc_done),
        .conv_done (conv_done)
    );

    pea_3x3 #(
        .ROW      (3),
        .COL      (COL),
        .WGT_WIDTH(WGT_WIDTH),
        .IFM_WIDTH(IFM_WIDTH),
        .OFM_WIDTH(OFM_WIDTH),
        .RF_AWIDTH(RF_AWIDTH)
    ) u_pea_3x3 (
        .clk      (clk),
        .rstn     (rstn),
        .stride   (stride),
        .wgt_read (wgt_read),
        .ifm_read (ifm_read),
        .pvalid   (pvalid),
        .ic_done  (ic_done),
        .oc_done  (oc_done),
        .wgt_group(wgt_group),
        .ifm_group(ifm_group),
        .sum_valid(sum_valid),
        .sum      (sum)
    );

endmodule

