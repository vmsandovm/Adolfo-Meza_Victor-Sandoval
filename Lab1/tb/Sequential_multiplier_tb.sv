`timescale 1ns / 1ps

module Sequential_multiplier_tb;

	parameter int DW = 5;
	
	logic Start;
	logic Reset;
	logic Clock;
	logic Square;
	
	logic [DW-1:0] Data0;
	logic [DW-1:0] Data1;

	logic Ready;
	logic [2*DW-1:0] Result;
	
// Instancia del DUT
	Sequential_multiplier #( .DW(DW)
	) dut (
		.Start(Start),
		.Reset(Reset),
		.Square(Square),
		.Clock(Clock),
		.Data0(Data0),
		.Data1(Data1),
		
		.Ready(Ready),
		.Result(Result)
	);
	
//	Clock 5 MHz
	always #100 Clock = ~Clock;	

//	Estados iniciales	
	initial begin	
	Start= 1'b0;
	Reset= 1'b0;
	Clock= 1'b0;
	Square= 1'b0;
	
	Data0= '0;
	Data1= '0;

// Reset
	#200;
	Reset = 1'b1;
// Preparar operación
	Data0 = 3;
	Data1 = 5;
	Square = 1'b0;

	// Pulso de Start durante un ciclo
	#100;
	Start = 1'b1;

	#200;
	Start = 1'b0;

	#2000;	// TIempo de sobra para ver si el resultado se genera correctamente
	
	$stop;	
	end
endmodule