module pea_ctrl #(
    parameter TILE_LEN      = 16,
    parameter CHN_WIDTH     = 4,
    parameter CHN_OFT_WIDTH = 6,
    parameter FMS_WIDTH     = 8,
    parameter PC_COL_WIDTH  = 4,   // Pixel col/row counter width
    parameter PC_ROW_WIDTH  = 3
) (
    input  wire                 clk,
    input  wire                 rstn,
    input  wire [CHN_WIDTH-1:0] chi,
    input  wire [CHN_WIDTH-1:0] cho,
    input  wire                 stride,
    input  wire [FMS_WIDTH-1:0] ifm_size,    // With padding
    input  wire                 start_conv,
    output wire                 ifm_read,
    output wire                 wgt_read,
    output wire                 pvalid,
    output wire                 ic_done,
    output wire                 oc_done,
    output wire                 conv_done
);

    // Pixel counter width when stride equal 2
    localparam PC_ROW_WIDTH_S2 = PC_ROW_WIDTH - 1;
    localparam PC_COL_WIDTH_S2 = PC_COL_WIDTH - 1;

    // Tile Col/Row counter width
    localparam TC_COL_WIDTH = FMS_WIDTH - PC_COL_WIDTH_S2;
    localparam TC_ROW_WIDTH = FMS_WIDTH - PC_ROW_WIDTH_S2;
    localparam CH_CNT_WIDTH = CHN_WIDTH + CHN_OFT_WIDTH;

    // Output feature map
    wire [FMS_WIDTH-1:0] ofm_size;
    assign ofm_size = stride ? ((ifm_size - 3) >> 1) + 1'b1 : ifm_size - 2;

    // Channel number decode
    wire [CH_CNT_WIDTH-1:0] ic_num, oc_num;
    assign ic_num = (chi << CHN_OFT_WIDTH) - 1'b1;
    assign oc_num = (cho << CHN_OFT_WIDTH) - 1'b1;

    // The last tile length in a row/col
    wire [PC_ROW_WIDTH-1:0] tile_row_offset_s1 = ofm_size[PC_ROW_WIDTH-1:0];
    wire [PC_COL_WIDTH-1:0] tile_col_offset_s1 = ofm_size[PC_COL_WIDTH-1:0];
    wire [PC_ROW_WIDTH_S2-1:0] tile_row_offset_s2 = ofm_size[PC_ROW_WIDTH_S2-1:0];
    wire [PC_COL_WIDTH_S2-1:0] tile_col_offset_s2 = ofm_size[PC_COL_WIDTH_S2-1:0];
    wire [PC_COL_WIDTH-1:0] tile_col_offset = stride ? (tile_col_offset_s2 << 1) : tile_col_offset_s1;
    wire [PC_ROW_WIDTH-1:0] tile_row_offset = stride ? (tile_row_offset_s2 << 1) : tile_row_offset_s1;

    wire [TC_ROW_WIDTH-1:0] tc_row_max_s1 = |tile_row_offset_s1 ? ofm_size[FMS_WIDTH-1:PC_ROW_WIDTH] : ofm_size[FMS_WIDTH-1:PC_ROW_WIDTH]-1;
    wire [TC_COL_WIDTH-1:0] tc_col_max_s1 = |tile_col_offset_s1 ? ofm_size[FMS_WIDTH-1:PC_COL_WIDTH] : ofm_size[FMS_WIDTH-1:PC_COL_WIDTH]-1;
    wire [TC_ROW_WIDTH-1:0] tc_row_max_s2 = |tile_row_offset_s2 ? ofm_size[FMS_WIDTH-1:PC_ROW_WIDTH_S2] : ofm_size[FMS_WIDTH-1:PC_ROW_WIDTH_S2]-1;
    wire [TC_COL_WIDTH-1:0] tc_col_max_s2 = |tile_col_offset_s2 ? ofm_size[FMS_WIDTH-1:PC_COL_WIDTH_S2] : ofm_size[FMS_WIDTH-1:PC_COL_WIDTH_S2]-1;
    wire [TC_ROW_WIDTH-1:0] tc_row_max = stride ? tc_row_max_s2 : tc_row_max_s1;
    wire [TC_COL_WIDTH-1:0] tc_col_max = stride ? tc_col_max_s2 : tc_col_max_s1;

    reg [TC_ROW_WIDTH-1:0] tc_row;
    reg [TC_COL_WIDTH-1:0] tc_col;

    wire tile_row_last, tile_col_last;
    assign tile_row_last = tc_row == tc_row_max;
    assign tile_col_last = tc_col == tc_col_max;

    wire tile_done, tile_ver_done;

    wire [TC_ROW_WIDTH-1:0] tc_row_nxt = conv_done ? 'b0 : tc_row + tile_ver_done;
    wire [TC_COL_WIDTH-1:0] tc_col_nxt = tile_ver_done ? 'b0 : tc_col + tile_done;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tc_row <= 'b0;
            tc_col <= 'b0;
        end else begin
            tc_row <= tc_row_nxt;
            tc_col <= tc_col_nxt;
        end
    end

    wire [7:0] valid_mask;
    assign valid_mask = tile_row_last & (|tile_row_offset) ? (8'hff >> (8 - tile_row_offset)) : 8'hff;

    reg [PC_COL_WIDTH-1:0] pc_col;
    wire [PC_COL_WIDTH-1:0] pc_col_max, pc_col_nxt;

    wire cnt_valid;
    assign pc_col_max = tile_col_last & (|tile_col_offset) ? tile_col_offset - 1 : TILE_LEN - 1;
    assign pc_col_nxt = ic_done ? 'b0 : pc_col + cnt_valid;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc_col <= 'b0;
        end else begin
            pc_col <= pc_col_nxt;
        end
    end

    wire ic_last, oc_last;
    reg [CH_CNT_WIDTH-1:0] ic_cnt, oc_cnt;
    wire [CH_CNT_WIDTH-1:0] ic_cnt_nxt, oc_cnt_nxt;
    assign ic_cnt_nxt = ic_done ? (ic_last ? 'b0 : ic_cnt + 1'b1) : ic_cnt;
    assign oc_cnt_nxt = oc_done ? (oc_last ? 'b0 : oc_cnt + 1'b1) : oc_cnt;

    assign ic_last = ic_cnt == ic_num;
    assign oc_last = oc_cnt == oc_num;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ic_cnt <= 'b0;
            oc_cnt <= 'b0;
        end else begin
            ic_cnt <= ic_cnt_nxt;
            oc_cnt <= oc_cnt_nxt;
        end
    end

    wire pc_col_last = pc_col == pc_col_max;

    reg [4:0] flush_stage;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            flush_stage <= 'b0;
        end else begin
            flush_stage <= {flush_stage[3:0], start_conv | (~conv_done & ic_done)};
        end
    end

    reg [4:0] conv_done_reg;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) conv_done_reg <= 'b0;
        else conv_done_reg <= {conv_done_reg[3:0], conv_done};
    end

    // FSM
    localparam IDLE = 3'b001;
    localparam FLUSH = 3'b010;
    localparam CALC = 3'b100;

    reg [2:0] curr_state, next_state;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end

    always @(*) begin
        case (curr_state)
            IDLE: begin
                if (start_conv) next_state = FLUSH;
                else next_state = IDLE;
            end
            FLUSH: begin
                if (flush_stage[4]) next_state = CALC;
                else next_state = FLUSH;
            end
            CALC: begin
                if (conv_done) next_state = IDLE;
                else if (ic_done) next_state = FLUSH;
                else next_state = CALC;
            end
            default: next_state = IDLE;
        endcase
    end

    reg  first_calc;
    wire first_calc_nxt = first_calc ? ~flush_stage[4] : start_conv;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) first_calc <= 1'b0;
        else first_calc <= first_calc_nxt;
    end

    // Read a row of weight kernel(3x3)
    // assign wgt_read  = first_calc ? |flush_stage[2:0] : ((|flush_stage[1:0]) | ic_done);
    assign wgt_read  = (start_conv | (|flush_stage[1:0])) | ((|flush_stage[1:0]) | (~conv_done&ic_done));
    assign ifm_read = start_conv | (|curr_state[2:1]);

    // PE data valid signal for different stride(1/2)
    assign cnt_valid = curr_state[2] | (curr_state[1] & (|flush_stage[4:2]));

    reg [2:0] pvalid_s1_reg;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) pvalid_s1_reg <= 'b0;
        else pvalid_s1_reg <= {pvalid_s1_reg[1:0], cnt_valid};
    end

    reg pvalid_s2_reg;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pvalid_s2_reg <= 'b0;
        end else if (pvalid_s1_reg[1]) begin
            pvalid_s2_reg <= ~pvalid_s2_reg;
        end
    end

    wire pvalid_s2;
    assign pvalid_s2 = pvalid_s1_reg[2] & pvalid_s2_reg;
    assign pvalid = stride ? pvalid_s2 : pvalid_s1_reg[2];

    assign ic_done = pc_col_last & cnt_valid;
    assign oc_done = ic_last & ic_done;
    assign tile_done = oc_last & oc_done;
    assign tile_ver_done = tile_col_last & tile_done;
    assign conv_done = tile_row_last & tile_ver_done;

endmodule
