import Poli_Register_Modes_pkg::*;

module MultipleModeRegister #( 
	parameter int DW   = 4,
	parameter int MODE = PIPO_MODE
)(
	input logic							clk, 
	input logic							sync_reset,
	input logic 						enb,
	input logic 						l_s,
	input logic  [ DW-1 :0 ]		inp,
	output logic [ DW-1 :0 ]		out
);

	Poli_Register #( 
	.DW(DW),
	.MODE(MODE)	
	) Registro (
	
	.clk   (clk),
	.sync_reset (sync_reset),
	.enb   (enb),
	.l_s   (l_s),
	.inp   (inp),
	.out   (out)
);

endmodule