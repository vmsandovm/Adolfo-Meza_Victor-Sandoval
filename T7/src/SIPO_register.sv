module SIPO_register #(
    parameter int DW                    = 8
)(
	input logic clk, rst, SIPO_load, rx_sync,
	output logic [DW-1:0] Data_out
);

    always_ff @(posedge clk) begin
        if (rst == 1'b0)
            Data_out <= '0;
        else if (SIPO_load == 1'b1)
            Data_out <= {rx_sync, Data_out[DW-1:1]};
    end

endmodule

