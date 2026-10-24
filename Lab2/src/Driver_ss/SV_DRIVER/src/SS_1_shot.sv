/*
* Module name: SS_1_shot
* Description: This module detects rising and falling transactions of signals.
* Author: Santiago Miguel Segovia Cazares
* Date: 03/12/2023
* Version: 1.0
* Release notes:
* 		1.0: Initial version
* Ports:
*  Inputs:
*   clk, register clock (works with posedge signal detection).
*   rst, asynchronos register reset signal, active in zero.
*   data_in, signal data to detect edges.
*  Outputs:
*   rising_shot, single cycle clock bit indicating data_in is rising
*   falling_shot, single cycle clock bit indicating data_in is falling
*/
module SS_1_shot#(
	// Register syze in bits
	parameter DW = 8
)(
	input clk,
	input rst,
	input data_in,
	output rising_shot,
	output falling_shot
);
wire last_data_in_wire;
wire previous_data_in_wire;

SS_register#(
	.DW(1)
)last_data_in(
	.clk(clk),
	.rst(rst),
	.enable(1'b1),
	.sync_rst(1'b0),
	.data_in(data_in),
	.data_out(last_data_in_wire)
);

SS_register#(
	.DW(1)
)previous_data_in(
	.clk(clk),
	.rst(rst),
	.enable(1'b1),
	.sync_rst(1'b0),
	.data_in(last_data_in_wire),
	.data_out(previous_data_in_wire)
);

assign rising_shot = last_data_in_wire & ~previous_data_in_wire;
assign falling_shot = ~last_data_in_wire & previous_data_in_wire;

endmodule
