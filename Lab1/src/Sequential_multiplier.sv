module Sequential_multiplier#( parameter int DW = 5,
                               parameter bit ACTIVE_LOW_BUTTONS = 1'b0
)(
	input logic Start,
	input logic Reset,
	input logic Clock,
	input logic Square,
	input logic [DW-1:0] Data0,
	input logic [DW-1:0] Data1,

	output logic Ready,
	output logic [(2*DW)-1:0] Result,
	
	output logic [6:0] HEX0,
	output logic [6:0] HEX1,
	output logic [6:0] HEX2,
	output logic [6:0] HEX3
	 
);

	logic [DW-1:0] Multiplicand_w;
	logic [DW-1:0] Multiplier_w;

	logic [(2*DW)+1:0] Product_w;
	logic [(2*DW)+1:0] Product_next_w;

	logic Iterate_w;
	logic Load_w;
	logic Capture_w;
	
	logic Clock_5MHz_w;
	logic PLL_locked_w;
	logic Reset_system_w;

	logic Start_w;
	logic Square_w;
	logic [1:0] Start_sync;
	logic Start_sync_previous;
	logic Start_pulse_w;

	assign Reset_system_w = Reset & PLL_locked_w;
	
	PLL_50MHz_a_5MHz Clock_generator (
		.refclk   (Clock),
		.rst      (~Reset),
		.outclk_0 (Clock_5MHz_w),
		.locked   (PLL_locked_w)
	);

// Los botones de la tarjeta son cero al presionarse y son uno sin presionar.
	always_comb begin
		if (ACTIVE_LOW_BUTTONS == 1'b1) begin
			Start_w  = ~Start;
			Square_w = ~Square;
		end
		else begin
			Start_w  = Start;
			Square_w = Square;
		end
	end

// Solo el flanco dispara la operacion, asi un boton sostenido no la relanza
	always_ff @(posedge Clock_5MHz_w or negedge Reset_system_w) begin
		if (Reset_system_w == 1'b0) begin
			Start_sync     		<= 2'b00;
			Start_sync_previous <= 1'b0;
		end
		else begin
			Start_sync     		<= {Start_sync[0], Start_w};
			Start_sync_previous <= Start_sync[1];
		end
	end

	// el valor nuevo es 1 Y el valor viejo es 0
	assign Start_pulse_w = Start_sync[1] & ~Start_sync_previous;
	
	Mux2to1_mod #( .DW(DW)  
	) Mul_Or_Square (
		.Input0(Data0),
		.Input1(Data1),
		.Sel(Square_w),
		.Output_fixed(Multiplicand_w),
		.Output2(Multiplier_w)
	);
	 
	FSM_Mealy #( .DW(DW)  
	) Booth_controller (
		.Clock(Clock_5MHz_w),
		.Reset(Reset_system_w),
		.Start(Start_pulse_w),

		.Ready(Ready),
		.Iterate(Iterate_w),
		.Load(Load_w),
		.Capture(Capture_w)
	);
	
	Booth_datapath #( .DW(DW)  
	) Booth_magic (
		.Reset(Reset_system_w),
		.Clock(Clock_5MHz_w),
		.Multiplicand_init(Multiplicand_w),
		.Multiplier_init(Multiplier_w),
		.Iterate(Iterate_w),
		.Load(Load_w),

		.Product(Product_w),
		.Product_next(Product_next_w)
	);

	Booth_result #( .DW(DW)  
	) Booth_result (
		.Clock(Clock_5MHz_w),
		.Reset(Reset_system_w),
		.Product(Product_next_w),
		.Capture(Capture_w),

		.Result(Result)
	);
	
	Result_display #( .DW(DW)
	) Display (
		.Result(Result),
	
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3)
	);
	
endmodule