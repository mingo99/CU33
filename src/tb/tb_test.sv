module tb_test;

    reg clk;
    task automatic write_ofm();
        $display("Start to write sum...");
        for (int i = 0; i < `PEA33_COL; ++i) begin
            fork
                automatic int col = i;
                automatic int j = 0;
                $display("Write line %0d", col);
                forever begin
                    $display("[Line] %0d: Write %0d", col, j);
                    j = j + 1;
                    #100;
                end
            join_none
        end
    endtask

    task automatic get_sum();
        $display("Start to get sum...");
        for (int i = 0; i < `PEA33_COL; ++i) begin
            fork
                automatic int col = i;
                $display("Get line %0d", col);
                forever begin
                    $display("[Line] %0d: Get xxx", col);
                    #100;
                end
            join_none
        end
    endtask

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        fork
            write_ofm();
            get_sum();
        join
    end

    initial begin
        for (int cnt = 0; cnt < 100; ++cnt) begin
            @(posedge clk);
            $display("Main thred: %0d", cnt);
        end
        $finish();
    end

    initial begin
        $fsdbDumpfile("sim_output_pluson.fsdb");
        $fsdbDumpvars(0);
    end
endmodule
