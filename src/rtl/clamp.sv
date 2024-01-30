module clamp #(
    parameter INPUT_DW = 8,
    parameter OUTPUT_DW = 8
)(
    input  logic [INPUT_DW-1:0]  data_in,
    output logic [OUTPUT_DW-1:0] data_out  
);
    always_comb begin
        if(data_in[INPUT_DW-1] && (!(&data_in[INPUT_DW-2:OUTPUT_DW-1]))) begin
            data_out = {{1'b1},{(OUTPUT_DW-1){1'b0}}};               
        end else if ((!data_in[INPUT_DW-1]) && (|data_in[INPUT_DW-2:OUTPUT_DW-1])) begin
            data_out = {{1'b0},{(OUTPUT_DW-1){1'b1}}};
        end else begin
            data_out = data_in[INPUT_DW-1:0];
        end
    end
endmodule
