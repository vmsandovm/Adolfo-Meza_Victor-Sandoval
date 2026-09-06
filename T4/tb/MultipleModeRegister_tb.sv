`timescale 1ns / 1ps

module MultipleModeRegister_tb;
	parameter int DW = 4;

	logic          clk;
	logic          sync_reset;
	logic          enb;
	logic [DW-1:0] inp;
	logic [DW-1:0] out;

// Instancia del DUT
	MultipleModeRegister #( .DW(DW) ) dut (
		.clk   (clk),
		.sync_reset (sync_reset),
		.enb   (enb),
		.inp   (inp),
		.out   (out)
	);

//	Clock
	always #2 clk = ~clk;

// Estímulos
	initial begin
	clk   		=  0 ;
	sync_reset 	=  1 ;
	enb   		=  0 ;
	inp   		=  '0;	// Todos los bits empiezan en 0.

// PIPO

// reset off & enb On : Cargar 1010 y out = 1010
	#20;	sync_reset = 0;	enb 	= 1;	inp = 4'b1010; 
// Cargar 0101
	#20; 											inp = 4'b0101;
// Deshabilitar: out debe conservar 0101
	#20;							enb = 0;		inp = 4'b1111;
// Hacer reset
	#20;	sync_reset = 1;
	#20;
		
	$stop;
	end

endmodule