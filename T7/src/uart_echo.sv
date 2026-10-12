import Poli_Register_Modes_pkg::*;

module uart_echo #( parameter DW= 8, parameter CLKS_PER_BIT = 43, parameter string PARITY_TYPE = "ODD" )(
	input logic Reset, 
	input logic Clk, 
	input logic Pin_rx, 

	output logic Pin_tx,
	output logic Ready
);

	logic PLL_locked_w;
	logic Clock_5MHz_w;	

	uart_pll PLL_50MHz_a_5MHz(
		.refclk(Clk), .rst(~Reset), 
		.outclk_0(Clock_5MHz_w), .locked(PLL_locked_w)
	);


// Rx
	logic [DW-1:0] Received;
	logic [2:0] bit_count;
	logic en_baud_count;
	logic en_bit_count;
	logic sample_count;
	logic SIPO_load;
	logic en_parity;
	logic rx_sync;
	logic received_pulse;
	logic parity_error;

	Synchronizer synchronizer (
		.clk(Clock_5MHz_w),
		.rst(Reset),
		.rx_async(Pin_rx),
		.rx_sync(rx_sync)
	);

	BR_counter #( .CLK_CYCLES_PER_BIT(CLKS_PER_BIT) ) br_counter (
		.clk(Clock_5MHz_w),
		.rst(Reset),
		.en_baud_count(en_baud_count),
		.sample_count(sample_count)
	);

	Bit_counter bit_counter (
		.clk(Clock_5MHz_w),
		.rst(Reset),
		.en_bit_count(en_bit_count),
		.sample_count (sample_count), 
		.bit_count(bit_count)
	);

	SIPO_register #( .DW(DW) ) sipo_register (
		.clk(Clock_5MHz_w),
		.rst(Reset),
		.SIPO_load(SIPO_load),
		.rx_sync(rx_sync),
		.Data_out(Received)
	);

	Parity_error #( .DW(DW), .PARITY_TYPE(PARITY_TYPE) ) parity_error_module (
		.Data_out(Received),
		.en_parity(en_parity),
		.parity_bit(rx_sync),
		.parity_error(parity_error)
	);

	UART_FSM_Mealy_Rx uart_fsm (
		.clk(Clock_5MHz_w),
		.rst(Reset),
		.rx_sync(rx_sync),
		.sample_count(sample_count),
		.bit_count(bit_count),
		.en_baud_count(en_baud_count),
		.en_bit_count(en_bit_count),
		.SIPO_load(SIPO_load),
		.en_parity(en_parity),
		.received(received_pulse)
	);

// Tx
	logic Data;
	logic enb;
	logic load_shift;
	logic Parity_control;
	logic Start_control;
	logic Data_control;	
	
	Poli_Register #( .DW(DW), .MODE(PISO_LSB_CIRC_MODE)	) PiSo_MSB (
		.clk(Clock_5MHz_w), .sync_reset(Reset), .enb(enb), .load_shift(load_shift), .inp(Received),
		
		.out(Data)
	);
	FSM_Moore_Tx #( .CLKS_PER_BIT(CLKS_PER_BIT) ) Tx_control (
		.Clk(Clock_5MHz_w), .Parity(1'b1), .Reset(Reset), .Start_tx(~received_pulse),
		
		.load_shift(load_shift), .enb(enb), .Parity_control(Parity_control), .Start_control(Start_control), .Ready(Ready), .Data_control(Data_control)
	);
	Tx_Frame #( .DW(DW) ) Tx_Frame ( 
		.Input(Received), .Reset(Reset), .Data(Data), .Parity_control(Parity_control), 
		.Start_control(Start_control), .Data_control(Data_control),
		
		.Output(Pin_tx)
	);
	 
	 
endmodule