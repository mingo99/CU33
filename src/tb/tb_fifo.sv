///==------------------------------------------------------------------==///
/// testbench of synchronous fifo
///==------------------------------------------------------------------==///

`define BUF_ADDR_WIDTH 3
`define BUF_DATA_WIDTH 25

module tb_fifo ();
    reg clk, rstn;
    reg [`BUF_DATA_WIDTH-1:0] data_in;
    reg [`BUF_DATA_WIDTH-1:0] data;
    wire [`BUF_DATA_WIDTH-1:0] data_out;
    wire empty;
    wire full;
    reg wr_en, rd_en;
    reg wr_factor, rd_factor;

    initial begin
        wr_factor = 0;
        rd_factor = 0;
        @(posedge rstn);
        wr_factor = 1;
        rd_factor = 0;
        #105 rd_factor = 1;
        #205 wr_factor = 0;
        #305 wr_factor = 1;
        #405 rd_factor = 1;
        #505 wr_factor = 0;
    end

    always_comb begin
        wr_en = ~full & wr_factor;
        rd_en = ~empty & rd_factor;
    end

    /// clock generation
    always #5 clk = ~clk;

    initial begin
        @(posedge rstn);
        forever begin
            @(posedge clk iff rd_en);
            $display("Pop data: %d", data_out);
        end
    end

    initial begin
        @(posedge rstn);
        forever begin
            data_in <= data_in + 1;
            @(posedge clk iff wr_en);
            $display("Push data: %d", data_in);
        end
    end

    /// Run simulation
    initial begin
        clk     = 0;
        rstn    = 1;
        rd_en   = 0;
        wr_en   = 0;
        data_in = 0;
        #5 rstn = 0;
        #10 rstn = 1;

        #600 $finish;
    end

    syncfifo #(
        .DWIDTH(`BUF_DATA_WIDTH),
        .AWIDTH(`BUF_ADDR_WIDTH)
    ) u_syncfifo (
        .clk  (clk),
        .rstn (rstn),
        .wren (wr_en),
        .rden (rd_en),
        .wdata(data_in),
        .rdata(data_out),
        .full (full),
        .empty(empty)
    );

    initial begin
        $fsdbDumpfile("sim_output_pluson.fsdb");
        $fsdbDumpvars(0);
    end

endmodule

