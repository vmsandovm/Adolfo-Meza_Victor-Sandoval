/*
* Module name: SS_mux
* Description: This module works as a simple 2 ports multiplexor were selected data in is assigned to output.
* Author: Santiago Miguel Segovia Cazares
* Date: 03/12/2023
* Version: 1.0
* Release notes:
* 		1.0: Initial version
* Ports:
*  Inputs:
*   data_0_in, data to be assigned to output if selector is zero.
*   data_1_in, data to be assigned to output if selector is one.
*   selector, single bit signal that will choose which data is shown in output port.
*  Outputs:
*   data_out, data selected value.
*/
module SS_mux#(
	// data in/out syze in bits
	parameter DW = 8
)(
	input [DW - 1 : 0] data_0_in,
	input [DW - 1 : 0] data_1_in,
	input selector,
	output [DW - 1 : 0] data_out
);

assign data_out = (selector == 1'b0)? data_0_in : data_1_in;

endmodule
