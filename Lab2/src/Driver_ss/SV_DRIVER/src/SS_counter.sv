/*
* Module name: SS_counter
* Description: This module works as a simple counter with current count data output and overflow signal.
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
*  Outputs:
*   data_count, current counter value.
*   overflow, set when counter is at limit (COUNT - 1).
*/
module SS_counter #(
	parameter DW = 8,
	parameter COUNT = 10
)(
	input clk,
	input rst,
	input enable,
	input sync_rst,
	output [DW - 1 : 0] data_count,
	output overflow
);
logic [DW - 1 : 0] data_count_reg;
logic [DW - 1 : 0] next_data_count_l;
logic overflow_l;

always_comb begin
	overflow_l = data_count_reg >= COUNT - 1;
end

always_comb begin
	if (overflow_l) begin
		next_data_count_l = {DW{1'b0}};
	end
	else begin
		next_data_count_l = data_count_reg + 1'b1;
	end
end

always_ff@(posedge clk, negedge rst) begin
	if(!rst) begin
		data_count_reg <= {DW{1'b0}};
	end
	else if (enable) begin
		if(sync_rst) begin
			data_count_reg <= {DW{1'b0}};
		end
		else begin
			data_count_reg <= next_data_count_l;
		end
	end
end

assign data_count = data_count_reg;
assign overflow = overflow_l;

endmodule
