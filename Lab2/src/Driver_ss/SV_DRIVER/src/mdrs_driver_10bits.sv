/*
* Module name: mdrs_driver_10bits
* Description: This module is ment to convert rx data received in given format from uart to MDRS
* 					input data and get results from mdrs module and send them out using a tx uart module.
*					Received expected format is as follows:
* 					BYTE | 7 bit | 6 bit | 5 bit | 4 bit | 3 bit | 2 bit | 1 bit | 0 bit
* 					  0  |   data_lower_3_bits   |      op       |  Load |  Rsvd |Trigger
* 					  1  |                 data_higher_7_bits                    | 1'b0
*					Send data expected format is as follows:
* 					BYTE | 7 bit | 6 bit | 5 bit | 4 bit | 3 bit | 2 bit | 1 bit | 0 bit
* 					  0  |   data_lower_3_bits   |      op       |  Load |  Rsvd |Trigger
* 					  1  |                 data_higher_7_bits                    | 1'b0
* 					  2  |                    result_lower_8_bits                    
* 					  3  |              reminder_lower_6_bits            |result_higher_2_bits 
* 					  4  | error | ready | loadY | loadX |      reminder_higher_4_bits                 
* Author: Santiago Miguel Segovia Cazares
* Date: 03/12/2023
* Version: 1.2
* Release notes:
* 		1.0: Initial version
* 		1.1: Added version local param and bug fixes for parameters.
* 		1.2: Removed start and renamed everything to mdrs.
* Ports:
*  Inputs:
*   clk_10MHz, system clock at 10MHz (same frequency than uart and mdrs modules).
*   rst, asynchronos system reset signal, active in zero.
*   uart_rx_data, data received from uart_rx (8 bits length).
*   uart_rx_received, single bit of 1 clock cycle duration when new data is got in uart rx.
							 if it is not single clock cycle, overwrite UART_RX_RECEIVED_ADD_1_SHOT to 1.
*	 uart_tx_ready, single bit that notifies when uart tx is not transmitting (i.e. is in IDLE state).
*	 mdrs_result, mdrs result port data
*	 mdrs_reminder, mdrs reminder port data
*	 mdrs_ready, mdrs ready signal (1 option trigger to send data back to uart tx).
*	 mdrs_loadX, mdrs loadx signal (1 option trigger to send data back to uart tx).
*	 mdrs_loadY, mdrs loady signal (1 option trigger to send data back to uart tx).
*	 mdrs_error, mdrs error signal (1 option trigger to send data back to uart tx).
*  Outputs:
*   uart_tx_data, uart data to be transmitted.
*   uart_tx_send, single bit to notify when uart tx data must be transmitted. Single clock cycle duration.
*   mdrs_data, 10-bits data port feeded to mdrs module
*   mdrs_op, 2-bits operation selector feeded to mdrs module
*   mdrs_load, bit to load data into mdrs module, 1-shoted
*/
module mdrs_driver_10bits#(
	// Parameters with default values for perfect uart features developed.
	parameter UART_TX_SWAP = 0,
	parameter UART_RX_SWAP = 0,
	parameter UART_RX_RECEIVED_ADD_1_SHOT = 0
)(
	// System general
	input clk_10MHz,
	input rst,
	// Uart ports
	//  RX
	input [7 : 0] uart_rx_data,
	input uart_rx_received,
	//  TX
	input uart_tx_ready,
	output [7 : 0] uart_tx_data,
	output uart_tx_send,
	// MDRS ports.
	//  mdrs inputs
	output [9 : 0] mdrs_data,
	output [1 : 0] mdrs_op,
	output mdrs_load,
	//  mdrs outputs
	input [9 : 0] mdrs_result,
	input [9 : 0] mdrs_reminder,
	input mdrs_error,
	input mdrs_ready,
	input mdrs_loadx,
	input mdrs_loady
);
localparam VERSION_MAJOR = 1;
localparam VERSION_MINOR = 2;

// input train data wires
wire [7 : 0] last_uart_rx_data_wire;
wire [7 : 0] previous_uart_rx_data_wire;
wire trigger_wire;
// mdrs data wires
wire [9 : 0] mdrs_data_wire;
wire [1 : 0] mdrs_op_wire;
wire mdrs_load_wire;
wire mdrs_load_1_shot_wire;
// output train data wires
wire [7 : 0] reponse_byte_4_wire;
wire [7 : 0] reponse_byte_3_wire;
wire [7 : 0] reponse_byte_2_wire;
wire [7 : 0] reponse_byte_1_wire;
wire [7 : 0] reponse_byte_0_wire;
wire [7 : 0] selected_reponse_byte_4_wire;
wire [7 : 0] selected_reponse_byte_3_wire;
wire [7 : 0] selected_reponse_byte_2_wire;
wire [7 : 0] selected_reponse_byte_1_wire;
// control unit wires
wire sending_wire;
wire sending_done_wire;
wire mdrs_error_1_shot_wire;
wire mdrs_ready_1_shot_wire;
wire mdrs_loadx_1_shot_wire;
wire mdrs_loady_1_shot_wire;



/***************************************************************/
/************** Workaround if RX is not well done **************/
/***************************************************************/
wire [7 : 0] uart_rx_data_wire;

genvar i;

generate
	for(i = 0; i < 8; i = i + 1) begin : swap_for
		if(UART_RX_SWAP) begin
			assign uart_rx_data_wire[i] = uart_rx_data[7 - i];
		end
		else begin
			assign uart_rx_data_wire[i] = uart_rx_data[i];
		end
	end
endgenerate
/***************************************************************/
/***************************************************************/
/***************************************************************/



/***************************************************************/
/********* Workaround if RX received is not well done **********/
/***************************************************************/
wire uart_rx_received_wire;
generate
	case(UART_RX_RECEIVED_ADD_1_SHOT)
	0: 	begin
		assign uart_rx_received_wire = uart_rx_received;
		end
	1:begin
		SS_1_shot received_1_shot(
			.clk(clk_10MHz),
			.rst(rst),
			.data_in(uart_rx_received),
			.rising_shot(uart_rx_received_wire),
			.falling_shot()
		);
		end
	endcase
endgenerate
/***************************************************************/
/***************************************************************/
/***************************************************************/



// INPUT register train
SS_register#(
	.DW(8)
)uart_rx_data_1(
	.clk(clk_10MHz),
	.rst(rst),
	.enable(uart_rx_received_wire),
	.sync_rst(1'b0),
	.data_in(uart_rx_data_wire),
	.data_out(last_uart_rx_data_wire)
);

SS_register#(
	.DW(8)
)uart_rx_data_2(
	.clk(clk_10MHz),
	.rst(rst),
	.enable(uart_rx_received_wire),
	.sync_rst(1'b0),
	.data_in(last_uart_rx_data_wire),
	.data_out(previous_uart_rx_data_wire)
);

SS_1_shot trigger_1shot(
	.clk(clk_10MHz),
	.rst(rst),
	.data_in(previous_uart_rx_data_wire[0]),
	.rising_shot(trigger_wire),
	.falling_shot()
);

// When trigger bit is 1 then pass all uart_rx saved data to mdrs ports
SS_register#(
	.DW(14)
)uart_rx_data_to_mdrs_inputs(
	.clk(clk_10MHz),
	.rst(rst),
	.enable(trigger_wire),
	.sync_rst(1'b0),
	.data_in({last_uart_rx_data_wire[7 : 1], previous_uart_rx_data_wire[7 : 2]}),
	.data_out({mdrs_data_wire, mdrs_op_wire, mdrs_load_wire})
);

SS_1_shot mdrs_load_1shot(
	.clk(clk_10MHz),
	.rst(rst),
	.data_in(mdrs_load_wire),
	.rising_shot(mdrs_load_1_shot_wire),
	.falling_shot()
);

// OUTPUT register train
SS_register#(
	.DW(8)
)response_reg_4(
	.clk(clk_10MHz),
	.rst(rst),
	.enable((uart_tx_ready & sending_wire) | ~ sending_wire),
	.sync_rst(1'b0),
	.data_in({mdrs_error, mdrs_ready, mdrs_loady, mdrs_loadx, mdrs_reminder[9 : 6]}),
	.data_out(reponse_byte_4_wire)
);

SS_mux#(
	.DW(8)
)reponse_mux_3(
   .data_0_in(reponse_byte_4_wire),
	.data_1_in({mdrs_reminder[5 : 0], mdrs_result[9 : 8]}),
	.selector(~sending_wire),
	.data_out(selected_reponse_byte_4_wire)
);

SS_register#(
	.DW(8)
)response_reg_3(
	.clk(clk_10MHz),
	.rst(rst),
	.enable((uart_tx_ready & sending_wire) | ~ sending_wire),
	.sync_rst(1'b0),
	.data_in(selected_reponse_byte_4_wire),
	.data_out(reponse_byte_3_wire)
);

SS_mux#(
	.DW(8)
)reponse_mux_2(
   .data_0_in(reponse_byte_3_wire),
	.data_1_in(mdrs_result[7 : 0]),
	.selector(~sending_wire),
	.data_out(selected_reponse_byte_3_wire)
);

SS_register#(
	.DW(8)
)response_reg_2(
	.clk(clk_10MHz),
	.rst(rst),
	.enable((uart_tx_ready & sending_wire) | ~ sending_wire),
	.sync_rst(1'b0),
	.data_in(selected_reponse_byte_3_wire),
	.data_out(reponse_byte_2_wire)
);

SS_mux#(
	.DW(8)
)reponse_mux_1(
   .data_0_in(reponse_byte_2_wire),
	.data_1_in(last_uart_rx_data_wire),
	.selector(~sending_wire),
	.data_out(selected_reponse_byte_2_wire)
);

SS_register#(
	.DW(8)
)response_reg_1(
	.clk(clk_10MHz),
	.rst(rst),
	.enable((uart_tx_ready & sending_wire) | ~ sending_wire),
	.sync_rst(1'b0),
	.data_in(selected_reponse_byte_2_wire),
	.data_out(reponse_byte_1_wire)
);

SS_mux#(
	.DW(8)
)reponse_mux_0(
   .data_0_in(reponse_byte_1_wire),
	.data_1_in(previous_uart_rx_data_wire),
	.selector(~sending_wire),
	.data_out(selected_reponse_byte_1_wire)
);

SS_register#(
	.DW(8)
)response_reg_0(
	.clk(clk_10MHz),
	.rst(rst),
	.enable((uart_tx_ready & sending_wire) | ~ sending_wire),
	.sync_rst(1'b0),
	.data_in(selected_reponse_byte_1_wire),
	.data_out(reponse_byte_0_wire)
);

// CONTROL unit
// mdrs status signals 1 shoted.
SS_1_shot mdrs_error_1shot(
	.clk(clk_10MHz),
	.rst(rst),
	.data_in(mdrs_error),
	.rising_shot(mdrs_error_1_shot_wire),
	.falling_shot()
);

SS_1_shot mdrs_ready_1shot(
	.clk(clk_10MHz),
	.rst(rst),
	.data_in(mdrs_ready),
	.rising_shot(mdrs_ready_1_shot_wire),
	.falling_shot()
);

SS_1_shot mdrs_loadx_1shot(
	.clk(clk_10MHz),
	.rst(rst),
	.data_in(mdrs_loadx),
	.rising_shot(mdrs_loadx_1_shot_wire),
	.falling_shot()
);

SS_1_shot mdrs_loady_1shot(
	.clk(clk_10MHz),
	.rst(rst),
	.data_in(mdrs_loady),
	.rising_shot(mdrs_loady_1_shot_wire),
	.falling_shot()
);

SS_register#(
	.DW(1)
)sending_reg(
	.clk(clk_10MHz),
	.rst(rst),
	.enable(mdrs_error_1_shot_wire | mdrs_ready_1_shot_wire | mdrs_loadx_1_shot_wire | mdrs_loady_1_shot_wire | sending_done_wire),
	.sync_rst(sending_done_wire),
	.data_in(1'b1),
	.data_out(sending_wire)
);

// previous_uart_rx_data_wire is rx trigger and counter restarts at that point.
SS_counter#(
	.DW(3),
	.COUNT(6)
)sending_counter(
	.clk(clk_10MHz),
	.rst(rst),
	.enable((uart_tx_ready & sending_wire) | trigger_wire),
	.sync_rst(trigger_wire),
	.data_count(),
	.overflow(sending_done_wire)
);



/***************************************************************/
/************** Workaround if TX is not well done **************/
/***************************************************************/
generate
	for(i = 0; i < 8; i = i + 1) begin : tx_swap_loop
		if(UART_TX_SWAP) begin
			assign uart_tx_data[i] = reponse_byte_0_wire[7 - i];
		end
		else begin
			assign uart_tx_data[i] = reponse_byte_0_wire[i];
		end
    end
endgenerate
/***************************************************************/
/***************************************************************/
/***************************************************************/


assign uart_tx_send = uart_tx_ready & sending_wire;
assign mdrs_data = mdrs_data_wire;
assign mdrs_op = mdrs_op_wire;
assign mdrs_load = mdrs_load_1_shot_wire;

endmodule
