import Poli_Register_Modes_pkg::*;
import MDRS_pkg::*;

module UART_DMRS (
	input  logic Clk,
	input  logic Reset,
	input  logic Pin_rx,
	output logic Pin_tx
);

	localparam int DW             = 10;
	localparam int UART_DW        = 8;
	localparam int CLKS_PER_BIT   = 43;
	localparam string PARITY_TYPE = "ODD";

	
	logic Clock_5MHz_w;
	pll PLL_50MHz_a_5MHz (
		.refclk(Clk), .rst(~Reset), .outclk_0(Clock_5MHz_w), .locked()
	);

// ==========================================================================================
// UART
// ============================================================================================
	logic [UART_DW-1:0] Rx_data_w;
	logic [UART_DW-1:0] Tx_data_w;
	logic Rx_received_w;
	logic Tx_send_w;
	logic Tx_ready_w;

// Rx
	logic rx_sync_w;
	logic sample_count_w;
	logic [2:0] bit_count_w;
	logic en_baud_count_w;
	logic en_bit_count_w;
	logic SIPO_load_w;
	logic en_parity_w;
	logic parity_error_w;

	// Tx
	logic [UART_DW-1:0] Tx_hold_w;
	logic [UART_DW-1:0] Piso_w;
	logic Tx_serial_w;
	logic Tx_enb_w;
	logic Tx_load_shift_w;
	logic Tx_parity_control_w;
	logic Tx_start_control_w;
	logic Tx_data_control_w;

	Synchronizer Rx_synchronizer (
		.clk(Clock_5MHz_w), .rst(Reset),
		.rx_async(Pin_rx), .rx_sync(rx_sync_w)
	);

	// BR_counter #( .CLK_CYCLES_PER_BIT(CLKS_PER_BIT) ) Rx_baud_counter (
	// 	.clk(Clock_5MHz_w), .rst(Reset),
	// 	.en_baud_count(en_baud_count_w), .sample_count(sample_count_w)
	// );

	// Bit_counter Rx_bit_counter (
	// 	.clk(Clock_5MHz_w), .rst(Reset),
	// 	.en_bit_count(en_bit_count_w), .sample_count(sample_count_w),
	// 	.bit_count(bit_count_w)
	// );

	SIPO_register #( .DW(UART_DW) ) Rx_sipo (
		.clk(Clock_5MHz_w), .rst(Reset),
		.SIPO_load(SIPO_load_w), .rx_sync(rx_sync_w),
		.Data_out(Rx_data_w)
	);

	Parity_error #( .DW(UART_DW), .PARITY_TYPE(PARITY_TYPE) ) Rx_parity (
		.Data_out(Rx_data_w), .en_parity(en_parity_w), .parity_bit(rx_sync_w),
		.parity_error(parity_error_w)
	);

	// UART_FSM_Mealy_Rx Rx_control (
	// 	.clk(Clock_5MHz_w), .rst(Reset),
	// 	.rx_sync(rx_sync_w), .sample_count(sample_count_w), .bit_count(bit_count_w),
	// 	.en_baud_count(en_baud_count_w), .en_bit_count(en_bit_count_w),
	// 	.SIPO_load(SIPO_load_w), .en_parity(en_parity_w), .received(Rx_received_w)
	// );


	Poli_Register #( .DW(UART_DW), .MODE(PIPO_MODE) ) Tx_hold_reg (
		.clk(Clock_5MHz_w), .sync_reset(Reset), .enb(Tx_send_w),
		.load_shift(1'b1), .inp(Tx_data_w),
		.out(Tx_hold_w)
	);

	Poli_Register #( .DW(UART_DW), .MODE(PISO_LSB_CIRC_MODE) ) Tx_piso (
		.clk(Clock_5MHz_w), .sync_reset(Reset), .enb(Tx_enb_w),
		.load_shift(Tx_load_shift_w), .inp(Tx_hold_w),
		.out(Piso_w)
	);
	assign Tx_serial_w = Piso_w[0];

	// FSM_Moore_Tx #( .CLKS_PER_BIT(CLKS_PER_BIT) ) Tx_control (
	// 	.Clk(Clock_5MHz_w), .Parity(1'b1), .Reset(Reset), .Start_tx(~Tx_send_w),
	// 	.load_shift(Tx_load_shift_w), .enb(Tx_enb_w),
	// 	.Parity_control(Tx_parity_control_w), .Start_control(Tx_start_control_w),
	// 	.Ready(Tx_ready_w), .Data_control(Tx_data_control_w)
	// );

    UART_FSM #( .CLKS_PER_BIT(CLKS_PER_BIT) ) UART_control (
        .Clk(Clock_5MHz_w), .Reset(Reset),
        .Rx_sync(rx_sync_w), .Parity_error(parity_error_w),
        .Start_tx(~Tx_send_w), .Parity(1'b1),
        .SIPO_load(SIPO_load_w), .En_parity(en_parity_w), .Received(Rx_received_w),
        .load_shift(Tx_load_shift_w), .enb(Tx_enb_w),
        .Parity_control(Tx_parity_control_w), .Start_control(Tx_start_control_w),
        .Data_control(Tx_data_control_w), .Ready(Tx_ready_w)
    );
		

	Tx_Frame #( .DW(UART_DW) ) Tx_frame (
		.Input(Tx_hold_w), .Reset(Reset), .Data(Tx_serial_w),
		.Parity_control(Tx_parity_control_w), .Start_control(Tx_start_control_w),
		.Data_control(Tx_data_control_w),
		.Output(Pin_tx)
	);

// ============================================================================================
// SS (driver del maestro)
// ============================================================================================
	logic [DW-1:0] mdrs_data_w;
	logic [1:0] mdrs_op_w;
	logic mdrs_load_w;
	logic [DW-1:0] mdrs_result_w;
	logic [DW-1:0] mdrs_remainder_w;
	logic mdrs_error_w;
	logic mdrs_ready_w;
	logic mdrs_loadx_w;
	logic mdrs_loady_w;

	mdrs_driver_10bits #( .UART_TX_SWAP(0), .UART_RX_SWAP(0), .UART_RX_RECEIVED_ADD_1_SHOT(0) ) Driver (
		.clk_10MHz(Clock_5MHz_w), .rst(Reset),
		.uart_rx_data(Rx_data_w), .uart_rx_received(Rx_received_w),
		.uart_tx_ready(Tx_ready_w), .uart_tx_data(Tx_data_w), .uart_tx_send(Tx_send_w),
		.mdrs_data(mdrs_data_w), .mdrs_op(mdrs_op_w), .mdrs_load(mdrs_load_w),
		.mdrs_result(mdrs_result_w), .mdrs_reminder(mdrs_remainder_w),
		.mdrs_error(mdrs_error_w), .mdrs_ready(mdrs_ready_w),
		.mdrs_loadx(mdrs_loadx_w), .mdrs_loady(mdrs_loady_w)
	);

// ============================================================================================
// DMRS
// ============================================================================================
// Control
	logic Needs_Y_w;
	logic Division_w;
	logic Iterate_w;
	logic Fix_w;
	logic Capture_w;
	logic Counter_clear_w;
	logic Counter_enable_w;
	logic Last_iteration_w;
	logic Capture_X_w;
	logic Capture_Y_w;
	// logic Init_w;

// Registros e datapath
	logic [1:0] Op_r_w;
	// logic signed [DW:0] Multiplicand_r_w;
	// logic signed [DW:0] Multiplicand_d_w;
	// logic [(2*DW)+1:0] Product_r_w;
	// logic [(2*DW)+1:0] Product_d_w;
	// logic [(2*DW)+1:0] Product_next_w;
	// logic [DW-1:0] Result_d_w;
	// logic [DW-1:0] Remainder_d_w;
	// logic Error_d_w;
	// logic [(2*DW):0] Output_r_w;

// Mult (0) y div (1) requieren Y. Sqrt (2) y square (3) no.
	assign Needs_Y_w   = ~mdrs_op_w[1];

	assign Division_w  = (Op_r_w == OP_DIV) || (Op_r_w == OP_SQRT);

// Habilitaciones de captura
// LoadX y LoadY indican que operando se espera
	assign Capture_X_w = mdrs_loadx_w & mdrs_load_w;
	assign Capture_Y_w = mdrs_loady_w & mdrs_load_w;

	//assign Init_w      = Capture_Y_w | (Capture_X_w & ~Needs_Y_w); // El producto se inicializa cuando ya estan todos los operandos

	UART_MDRS_FSM DMRS_control (
		.Clk(Clock_5MHz_w), .Reset(Reset), .Load(mdrs_load_w), .Needs_Y(Needs_Y_w),
		.Last_iteration(Last_iteration_w), .Division(Division_w),
		.Ready(mdrs_ready_w), .LoadX(mdrs_loadx_w), .LoadY(mdrs_loady_w),
		.Iterate(Iterate_w), .Fix(Fix_w), .Capture(Capture_w),
		.Counter_clear(Counter_clear_w), .Counter_enable(Counter_enable_w)
	);

	Iteration_counter #( .DW(DW) ) DMRS_counter (
		.Clk(Clock_5MHz_w), .Reset(Reset),
		.Clear(Counter_clear_w), .Enable(Counter_enable_w),
		.Operation(Op_r_w), .Last_iteration(Last_iteration_w)
	);

	MDRS_datapath #( .DW(DW) ) DMRS_datapath_unit (
        .clk(Clock_5MHz_w), .rst(Reset),
        .save_x(Capture_X_w), .save_y(Capture_Y_w),
        .en_step(Iterate_w), .en_write_result(Fix_w), .capture(Capture_w),
        .operation(mdrs_op_w), .data(mdrs_data_w),
        .op_reg(Op_r_w), .result(mdrs_result_w), .remainder(mdrs_remainder_w), .error(mdrs_error_w)
    );

// 	DMRS_datapath #( .DW(DW) ) DMRS_booth (
// 		.Load(Init_w),
// 		.Multiplicand_init(mdrs_data_w), .Multiplier_init(mdrs_data_w),
// 		.Product(Product_r_w), .Multiplicand_r(Multiplicand_r_w),
// 		.Product_d_w(Product_d_w), .Multiplicand_extension_w(Multiplicand_d_w),
// 		.Product_next(Product_next_w)
// 	);

// 	DMRS_result #( .DW(DW) ) DMRS_result_logic (
// 		.Product_next(Product_next_w),
// 		.Result_d(Result_d_w), .Remainder_d(Remainder_d_w), .Error_d(Error_d_w)
// 	);

// 	Poli_Register #( .DW(2), .MODE(PIPO_MODE) ) DMRS_op_reg (
// 		.clk(Clock_5MHz_w), .sync_reset(Reset), .enb(Capture_X_w),
// 		.load_shift(1'b1), .inp(mdrs_op_w),
// 		.out(Op_r_w)
// 	);

// 	Poli_Register #( .DW(DW+1), .MODE(PIPO_MODE) ) DMRS_multiplicand_reg (
// 		.clk(Clock_5MHz_w), .sync_reset(Reset), .enb(Capture_X_w),
// 		.load_shift(1'b1), .inp(Multiplicand_d_w),
// 		.out(Multiplicand_r_w)
// 	);

// 	Poli_Register #( .DW((2*DW)+2), .MODE(PIPO_MODE) ) DMRS_product_reg (
// 		.clk(Clock_5MHz_w), .sync_reset(Reset), .enb(Init_w | Iterate_w),
// 		.load_shift(1'b1), .inp(Product_d_w),
// 		.out(Product_r_w)
// 	);

// // Result, remainder y error en un solo registro, capturados juntos
// 	Poli_Register #( .DW((2*DW)+1), .MODE(PIPO_MODE) ) DMRS_output_reg (
// 		.clk(Clock_5MHz_w), .sync_reset(Reset), .enb(Capture_w),
// 		.load_shift(1'b1), .inp({Error_d_w, Remainder_d_w, Result_d_w}),
// 		.out(Output_r_w)
// 	);

	// assign mdrs_result_w    = Output_r_w[DW-1:0];
	// assign mdrs_remainder_w = Output_r_w[(2*DW)-1:DW];
	// assign mdrs_error_w     = Output_r_w[2*DW];

endmodule