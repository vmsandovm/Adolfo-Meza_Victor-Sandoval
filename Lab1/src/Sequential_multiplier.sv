module Sequential_multiplier#( parameter int DW = 5
)(
	input logic Start,
	input logic Reset,
	input logic Clock,
	input logic Square,
	input logic [DW-1:0] Data0,
	input logic [DW-1:0] Data1,

	output logic Ready,
	output logic [2*DW-1:0] Result
);

	logic [DW-1:0] Multiplicand_w;
	logic [DW-1:0] Multiplier_w;
	logic Iterate_w;
	logic Load_w;
	logic Capture_w;

	Mux2to1_mod #( .DW(DW)  
	) Mul_Or_Square (
		.Input0(Data0),
		.Input1(Data1),
		.Sel(Square),
		.Output_fixed(Multiplicand_w),
		.Output2(Multiplier_w)
	);
	 
	FSM_moore Booth_controller (
		.Clock(Clock),
		.Reset(Reset),
		.Start(Start),
		.Ready(Ready),
		.Iterate(Iterate_w),
		.Load(Load_w),
		.Capture(Capture_w)
	);

endmodule