/*
* Module name: SS_register
* Description: This module works as a simple PIPO register with enable and sync_rst signals.
* Author: Santiago Miguel Segovia Cazares
* Date: 03/12/2023
* Version: 1.0
* Release notes:
* 		1.0: Initial version
* Ports:
*  Inputs:
*   clk, register clock (works with posedge signal detection).
*   rst, asynchronos register reset signal, active in zero.
*   enable, if set will pass data_in to data_out, otherwise will retain old value.
*   sync_rst, when set will ignore data_in and set 0's to register value and data_out (needs enable signal set).
*	 data_in, data to be passed to register
*  Outputs:
*   data_out, last data saved in register.
*/
module SS_register#(
	// Register syze in bits
	parameter DW = 8
)(
	input clk,
	input rst,
	input enable,
	input sync_rst,
	input [DW - 1 : 0] data_in,
	output [DW - 1 : 0] data_out
);

logic [DW - 1 : 0] data_reg;

always_ff @(posedge clk, negedge rst) begin
	// Active in low (zero)
	if (!rst) begin
		data_reg <= {DW {1'b0} };
	end
	else if(enable) begin
		if (sync_rst) begin
			data_reg <= {DW {1'b0} };
		end
		else begin
			data_reg <= data_in;
		end
	end
end

assign data_out = data_reg;

endmodule
