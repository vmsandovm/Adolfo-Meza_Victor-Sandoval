`timescale 1ns / 1ps

module MultipleModeRegister_tb;
	parameter int DW = 4;

	logic          clk;
	logic          reset;
	logic          enb;
	logic [DW-1:0] inp;
	logic [DW-1:0] out;

// Instancia del DUT
	MultipleModeRegister #( .DW(DW) ) dut (
		.clk   (clk),
		.reset (reset),
		.enb   (enb),
		.inp   (inp),
		.out   (out)
	);

//	Clock
	always #5 clk = ~clk;

// Estímulos
	initial begin
	clk   =  0;
	reset =  1;
	enb   =  0;
	inp   = '0;

// PIPO

// reset off & enb On : Cargar 1010 y out = 1010
	#10;	reset = 0;	enb 	= 1;	inp = 4'b1010; 
// Cargar 0101
	#10; 									inp = 4'b0101;
// Deshabilitar: out debe conservar 0101
	#10;					enb = 0;		inp = 4'b1111;
// Hacer reset
	#10;	reset = 1;
	#10;
		
	$stop;
	end

endmodule