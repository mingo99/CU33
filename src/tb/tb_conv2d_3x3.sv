///==------------------------------------------------------------------==///
/// testbench of top level conv kernel
///==------------------------------------------------------------------==///

module tb_conv2d_3x3;

    reg clk, rstn, start_conv;

    // configuration signals
    reg        [      `CHN_WIDTH-1:0] cfg_ci;
    reg        [      `CHN_WIDTH-1:0] cfg_co;
    reg                               cfg_stride;

    // data input
    reg        [`PEA33_IFM_WIDTH-1:0] ifm_group;
    reg        [`PEA33_WGT_WIDTH-1:0] wgt_group;

    // output of dut
    wire sum_t                        sum        [`PEA33_COL];
    wire       [      `PEA33_COL-1:0] sum_valid;
    wire ifm_read, wgt_read, conv_done;

    reg [32:0] ifm_cnt;
    reg [32:0] wgt_cnt;

    /// Store weight and ifm
    reg [ 7:0] ifm_in  [`IFM_LEN];
    reg [ 7:0] wgt_in  [`WGT_LEN];

    integer fp_w [`PEA33_COL];
    sum_q sum_group[`PEA33_COL];
    reg signed [`OFM_WIDTH-1:0] ofm[`CHO][`OFM_SIZE][`OFM_SIZE];

    /// Ifm dispatcher
    initial begin
        string ifm_file_name = $sformatf("../data/ifm_hex_c%0d_h%0d_w%0d.txt",`CHI,`IFM_SIZE,`IFM_SIZE);
        $readmemh(ifm_file_name, ifm_in);
    end

    always_comb begin
        if (!rstn) begin
            ifm_group = 0;
        end else if (ifm_read) begin
            ifm_group[7:0]   = ifm_in[ifm_cnt+0];
            ifm_group[15:8]  = ifm_in[ifm_cnt+1];
            ifm_group[23:16] = ifm_in[ifm_cnt+2];
            ifm_group[31:24] = ifm_in[ifm_cnt+3];
            ifm_group[39:32] = ifm_in[ifm_cnt+4];
            ifm_group[47:40] = ifm_in[ifm_cnt+5];
            ifm_group[55:48] = ifm_in[ifm_cnt+6];
            ifm_group[63:56] = ifm_in[ifm_cnt+7];
            ifm_group[71:64] = ifm_in[ifm_cnt+8];
            ifm_group[79:72] = ifm_in[ifm_cnt+9];
        end else ifm_group = 0;
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) ifm_cnt <= 0;
        else if (ifm_cnt == `IFM_LEN && !ifm_read) ifm_cnt <= 0;
        else if (ifm_read) ifm_cnt <= ifm_cnt + 10;
        else ifm_cnt <= ifm_cnt;
    end

    /// Wgt dispatcher
    initial begin
        string wgt_file_name = $sformatf("../data/weight_hex_co%0d_ci%0d_k3_k3.txt",`CHO,`CHI);
        $readmemh(wgt_file_name, wgt_in);
    end

    always_comb begin
        if (!rstn) begin
            wgt_group = 0;
        end else if (wgt_read) begin
            wgt_group[7:0]   = wgt_in[wgt_cnt+0];
            wgt_group[15:8]  = wgt_in[wgt_cnt+1];
            wgt_group[23:16] = wgt_in[wgt_cnt+2];
        end else begin
            wgt_group = 0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) wgt_cnt <= 0;
        else if (wgt_cnt == `WGT_LEN && !wgt_read) wgt_cnt <= 0;
        else if (wgt_read) wgt_cnt <= wgt_cnt + 3;
 else wgt_cnt <= wgt_cnt;
    end

task automatic get_sum();
    for (int i = 0; i < `PEA33_COL; ++i) begin
    automatic int col = i;
    fork
    @(posedge clk iff sum_valid[col]);
    $display("valid is assert");
    sum_group[col].push_back(sum[col]);
    join_none
    end
    endtask

    // function static write_ofm();
    // for (int tr = 0; tr < `TILE_ROW; ++tr) begin
    // for (int tc = 0; tc < `TILE_COL; ++tc) begin
    // $fwrite(fp_w, "\n");
    // for (int oc = 0; oc < `CHO; ++oc) begin
    // $fwrite(fp_w, "\n");
    // for (int ow = 0; ow < `TILE_RUN; ++ow) begin
    // for (int oh = 0; oh < `TILE_LEN; ++oh) begin
    // // ofm[oc][tr*`TILE_RUN+ow][tc*`TILE_LEN+oh] = sum_group[ow].pop_front();
    // $fwrite(fp_w, "%d ", sum_group[ow].pop_front());
    // if (oh == `TILE_LEN - 1) begin
    // $fwrite(fp_w, "\n");
    // end
    // end
    // end
    // end
    // end
    // end
    // $display("\033[32m[ConvKernel: ] Finish writing results to conv_acc_out.txt\033[0m");
    // endfunction
    //
    // generate clock
    initial begin
        clk = 1'b0;
        #5 clk = 1'b1;
        forever #5 clk = ~clk;
    end
    /// reset and other control signal from master side
    initial begin
        // fp_w       = $fopen("conv_acc_out.txt");
        rstn       = 1;
        start_conv = 0;
        cfg_ci     = `CHN_64;
        cfg_co     = `CHN_64;
        cfg_stride = 0;
        #10 rstn = 0;
        #10 rstn = 1;

        $display(`CHI, `CHO);
        $display(`TILE_ROW, `TILE_COL);
        $display(`IFM_LEN, `WGT_LEN);
        #10 @(posedge clk) start_conv <= 1;
        #10 @(posedge clk) start_conv <= 0;
        // #10 start_conv = 0;
        $display("\n\033[32m[ConvKernel: ] Set the clock period to 10ns\033[0m");
        $display("\033[32m[ConvKernel: ] Start to compute conv\033[0m");
        while(!conv_done) @(posedge clk);
        $display("\033[32m Finish computing \033[0m");
        $finish();
    end

    // initial begin
    // forever begin
    // get_sum();
    // end
    // end

    // extract wave information
    initial begin
        $fsdbDumpfile("sim_output_pluson.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA(0);
    end

    conv2d_3x3 #(
        .COL          (`PEA33_COL),
        .WGT_WIDTH    (`PEA33_WGT_WIDTH),
        .IFM_WIDTH    (`PEA33_IFM_WIDTH),
        .OFM_WIDTH    (`OFM_WIDTH),
        .RF_AWIDTH    (`RF_AWIDTH),
        .TILE_LEN     (`TILE_LEN),
        .CHN_WIDTH    (`CHN_WIDTH),
        .CHN_OFT_WIDTH(`CHN_OFT_WIDTH),
        .FMS_WIDTH    (`FMS_WIDTH)
    ) u_conv2d_3x3 (
        .clk         (clk),
        .rstn        (rstn),
        .cfg_ci      (cfg_ci),
        .cfg_co      (cfg_co),
        .cfg_stride  (cfg_stride),
        .cfg_ifm_size(`IFM_SIZE),
        .start_conv  (start_conv),
        .ifm_group   (ifm_group),
        .wgt_group   (wgt_group),
        .ifm_read    (ifm_read),
        .wgt_read    (wgt_read),
        .conv_done   (conv_done),
        .sum_valid   (sum_valid),
        .sum         (sum)
    );

endmodule
